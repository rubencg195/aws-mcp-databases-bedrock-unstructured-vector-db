# Database initialization script for Bedrock Knowledge Base with RDS
# This script initializes the PostgreSQL database with pgvector extension using RDS Data API

param(
    [string]$ProjectName = "mcp-demo"
)

$SecretName = "$ProjectName-rds-credentials"
$ClusterArn = "arn:aws:rds:us-east-1:176843580427:cluster:$ProjectName-vector-store"

Write-Host "Getting RDS credentials from Secrets Manager..."
$Credentials = aws secretsmanager get-secret-value --secret-id $SecretName --query 'SecretString' --output text | ConvertFrom-Json

Write-Host "Initializing database with vector extension and tables..."

# Enable pgvector extension
Write-Host "Enabling pgvector extension..."
aws rds-data execute-statement `
    --resource-arn $ClusterArn `
    --secret-arn "arn:aws:secretsmanager:us-east-1:176843580427:secret:$SecretName" `
    --database "bedrock_vectors" `
    --sql "CREATE EXTENSION IF NOT EXISTS vector;"

# Create the bedrock_vectors table
Write-Host "Creating bedrock_vectors table..."
$createTableSQL = "CREATE TABLE IF NOT EXISTS bedrock_vectors (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), content TEXT NOT NULL, embedding vector(1024), metadata JSONB, created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP);"
aws rds-data execute-statement `
    --resource-arn $ClusterArn `
    --secret-arn "arn:aws:secretsmanager:us-east-1:176843580427:secret:$SecretName" `
    --database "bedrock_vectors" `
    --sql $createTableSQL

# Create indexes
Write-Host "Creating indexes..."
aws rds-data execute-statement `
    --resource-arn $ClusterArn `
    --secret-arn "arn:aws:secretsmanager:us-east-1:176843580427:secret:$SecretName" `
    --database "bedrock_vectors" `
    --sql "CREATE INDEX IF NOT EXISTS idx_bedrock_vectors_embedding ON bedrock_vectors USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);"

aws rds-data execute-statement `
    --resource-arn $ClusterArn `
    --secret-arn "arn:aws:secretsmanager:us-east-1:176843580427:secret:$SecretName" `
    --database "bedrock_vectors" `
    --sql "CREATE INDEX IF NOT EXISTS idx_bedrock_vectors_metadata ON bedrock_vectors USING GIN (metadata);"

aws rds-data execute-statement `
    --resource-arn $ClusterArn `
    --secret-arn "arn:aws:secretsmanager:us-east-1:176843580427:secret:$SecretName" `
    --database "bedrock_vectors" `
    --sql "CREATE INDEX IF NOT EXISTS idx_bedrock_vectors_created_at ON bedrock_vectors (created_at);"

# Create update function
Write-Host "Creating update function..."
$updateFunctionSQL = "CREATE OR REPLACE FUNCTION update_updated_at_column() RETURNS TRIGGER AS `$`$ BEGIN NEW.updated_at = CURRENT_TIMESTAMP; RETURN NEW; END; `$`$ language 'plpgsql';"
aws rds-data execute-statement `
    --resource-arn $ClusterArn `
    --secret-arn "arn:aws:secretsmanager:us-east-1:176843580427:secret:$SecretName" `
    --database "bedrock_vectors" `
    --sql $updateFunctionSQL

# Create trigger
Write-Host "Creating trigger..."
$triggerSQL = "CREATE TRIGGER update_bedrock_vectors_updated_at BEFORE UPDATE ON bedrock_vectors FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();"
aws rds-data execute-statement `
    --resource-arn $ClusterArn `
    --secret-arn "arn:aws:secretsmanager:us-east-1:176843580427:secret:$SecretName" `
    --database "bedrock_vectors" `
    --sql $triggerSQL

# Grant permissions
Write-Host "Granting permissions..."
aws rds-data execute-statement `
    --resource-arn $ClusterArn `
    --secret-arn "arn:aws:secretsmanager:us-east-1:176843580427:secret:$SecretName" `
    --database "bedrock_vectors" `
    --sql "GRANT ALL PRIVILEGES ON TABLE bedrock_vectors TO bedrock_user;"

# Note: No sequence grant needed for UUID primary key

# Create similarity search function
Write-Host "Creating similarity search function..."
$similarityFunctionSQL = "CREATE OR REPLACE FUNCTION vector_similarity_search(query_embedding vector(1024), match_threshold float, match_count int) RETURNS TABLE (id uuid, content text, metadata jsonb, similarity float) LANGUAGE plpgsql AS `$`$ BEGIN RETURN QUERY SELECT bv.id, bv.content, bv.metadata, 1 - (bv.embedding <=> query_embedding) AS similarity FROM bedrock_vectors bv WHERE 1 - (bv.embedding <=> query_embedding) > match_threshold ORDER BY bv.embedding <=> query_embedding LIMIT match_count; END; `$`$;"
aws rds-data execute-statement `
    --resource-arn $ClusterArn `
    --secret-arn "arn:aws:secretsmanager:us-east-1:176843580427:secret:$SecretName" `
    --database "bedrock_vectors" `
    --sql $similarityFunctionSQL

# Grant execute permission
aws rds-data execute-statement `
    --resource-arn $ClusterArn `
    --secret-arn "arn:aws:secretsmanager:us-east-1:176843580427:secret:$SecretName" `
    --database "bedrock_vectors" `
    --sql "GRANT EXECUTE ON FUNCTION vector_similarity_search TO bedrock_user;"

Write-Host "Database initialization completed successfully!"

# Test the setup
Write-Host "Testing database setup..."
aws rds-data execute-statement `
    --resource-arn $ClusterArn `
    --secret-arn "arn:aws:secretsmanager:us-east-1:176843580427:secret:$SecretName" `
    --database "bedrock_vectors" `
    --sql "SELECT version();"

aws rds-data execute-statement `
    --resource-arn $ClusterArn `
    --secret-arn "arn:aws:secretsmanager:us-east-1:176843580427:secret:$SecretName" `
    --database "bedrock_vectors" `
    --sql "SELECT * FROM pg_extension WHERE extname = 'vector';"

Write-Host "Database is ready for Bedrock Knowledge Base!"
