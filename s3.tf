resource "aws_s3_bucket" "knowledge_base_input_data" {
  bucket = "${local.knowledge_base_bucket_name}-input"
  tags   = local.tags
}

resource "aws_s3_object" "csv_upload" {
  for_each     = toset(local.knowledge_base_csv_files)
  bucket       = aws_s3_bucket.knowledge_base_input_data.bucket
  key          = "${local.knowledge_base_input_data_prefix}${each.value}"
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


resource "aws_s3_bucket" "knowledge_base_website" {
  bucket = "${local.knowledge_base_bucket_name}-website"
  tags   = local.tags
}

resource "aws_s3_bucket_ownership_controls" "website_ownership" {
  bucket = aws_s3_bucket.knowledge_base_website.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "website_public_access" {
  bucket                  = aws_s3_bucket.knowledge_base_website.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "website_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.website_ownership, aws_s3_bucket_public_access_block.website_public_access]
  bucket = aws_s3_bucket.knowledge_base_website.id
  acl    = "public-read" # Allow public read access for static website hosting
}

resource "aws_s3_bucket_policy" "website_policy" {
  depends_on = [aws_s3_bucket_public_access_block.website_public_access]
  bucket = aws_s3_bucket.knowledge_base_website.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.knowledge_base_website.arn}/*"
      },
    ]
  })
}

resource "aws_s3_bucket_website_configuration" "website_configuration" {
  bucket = aws_s3_bucket.knowledge_base_website.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_object" "website_assets" {
  for_each     = local.website_assets
  bucket       = aws_s3_bucket.knowledge_base_website.bucket
  key          = each.key
  source       = each.value.source
  content_type = each.value.content_type
  tags         = local.tags
}

resource "local_file" "website_info" {
  filename = "${path.module}/.website_info.txt"
  content  = <<EOT
Website URL:
http://${aws_s3_bucket_website_configuration.website_configuration.website_endpoint}

Website Bucket Name:
${aws_s3_bucket.knowledge_base_website.bucket}

Website Bucket ARN:
${aws_s3_bucket.knowledge_base_website.arn}

Website Bucket ID:
${aws_s3_bucket.knowledge_base_website.id}

Website Bucket Region:
${aws_s3_bucket.knowledge_base_website.region}
EOT
}
