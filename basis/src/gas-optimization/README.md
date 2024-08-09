## Task1
编写一个 Bank 存款合约，实现功能：

可以通过 Metamask 等钱包直接给 Bank 合约地址存款
在 Bank 合约里记录了每个地址的存款金额
用可迭代的链表保存存款金额的前 10 名用户

### 实现代码：
[OptimizationBank2.sol](./OptimizationBank2.sol)

### 测试用例
[BankGasTest](../../test/OptimizationBank.t.sol)

### 测试结果
[BankGasTest.log](../../test/BankGasTest.log)


## Task2
实现一个 AirdopMerkleNFTMarket 合约(假定 Token、NFT、AirdopMerkleNFTMarket 都是同一个开发者开发)，功能如下：

基于 Merkel 树验证某用户是否在白名单中
在白名单中的用户可以使用上架（和之前的上架逻辑一致）指定价格的优惠 50% 的Token 来购买 NFT， Token 需支持 permit 授权。
要求使用 multicall( delegateCall 方式) 一次性调用两个方法：

- `permitPrePay()` : 调用token的 permit 进行授权
- `claimNFT()` : 通过默克尔树验证白名单，并利用 permitPrePay 的授权，转入 token 转出 NFT 

