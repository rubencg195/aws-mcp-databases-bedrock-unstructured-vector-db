
data "aws_iam_policy_document" "vpc_logs_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "vpc_logs_role" {
  name               = "vpc-logs-role"
  assume_role_policy = data.aws_iam_policy_document.vpc_logs_assume_role.json
  tags               = merge(local.tags, { Name = "vpc-logs-role" })
}

data "aws_iam_policy_document" "vpc_logs_policy" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "vpc_logs_policy" {
  name   = "vpc-logs-policy"
  role   = aws_iam_role.vpc_logs_role.id
  policy = data.aws_iam_policy_document.vpc_logs_policy.json
}