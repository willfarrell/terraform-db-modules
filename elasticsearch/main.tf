resource "aws_elasticsearch_domain" "main" {
  domain_name           = local.name
  elasticsearch_version = var.engine_version

  cluster_config {
    instance_type            = var.instance_type
    instance_count           = var.node_count
    dedicated_master_enabled = var.dedicated_master_count
    dedicated_master_type    = var.dedicated_master_type
    dedicated_master_count   = var.dedicated_master_count
    zone_awareness_enabled   = var.multi_az
  }

  vpc_options {
    security_group_ids = [aws_security_group.main.id]
    subnet_ids         = var.private_subnet_ids
  }

  node_to_node_encryption {
    enabled = "true"
  }

  encrypt_at_rest {
    enabled = "true"
    #kms_key_id = var.kms_key_id
  }

  snapshot_options {
    automated_snapshot_start_hour = var.automated_snapshot_start_hour
  }

  ebs_options {
    ebs_enabled = "true"
    volume_type = var.ebs_volume_type
    volume_size = var.ebs_volume_size
    iops        = var.ebs_iops
  }

  log_publishing_options = {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.default.arn
    log_type                 = "SEARCH_SLOW_LOGS" # INDEX_SLOW_LOGS, SEARCH_SLOW_LOGS, ES_APPLICATION_LOGS
  }
  cognito_options = var.cognito_options

  access_policies = <<POLICY
  {
      "Version": "2012-10-17",
      "Statement": [
          {
              "Action": "es:*",
              "Principal": "*",
              "Effect": "Allow",
              "Resource": "arn:aws:es:${local.region}:${local.account_id}:domain/${local.name}/*"
          }
      ]
  }
POLICY


  tags = merge(
    local.tags,
    {
      Name = local.name
    }
  )
}

resource "aws_cloudwatch_log_group" "default" {
  name = "elasticsearch/${local.name}"
  retention_in_days = var.retention_in_days == 0 ? (terraform.workspace == "production" ? 365 : 7) : var.retention_in_days
}
