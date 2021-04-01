/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { Signer } from 'ethers'
import { Provider, TransactionRequest } from '@ethersproject/providers'
import { Contract, ContractFactory, Overrides } from '@ethersproject/contracts'

import type { TestERC20 } from '../TestERC20'

export class TestERC20__factory extends ContractFactory {
  constructor(signer?: Signer) {
    super(_abi, _bytecode, signer)
  }

  deploy(overrides?: Overrides): Promise<TestERC20> {
    return super.deploy(overrides || {}) as Promise<TestERC20>
  }
  getDeployTransaction(overrides?: Overrides): TransactionRequest {
    return super.getDeployTransaction(overrides || {})
  }
  attach(address: string): TestERC20 {
    return super.attach(address) as TestERC20
  }
  connect(signer: Signer): TestERC20__factory {
    return super.connect(signer) as TestERC20__factory
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): TestERC20 {
    return new Contract(address, _abi, signerOrProvider) as TestERC20
  }
}

const _abi = [
  {
    inputs: [],
    stateMutability: 'nonpayable',
    type: 'constructor',
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: 'address',
        name: 'owner',
        type: 'address',
      },
      {
        indexed: true,
        internalType: 'address',
        name: 'spender',
        type: 'address',
      },
      {
        indexed: false,
        internalType: 'uint256',
        name: 'value',
        type: 'uint256',
      },
    ],
    name: 'Approval',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: 'address',
        name: 'from',
        type: 'address',
      },
      {
        indexed: true,
        internalType: 'address',
        name: 'to',
        type: 'address',
      },
      {
        indexed: false,
        internalType: 'uint256',
        name: 'value',
        type: 'uint256',
      },
    ],
    name: 'Transfer',
    type: 'event',
  },
  {
    inputs: [
      {
        internalType: 'address',
        name: 'owner',
        type: 'address',
      },
      {
        internalType: 'address',
        name: 'spender',
        type: 'address',
      },
    ],
    name: 'allowance',
    outputs: [
      {
        internalType: 'uint256',
        name: '',
        type: 'uint256',
      },
    ],
    stateMutability: 'view',
    type: 'function',
  },
  {
    inputs: [
      {
        internalType: 'address',
        name: 'spender',
        type: 'address',
      },
      {
        internalType: 'uint256',
        name: 'amount',
        type: 'uint256',
      },
    ],
    name: 'approve',
    outputs: [
      {
        internalType: 'bool',
        name: '',
        type: 'bool',
      },
    ],
    stateMutability: 'nonpayable',
    type: 'function',
  },
  {
    inputs: [
      {
        internalType: 'address',
        name: 'account',
        type: 'address',
      },
    ],
    name: 'balanceOf',
    outputs: [
      {
        internalType: 'uint256',
        name: '',
        type: 'uint256',
      },
    ],
    stateMutability: 'view',
    type: 'function',
  },
  {
    inputs: [],
    name: 'decimals',
    outputs: [
      {
        internalType: 'uint8',
        name: '',
        type: 'uint8',
      },
    ],
    stateMutability: 'view',
    type: 'function',
  },
  {
    inputs: [
      {
        internalType: 'address',
        name: 'spender',
        type: 'address',
      },
      {
        internalType: 'uint256',
        name: 'subtractedValue',
        type: 'uint256',
      },
    ],
    name: 'decreaseAllowance',
    outputs: [
      {
        internalType: 'bool',
        name: '',
        type: 'bool',
      },
    ],
    stateMutability: 'nonpayable',
    type: 'function',
  },
  {
    inputs: [
      {
        internalType: 'address',
        name: 'spender',
        type: 'address',
      },
      {
        internalType: 'uint256',
        name: 'addedValue',
        type: 'uint256',
      },
    ],
    name: 'increaseAllowance',
    outputs: [
      {
        internalType: 'bool',
        name: '',
        type: 'bool',
      },
    ],
    stateMutability: 'nonpayable',
    type: 'function',
  },
  {
    inputs: [],
    name: 'mint',
    outputs: [],
    stateMutability: 'nonpayable',
    type: 'function',
  },
  {
    inputs: [],
    name: 'name',
    outputs: [
      {
        internalType: 'string',
        name: '',
        type: 'string',
      },
    ],
    stateMutability: 'view',
    type: 'function',
  },
  {
    inputs: [],
    name: 'symbol',
    outputs: [
      {
        internalType: 'string',
        name: '',
        type: 'string',
      },
    ],
    stateMutability: 'view',
    type: 'function',
  },
  {
    inputs: [],
    name: 'totalSupply',
    outputs: [
      {
        internalType: 'uint256',
        name: '',
        type: 'uint256',
      },
    ],
    stateMutability: 'view',
    type: 'function',
  },
  {
    inputs: [
      {
        internalType: 'address',
        name: 'recipient',
        type: 'address',
      },
      {
        internalType: 'uint256',
        name: 'amount',
        type: 'uint256',
      },
    ],
    name: 'transfer',
    outputs: [
      {
        internalType: 'bool',
        name: '',
        type: 'bool',
      },
    ],
    stateMutability: 'nonpayable',
    type: 'function',
  },
  {
    inputs: [
      {
        internalType: 'address',
        name: 'sender',
        type: 'address',
      },
      {
        internalType: 'address',
        name: 'recipient',
        type: 'address',
      },
      {
        internalType: 'uint256',
        name: 'amount',
        type: 'uint256',
      },
    ],
    name: 'transferFrom',
    outputs: [
      {
        internalType: 'bool',
        name: '',
        type: 'bool',
      },
    ],
    stateMutability: 'nonpayable',
    type: 'function',
  },
]

