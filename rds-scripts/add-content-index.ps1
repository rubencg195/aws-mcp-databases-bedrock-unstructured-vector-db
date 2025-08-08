# Script to add full-text search index on content column for Bedrock Knowledge Base
param(
    [string]$ProjectName = "mcp-demo"
)

$SecretName = "$ProjectName-rds-credentials"
$ClusterArn = "arn:aws:rds:us-east-1:176843580427:cluster:$ProjectName-vector-store"

Write-Host "Getting RDS credentials from Secrets Manager..."
$Credentials = aws secretsmanager get-secret-value --secret-id $SecretName --query 'SecretString' --output text | ConvertFrom-Json

Write-Host "Adding full-text search index on content column..."

# Add full-text search index on content column
Write-Host "Creating full-text search index on content column..."
aws rds-data execute-statement `
    --resource-arn $ClusterArn `
    --secret-arn "arn:aws:secretsmanager:us-east-1:176843580427:secret:$SecretName" `
    --database "bedrock_vectors" `
    --sql "CREATE INDEX IF NOT EXISTS idx_bedrock_vectors_content_fts ON bedrock_vectors USING gin (to_tsvector('simple', content));"

Write-Host "Full-text search index created successfully!"

# Test the index
Write-Host "Testing the new index..."
aws rds-data execute-statement `
    --resource-arn $ClusterArn `
    --secret-arn "arn:aws:secretsmanager:us-east-1:176843580427:secret:$SecretName" `
    --database "bedrock_vectors" `
    --sql "SELECT indexname, indexdef FROM pg_indexes WHERE tablename = 'bedrock_vectors' AND indexname LIKE '%content%';"

Write-Host "Content column is now properly indexed for Bedrock Knowledge Base!"
