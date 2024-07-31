
# 合约代理升级

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


## 参考链接
- [Writing Upgradeable Contracts](https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable)

- [Transparent vs UUPS Proxies](https://docs.openzeppelin.com/contracts/5.x/api/proxy#TransparentUpgradeableProxy)