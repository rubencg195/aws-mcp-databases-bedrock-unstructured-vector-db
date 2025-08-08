#!/bin/bash

# Database initialization script for Bedrock Knowledge Base with RDS
# This script initializes the PostgreSQL database with pgvector extension

set -e

# Configuration
PROJECT_NAME="mcp-demo"
SECRET_NAME="${PROJECT_NAME}-rds-credentials"

echo "Getting RDS credentials from Secrets Manager..."
CREDENTIALS=$(aws secretsmanager get-secret-value --secret-id "$SECRET_NAME" --query 'SecretString' --output text)

# Extract connection details
DB_HOST=$(echo "$CREDENTIALS" | jq -r '.host')
DB_PORT=$(echo "$CREDENTIALS" | jq -r '.port')
DB_NAME=$(echo "$CREDENTIALS" | jq -r '.dbname')
DB_USER=$(echo "$CREDENTIALS" | jq -r '.username')
DB_PASSWORD=$(echo "$CREDENTIALS" | jq -r '.password')

echo "Connecting to RDS instance at $DB_HOST:$DB_PORT..."

# Wait for RDS to be available
echo "Waiting for RDS instance to be available..."
aws rds wait db-instance-available --db-instance-identifier "${PROJECT_NAME}-vector-store"

# Install PostgreSQL client if not available
if ! command -v psql &> /dev/null; then
    echo "Installing PostgreSQL client..."
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo apt-get update && sudo apt-get install -y postgresql-client
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        brew install postgresql
    else
        echo "Please install PostgreSQL client manually"
        exit 1
    fi
fi

# Set environment variables for psql
export PGPASSWORD="$DB_PASSWORD"

echo "Initializing database with vector extension and tables..."

# Run the initialization script
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f database-init.sql

echo "Database initialization completed successfully!"

# Test the vector extension
echo "Testing vector extension..."
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT version();" -c "SELECT * FROM pg_extension WHERE extname = 'vector';"

echo "Database is ready for Bedrock Knowledge Base!"
