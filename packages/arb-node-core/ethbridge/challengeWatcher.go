package ethbridge

import (
	"context"
	"github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	ethcommon "github.com/ethereum/go-ethereum/common"
	"github.com/offchainlabs/arbitrum/packages/arb-node-core/ethbridgecontracts"
	"github.com/offchainlabs/arbitrum/packages/arb-node-core/ethutils"
	"github.com/offchainlabs/arbitrum/packages/arb-util/common"
	"github.com/pkg/errors"
	"strings"
)

type ChallengeKind uint8

const (
	UNINITIALIZED ChallengeKind = iota
	INBOX_CONSISTENCY
	INBOX_DELTA
	EXECUTION
	STOPPED_SHORT
	NO_CHALLENGE
)

var bisectedID ethcommon.Hash
var bisectedInboxDeltaID ethcommon.Hash

func init() {
	parsedChallenge, err := abi.JSON(strings.NewReader(ethbridgecontracts.ChallengeABI))
	if err != nil {
		panic(err)
	}
	bisectedID = parsedChallenge.Events["Bisected"].ID
	bisectedInboxDeltaID = parsedChallenge.Events["BisectedInboxDelta"].ID
}

type Cut interface {
	Equals(other Cut) bool
	Hash() [32]byte
}

type InboxConsistencyCut struct {
	InboxAccHash [32]byte
}

func (c InboxConsistencyCut) Equals(other Cut) bool {
	o, ok := other.(InboxConsistencyCut)
	if !ok {
		return false
	}
	return c.InboxAccHash == o.InboxAccHash
}

func (c InboxConsistencyCut) Hash() [32]byte {
	return c.InboxAccHash
}

type InboxDeltaCut struct {
	InboxAccHash   [32]byte
	InboxDeltaHash [32]byte
}

func (c InboxDeltaCut) Equals(other Cut) bool {
	o, ok := other.(InboxDeltaCut)
	if !ok {
		return false
	}
	return c.InboxAccHash == o.InboxAccHash && c.InboxDeltaHash == o.InboxDeltaHash
}

func (c InboxDeltaCut) Hash() [32]byte {
	return inboxDeltaHash(c.InboxAccHash, c.InboxDeltaHash)
}

type Bisection struct {
	ChallengedSegment *ChallengeSegment
	Cuts              []Cut
}

type ChallengeTurn uint8

const (
	NONE ChallengeTurn = iota
	ASSERTER
	CHALLENGER
)

type ChallengeWatcher struct {
	con     *ethbridgecontracts.Challenge
	address ethcommon.Address
	client  ethutils.EthClient
}

func NewChallengeWatcher(address ethcommon.Address, client ethutils.EthClient) (*ChallengeWatcher, error) {
	con, err := ethbridgecontracts.NewChallenge(address, client)
	if err != nil {
		return nil, err
	}

	return &ChallengeWatcher{
		con:     con,
		address: address,
		client:  client,
	}, nil
}

func (c *ChallengeWatcher) Kind(ctx context.Context) (ChallengeKind, error) {
	rawKind, err := c.con.Kind(&bind.CallOpts{Context: ctx})
	if err != nil {
		return 0, err
	}
	return ChallengeKind(rawKind), nil
}

func (c *ChallengeWatcher) Turn(ctx context.Context) (ChallengeTurn, error) {
	rawTurn, err := c.con.Turn(&bind.CallOpts{Context: ctx})
	if err != nil {
		return 0, err
	}
	return ChallengeTurn(rawTurn), nil
}

func (c *ChallengeWatcher) Asserter(ctx context.Context) (common.Address, error) {
	asserter, err := c.con.Asserter(&bind.CallOpts{Context: ctx})
	if err != nil {
		return common.Address{}, err
	}
	return common.NewAddressFromEth(asserter), nil
}

func (c *ChallengeWatcher) Challenger(ctx context.Context) (common.Address, error) {
	challenger, err := c.con.Challenger(&bind.CallOpts{Context: ctx})
	if err != nil {
		return common.Address{}, err
	}
	return common.NewAddressFromEth(challenger), nil
}

func (c *ChallengeWatcher) CurrentResponder(ctx context.Context) (common.Address, error) {
	responder, err := c.con.CurrentResponder(&bind.CallOpts{Context: ctx})
	if err != nil {
		return common.Address{}, err
	}
	return common.NewAddressFromEth(responder), nil
}

func (c *ChallengeWatcher) ChallengeState(ctx context.Context) (common.Hash, error) {
	challengeState, err := c.con.ChallengeState(&bind.CallOpts{Context: ctx})
	if err != nil {
		return common.Hash{}, err
	}
	return common.NewHashFromEth(challengeState), nil
}

func (c *ChallengeWatcher) LookupBisection(ctx context.Context, challengeState common.Hash) (*Bisection, error) {
	var query = ethereum.FilterQuery{
		BlockHash: nil,
		FromBlock: nil,
		ToBlock:   nil,
		Addresses: []ethcommon.Address{c.address},
		Topics:    [][]ethcommon.Hash{{bisectedID, bisectedInboxDeltaID}, {challengeState.ToEthHash()}},
	}
	logs, err := c.client.FilterLogs(ctx, query)
	if err != nil {
		return nil, err
	}
	if len(logs) == 0 {
		return nil, errors.New("no matching bisection")
	}
	if len(logs) > 1 {
		return nil, errors.New("too many matching  bisections")
	}
	var cuts []Cut
	var challengeSegment *ChallengeSegment
	if logs[0].Topics[0] == bisectedID {
		parsedLog, err := c.con.ParseBisected(logs[0])
		if err != nil {
			return nil, err
		}
		cuts = make([]Cut, 0, len(parsedLog.ChainHashes))
		for _, ch := range parsedLog.ChainHashes {
			cuts = append(cuts, InboxConsistencyCut{InboxAccHash: ch})
		}
		challengeSegment = &ChallengeSegment{
			Start:  parsedLog.ChallengedSegmentStart,
			Length: parsedLog.ChallengedSegmentLength,
		}
	} else if logs[0].Topics[0] == bisectedInboxDeltaID {
		parsedLog, err := c.con.ParseBisectedInboxDelta(logs[0])
		if err != nil {
			return nil, err
		}
		cuts = make([]Cut, 0, len(parsedLog.InboxAccHashes))
		for i, inboxAccHash := range parsedLog.InboxAccHashes {
			cuts = append(cuts, InboxDeltaCut{
				InboxAccHash:   inboxAccHash,
				InboxDeltaHash: parsedLog.InboxDeltaHashes[i],
			})
		}
		challengeSegment = &ChallengeSegment{
			Start:  parsedLog.ChallengedSegmentStart,
			Length: parsedLog.ChallengedSegmentLength,
		}
	} else {
		return nil, errors.New("unexpected event type")
	}

	return &Bisection{
		ChallengedSegment: challengeSegment,
		Cuts:              cuts,
	}, nil
}
