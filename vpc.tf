resource "aws_vpc" "main" {
  cidr_block           = local.cidr_block
  enable_dns_support   = local.enable_dns_support
  enable_dns_hostnames = local.enable_dns_hostnames
  tags = merge(local.tags, { Name = local.vpc_name})
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = merge(local.tags, { Name = "main-igw" })
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  tags = merge(local.tags, { Name = "main-nat-eip" })
}

resource "aws_subnet" "public" {
  count                   = local.number_of_subnets
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 4, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags                    = merge(local.tags, { Name = "public-${count.index}" })
}

resource "aws_subnet" "private" {
  count             = local.number_of_subnets
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 4, count.index + 4)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags              = merge(local.tags, { Name = "private-${count.index}" })
}

# NAT Gateway (in first public subnet)
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
  tags          = merge(local.tags, { Name = "main-nat" })
  depends_on    = [aws_internet_gateway.gw]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags   = merge(local.tags, { Name = "public-rt" })
}

resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = local.destination_cidr_block
  gateway_id             = aws_internet_gateway.gw.id
}

resource "aws_route_table_association" "public" {
  count          = local.number_of_subnets
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags   = merge(local.tags, { Name = "private-rt" })
}

resource "aws_route" "private_nat_gateway" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = local.destination_cidr_block
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "private" {
  count          = local.number_of_subnets
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_cloudwatch_log_group" "flow_logs" {
  name              = "flow-logs"
  retention_in_days = local.flow_logs_retention
  tags              = merge(local.tags, { Name = "flow-logs" })
}

resource "aws_flow_log" "vpc" {
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.flow_logs.arn
  vpc_id               = aws_vpc.main.id
  traffic_type         = "ALL"
  iam_role_arn         = aws_iam_role.vpc_logs_role.arn
  tags                 = merge(local.tags, { Name = "flow-logs" })
}

resource "aws_security_group" "opensearch" {
  name   = "${local.vpc_name}-opensearch-sg"
  vpc_id = aws_vpc.main.id
}

resource "aws_opensearchserverless_vpc_endpoint" "opensearch" {
  name               = "${local.vpc_name}-opensearch"
  vpc_id             = aws_vpc.main.id
  subnet_ids         = aws_subnet.private.*.id
  security_group_ids = [aws_security_group.opensearch.id]
}