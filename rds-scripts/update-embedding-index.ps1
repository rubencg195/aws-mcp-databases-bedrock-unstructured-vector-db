# Script to update embedding index to HNSW for Bedrock Knowledge Base
param(
    [string]$ProjectName = "mcp-demo"
)

$SecretName = "$ProjectName-rds-credentials"
$ClusterArn = "arn:aws:rds:us-east-1:176843580427:cluster:$ProjectName-vector-store"

Write-Host "Getting RDS credentials from Secrets Manager..."
$Credentials = aws secretsmanager get-secret-value --secret-id $SecretName --query 'SecretString' --output text | ConvertFrom-Json

Write-Host "Updating embedding index to HNSW for Bedrock Knowledge Base..."

# Drop the existing IVFFlat index
Write-Host "Dropping existing IVFFlat index..."
aws rds-data execute-statement `
    --resource-arn $ClusterArn `
    --secret-arn "arn:aws:secretsmanager:us-east-1:176843580427:secret:$SecretName" `
    --database "bedrock_vectors" `
    --sql "DROP INDEX IF EXISTS idx_bedrock_vectors_embedding;"

# Create the HNSW index on embedding column
Write-Host "Creating HNSW index on embedding column..."
aws rds-data execute-statement `
    --resource-arn $ClusterArn `
    --secret-arn "arn:aws:secretsmanager:us-east-1:176843580427:secret:$SecretName" `
    --database "bedrock_vectors" `
    --sql "CREATE INDEX idx_bedrock_vectors_embedding ON bedrock_vectors USING hnsw (embedding vector_cosine_ops);"

Write-Host "HNSW index created successfully!"

# Test the new index
Write-Host "Testing the new HNSW index..."
aws rds-data execute-statement `
    --resource-arn $ClusterArn `
    --secret-arn "arn:aws:secretsmanager:us-east-1:176843580427:secret:$SecretName" `
    --database "bedrock_vectors" `
    --sql "SELECT indexname, indexdef FROM pg_indexes WHERE tablename = 'bedrock_vectors' AND indexname LIKE '%embedding%';"

Write-Host "Embedding column is now properly indexed with HNSW for Bedrock Knowledge Base!"
