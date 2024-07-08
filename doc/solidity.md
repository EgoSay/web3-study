
## 继承、接口
- `is` ： 继承某合约
- `abstract`： 表示该合约不可被部署
- `super`：调用父合约函数
- `virtual`： 表示函数可以被重写
- `override`： 表示重写了父合约函数

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

有索引的参数放在 topics 下，没有索引的参数放在 data 下，以太坊会为日志地址及主题创建Bloom过滤器，以便更快的对数据检索

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