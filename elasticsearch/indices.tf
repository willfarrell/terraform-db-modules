
resource "local_file" "indices_script" {
  count      = var.bootstrap_file == "" ? 0 : 1
  content    =templatefile("${path.module}/create_indices_template.sh", {
    SSH_IDENTITY_FILE      = var.ssh_identity_file
    SSH_USERNAME           = var.ssh_username
    BASTION_NAME             = var.bastion_name
    ELASTICSEARCH_ENDPOINT = aws_elasticsearch_domain.main.endpoint
    INDICES_CONFIG_FILE    = var.bootstrap_file
  })
  filename   = "${path.cwd}/${var.bootstrap_file}/create_indices.sh"
  depends_on = [aws_elasticsearch_domain.main]
}

data "local_file" "indices_config" {
  count    = var.bootstrap_file == "" ? 0 : 1
  filename = "${path.cwd}/${var.bootstrap_file}"
}

data "local_file" "init_script" {
  filename = "${path.module}/${var.bootstrap_file}/indices.js"
}

resource "null_resource" "init" {
  count      = var.bootstrap_file == "" ? 0 : 1
  depends_on = [local_file.indices_script]

  triggers = {
    mappings    = md5(data.local_file.indices_config[0].content)
    init_script = md5(data.local_file.init_script.content)
  }

  provisioner "local-exec" {
    command = "docker run --rm -v ${path.cwd}:/data -e USE_BASTION=${var.bastion_ip == "" ? "false" : "true"} tesera/node10-ssh:latest /bin/bash /data/${var.bootstrap_file}/create_indices.sh"
  }
}

