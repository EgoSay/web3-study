'use client'
import React, { useState } from 'react';
import styles from './NftDetail.module.css';
import { fetchNftDetails } from '../lib/viem';

interface Detail {
  dna: string;
  name: string;
  description: string;
  image: string;
  edition: number;
  date: number;
}

interface NftData {
  tokenURI: string;
  name: string;
  detail: Detail;
  owner: string;
}

const Home: React.FC = () => {
  const [tokenId, setTokenId] = useState<string>('');
  const [nftData, setNft] = useState<any>(null);
  const [loading, setLoading] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);

  const handleFetchNftDetails = async () => {
    setLoading(true);
    setError(null);
    try {
      const nftData = await fetchNftDetails(tokenId);
      if (nftData) {
        console.log(nftData)
        setNft(nftData!);
      } else {
        setError('NFT not found');
      }
    } catch (err) {
      setError('Error fetching NFT details');
    }
    setLoading(false);
  };

  return (
    <div className="container">
      <div className="input-container">
        <input
          type="text"
          value={tokenId}
          onChange={(e) => setTokenId(e.target.value)}
          placeholder="Enter Token ID"
        />
        <button onClick={handleFetchNftDetails} disabled={loading}>
          {loading ? 'Loading...' : 'Fetch NFT Details'}
        </button>
      </div>
      {error && <p className="error">{error}</p>}
      {nftData && (
        <div className={styles.result}>
          <h2>{nftData.name}</h2>
          <p><strong>Token URI:</strong> {nftData.tokenURI}</p>
          <p><strong>Owner:</strong> {nftData.owner}</p>
          <div className={styles.content}>
            {nftData.detail.image && (
              <img 
                src={nftData.detail.image.replace("ipfs://", "https://gateway.pinata.cloud/ipfs/")}
                alt="NFT"
                className={styles.image}
              />
            )}
            </div>
            <div className='metadata'>
            <p><strong>DNA:</strong> {nftData.detail.dna}</p>
            <p><strong>Description:</strong> {nftData.detail.description}</p>
            <p><strong>Edition:</strong> {nftData.detail.edition}</p>
            <p><strong>Date:</strong> {new Date(nftData.detail.date).toLocaleString()}</p>

            </div>
        </div>)}
    </div>
  )
};

export default Home;
