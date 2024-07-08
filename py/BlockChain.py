import hashlib
import json
from time import time
from typing import Any, Dict, List, Optional
from urllib.parse import urlparse
from uuid import uuid4

import requests
from flask import Flask, jsonify, request
from argparse import ArgumentParser

'''
Author: Joe_Chan 
Date: 2024-07-07 14:55:29
Description: create a simple blockchain
'''

class Blockchain(object):
    def __init__(self):
        self.chain = []
        self.current_transactions = []
        self.nodes = set()
        # Create the genesis block
        self.new_block(previous_hash=1, proof=100)
        
    def new_block(self, proof, previous_hash=None):
        '''
        # Creates a new Block and adds it to the chain
        :param proof: <int> The proof given by the Proof of Work algorithm
        :param previous_hash: (Optional) <str> Hash of previous Block
        :return: <dict> New Block
        ''' 
        block = {
            'index': len(self.chain) + 1,
            'timestamp': time(),
            'transactions': self.current_transactions,
            'proof': proof,
            'previous_hash': previous_hash or self.hash(self.chain[-1])
        } 
        print(f'{block}')
        self.current_transactions = []
        self.chain.append(block)
        print(f'{self.chain}')
        return block      
    
    def new_transaction(self, sender, recipient, amount):
        # Adds a new transaction to the list of transactions
        self.current_transactions.append({
            'sender':sender,
            'recipient':recipient,
            'amount':amount
        })
        return self.last_block['index'] + 1
    
    @staticmethod
    def hash(block):
        """
        生成块的 SHA-256 hash值
        :param block: <dict> Block
        :return: <str>
        """

        # We must make sure that the Dictionary is Ordered, or we'll have inconsistent hashes
        block_string = json.dumps(block, sort_keys=True).encode()
        return hashlib.sha256(block_string).hexdigest()

    @property
    def last_block(self):
        # Returns the last Block in the chain
        return self.chain[-1]
    
    def proof_of_work(self, last_proof:int) -> int:
        """
        简单的工作量证明:
         - 查找一个 p' 使得 hash(pp') 以4个0开头
         - p 是上一个块的证明,  p' 是当前的证明
        """

        proof = 0
        while self.valid_proof(last_proof, proof) is False:
            proof += 1

        return proof

    @staticmethod
    def valid_proof(last_proof: int, proof: int) -> bool:
        """
        验证证明: 是否hash(last_proof, proof)以4个0开头

        :param last_proof: Previous Proof
        :param proof: Current Proof
        :return: True if correct, False if not.
        """

        guess = f'{last_proof}{proof}'.encode()
        guess_hash = hashlib.sha256(guess).hexdigest()
        return guess_hash[:4] == "0000"

    def register_node(self, address):
        '''
        description: add new node
        return {*}
        '''        
        parsed_url = urlparse(address)
        self.nodes.add(parsed_url.netloc)

    '''
    description: check valid chain
    param {*} self
    param {*} chain
    return {*}
    '''
    def valid_chain(self, chain):
        last_block = chain[0]
        current_index = 1
        while current_index < len(chain):
            block = chain[current_index]
            print(f'{last_block}')
            print(f'{block}')
            print("\n-----------\n")
            # check the hash of the block is correct
            if block['previous_hash'] != self.hash(last_block):
                return False
            # check the proof is correct
            if not self.valid_proof(last_block['proof'], block['proof']):
                return False
            
            last_block = block
            current_index += 1
        return True
    
    '''
    description: A simple consensus algorithm implementation, using the longest chain in the network as the main chain
    param {*} self
    return {*} if chain change, return True, else false
    '''
    def resolve_conflicts(self):
        nodes = self.nodes
        new_chain = None
        max_length = len(self.chain)

        for node in self.nodes:
            response = requests.get(f'http://{node}/chain')
            length = response.json()['length']
            chain = response.json()['chain']
             # Check if the length is longer and the chain is valid
            if length > max_length & self.valid_chain(chain):
                max_length = length
                new_chain = chain

        # Replace our chain if we discovered a new, valid chain longer than ours
        if new_chain:
            self.chain = new_chain
            return True
        return False
        

app = Flask(__name__)
# Generate a globally unique address for this node
node_identifier = str(uuid4()).replace('-', '')

# Instantiate the Blockchain
blockchain = Blockchain()

@app.route('/mine', methods=['GET'])
def mine():
    last_block = blockchain.last_block
    last_proof=last_block['proof']
    proof =  blockchain.proof_of_work(last_proof)

     # 给工作量证明的节点提供奖励.
    # 发送者为 "0" 表明是新挖出的币
    blockchain.new_transaction(
        sender="0",
        recipient=node_identifier,
        amount=1,
    )

    block = blockchain.new_block(proof)
    response = {
        'message': "New Block Forged",
        'index': block['index'],
        'transactions': block['transactions'],
        'proof': block['proof'],
        'previous_hash': block['previous_hash'],
    }
    return jsonify(response), 200
  
@app.route('/transactions/new', methods=['POST'])
def new_transaction():
    values = request.get_json()
    required = ['sender', 'recipient', 'amount']
    if not all(k in values for k in required):
        return 'Missing values', 400
    
    # create a new transactions
    index = blockchain.new_transaction(values['sender'], values['recipient'], values['amount'])
    response = {'message': f'Transaction will be added to Block {index}'}
    return jsonify(response), 201

@app.route('/chain', methods=['GET'])
def full_chain():
    response = {
        'chain': blockchain.chain,
        'length': len(blockchain.chain),
    }
    return jsonify(response), 200

@app.route('/nodes/register', methods=['POST'])
def register_nodes():
    values = request.get_json()
    nodes = values.get('nodes')

    if not nodes:
        return "Error: Please supply a valid list of nodes", 400
    for node in nodes:
        blockchain.register_node(node)

    response = {
        'message': 'New nodes have been added',
        'total_nodes': list(blockchain.nodes),
    }
    return jsonify(response), 201

@app.route('/nodes/resolve', methods=['GET'])
def consensus():
    replaced = blockchain.resolve_conflicts()

    if replaced:
        response = {
            'message': 'Our chain was replaced',
            'new_chain': blockchain.chain
        }
    else:
        response = {
            'message': 'Our chain is authoritative',
            'chain': blockchain.chain
        }

    return jsonify(response), 200


if __name__ == '__main__':
    parser = ArgumentParser()
    parser.add_argument('-p', '--port', default=7001, type=int, help='port to listen on')
    args = parser.parse_args()
    port = args.port
    app.run(host='0.0.0.0', port=port)

    