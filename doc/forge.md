
forge create --account test1 --rpc-url sepolia BaseERC20 

forge script --chain sepolia script/UUPSDeploymentScript.s.sol:UUPSDeploymentScript --rpc-url sepolia --account test1 --broadcast --verify -vvvv
forge script --chain sepolia ERC20TokenScript --rpc-url sepolia --account test1 --broadcast --verify -vvvv

cast call -r local 0x5fbdb2315678afecb367f032d93f642f64180aa3 "name() returns(string)"

cast call -r sepolia --private-key c79d674c0ef37d35b3ef057c31af01038ad366046a2e5ad7ff869ff7492d7c9a "buyNFT(address, uint256) returns (bool)" 0x0D3FDd6e976b076f986A398EC6dD56f5DA117bcf 17

查看合约 slot 存储布局
`forge inspect MyERC20 storageLayout `