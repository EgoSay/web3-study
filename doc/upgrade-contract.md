
# 合约代理升级

## 底层调用（Call /DelegateCall）
> - **Call**：调用目标合约的函数，并在目标合约的上下文中执行，但调用者合约的存储状态不会改变
> - **DelegateCall**：调用目标合约的函数，并在调用者合约的上下文中执行，调用者合约的存储状态会改变

### 底层概念
- EVM 不关心状态变量，而是**在存储槽上操作**，所有的变量状态变化，都是对应于存储slot 上的内容变更， 所以需要**注意 slot 冲突, 也就是当前合约和目标合约的 slot 槽位布局不能冲突**
- **一个合约对目标智能合约进行 delegatecall 时，会在自己的环境中执行目标合约的逻辑**  (相当于把目标合约的代码复制到当前合约中执行)


## 合约创建
创建合约有几种主要的实现方式：

1. 直接部署
```solidity
contractA = new contractA(....)
```
2. 工厂模式，通过一个工厂合约来操作, 有利于批量创建相似的合约，并可以实现一些额外的逻辑或限制
```solidity
contract ContractFactory {
    function createContract(uint _value) public returns (address) {
        SimpleContract newContract = new SimpleContract(_value);
        return address(newContract);
    }
}
```

3. create2 操作码：可以提前预测合约地址，从而实现更复杂的部署策略，如延迟部署
```solidity
contract Create2Factory {
    function deployContract(uint _salt, uint _value) public returns (address) {
        return address(new SimpleContract{salt: bytes32(_salt)}(_value));
    }

    function predictAddress(uint _salt, uint _value) public view returns (address) {
        bytes memory bytecode = abi.encodePacked(type(SimpleContract).creationCode, abi.encode(_value));
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                _salt,
                keccak256(bytecode)
            )
        );
        return address(uint160(uint(hash)));
    }
}
```
4. 最小代理模式（EIP-1167）: 创建非常轻量级的代理合约，指向一个已部署的实现合约, 可以大大节省 gas
```solidity
contract MinimalProxy {
    function clone(address target) external returns (address result) {
        // 将目标合约的地址转换为 bytes20
        bytes20 targetBytes = bytes20(target);
        
        // 最小代理的字节码
        bytes memory minimalProxyCode = abi.encodePacked(
            hex"3d602d80600a3d3981f3363d3d373d3d3d363d73",
            targetBytes,
            hex"5af43d82803e903d91602b57fd5bf3"
        );
        
        // 使用 create 部署新的代理合约
        assembly {
            result := create(0, add(minimalProxyCode, 0x20), mload(minimalProxyCode))
        }
    }
}
```
5. 代理模式（可升级合约）: 创建可升级的合约，允许在不改变合约地址的情况下更新合约逻辑, 适用于需要长期维护和更新的复杂系统
```solidity
contract UpgradeableContract is Initializable {
    uint public value;

    function initialize(uint _value) public initializer {
        value = _value;
    }
}

contract ProxyFactory {
    function deployProxy(address _logic, address _admin, bytes memory _data) public returns (address) {
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(_logic, _admin, _data);
        return address(proxy);
    }
}
```

### 透明代理

## 合约升级

### 变量问题
- 升级合约时不要随意变更变量，包括类型、定义顺序等，如果新添加的合约变量，可以在末尾添加 `bytes32(uint(keccak256("eip1967.proxy.implementation")) - 1)` ，用于将槽位指定到一个不会发生冲突的位置

- 需要保证合约中的变量在 `initialize` 函数中初始化，而不是通过构造函数初始化，比如
    ```solidity
    contract MyContract {
        uint256 public hasInitialValue = 42; // equivalent to setting in the constructor
    }
    ```
    就需要改成:
    ```solidity
    contract MyContract is Initializable {
        uint256 public hasInitialValue;

        function initialize() public initializer {
            hasInitialValue = 42; // set initial value in initializer
        }
    }
    ```



### 构造函数的问题

1. 为了防止实现合约被直接初始化。在代理模式中，我们希望只有代理合约能够调用初始化函数，而不是实现合约本身，我们需要定义一个普通函数，通常叫 `initialize` 去替代构造函数，但因为普通函数可以重复调用，所以同时需要保证这个函数只能被调用一次

2. 如果继承了父合约，也需要保证父合约的初始化函数只能在初始化时被调用一次

3. 可以在构造函数中调用 `disableInitializers` 函数： `constructor() { _disableInitializers();}` , 
作用在于: 
    - 禁用初始化构造函数，防止恶意攻击者直接调用实现合约的初始化函数，导致状态被意外或恶意修改   
    - 在升级过程中，新的实现合约不应该被初始化，因为它会继承之前版本的状态。禁用初始化器可以防止在升级过程中意外重新初始化合约
       

### selfdestruct 问题
通过代理合约，不会直接和底层逻辑合约交互，即使存在恶意行为者直接向逻辑合约发送交易，也没关系，因为我们是通过代理合约管理存储状态资产，底层逻辑合约的存储状态变更都不会影响代理合约，但有一点需要注意:

