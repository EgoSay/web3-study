'''
Author: Joe_Chan 
Date: 2024-07-01 19:45:34
Description: 
Copyright (c) 2024  All Rights Reserved. 
'''

import random
from datetime import datetime
import hashlib


def generate_sha256_hash(initial_value, chainPrefix):
    attempts = 0
    start_time = datetime.now()
    while True:
        # 生成随机数
        random_number = random.randint(0, 1e6)
        
        # 组合初始值和随机数生成新的字符串
        combined_string = f"{initial_value}{random_number}"
        
        # 计算 SHA-256 哈希值
        sha256_hash = hashlib.sha256(combined_string.encode()).hexdigest()
        # print(sha256_hash)
            
        
        # 增加尝试次数
        attempts += 1
        
        # 检查哈希值开头是否满足规则
        if sha256_hash.startswith(chainPrefix):
            current_time = datetime.now()
            cost_time = current_time - start_time
            total_cost_ms = cost_time.days * 24 * 60 * 60 * 1000 + cost_time.seconds * 1000 + cost_time.microseconds / 1000
            return sha256_hash, combined_string, attempts, total_cost_ms

nick = 'Joe_chan'
hash_result, final_string, total_attempts, total_cost_ms = generate_sha256_hash(nick, '0000')
print(f"找到的哈希值: {hash_result}, 对应的组合字符串: {final_string}\n总尝试次数: {total_attempts}, 花费时间: {total_cost_ms}ms\n=============")
hash_result, final_string, total_attempts, total_cost_ms = generate_sha256_hash(nick, '00000')
print(f"找到的哈希值: {hash_result}, 对应的组合字符串: {final_string}\n总尝试次数: {total_attempts}, 花费时间: {total_cost_ms}ms\n=============")
