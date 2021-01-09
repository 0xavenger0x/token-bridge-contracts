// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2021, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.6.11;

import "./IRollup.sol";
import "./Node.sol";
import "./RollupLib.sol";
import "./Inbox.sol";
import "./Outbox.sol";
import "./INodeFactory.sol";

import "../challenge/ChallengeLib.sol";
import "../challenge/IChallengeFactory.sol";

contract Rollup is Inbox, Outbox, IRollup {
    event SentLogs(bytes32 logsAccHash);

    struct Staker {
        uint256 index;
        uint256 latestStakedNode;
        uint256 amountStaked;
        // currentChallenge is 0 if staker is not in a challenge
        address currentChallenge;
        bool isStaked;
    }

    struct Zombie {
        address stakerAddress;
        uint256 latestStakedNode;
    }

    struct ChallengeState {
        bytes32 inboxConsistencyHash;
        bytes32 inboxDeltaHash;
        bytes32 executionHash;
        uint256 executionCheckTime;
    }

    uint256 public latestConfirmed;
    uint256 public firstUnresolvedNode;
    uint256 public latestNodeCreated;
    mapping(uint256 => Node) public nodes;
    uint256 lastStakeBlock;

    address payable[] public stakerList;
    mapping(address => Staker) public stakerMap;

    Zombie[] zombies;

    // Rollup Config
    uint256 public challengePeriodBlocks;
    uint256 public arbGasSpeedLimitPerBlock;
    uint256 public baseStake;
    address public stakeToken;

    IChallengeFactory public challengeFactory;
    INodeFactory public nodeFactory;

    constructor(
        bytes32 _machineHash,
        uint256 _challengePeriodBlocks,
        uint256 _arbGasSpeedLimitPerBlock,
        uint256 _baseStake,
        address _stakeToken,
        address _owner,
        address _challengeFactory,
        address _nodeFactory,
        bytes memory _extraConfig
    ) public {
        challengeFactory = IChallengeFactory(_challengeFactory);
        nodeFactory = INodeFactory(_nodeFactory);

        bytes32 state =
            RollupLib.nodeStateHash(
                block.number, // block proposed
                0,
                _machineHash,
                0, // inbox top
                0, // inbox count
                0, // send count
                0, // log count
                0 // inbox max couny
            );
        Node node =
            Node(
                nodeFactory.createNode(
                    state,
                    0, // challenge hash (not challengeable)
                    0, // confirm data
                    0, // prev node
                    0 // deadline block (not challengeable)
                )
            );
        nodes[0] = node;

        challengePeriodBlocks = _challengePeriodBlocks;
        arbGasSpeedLimitPerBlock = _arbGasSpeedLimitPerBlock;
        baseStake = _baseStake;
        stakeToken = _stakeToken;

        sendInitializationMessage(
            abi.encodePacked(
                uint256(_challengePeriodBlocks),
                uint256(_arbGasSpeedLimitPerBlock),
                uint256(_baseStake),
                bytes32(bytes20(_stakeToken)),
                bytes32(bytes20(_owner)),
                _extraConfig
            )
        );

        firstUnresolvedNode = 1;
    }

    function rejectNextNode(uint256 successorWithStake, address stakerAddress) external {
        checkUnresolved();
        checkNoRecentStake();

        require(successorWithStake > firstUnresolvedNode, "SUCCESSOR_TO_LOW");
        require(successorWithStake <= latestNodeCreated, "SUCCESSOR_TO_HIGH");
        require(stakerMap[stakerAddress].isStaked, "NOT_STAKED");

        // Confirm that someone is staked on some sibling node
        Node stakedSiblingNode = nodes[successorWithStake];
        // stakedSiblingNode is a child of latestConfirmed
        require(stakedSiblingNode.prev() == latestConfirmed, "BAD_SUCCESSOR");
        // staker is actually staked on stakedSiblingNode
        require(stakedSiblingNode.stakers(stakerAddress), "BAD_STAKER");

        removeOldZombies(0);

        Node node = nodes[firstUnresolvedNode];
        node.checkConfirmInvalid(countStakedZombies(node));
        destroyNode(firstUnresolvedNode);
        firstUnresolvedNode++;
    }

    // If the node previous to this one is not the latest confirmed, we can reject immediately
    function rejectNextNodeOutOfOrder() external {
        checkUnresolved();
        Node node = nodes[firstUnresolvedNode];
        node.checkConfirmOutOfOrder(latestConfirmed);
        destroyNode(firstUnresolvedNode);
        firstUnresolvedNode++;
    }

    function confirmNextNode(
        bytes32 logAcc,
        bytes calldata messageData,
        uint256[] calldata messageLengths
    ) external {
        checkUnresolved();
        checkNoRecentStake();

        Node node = nodes[firstUnresolvedNode];

        removeOldZombies(0);

        // Make sure that the number of stakes on the node is that sum of the number of real stakers and the number of zombies staked there
        node.checkConfirmValid(stakerList.length + countStakedZombies(node), latestConfirmed);

        bytes32 sendAcc = RollupLib.generateLastMessageHash(messageData, messageLengths);
        require(node.confirmData() == RollupLib.confirmHash(sendAcc, logAcc), "CONFIRM_DATA");

        processOutgoingMessages(messageData, messageLengths);

        destroyNode(latestConfirmed);

        latestConfirmed = firstUnresolvedNode;
        firstUnresolvedNode++;

        emit SentLogs(logAcc);
    }

    function newStakeOnExistingNode(
        bytes32 blockHash,
        uint256 blockNumber,
        uint256 nodeNum
    ) external payable {
        require(blockhash(blockNumber) == blockHash, "invalid known block");
        // Must stake on valid node
        checkValidNodeNumForStake(nodeNum);
        Node node = nodes[nodeNum];
        require(node.prev() == latestConfirmed);

        Staker storage staker = addNewStaker();

        node.addStaker(msg.sender);
        staker.latestStakedNode = nodeNum;
    }

    function addStakeOnExistingNode(
        bytes32 blockHash,
        uint256 blockNumber,
        uint256 nodeNum
    ) external {
        require(blockhash(blockNumber) == blockHash, "invalid known block");
        checkValidNodeNumForStake(nodeNum);
        Staker storage staker = stakerMap[msg.sender];
        require(staker.isStaked, "NOT_STAKED");
        Node node = nodes[nodeNum];
        require(staker.latestStakedNode == node.prev(), "NOT_STAKED_PREV");

        node.addStaker(msg.sender);
        staker.latestStakedNode = nodeNum;
    }

    function newStakeOnNewNode(
        bytes32 blockHash,
        uint256 blockNumber,
        uint256 nodeNum,
        uint256 prev,
        bytes32[7] calldata assertionBytes32Fields,
        uint256[11] calldata assertionIntFields
    ) external payable {
        require(blockhash(blockNumber) == blockHash, "invalid known block");
        require(nodeNum == latestNodeCreated + 1, "NODE_NUM");
        require(prev == latestConfirmed, "PREV");

        RollupLib.Assertion memory assertion =
            RollupLib.decodeAssertion(assertionBytes32Fields, assertionIntFields);
        Node node = createNewNode(assertion, prev);

        Staker storage staker = addNewStaker();

        node.addStaker(msg.sender);
        staker.latestStakedNode = nodeNum;

        nodes[nodeNum] = node;
        latestNodeCreated++;
    }

    function addStakeOnNewNode(
        bytes32 blockHash,
        uint256 blockNumber,
        uint256 nodeNum,
        bytes32[7] calldata assertionBytes32Fields,
        uint256[11] calldata assertionIntFields
    ) external {
        require(blockhash(blockNumber) == blockHash, "invalid known block");
        require(nodeNum == latestNodeCreated + 1, "NODE_NUM");
        Staker storage staker = stakerMap[msg.sender];
        require(staker.isStaked, "NOT_STAKED");

        RollupLib.Assertion memory assertion =
            RollupLib.decodeAssertion(assertionBytes32Fields, assertionIntFields);

        Node node = createNewNode(assertion, staker.latestStakedNode);

        node.addStaker(msg.sender);
        staker.latestStakedNode = nodeNum;

        nodes[nodeNum] = node;
        latestNodeCreated++;
    }

    function returnOldDeposit(address payable stakerAddress) external {
        Staker storage staker = stakerMap[stakerAddress];
        require(staker.latestStakedNode <= latestConfirmed, "TOO_RECENT");
        checkUnchallengedStaker(staker);
        uint256 amountStaked = staker.amountStaked;
        deleteStaker(staker);
        // TODO: Staker could force transfer to revert. We may want to allow funds to be withdrawn separately
        stakerAddress.transfer(amountStaked);
    }

    function addToDeposit(address stakerAddress) external payable {
        Staker storage staker = stakerMap[stakerAddress];
        checkUnchallengedStaker(staker);
        staker.amountStaked += msg.value;
    }

    function reduceDeposit(uint256 maxReduction) external {
        Staker storage staker = stakerMap[msg.sender];
        checkUnchallengedStaker(staker);
        uint256 currentRequired = currentRequiredStake();
        require(staker.amountStaked > currentRequired);
        uint256 withdrawAmount = staker.amountStaked - currentRequired;
        // Cap withdrawAmount at maxReduction
        if (withdrawAmount > maxReduction) {
            withdrawAmount = maxReduction;
        }
        msg.sender.transfer(withdrawAmount);
    }

    function createChallenge(
        address payable staker1Address,
        uint256 nodeNum1,
        address payable staker2Address,
        uint256 nodeNum2,
        bytes32 inboxConsistencyHash,
        bytes32 inboxDeltaHash,
        bytes32 executionHash,
        uint256 executionCheckTime
    ) external {
        createChallenge(
            staker1Address,
            nodeNum1,
            staker2Address,
            nodeNum2,
            ChallengeState(inboxConsistencyHash, inboxDeltaHash, executionHash, executionCheckTime)
        );
    }

    function completeChallenge(address winningStaker, address payable losingStaker)
        external
        override
    {
        Staker storage winner = stakerMap[winningStaker];
        Staker storage loser = stakerMap[losingStaker];

        // Only the challenge contract can declare winners and losers
        require(winner.currentChallenge == msg.sender);
        require(loser.currentChallenge == msg.sender);

        if (loser.amountStaked > winner.amountStaked) {
            uint256 extraLoserStake = loser.amountStaked - winner.amountStaked;
            // TODO: unsafe to transfer to the loser directly
            losingStaker.transfer(extraLoserStake);
            loser.amountStaked -= extraLoserStake;
        }

        winner.amountStaked += loser.amountStaked / 2;
        winner.currentChallenge = address(0);

        // TODO: deposit extra loser stake into ArbOS

        zombies.push(Zombie(losingStaker, loser.latestStakedNode));
        deleteStaker(loser);
    }

    function removeZombie(uint256 zombieNum, uint256 maxNodes) external {
        require(zombieNum <= zombies.length, "NO_SUCH_ZOMBIE");
        Zombie storage zombie = zombies[zombieNum];
        uint256 latestStakedNode = zombie.latestStakedNode;
        uint256 nodesRemoved = 0;
        while (latestStakedNode > firstUnresolvedNode && nodesRemoved < maxNodes) {
            Node node = nodes[latestStakedNode];
            node.removeStaker(zombie.stakerAddress);
            latestStakedNode = node.prev();
            nodesRemoved++;
        }
        if (latestStakedNode < firstUnresolvedNode) {
            zombies[zombieNum] = zombies[zombies.length - 1];
            zombies.pop();
        } else {
            zombie.latestStakedNode = latestStakedNode;
        }
    }

    function stakerCount() external view returns (uint256) {
        return stakerList.length;
    }

    function getStakers(uint256 startIndex, uint256 max) external view returns (address[] memory) {
        uint256 maxStakers = stakerList.length;
        if (startIndex + max < maxStakers) {
            maxStakers = startIndex + max;
        }

        address[] memory stakers = new address[](maxStakers);
        for (uint256 i = 0; i < maxStakers; i++) {
            stakers[i] = stakerList[startIndex + i];
        }
        return stakers;
    }

    function removeOldZombies(uint256 startIndex) public {
        uint256 zombieCount = zombies.length;
        for (uint256 i = startIndex; i < zombieCount; i++) {
            Zombie storage zombie = zombies[i];
            while (zombie.latestStakedNode < firstUnresolvedNode && zombieCount > 0) {
                zombies[i] = zombies[zombieCount - 1];
                zombies.pop();
                zombie = zombies[i];
                zombieCount--;
            }
        }
    }

    function currentRequiredStake() public view returns (uint256) {
        uint256 MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

        if (block.number < nodes[latestConfirmed].deadlineBlock()) {
            return baseStake;
        }
        uint256 latestConfirmedAge = block.number - nodes[latestConfirmed].deadlineBlock();
        uint256 challengePeriodsPassed = latestConfirmedAge / challengePeriodBlocks;
        if (challengePeriodsPassed > 255) {
            challengePeriodsPassed = 255;
        }
        uint256 multiplier = 2**challengePeriodsPassed - 1;
        if (multiplier == 0) {
            multiplier = 1;
        }

        if (multiplier > MAX_INT / baseStake) {
            return MAX_INT;
        }

        return baseStake * multiplier;
    }

    function countStakedZombies(Node node) public view returns (uint256) {
        uint256 zombieCount = zombies.length;
        uint256 stakedZombieCount = 0;
        for (uint256 i = 0; i < zombieCount; i++) {
            Zombie storage zombie = zombies[i];
            if (node.stakers(zombie.stakerAddress)) {
                stakedZombieCount++;
            }
        }
        return stakedZombieCount;
    }

    function checkNoRecentStake() public view {
        // No stake has been placed during the last challengePeriod blocks
        require(block.number - lastStakeBlock >= challengePeriodBlocks, "RECENT_STAKE");
    }

    function checkUnresolved() public view {
        require(
            firstUnresolvedNode > latestConfirmed && firstUnresolvedNode <= latestNodeCreated,
            "NO_UNRESOLVED"
        );
    }

    function createNewNode(RollupLib.Assertion memory assertion, uint256 prev)
        private
        returns (Node)
    {
        Node prevNode = nodes[prev];
        // Make sure the previous state is correct against the node being built on
        require(
            RollupLib.beforeNodeStateHash(assertion) == prevNode.stateHash(),
            "PREV_STATE_HASH"
        );

        // inboxMaxCount must be greater than beforeInboxCount since we can't have read past the end of the inbox
        require(
            assertion.inboxMessagesRead <= inboxMaxCount - assertion.beforeInboxCount,
            "INBOX_PAST_END"
        );

        uint256 prevDeadlineBlock = prevNode.deadlineBlock();
        uint256 timeSinceLastNode = block.number - assertion.beforeProposedBlock;
        uint256 minimumAssertionPeriod = challengePeriodBlocks / 10;
        uint256 minGasUsed = timeSinceLastNode * arbGasSpeedLimitPerBlock;
        // Verify that assertion meets the minimum Delta time requirement
        require(timeSinceLastNode >= minimumAssertionPeriod, "TIME_DELTA");

        // Minimum size requirements: each assertion must satisfy either
        require(
            // Consumes at least all inbox messages put into L1 inbox before your prev node’s L1 blocknum
            assertion.inboxMessagesRead >=
                assertion.beforeInboxMaxCount - assertion.beforeInboxCount ||
                // Consumes ArbGas >=100% of speed limit for time since your prev node (based on difference in L1 blocknum)
                assertion.gasUsed >= minGasUsed,
            "TOO_SMALL"
        );

        // Don't allow an assertion to use above a maximum amount of gas
        require(assertion.gasUsed <= minGasUsed * 4, "TOO_LARGE");

        uint256 deadlineBlock = block.number + challengePeriodBlocks;
        if (deadlineBlock < prevDeadlineBlock) {
            deadlineBlock = prevDeadlineBlock;
        }
        uint256 executionCheckTimeBlocks = assertion.gasUsed / arbGasSpeedLimitPerBlock;
        deadlineBlock += executionCheckTimeBlocks;

        return
            Node(
                nodeFactory.createNode(
                    RollupLib.nodeStateHash(assertion, inboxMaxCount),
                    RollupLib.challengeRoot(
                        assertion,
                        inboxMaxCount,
                        inboxMaxValue,
                        executionCheckTimeBlocks
                    ),
                    RollupLib.confirmHash(assertion),
                    prev,
                    deadlineBlock
                )
            );
    }

    function createChallenge(
        address payable staker1Address,
        uint256 nodeNum1,
        address payable staker2Address,
        uint256 nodeNum2,
        ChallengeState memory state
    ) private {
        require(nodeNum1 < nodeNum2, "WRONG_ORDER");
        require(nodeNum2 <= latestNodeCreated, "NOT_PROPOSED");
        require(latestConfirmed < nodeNum1, "ALREADY_CONFIRMED");

        Node node1 = nodes[nodeNum1];
        Node node2 = nodes[nodeNum2];

        require(node1.prev() == node2.prev(), "DIFF_PREV");

        Staker storage staker1 = stakerMap[staker1Address];
        Staker storage staker2 = stakerMap[staker2Address];

        checkUnchallengedStaker(staker1);
        checkUnchallengedStaker(staker2);

        require(node1.stakers(staker1Address), "STAKER1_NOT_STAKED");
        require(node2.stakers(staker2Address), "STAKER2_NOT_STAKED");

        require(
            node1.challengeHash() ==
                ChallengeLib.challengeRootHash(
                    state.inboxConsistencyHash,
                    state.inboxDeltaHash,
                    state.executionHash,
                    state.executionCheckTime
                ),
            "CHAL_HASH"
        );

        // Start a challenge between staker1 and staker2. Staker1 will defend the correctness of node1, and staker2 will challenge it.
        address challengeAddress =
            challengeFactory.createChallenge(
                state.inboxConsistencyHash,
                state.inboxDeltaHash,
                state.executionHash,
                state.executionCheckTime,
                staker1Address,
                staker2Address,
                challengePeriodBlocks
            );

        staker1.currentChallenge = challengeAddress;
        staker2.currentChallenge = challengeAddress;

        emit RollupChallengeStarted(staker1Address, staker2Address, challengeAddress);
    }

    function destroyNode(uint256 nodeNum) private {
        nodes[nodeNum].destroy();
        nodes[nodeNum] = Node(0);
    }

    function deleteStaker(Staker storage staker) private {
        uint256 stakerIndex = staker.index;
        address stakerAddress = stakerList[stakerIndex];
        stakerList[stakerIndex] = stakerList[stakerList.length - 1];
        stakerMap[stakerList[stakerIndex]].index = stakerIndex;
        stakerList.pop();
        delete stakerMap[stakerAddress];
    }

    function addNewStaker() private returns (Staker storage) {
        // Verify that sender is not already a staker
        require(!stakerMap[msg.sender].isStaked, "ALREADY_STAKED");
        require(msg.value >= currentRequiredStake(), "NOT_ENOUGH_STAKE");

        uint256 stakerIndex = stakerList.length;
        stakerList.push(msg.sender);
        stakerMap[msg.sender] = Staker(stakerIndex, latestConfirmed, msg.value, address(0), true);
        lastStakeBlock = block.number;
        return stakerMap[msg.sender];
    }

    function checkValidNodeNumForStake(uint256 nodeNum) private view {
        require(nodeNum >= firstUnresolvedNode && nodeNum <= latestNodeCreated);
    }

    function checkUnchallengedStaker(Staker storage staker) private view {
        require(staker.isStaked, "NOT_STAKED");
        require(staker.currentChallenge == address(0), "IN_CHAL");
    }
}
