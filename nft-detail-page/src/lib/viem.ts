/*
 * @Author: Joe_Chan 
 * @Date: 2024-07-15 22:02:30
 * @Description: 
 */
import { createPublicClient, http } from 'viem'
import { mainnet } from 'viem/chains';
import TestABI from './abi.json'

const client = createPublicClient({
  chain: mainnet,
  transport: http(),
})

const normalizeTokenURI = (uri: string) => {
  return uri.replace('ipfs://', 'https://gateway.pinata.cloud/ipfs/');
};

const wagmiContract = {
  address: '0x0483b0dfc6c78062b9e999a82ffb795925381415',
  abi: TestABI
} as const

export const fetchNftDetails = async (tokenId: string) => {
  try {
    const data = await client.multicall({
      contracts: [
        {
          ...wagmiContract,
          functionName: 'name',
        },
        {
          ...wagmiContract,
          functionName: 'ownerOf',
          args: [BigInt(tokenId)],
        },
        {
          ...wagmiContract,
          functionName: 'tokenURI',
          args: [BigInt(tokenId)],
        },
      ],
    });
    console.log(data)

    const [nameResult, ownerResult, tokenURIResult] = data;

    if (nameResult.status !== 'success' || ownerResult.status !== 'success' || tokenURIResult.status !== 'success') {
      throw new Error('One or more multicall requests failed');
    }

    const name = nameResult.result;
    const owner = ownerResult.result;
    let tokenURI = tokenURIResult.result;

    if (typeof tokenURI !== 'string') {
      throw new Error('Invalid token URI');
    }

    const normalizedTokenURI = normalizeTokenURI(tokenURI);
    const tokenUriResponse = await fetch(normalizedTokenURI, {
      headers: {
        'Accept': 'application/json'
      }
    });

    if (!tokenUriResponse.ok) {
      throw new Error('Failed to fetch token URI');
    }

    const metadata = await tokenUriResponse.json();

    return {
      nftName: name,
      owner: owner,
      tokenURI: tokenURI,
      detail: metadata
    };
  } catch (error) {
    console.error('Error fetching NFT details:', error);
    return null;
  }
};
