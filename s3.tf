resource "aws_s3_bucket" "knowledge_base" {
  bucket = local.knowledge_base_bucket_name
  tags   = local.tags
}

resource "aws_s3_object" "csv_upload" {
  for_each     = toset(local.knowledge_base_csv_files)
  bucket       = aws_s3_bucket.knowledge_base.bucket
  key          = each.key
  source       = "${local.knowledge_base_local_folder}/${each.value}"
  etag         = filemd5("${local.knowledge_base_local_folder}/${each.value}")
  content_type = "text/csv"
  tags         = local.tags 
}

resource "aws_s3_bucket_public_access_block" "knowledge_base" {
  bucket                  = aws_s3_bucket.knowledge_base.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
}


