resource "aws_s3_bucket" "knowledge_base_input_data" {
  bucket = "${local.knowledge_base_bucket_name}-input"
  tags   = local.tags
}

resource "aws_s3_object" "csv_upload" {
  for_each     = toset(local.knowledge_base_csv_files)
  bucket       = aws_s3_bucket.knowledge_base_input_data.bucket
  key          = "input-data/${each.value}"
  source       = "${local.knowledge_base_local_folder}/${each.value}"
  etag         = filemd5("${local.knowledge_base_local_folder}/${each.value}")
  content_type = "text/csv"
  tags         = local.tags 
}

resource "aws_s3_bucket_public_access_block" "knowledge_base_input_data" {
  bucket                  = aws_s3_bucket.knowledge_base_input_data.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
}


resource "aws_s3_bucket" "knowledge_base_storage" {
  bucket = "${local.knowledge_base_bucket_name}-storage"
  tags   = local.tags
}

resource "aws_s3_bucket_public_access_block" "knowledge_base_storage" {
  bucket                  = aws_s3_bucket.knowledge_base_storage.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
}
