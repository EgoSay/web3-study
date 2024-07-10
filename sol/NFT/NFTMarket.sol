// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NFTMarket {

    // define nft sale info
    struct nftTokens {
        address seller;
        address nftContract;
        uint256 tokenId;
        uint256 price;
    }

    // Mapping to track the nft type to nftTokens
    mapping(address => mapping(uint256 => nftTokens)) nftSaleMap;

    // event to log nft trade record
    event NFTListed(address indexed seller, address indexed nftContract, uint256 indexed tokenId, uint256 price);
    event NFTBought(address indexed buyer, address indexed nftContract, uint256 indexed tokenId);

    // my ERC20 token contract address
    IERC20 private paymentTokenAddr;
    constructor(IERC20 _paymentToken) {
        paymentTokenAddr = _paymentToken;
    }

    // add nft to the market list
    function list(address nftContract, uint256 tokenId, uint256 price) external returns (bool) {
        require(price > 0, "nft price must greater than 0");
        address owner = IERC721(nftContract).ownerOf(tokenId);
        require(msg.sender == owner, "not nft owner");

        // transfer nft and list
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
        nftSaleMap[nftContract][tokenId] = nftTokens({
            seller: msg.sender,
            nftContract: nftContract,
            tokenId: tokenId,
            price: price
        });
        emit NFTListed(msg.sender, nftContract, tokenId, price);
        return true;
    }

    // buy nft from the market
    function buyNFT(address nftContract, uint256 tokenId) public returns (bool) {
        nftTokens memory nftInfo = nftSaleMap[nftContract][tokenId];
        uint256 balance = paymentTokenAddr.balanceOf(msg.sender);
        require(balance > nftInfo.price, "have no enough balance");
        // transfer erc20 token to the seller
        paymentTokenAddr.transferFrom(msg.sender, nftInfo.seller, nftInfo.price);
        // erc721 transfer nft to the buyer
        IERC721(nftContract).transferFrom(nftInfo.seller, msg.sender, tokenId);
        // delist nft from the market
        delete nftSaleMap[nftContract][tokenId];
        emit NFTBought(msg.sender, nftContract, tokenId);
        return true;
    }

    function getNFTPrice(address nftContract, uint256 tokenId) public view returns (uint256) {
        nftTokens memory nftInfo = nftSaleMap[nftContract][tokenId];
        return nftInfo.price;
    }

    function onTransferReceived(address buyer, uint256 amount, bytes calldata data) external returns (bool) {
        // decode calldata and get nftContract address and tokenId
        address nftContract;
        uint256 tokenId;
        (nftContract, tokenId) = decodeNFTInfo(data);
        uint256 price = getNFTPrice(nftContract, tokenId);
        require(amount >= price, "have no enough token");
        paymentTokenAddr.transfer(nftSaleMap[nftContract][tokenId].seller, amount);
        // erc721 transfer nft to the buyer
        IERC721(nftContract).transferFrom(address(this), buyer, tokenId);
        // delist nft from the market
        delete nftSaleMap[nftContract][tokenId];
        emit NFTBought(buyer, nftContract, tokenId);
        return true;
    }

    // check if EOA
    function isContract(address user) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(user)
        }
        // eoa account have no codeHash
        return size > 0;
    }

    function decodeNFTInfo(bytes calldata data) public pure returns (address, uint256) {
        // 使用 abi.decode 从 data 中解析出 address 和 uint256
        (address addr, uint256 value) = abi.decode(data, (address, uint256));
        return (addr, value);
    }

}