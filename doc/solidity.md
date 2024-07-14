## 基础概念
### 可见性
|     | public   | external   | internal   | private   |
| --- | --- | --- | --- | --- |
| 修饰函数   |   Yes  |  Yes   |  Yes   |  Yes   |
| 修饰变量   |   Yes  |   No  |    Yes |   Yes  |
| 当前合约内可访问    |   Yes  |  No   |  Yes   |  Yes   |
| 派生合约可访问    |   Yes  |  No  |   Yes  |  No   |
| 外部访问    |  Yes   |   Yes  |   No  |  No   |

### 变量
- `constant` 定义常量, 常量不占用合约的存储空间，定义的时候必须赋值
- `immutable` 定义不可修改变量, 在构造函数中进行赋值，构造函数是在部署的时候执行，因此这是运行时赋值

### 函数
函数定义: `function + 函数名(参数列表) + 可⻅性 + 状态可变性（可多个）+ 返回值
`

#### 状态可变性: 
- `view`：用 view 修饰的函数，称为视图函数，它只能读取状态，而不能修改状态。
- `pure`：用 pure 修饰的函数，称为纯函数，它既不能读取也不能修改状态。
- `payable`：用 payable 修饰的函数表示可以接受以太币，如果未指定，该函数将自动拒绝所有发送给它的以太币

#### 回调函数
- `receive`: 有转账了，通知告诉合约一下
- `fallback`: 找不到对应的方法时被调用，最后的保障

receive 和 payable 只适用于接收以太坊


### 继承、接口
- `is` ： 继承某合约
- `abstract`： 表示该合约不可被部署
- `super`：调用父合约函数
- `virtual`： 表示函数可以被重写
- `override`： 表示重写了父合约函数

### 函数修饰器
用于在函数执行前检查某种前置条件, 支持传递参数，支持多个修改器一起使用
修改器也是可被继承的，同时还可被继承合约重写（Override）

```
modifier checkAmount(uint256 amount) {
        require (amount > 0, "amount must be greater than 0");
        _;
    }
```
函数修改器一般是带有一个特殊符号 `_;`  修改器所修饰的函数的函数体会被插入到`_;`的位置, 注意调用顺序

### 错误处理
TODO

### 区分合约及外部地址
合约地址和外部地址在 EVM 层本质是一样的，都是有：`nonce（交易序号）`、
`balance（余额）`、`storageRoot（状态）`、`codeHash（代码）`, 区别在于外部 EOA 账户并没有 `storageRoot（状态）`、`codeHash（代码）` 

EVM提供了一个操作码EXTCODESIZE，用来获取地址相关联的代码大小（长度），如果是外部账号地址，则没有代码返回， 因此我们可以使用以下方法判断合约地址及外部账号地址:
```solidity
function isContract(address addr) internal view returns (bool) {
  uint256 size;
  assembly { size := extcodesize(addr) }
    return size > 0;
}
```

## 事件日志
### 定义
事件是外部事件获取EVM内部状态变化的一个手段，使用 event 关键字定义事件，使用 emit 来触发定义的事件

```solidity
// 定义事件
event Deposit(address indexed _from, uint _value);  
// 触发事件
emit Deposit(msg.sender, value);  
```

日志包含的内容有：
- `address`：表示当前事件来自哪个合约。
- `topics`：事件的主题, 定义事件参数时加上 `indexed` 来标记指定为主题, 每个事件最多可以有三个额外的 indexed 参数，因此最多有四个主题。
- `data`: 事件的参数数据（非索引的参数数据）

每个事件的第一个主题默认是**事件签名**的哈希值, 是事件唯一性的关键，使得不同的事件即使名称相同，只要参数类型列表不同，其签名也会不同，从而确保了区块链上的事件可以被准确地识别和搜索

有索引的参数放在 topics 下，没有索引的参数放在 data 下，以太坊会为日志地址及主题创建 `Bloom` 过滤器，以便更快的对数据检索

> **以太坊区块结构中对应有一个 交易回执 的 Merkel 树结构, 日志就存储于交易回执数据中** 
参考: [交易回执](https://learnblockchain.cn/books/geth/part1/receipt.html)

### 事件操作
在合约内触发事件后，在外部可以通过一些手段获取或监听到该事件:
- 通过交易收据获取事件: `eth_gettransactionreceipt()` 
- 使用过滤器获取过去事件: `eth_getlogs()`
- 使用过滤器获取实时事件: 建立长链接, 使用 ` eth_subscribe` 订阅
### 使用场景
- 链上存储成本很高，一些变量定义如果不是被经常调用或者必须使用，就可以考虑使用事件来存储，能降低很多 Gas 成本
- 用事件记录完整的交易历史


## ABI 与底层调用
类似于 Java 中的 RPC 接口定义，其他合约可以根据 ABI 找到对应的函数方法，调用其他合约

### 底层调用
使用地址的底层调用功能，是在运行时动态地决定调用目标合约和函数， 因此在编译时，可以不知道具体要调用的函数或方法，类似于 Java 中的反射
有 3 个底层的成员函数
- `targetAddr.call(bytes memory abiEncodeData) returns (bool, bytes memory)`
- `targetAddr.delegatecall(bytes memory abiEncodeData) returns (bool, bytes memory)`
- `targetAddr.staticcall(bytes memory abiEncodeData) returns (bool, bytes memory)`

call 是常规调用，delegatecall 为委托调用，staticcall 是静态调用（不修改合约状态， 相当于调用 view 方法）

### call 与 delegatecall
https://decert.me/tutorial/solidity/solidity-adv/addr_call