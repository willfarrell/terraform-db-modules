resource "aws_iam_role" "monitoring" {
  name = "${local.name}-rds-monitoring-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "monitoring.rds.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY

  tags = merge(
    local.tags,
    {
      Name = "${local.identifier} Monitoring"
    }
  )
}

resource "aws_iam_role_policy_attachment" "monitoring" {
  role       = aws_iam_role.monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

resource "aws_iam_role" "rds-sns" {
  name               = "${local.name}-rds-sns-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.rds-sns.json
}

data "aws_iam_policy_document" "rds-sns" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["sns.${data.aws_partition.current.dns_suffix}"]
    }
  }
}

resource "aws_iam_role_policy" "rds-sns-feedback-role-policy" {
  name   = "${local.identifier}-rds-sns-feedback-role-policy"
  role   = aws_iam_role.rds-sns.id
  policy = data.aws_iam_policy_document.rds-sns-feedback-role-policy.json
}

data "aws_iam_policy_document" "rds-sns-feedback-role-policy" {
  statement {
    effect  = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:PutMetricFilter",
      "logs:PutRetentionPolicy"
    ]
    resources = ["*"]
  }
}