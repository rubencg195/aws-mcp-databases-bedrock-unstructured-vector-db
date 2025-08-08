# RDS PostgreSQL Configuration for Vector Storage
resource "aws_db_subnet_group" "bedrock_rds" {
  name       = "${local.project_name}-rds-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = local.tags
}

resource "aws_security_group" "bedrock_rds" {
  name        = "${local.project_name}-rds-sg"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]  # Allow access from VPC CIDR
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

# RDS Aurora PostgreSQL Cluster for Vector Storage
resource "aws_rds_cluster" "bedrock_vector_store" {
  cluster_identifier = "${local.project_name}-vector-store"

  # Engine configuration
  engine         = "aurora-postgresql"
  engine_version = "15.4"
  engine_mode    = "provisioned"

  # Database configuration
  database_name   = "bedrock_vectors"
  master_username = "bedrock_user"
  master_password = random_password.rds_password.result

  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.bedrock_rds.name
  vpc_security_group_ids = [aws_security_group.bedrock_rds.id]
  skip_final_snapshot    = true

  # Backup configuration
  backup_retention_period = local.rds_backup_retention_period
  preferred_backup_window = "03:00-04:00"
  preferred_maintenance_window = "sun:04:00-sun:05:00"

  # Storage configuration
  storage_encrypted = true
  kms_key_id       = aws_kms_key.bedrock_knowledge_base_key.arn

  # Performance insights
  performance_insights_enabled = true
  performance_insights_retention_period = 7

  # Enable Data API v2 for Bedrock Knowledge Base
  enable_http_endpoint = true

  tags = local.tags

  depends_on = [
    aws_kms_key.bedrock_knowledge_base_key
  ]
}

# RDS Aurora Instance
resource "aws_rds_cluster_instance" "bedrock_vector_store" {
  identifier         = "${local.project_name}-vector-store-instance"
  cluster_identifier = aws_rds_cluster.bedrock_vector_store.id
  instance_class     = local.rds_instance_class
  engine             = aws_rds_cluster.bedrock_vector_store.engine
  engine_version     = aws_rds_cluster.bedrock_vector_store.engine_version

  # Monitoring
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_monitoring_role.arn

  tags = local.tags

  depends_on = [
    aws_iam_role.rds_monitoring_role
  ]
}

# Random password for RDS
resource "random_password" "rds_password" {
  length  = 16
  special = true
}

# IAM Role for RDS Enhanced Monitoring
resource "aws_iam_role" "rds_monitoring_role" {
  name = "${local.project_name}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "rds_monitoring_policy" {
  role       = aws_iam_role.rds_monitoring_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# Output RDS connection information
resource "local_file" "rds_connection_info" {
  filename = "${path.module}/.rds_connection_info.txt"
  content  = <<EOT
endpoint      = ${aws_rds_cluster.bedrock_vector_store.endpoint}
database_name = ${aws_rds_cluster.bedrock_vector_store.database_name}
username      = ${aws_rds_cluster.bedrock_vector_store.master_username}
password      = ${random_password.rds_password.result}
EOT
}

# Secrets Manager for RDS credentials
resource "aws_secretsmanager_secret" "rds_credentials" {
  name        = "${local.project_name}-rds-credentials"
  description = "RDS credentials for Bedrock Knowledge Base"
  kms_key_id  = aws_kms_key.bedrock_knowledge_base_key.arn

  tags = local.tags
}

resource "aws_secretsmanager_secret_version" "rds_credentials" {
  secret_id = aws_secretsmanager_secret.rds_credentials.id
  secret_string = jsonencode({
    username = aws_rds_cluster.bedrock_vector_store.master_username
    password = random_password.rds_password.result
    host     = aws_rds_cluster.bedrock_vector_store.endpoint
    port     = aws_rds_cluster.bedrock_vector_store.port
    dbname   = aws_rds_cluster.bedrock_vector_store.database_name
  })
}
