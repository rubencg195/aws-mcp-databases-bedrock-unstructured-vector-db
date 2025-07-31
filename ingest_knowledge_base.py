#!/usr/bin/env python3
"""
Script to ingest data into Bedrock Knowledge Base
"""

import boto3
import json
import csv
import os
from typing import List, Dict

class KnowledgeBaseIngester:
    def __init__(self, region: str, knowledge_base_id: str):
        self.bedrock_client = boto3.client('bedrock-agent-runtime', region_name=region)
        self.knowledge_base_id = knowledge_base_id
        
    def read_csv_data(self, csv_file_path: str) -> List[Dict]:
        """Read CSV file and convert to list of dictionaries"""
        data = []
        with open(csv_file_path, 'r', encoding='utf-8') as file:
            csv_reader = csv.DictReader(file)
            for row in csv_reader:
                data.append(row)
        return data
    
    def format_data_for_ingestion(self, data: List[Dict]) -> List[str]:
        """Format data for ingestion into knowledge base"""
        formatted_data = []
        for row in data:
            # Convert each row to a text format
            text_content = " ".join([f"{key}: {value}" for key, value in row.items()])
            formatted_data.append(text_content)
        return formatted_data
    
    def ingest_data(self, data: List[str]):
        """Ingest data into the knowledge base"""
        print(f"Ingesting {len(data)} documents into knowledge base...")
        
        # Note: This is a simplified example. In practice, you would use the
        # Bedrock Agent Runtime API to ingest data. The actual implementation
        # depends on your specific use case and data format.
        
        for i, content in enumerate(data):
            try:
                # This is a placeholder for the actual ingestion API call
                # You would need to use the appropriate Bedrock API for data ingestion
                print(f"Processing document {i+1}/{len(data)}")
                
                # Example structure for ingestion (actual API may differ)
                ingestion_request = {
                    "knowledgeBaseId": self.knowledge_base_id,
                    "dataSource": {
                        "type": "S3",
                        "dataSourceConfiguration": {
                            "s3Configuration": {
                                "bucketArn": "your-bucket-arn",
                                "inclusionPrefixes": ["your-prefix/"]
                            }
                        }
                    }
                }
                
                # Placeholder for actual API call
                # response = self.bedrock_client.start_ingestion_job(**ingestion_request)
                print(f"Successfully processed document {i+1}")
                
            except Exception as e:
                print(f"Error processing document {i+1}: {str(e)}")
    
    def ingest_from_csv(self, csv_file_path: str):
        """Ingest data from a CSV file"""
        print(f"Reading data from {csv_file_path}")
        data = self.read_csv_data(csv_file_path)
        formatted_data = self.format_data_for_ingestion(data)
        self.ingest_data(formatted_data)

def main():
    # Configuration
    region = os.environ.get('AWS_REGION', 'us-east-1')
    knowledge_base_id = os.environ.get('KNOWLEDGE_BASE_ID')
    
    if not knowledge_base_id:
        print("Please set KNOWLEDGE_BASE_ID environment variable")
        return
    
    # Initialize ingester
    ingester = KnowledgeBaseIngester(region, knowledge_base_id)
    
    # Ingest data from CSV files
    csv_files = [
        "knowledge-bases/knowledge-base-1.csv"
    ]
    
    for csv_file in csv_files:
        if os.path.exists(csv_file):
            print(f"\nIngesting data from {csv_file}")
            ingester.ingest_from_csv(csv_file)
        else:
            print(f"CSV file {csv_file} not found")

if __name__ == "__main__":
    main() 