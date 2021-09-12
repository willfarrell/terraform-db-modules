resource "aws_db_instance" "main" {
  count = var.type == "cluster" ? 0 : 1

  auto_minor_version_upgrade = true
  allow_major_version_upgrade = true
  allocated_storage = var.allocated_storage
  max_allocated_storage = max(var.max_allocated_storage, var.allocated_storage)
  identifier = local.identifier
  storage_type = var.storage_type
  engine = var.engine
  engine_version = var.engine_version
  port = var.port
  instance_class = var.instance_type
  name = local.db_name
  parameter_group_name = local.parameter_group_name
  apply_immediately = var.apply_immediately
  deletion_protection = true
  final_snapshot_identifier = "${local.identifier}-final"

  ## Confidentiality ##
  username = var.username
  password = var.password
  iam_database_authentication_enabled = var.iam_database_authentication_enabled
  publicly_accessible = var.publicly_accessible
  db_subnet_group_name = aws_db_subnet_group.main.name

  vpc_security_group_ids = [
    aws_security_group.main.id,
  ]

  # TODO research and apply `kms_key_id`
  ca_cert_identifier = "rds-ca-2019"
  storage_encrypted = replace(var.instance_type, "micro", "") == var.instance_type

  ## Integrity ##
  enabled_cloudwatch_logs_exports = var.cloudwatch_logs_exports
  performance_insights_enabled = var.performance_insights
  monitoring_role_arn = var.monitoring_interval > 0 ? aws_iam_role.monitoring.arn : null
  monitoring_interval = var.monitoring_interval

  # TODO add in `monitoring_interval` & `monitoring_role_arn`
  copy_tags_to_snapshot = true
  backup_retention_period = var.backup_retention_period
  backup_window = var.backup_window

  ## Availability ##
  multi_az = var.multi_az
  tags = merge(
  local.tags,
  {
    Name = "${local.identifier} Primary/Secondary"
  }
  )
}

resource "aws_cloudwatch_log_group" "instance" {
  count = var.type == "cluster" ? 0 : length(var.cloudwatch_logs_exports)
  name = "/aws/rds/instance/${local.identifier}/${element(var.cloudwatch_logs_exports, count.index)}"
  retention_in_days = 30

  tags = merge(
  local.tags,
  {
    Name = "${local.identifier} ${element(var.cloudwatch_logs_exports, count.index)}"
  }
  )
}

resource "aws_db_instance" "replica" {
  count = var.type == "cluster" ? 0 : var.replica_count
  replicate_source_db = aws_db_instance.main[0].identifier

  auto_minor_version_upgrade = true
  allow_major_version_upgrade = true
  allocated_storage = var.allocated_storage
  max_allocated_storage = max(var.max_allocated_storage, var.allocated_storage)
  identifier = "${local.name}-${var.engine}-${var.type}-replica-${count.index}"
  storage_type = var.storage_type
  engine = var.engine
  engine_version = var.engine_version
  instance_class = var.replica_instance_type != "" ? var.replica_instance_type : var.instance_type
  name = local.db_name
  parameter_group_name = local.parameter_group_name
  apply_immediately = true
  deletion_protection = false
  skip_final_snapshot = true

  ## Confidentiality ##
  username = var.username
  #password = var.password
  iam_database_authentication_enabled = var.iam_database_authentication_enabled
  publicly_accessible = var.publicly_accessible
  vpc_security_group_ids = [
    aws_security_group.main.id
  ]

  # TODO research and apply `kms_key_id`
  ca_cert_identifier = "rds-ca-2019"
  storage_encrypted = replace(var.instance_type, "micro", "") == var.instance_type

  ## Integrity ##
  enabled_cloudwatch_logs_exports = length(var.cloudwatch_logs_exports) > 0 ? var.cloudwatch_logs_exports : null
  performance_insights_enabled = var.performance_insights
  monitoring_role_arn = var.monitoring_interval > 0 ? aws_iam_role.monitoring.arn : null
  monitoring_interval = var.monitoring_interval

  # TODO add in `monitoring_interval` & `monitoring_role_arn`
  copy_tags_to_snapshot = true
  backup_retention_period = 0
  backup_window = var.backup_window

  ## Availability ##
  multi_az = false
  tags = merge(
  local.tags,
  {
    Name = "${local.identifier} Replica"
  }
  )
}

resource "aws_db_parameter_group" "default" {
  count = var.type == "cluster" ? 0 : 1
  name = "${local.engine_family}-secure"
  family = local.engine_family
  description = "RDS default parameter group"

  // Security
  parameter {
    name = "rds.force_ssl"
    value = "1"
  }

  dynamic "parameter" {
    for_each = keys(var.config)
    content {
      apply_method = "pending-reboot"
      name = parameter.value
      value = var.config[parameter.value]
    }
  }
}

