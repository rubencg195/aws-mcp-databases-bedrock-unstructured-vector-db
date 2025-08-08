-- Database initialization script for Bedrock Knowledge Base with RDS
-- This script sets up the PostgreSQL database with pgvector extension

-- Enable the pgvector extension
CREATE EXTENSION IF NOT EXISTS vector;

-- Create the bedrock_vectors table
CREATE TABLE IF NOT EXISTS bedrock_vectors (
    id SERIAL PRIMARY KEY,
    content TEXT NOT NULL,
    embedding vector(1024),
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_bedrock_vectors_embedding ON bedrock_vectors USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);
CREATE INDEX IF NOT EXISTS idx_bedrock_vectors_metadata ON bedrock_vectors USING GIN (metadata);
CREATE INDEX IF NOT EXISTS idx_bedrock_vectors_created_at ON bedrock_vectors (created_at);

-- Create a function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create a trigger to automatically update the updated_at column
CREATE TRIGGER update_bedrock_vectors_updated_at 
    BEFORE UPDATE ON bedrock_vectors 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Grant permissions to the bedrock user
GRANT ALL PRIVILEGES ON TABLE bedrock_vectors TO bedrock_user;
GRANT USAGE, SELECT ON SEQUENCE bedrock_vectors_id_seq TO bedrock_user;

-- Create a function for vector similarity search
CREATE OR REPLACE FUNCTION vector_similarity_search(
    query_embedding vector(1024),
    match_threshold float,
    match_count int
)
RETURNS TABLE (
    id int,
    content text,
    metadata jsonb,
    similarity float
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        bv.id,
        bv.content,
        bv.metadata,
        1 - (bv.embedding <=> query_embedding) AS similarity
    FROM bedrock_vectors bv
    WHERE 1 - (bv.embedding <=> query_embedding) > match_threshold
    ORDER BY bv.embedding <=> query_embedding
    LIMIT match_count;
END;
$$;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION vector_similarity_search TO bedrock_user;
