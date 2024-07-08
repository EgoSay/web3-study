
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
- `topics`：事件的主题, 定义事件参数时加上 `indexed`
- `data`: 事件的参数数据（非索引的参数数据）

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
--- 
## ABI
