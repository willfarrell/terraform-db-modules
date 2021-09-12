data "template_file" "postgres" {
  count    = var.ssh_username == "" ? 0 : 1
  template = file("${path.module}/postgres_sql_template.sh")

  vars = {
    AWS_PROFILE = var.aws_profile
    AWS_REGION = local.region
    SSH_IDENTITY_FILE   = var.ssh_identity_file
    SSH_USERNAME        = var.ssh_username
    BASTION_NAME        = var.bastion_name
    DB_HOST             = local.endpoint
    DB_FROM_PORT             = local.port
    DB_TO_PORT             = local.port
    DATABASE_NAME       = local.db_name
    INIT_SCRIPTS_FOLDER = local.bootstrap_folder
  }
}

resource "local_file" "postgres" {
  count      = var.ssh_username == "" ? 0 : 1
  content    = data.template_file.postgres[0].rendered
  filename   = "${path.cwd}/${local.bootstrap_folder}_sql.sh"
  depends_on = [aws_rds_cluster_instance.main, aws_db_instance.main]
}

# purely to re-trigger update - TODO update
data "archive_file" "postgres" {
  count       = var.ssh_username == "" ? 0 : 1
  type        = "zip"
  output_path = "${path.cwd}/${local.bootstrap_folder}_sql.zip"
  source_dir  = local.bootstrap_folder
}

resource "null_resource" "postgres" {
  count = var.ssh_username == "" ? 0 : 1

  # Changes to the files in init_scripts_folder will execute the script
  triggers = {
    scripts_hash = data.archive_file.postgres[0].output_base64sha256
    script       = md5(local_file.postgres[0].content)
  }

  provisioner "local-exec" {
    command = "docker run --rm -v ~/.ssh/${var.ssh_identity_file}:/root/.ssh/${var.ssh_identity_file} -v ~/.aws/credentials:/root/.aws/credentials:ro -v ~/.aws/config:/root/.aws/config:ro -v ${path.cwd}:/data -e PGPASSWORD=\"${var.password}\" -e PGUSER=${var.username} psql-ssm:latest /bin/bash /data/${local.bootstrap_folder}_sql.sh"
    #command = "docker run --rm -v ${path.cwd}:/data -e PGUSER=${var.username} -e PGPASSWORD=\"${var.password}\" governmentpaas/psql:latest /bin/bash /data/${local.bootstrap_folder}_sql.sh"
  }
}

