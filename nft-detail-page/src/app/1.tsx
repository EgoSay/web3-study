'use client'
import { useState } from 'react';
import { createPublicClient, http } from 'viem'
import { mainnet } from 'viem/chains'
import TestABI from '../lib/abi.json'
 
const client = createPublicClient({ 
    chain: mainnet, 
    transport: http(), 
}) 

const normalizeTokenURI = (uri: string) => {
  return uri.replace('ipfs://', 'https://ipfs.io/ipfs/');
};

const wagmiContract = {
address: '0x0483b0dfc6c78062b9e999a82ffb795925381415',
abi: TestABI
} as const

const contractAddress = '0x0483b0dfc6c78062b9e999a82ffb795925381415'

const fetchNftDetails = async (tokenId: string) => {
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
  
      const [nameResult, ownerResult, tokenURIResult] = data;
  
      if (
        nameResult.status !== 'success' ||
        ownerResult.status !== 'success' ||
        tokenURIResult.status !== 'success'
      ) {
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
          Accept: 'application/json',
        },
      });
  
      if (!tokenUriResponse.ok) {
        throw new Error('Failed to fetch token URI');
      }
  
      const metadata = await tokenUriResponse.json();
  
      return {
        name,
        owner,
        imageUrl: metadata.image,
        description: metadata.description,
        price: metadata.price || 'N/A',
      };
    } catch (error) {
      console.error('Error fetching NFT details:', error);
      return null;
    }
  };

export default function Home() {
  const [tokenId, setTokenId] = useState('');
  const [owner, setOwner] = useState('');
  const [tokenURI, setTokenURI] = useState('');
  const [metaData, setMetaData] = useState<any>(null);

  const handleTokenIdChange = (value: string) => {
    setTokenId(value);
    setOwner('');
    setTokenURI('');
  }

  const handleQuery = () => {
    client.readContract({
      address: contractAddress,
      abi: OrbitABI,
      functionName: 'ownerOf',
      args: [BigInt(tokenId)]
    }).then((res: any) => {
      setOwner(String(res));
    })
    client.readContract({
      address: contractAddress,
      abi: OrbitABI,
      functionName: 'tokenURI',
      args: [BigInt(tokenId)]
    }).then((res: any) => {
      setTokenURI(res);
      fetchTokenURI(res);
    })
  }

  function fetchTokenURI(tokenURI: string) {
    fetch(tokenURI.replace('ipfs://','https://ipfs.io/ipfs/'))
      .then(res => res.json())
      .then(res => {
        console.log(res);
        setMetaData(res);
      })
  }
  
  return (
    <div className='p-4'>
      <div className='mb-4'>
        <label className="mr-4">tokenId:</label>
        <input className="shadow appearance-none border rounded w-40 py-2 px-3 mr-4 text-gray-700 leading-tight focus:outline-none focus:shadow-outline" type="text" placeholder="Enter tokenId" value={tokenId} onChange={e => handleTokenIdChange(e.target.value)} />
        <button className="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline" onClick={handleQuery}>Query</button>
      </div>
      <div>
        {
          owner ? (
            <>
              <div className='text-2xl mb-2'>NFT Info</div>
              <p>
                <span className='text-gray-400 w-20 inline-block'>owner: </span>
                {owner}
              </p>
            </>
          ) : null
        }
      </div>
      <div className='mb-4'>
        {
          tokenURI ? (
            <p>
              <span className='text-gray-400 w-20 inline-block'>tokenURI: </span>
              {tokenURI}
            </p>
          ) : null
        }
      </div>
      <div className='mb-4'>
        {
          metaData ? (
            <div className='flex'>
              <div className='mr-8'>
                <div className='text-2xl mb-2'>NFT Image</div>
                <img className='w-80' src={metaData.image.replace('ipfs://','https://gateway.pinata.cloud/ipfs/')} alt={metaData.name} />
              </div>
              <div className='flex-1'>
                <div className='text-2xl mb-2'>NFT Details</div>
                <p><span className='text-gray-400 w-20 inline-block'>name: </span>{metaData.name}</p>
                <p><span className='text-gray-400 w-20 inline-block'>desc: </span>{metaData.description || '-'}</p>
                <p><span className='text-gray-400 w-20 inline-block'>edition: </span>{metaData.edition}</p>
                <p><span className='text-gray-400 w-20 inline-block'>DNA: </span>{metaData.dna}</p>
                <p><span className='text-gray-400 w-20 inline-block'>date: </span>{new Date(metaData.date).toLocaleString()}</p>
                <p className='text-gray-400 inline-block'>attributes:</p>
                <table className="border">
                  <tbody>
                    {
                      metaData.attributes.map((item: any, index: number) => (
                        <tr key={index}>
                          <td className='px-4'>{item.trait_type}</td>
                          <td className='px-4'>{item.value}</td>
                        </tr>
                      ))
                    }
                  </tbody>
                </table>
              </div>
            </div>
          ) : null
        }
      </div>
    </div>
  );
}