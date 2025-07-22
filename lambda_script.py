import os
import boto3
import json
class MCPClient:
    def __init__(self, bedrock_client, knowledge_base_bucket, knowledge_base_files):
        self.bedrock_client = bedrock_client
        self.knowledge_base_bucket = knowledge_base_bucket
        self.knowledge_base_files = knowledge_base_files
        self.s3_client = boto3.client("s3")

    def fetch_knowledge_base(self):
        # Download and combine all CSV files from the knowledge base bucket
        combined_data = ""
        for file_key in self.knowledge_base_files:
            obj = self.s3_client.get_object(Bucket=self.knowledge_base_bucket, Key=file_key)
            file_content = obj["Body"].read().decode("utf-8")
            combined_data += file_content + "\n"
        return combined_data

    def build_agent_prompt(self, user_prompt, knowledge_base_data):
        # Inline agent prompt: provide the knowledge base as context
        agent_prompt = (
            "You are an intelligent agent with access to the following knowledge base:\n"
            "-----\n"
            f"{knowledge_base_data}\n"
            "-----\n"
            f"User question: {user_prompt}\n"
            "Answer using only the information from the knowledge base above."
        )
        return agent_prompt

    def query(self, user_prompt, model_id, max_tokens=256, temperature=0.5):
        knowledge_base_data = self.fetch_knowledge_base()
        agent_prompt = self.build_agent_prompt(user_prompt, knowledge_base_data)
        body = {
            "prompt": agent_prompt,
            "max_tokens_to_sample": max_tokens,
            "temperature": temperature
        }
        response = self.bedrock_client.invoke_model(
            modelId=model_id,
            body=json.dumps(body),
            accept="application/json",
            contentType="application/json"
        )
        result = response["body"].read().decode("utf-8")
        return result
def lambda_handler(event, context):
    bedrock = boto3.client("bedrock-runtime", region_name=os.environ.get("BEDROCK_REGION", "${bedrock_region}"))
    model_id = event.get("model_id", "anthropic.claude-v2")
    prompt = event.get("prompt", "Hello from Lambda!")
    # These could be set as environment variables or hardcoded for now
    knowledge_base_bucket = os.environ.get("KNOWLEDGE_BASE_BUCKET", "${knowledge_base_bucket}")
    knowledge_base_files = os.environ.get("KNOWLEDGE_BASE_FILES", "knowledge-base-1.csv").split(",")
    try:
        mcp_client = MCPClient(
            bedrock_client=bedrock,
            knowledge_base_bucket=knowledge_base_bucket,
            knowledge_base_files=knowledge_base_files
        )
        result = mcp_client.query(
            user_prompt=prompt,
            model_id=model_id,
            max_tokens=256,
            temperature=0.5
        )
        return {
            "statusCode": 200,
            "body": result
        }
    except Exception as e:
        return {
            "statusCode": 500,
            "error": str(e)
        }