const _bytecode =
  '0x608060405234801561001057600080fd5b5060408051808201909152600f8082526e24b73a20b9312a32b9ba2a37b5b2b760891b602090920191825261004791600391610084565b506040805180820190915260048082526324a0a92160e11b60209092019182526100719181610084565b506005805460ff1916601217905561011f565b828054600181600116156101000203166002900490600052602060002090601f016020900481019282601f106100c557805160ff19168380011785556100f2565b828001600101855582156100f2579182015b828111156100f25782518255916020019190600101906100d7565b506100fe929150610102565b5090565b61011c91905b808211156100fe5760008155600101610108565b90565b610b318061012e6000396000f3fe608060405234801561001057600080fd5b50600436106100b45760003560e01c8063395093511161007157806339509351146101ee57806370a082311461021a57806395d89b4114610240578063a457c2d714610248578063a9059cbb14610274578063dd62ed3e146102a0576100b4565b806306fdde03146100b9578063095ea7b3146101365780631249c58b1461017657806318160ddd1461018057806323b872dd1461019a578063313ce567146101d0575b600080fd5b6100c16102ce565b6040805160208082528351818301528351919283929083019185019080838360005b838110156100fb5781810151838201526020016100e3565b50505050905090810190601f1680156101285780820380516001836020036101000a031916815260200191505b509250505060405180910390f35b6101626004803603604081101561014c57600080fd5b506001600160a01b038135169060200135610364565b604080519115158252519081900360200190f35b61017e610381565b005b610188610391565b60408051918252519081900360200190f35b610162600480360360608110156101b057600080fd5b506001600160a01b03813581169160208101359091169060400135610397565b6101d8610424565b6040805160ff9092168252519081900360200190f35b6101626004803603604081101561020457600080fd5b506001600160a01b03813516906020013561042d565b6101886004803603602081101561023057600080fd5b50356001600160a01b0316610481565b6100c161049c565b6101626004803603604081101561025e57600080fd5b506001600160a01b0381351690602001356104fd565b6101626004803603604081101561028a57600080fd5b506001600160a01b03813516906020013561056b565b610188600480360360408110156102b657600080fd5b506001600160a01b038135811691602001351661057f565b60038054604080516020601f600260001961010060018816150201909516949094049384018190048102820181019092528281526060939092909183018282801561035a5780601f1061032f5761010080835404028352916020019161035a565b820191906000526020600020905b81548152906001019060200180831161033d57829003601f168201915b5050505050905090565b60006103786103716105aa565b84846105ae565b50600192915050565b61038f336302faf08061069a565b565b60025490565b60006103a4848484610796565b61041a846103b06105aa565b61041585604051806060016040528060288152602001610a66602891396001600160a01b038a166000908152600160205260408120906103ee6105aa565b6001600160a01b03168152602081019190915260400160002054919063ffffffff6108fd16565b6105ae565b5060019392505050565b60055460ff1690565b600061037861043a6105aa565b84610415856001600061044b6105aa565b6001600160a01b03908116825260208083019390935260409182016000908120918c16815292529020549063ffffffff61099416565b6001600160a01b031660009081526020819052604090205490565b60048054604080516020601f600260001961010060018816150201909516949094049384018190048102820181019092528281526060939092909183018282801561035a5780601f1061032f5761010080835404028352916020019161035a565b600061037861050a6105aa565b8461041585604051806060016040528060258152602001610ad760259139600160006105346105aa565b6001600160a01b03908116825260208083019390935260409182016000908120918d1681529252902054919063ffffffff6108fd16565b60006103786105786105aa565b8484610796565b6001600160a01b03918216600090815260016020908152604080832093909416825291909152205490565b3390565b6001600160a01b0383166105f35760405162461bcd60e51b8152600401808060200182810382526024815260200180610ab36024913960400191505060405180910390fd5b6001600160a01b0382166106385760405162461bcd60e51b8152600401808060200182810382526022815260200180610a1e6022913960400191505060405180910390fd5b6001600160a01b03808416600081815260016020908152604080832094871680845294825291829020859055815185815291517f8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b9259281900390910190a3505050565b6001600160a01b0382166106f5576040805162461bcd60e51b815260206004820152601f60248201527f45524332303a206d696e7420746f20746865207a65726f206164647265737300604482015290519081900360640190fd5b610701600083836109f5565b600254610714908263ffffffff61099416565b6002556001600160a01b038216600090815260208190526040902054610740908263ffffffff61099416565b6001600160a01b0383166000818152602081815260408083209490945583518581529351929391927fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef9281900390910190a35050565b6001600160a01b0383166107db5760405162461bcd60e51b8152600401808060200182810382526025815260200180610a8e6025913960400191505060405180910390fd5b6001600160a01b0382166108205760405162461bcd60e51b81526004018080602001828103825260238152602001806109fb6023913960400191505060405180910390fd5b61082b8383836109f5565b61086e81604051806060016040528060268152602001610a40602691396001600160a01b038616600090815260208190526040902054919063ffffffff6108fd16565b6001600160a01b0380851660009081526020819052604080822093909355908416815220546108a3908263ffffffff61099416565b6001600160a01b038084166000818152602081815260409182902094909455805185815290519193928716927fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef92918290030190a3505050565b6000818484111561098c5760405162461bcd60e51b81526004018080602001828103825283818151815260200191508051906020019080838360005b83811015610951578181015183820152602001610939565b50505050905090810190601f16801561097e5780820380516001836020036101000a031916815260200191505b509250505060405180910390fd5b505050900390565b6000828201838110156109ee576040805162461bcd60e51b815260206004820152601b60248201527f536166654d6174683a206164646974696f6e206f766572666c6f770000000000604482015290519081900360640190fd5b9392505050565b50505056fe45524332303a207472616e7366657220746f20746865207a65726f206164647265737345524332303a20617070726f766520746f20746865207a65726f206164647265737345524332303a207472616e7366657220616d6f756e7420657863656564732062616c616e636545524332303a207472616e7366657220616d6f756e74206578636565647320616c6c6f77616e636545524332303a207472616e736665722066726f6d20746865207a65726f206164647265737345524332303a20617070726f76652066726f6d20746865207a65726f206164647265737345524332303a2064656372656173656420616c6c6f77616e63652062656c6f77207a65726fa2646970667358221220d9ce501c1ee1d8cb9fda09255b3aeb15844acbee6a70bb454837bdc8162399c164736f6c634300060b0033'
