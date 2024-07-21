
// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {NFTMarket} from "../src/sol/NFT/NFTMarket.sol";
import {console, StdCheats, Test} from "forge-std/Test.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

import {IERC20, NFTToken} from "../src/sol/NFT/NFTToken.sol";
import {MyNFT} from "../src/sol/NFT/MyNFT.sol";

/*
 * @Author: Joe_Chan 
 * @Date: 2024-07-11 12:00:27
 * @Description: 
    测试 NFTMarket 合约:测试Case 上架NFT:测试上架成功和失败情况，要求断言错误信息和上架事件。
    购买NFT:测试购买成功、自己购买自己的NFT、NFT被重复购买、支付Token过多或者过 少情况，要求断言错误信息和购买事件。
    模糊测试:测试随机使用 0.01-10000 Token价格上架NFT，并随机使用任意Address购买 NFT
    「可选」不可变测试:测试无论如何买卖，NFTMarket合约中都不可能有 Token 持仓
 */
contract NFTMarketTest is Test {

     event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    // event to log nft trade record
    event NFTListed(address indexed seller, address indexed nftContract, uint256 indexed tokenId, uint256 price);
    event NFTBought(address indexed buyer, address indexed nftContract, uint256 indexed tokenId);

    // TODO 不依赖具体的合约，而是接口
    NFTToken nftToken;
    NFTMarket nftMarketplace;
    MyNFT nftContract;
    // generate some user address;
    address[] users;
    // Mappingto track nft tokenId and it's owner
    mapping(address => uint256) nftOwnerMap;
    uint256 constant private INIT_TOKEN_PRICE = 888;

    function setUp() public {
        address initAddr = makeAddr("init");
        deal(initAddr, 1e9 ether);
        vm.startPrank(initAddr);
        nftToken = new NFTToken();
        deal(address(nftToken), 1e9 ether);
        nftMarketplace = new NFTMarket(nftToken);
        deal(address(nftMarketplace), 1e9 ether);
        nftContract = new MyNFT();
        deal(address(nftContract), 1e9 ether);
        // 初始化 mint 一些 nft 给用户
        for(uint i = 0; i< 10; i++) {
            // generate a user and nft uri
            address testUser = address(uint160(uint256(keccak256(abi.encodePacked(i)))));
            deal(testUser, 1e9 ether);
            deal(address(nftToken), testUser, INIT_TOKEN_PRICE);
            string memory tokenURI = generateRandomURI();
            // mint nft to user
            uint256 tokenId = nftContract.mint(testUser, tokenURI);
            users.push(testUser);
            nftOwnerMap[testUser] = tokenId;
        }
        vm.stopPrank();
    }

    function generateRandomURI() public view returns (string memory) {
        bytes32 seed = keccak256(abi.encodePacked(block.number, tx.origin));
        bytes memory randomBytes = new bytes(32);
        for (uint256 i = 0; i < 32; i++) {
            randomBytes[i] = seed[i];
        }
        return string(randomBytes);
    }
    
    // 测试用例1：测试上架成功
    function testListNFT() public {
        for (uint i = 0; i < users.length; i++) {
            // 获取用户地址
            address user = users[i];
            vm.startPrank(user);
            // 获取用户持有的NFT
            uint256 tokenId = nftOwnerMap[user];
            // 授权 NFTMarket 合约可以操作该用户的NFT
            nftContract.approve(address(nftMarketplace), tokenId);
            assertEq(nftContract.isApprovedForAll(user, address(nftMarketplace)), true);

            uint256 price = 100;
            // 上架并验证断言是否正确
            vm.expectEmit(true, true, true, false);
            // check transfer event
            emit Transfer(user, address(nftMarketplace), tokenId);
            vm.expectEmit(true, true, true, true);
            // check nft listed event
            emit NFTListed(user, address(nftContract), tokenId, price);
            bool listedRsult = nftMarketplace.list(address(nftContract), tokenId, price);
            
            // 验证结果
            assertTrue(listedRsult);
            // 验证 NFTMarket 是否更新 NFT 上架信息
            assertEq(nftMarketplace.getNFTPrice(address(nftContract), tokenId), price);
            // 验证 NFT 是否被转移到 NFTMarket 合约地址
            assertEq(IERC721(nftContract).ownerOf(tokenId), address(nftMarketplace));
            vm.stopPrank();
        }
    }

    /**
     * 测试用例2：测试失败场景，包括
     * 1. 上架 NFT 时价格小于等于 0
     * 2. 非 NFT 拥有者操作上架 
     * 3. NFTMarket 合约没有 NFT 的授权
     */

    function testFailListNFT() public {

        // 测试用例2：非 NFT 拥有者操作上架
        for (uint i = 0; i < users.length; i++) {
            // 获取用户地址
            address user = users[i];
            // 获取用户持有的NFT
            uint256 tokenId = nftOwnerMap[user];
            uint256 price = 100;
            // 验证 非 NFT 拥有者操作上架  是否抛出异常
            address nonOwner = makeAddr("nonOwner");
            vm.prank(nonOwner);
            vm.expectRevert("not nft owner");
            nftMarketplace.list(address(nftContract), tokenId, price);
           
            
            // 验证上架 NFT 时价格小于等于 0
            price = 0;
            vm.startPrank(user);
            vm.expectRevert("nft price must greater than 0");
            nftMarketplace.list(address(nftContract), tokenId, price);

            // 验证 NFTMarket 合约没有 NFT 的授权
            price = 100;
            // vm.expectRevert(
            //     abi.encodeWithSelector(ERC721InsufficientApproval.selector, address(nftMarketplace), tokenId)
            // );
            // TODO 
            nftMarketplace.list(address(nftContract), tokenId, price);
            vm.stopPrank();
        }
            
    }

    function testBuyNFT() public {
            (address seller, uint256 price) = prepareBeforeBuyNFT();
            uint256 init_price = nftToken.balanceOf(seller);
            uint256 tokenId = nftOwnerMap[seller];
            // 随机生成一个用户 buyer, deal 部分 token, 用于购买 nft
            address buyer = makeAddr("buyer");
            vm.startPrank(buyer);
            deal(address(nftToken), buyer, INIT_TOKEN_PRICE);
            nftToken.approve(address(nftMarketplace), INIT_TOKEN_PRICE);
            // 购买 nft, 验证断言是否正确
            bool buyResult = nftMarketplace.buyNFT(address(nftContract), tokenId);
            assertTrue(buyResult);
            vm.stopPrank();
            // 验证 nft owner 是否转移
            assertEq(buyer, nftContract.ownerOf(tokenId));
            // 验证 user 和 buyer 余额 token 是否正确
            assertEq(nftToken.balanceOf(buyer), (INIT_TOKEN_PRICE - price));
            assertEq(nftToken.balanceOf(seller), (init_price + price));
    }

    // 购买 NFT 前置准备
    function prepareBeforeBuyNFT() internal returns (address, uint256) {
            // 获取用户地址并设置 nft owner 
            address user = users[0];
            vm.startPrank(user);
            // 获取用户持有的NFT
            uint256 tokenId = nftOwnerMap[user];
            // 授权 NFTMarket 合约可以操作该用户的NFT
            nftContract.approve(address(nftMarketplace), tokenId);
            uint256 price = 100;
            // 上架 nft
            bool listedRsult = nftMarketplace.list(address(nftContract), tokenId, price);
             // 验证结果
            assertTrue(listedRsult);
            vm.stopPrank();
            return (user,  price);
    }

    function testFailBuyNFT() public {
        (address seller, uint256 price) = prepareBeforeBuyNFT();
        uint256 tokenId = nftOwnerMap[seller];
        // 随机生成一个用户 buyer, deal 部分 token, 用于购买 nft
        address buyer = makeAddr("buyer");
        vm.startPrank(buyer);
        // 支付Token过多或者过少情况
        deal(address(nftToken), buyer, price - 1);
        nftToken.approve(address(nftMarketplace), price - 1);
        vm.expectRevert(bytes("have no enough balance"));
        nftMarketplace.buyNFT(address(nftContract), tokenId);
        vm.stopPrank();
        // 自己购买自己的NFT
        // NFT被重复购买
    }

    
    // 测试随机使用 0.01-10000 Token价格上架NFT, 并随机使用任意Address购买 NFT
    function testFuzzNFT(address buyer, uint256 price) public {
        
    }

     // 不可变测试：测试无论如何买卖，NFTMarket合约中都不可能有 Token 持仓
    function invariant_nftmarketTokenBalance() public {
        
    }
    
}