如果逻辑合约触发了 `selfdestruct` 操作，那么逻辑合约将被销毁, 代理合约将无法继续使用，因为 `delegatecall` 将无法调用已经销毁的合约

同样，如果逻辑合约中包含了一个可以被外部控制的 `delegatecall`，那么这可能被恶意利用。攻击者可能会让这个 `delegatecall` 指向一个包含 selfdestruct 的恶意合约, 由于是通过 `delegatecall` 调用的恶意合约， `selfdestruct` 是在逻辑合约的上下文中执行的，它实际上会销毁调用它的合约（在这种情况下也就是逻辑合约）， 也将导致逻辑合约被销毁。

举个例子:
```solidity
contract LogicContract {
    address public implementation;
    
    function setImplementation(address _impl) public {
        implementation = _impl;
    }
    
    function delegateCall(bytes memory _data) public {
        // 攻击者能够将 implementation 设置为 MaliciousContract 的地址，然后调用 delegateCall 函数并传入 destroy 函数的调用数据
        // 导致 LogicContract 执行 MaliciousContract 的 destroy 函数，从而销毁 LogicContract 自身
        (bool success, ) = implementation.delegatecall(_data);
        require(success, "Delegatecall failed");
    }
}

contract MaliciousContract {
    function destroy() public {
        selfdestruct(payable(msg.sender));
    }
}
```

**因此，需要禁止在逻辑合约中使用 `selfdestruct` 或 `delegatecall`**,  以太坊社区正在讨论完全移除 `selfdestruct` 的可能性

## 透明代理和 UUPS 代理

```solidity
// SPDX-License-Identifier: MIT
// wtf.academy
pragma solidity ^0.8.21;

// 简单的可升级合约，管理员可以通过升级函数更改逻辑合约地址，从而改变合约的逻辑。
// 教学演示用，不要用在生产环境
contract SimpleUpgrade {
    address public implementation; // 逻辑合约地址
    address public admin; // admin地址
    string public words; // 字符串，可以通过逻辑合约的函数改变

    // 构造函数，初始化admin和逻辑合约地址
    constructor(address _implementation) {
        admin = msg.sender;
        implementation = _implementation;
    }

    // fallback函数，将调用委托给逻辑合约
    fallback() external payable {
        (bool success, bytes memory data) = implementation.delegatecall(msg.data);
    }

    // 升级函数，改变逻辑合约地址，只能由admin调用
    function upgrade(address newImplementation) external {
        require(msg.sender == admin);
        implementation = newImplementation;
    }
}
```
以上是一个最简单可升级的代理合约，它通过 `delegatecall` 将所有调用委托给逻辑合约，同时定义了一个`upgrade()` 函数，从而实现了合约的代理升级, 但是这里存在一个问题，通过 `delegatecall` 调用传参都是函数选择器（selector），它是函数签名的哈希的前4个字节，因此需要一种机制来避免这种冲突，这就引出了透明代理和 UUPS 代理

### 透明代理
透明代理的逻辑非常简单：管理员可能会因为“函数选择器冲突”，在调用逻辑合约的函数时，误调用代理合约的可升级函数。那么限制管理员的权限，不让他调用任何逻辑合约的函数，就能解决冲突：
- 管理员变为工具人，仅能调用代理合约的可升级函数对合约升级，不能通过回调函数调用逻辑合约。
- 其它用户不能调用可升级函数，但是可以调用逻辑合约的函数

可以参考 openzeppelin 中的实现 [TransparentUpgradeableProxy](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/transparent/TransparentUpgradeableProxy.sol)

### UUPS 代理
透明代理的逻辑简单，但也存在一个问题，每次用户调用函数时，都会多一步是否为管理员的检查，消耗更多 gas， 这就引出了另一种方案 `UUPS 代理`
UUPS（universal upgradeable proxy standard，通用可升级代理）将升级函数放在逻辑合约中，这样一来，如果有其它函数与升级函数存在“选择器冲突”，编译时就会报错

参考链接: [UUPS](https://www.wtf.academy/docs/solidity-103/UUPS/)

### 总结
普通可升级合约，透明代理，和UUPS的不同点：

| 标准       | 升级函数在       | 是否会“选择器冲突” | 缺点         |
| ---------- | ---------------- | ------------------ | ------------ |
| 可升级代理 | Proxy合约         | 会                 | 选择器冲突   |
| 透明代理   | Proxy合约         | 不会               | 费gas        |
| UUPS       | Logic合约         | 不会               | 更复杂       |


## 参考链接
- [# Delegatecall: 详细且生动的指南](https://learnblockchain.cn/article/8827)

- [Writing Upgradeable Contracts](https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable)

- [Transparent vs UUPS Proxies](https://docs.openzeppelin.com/contracts/5.x/api/proxy#TransparentUpgradeableProxy)