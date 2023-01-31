data "aws_partition" "current" {}

module "defaults" {
  source = "git@github.com:willfarrell/terraform-defaults?ref=v0.1.0"
  name   = var.name
  tags   = var.default_tags
}

locals {
  account_id           = module.defaults.account_id
  region               = module.defaults.region
  name                 = module.defaults.name
  tags                 = module.defaults.tags
  identifier           = "${var.name}-${var.engine}-${var.type}"
  engine               = var.engine
  engine_family        = "${var.engine}${var.engine_version}"
  parameter_group_name = var.parameter_group_name != "" ? var.parameter_group_name : (var.type == "cluster" ? aws_rds_cluster_parameter_group.default[0].name : aws_db_parameter_group.default[0].name)
  // "default.${local.engine_family}"
  db_name              = var.db_name != "" ? var.db_name : var.name
  endpoint             = concat(aws_rds_cluster.main.*.endpoint, aws_db_instance.main.*.address)[0]
  bootstrap_folder     = var.bootstrap_folder != "" ? var.bootstrap_folder : var.engine

  port = concat(aws_rds_cluster.main.*.port, aws_db_instance.main.*.port)[0]
}
