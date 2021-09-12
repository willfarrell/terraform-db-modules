
resource "aws_route53_record" "replica-primary" {
  count   = var.zone_id != "" && var.dns_replicas != "" && var.replica_count != 0 ? 1 : 0
  name    = var.dns_replicas
  zone_id = var.zone_id
  type    = "CNAME"
  ttl     = 300
  records = concat(aws_rds_cluster.main.*.reader_endpoint,aws_db_instance.replica.*.address)
  set_identifier = "failover"
  failover_routing_policy {
    type = "PRIMARY"
  }
}

// aka master
resource "aws_route53_record" "replica-secondary" {
  count   = var.zone_id != "" && var.dns_replicas != "" && var.replica_count != 0 ? 1 : 0
  name    = var.dns_replicas
  zone_id = var.zone_id
  type    = "CNAME"
  ttl     = 300
  records = concat(aws_rds_cluster.main.*.endpoint, aws_db_instance.main.*.address)
  set_identifier = "failover"
  failover_routing_policy {
    type = "SECONDARY"
  }
}

// for when there are no replicas
resource "aws_route53_record" "replica" {
  count   = var.zone_id != "" && var.dns_master != "" && var.replica_count == 0 ? 1 : 0
  name    = var.dns_replicas
  zone_id = var.zone_id
  type    = "CNAME"
  ttl     = 300
  records = concat(aws_rds_cluster.main.*.endpoint, aws_db_instance.main.*.address)
}

resource "aws_route53_record" "master" {
  count   = var.zone_id != "" && var.dns_master != "" ? 1 : 0
  name    = var.dns_master
  zone_id = var.zone_id
  type    = "CNAME"
  ttl     = 300
  records = concat(aws_rds_cluster.main.*.endpoint, aws_db_instance.main.*.address)
}
