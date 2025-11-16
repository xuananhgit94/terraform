provider "aws" {}

data "cloudinit_config" "cdc-data" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = templatefile("${path.module}/cloud_config.yaml", {})
  }
}

data "cloudinit_config" "runner" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = templatefile("${path.module}/cloud_config_runner.yaml", {})
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  owners = ["099720109477"]
}

resource "aws_instance" "cdc-data" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.large"
  key_name                    = "test"
  user_data_base64            = data.cloudinit_config.cdc-data.rendered
  vpc_security_group_ids      = [aws_security_group.cdc-data.id]

  root_block_device {
    volume_size = 100
  }

  lifecycle {
    ignore_changes = [ami]
  }

  tags = {
    Name = "cdc-data"
  }
}

resource "aws_instance" "runner" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.medium"
  key_name                    = "test"
  user_data_base64            = data.cloudinit_config.runner.rendered
  vpc_security_group_ids      = [aws_security_group.runner.id]

  root_block_device {
    volume_size = 30
  }

  lifecycle {
    ignore_changes = [ami]
  }

  tags = {
    Name = "runner"
  }
}

output "ec2_public_ips" {
  description = "Public IPs of all EC2 instances"
  value = {
    cdc_data = aws_instance.cdc-data.public_ip
    runner   = aws_instance.runner.public_ip
  }
}