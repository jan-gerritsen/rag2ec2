data "aws_subnet" "existing" {
  id = var.aws_subnet_id
}

data "aws_ami" "amazon_linux_2_latest" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

data "aws_iam_role" "ecr_access" {
  name = "ec2-ecr-role"
}

data "aws_iam_policy_document" "ec2_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecr_readonly" {
  role       = data.aws_iam_role.ecr_access.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

data "aws_iam_instance_profile" "ec2_ecr_profile" {
  name = "ec2-ecr-profile"
}


resource "aws_volume_attachment" "ebs_flask_attach" {
  device_name = "/dev/xvdf"
  volume_id   = var.aws_ebs_rag_volume_id # For model data
  instance_id = aws_instance.flask_server.id
  force_detach = true
}

resource "aws_volume_attachment" "ebs_ollama_attach" {
  device_name = "/dev/xvdf"
  volume_id   = var.aws_ebs_ollama_volume_id # For model data
  instance_id = aws_instance.ollama_server.id
  force_detach = true
}

resource "aws_instance" "flask_server" {
  ami           = data.aws_ami.amazon_linux_2_latest.id # Amazon Linux 2 (update as needed)
  instance_type = "t2.small"
  subnet_id     = data.aws_subnet.existing.id
  security_groups = var.aws_security_group_ids
  key_name      = "gsemi-key"
  iam_instance_profile = data.aws_iam_instance_profile.ec2_ecr_profile.name
  associate_public_ip_address = true

  provisioner "file" {
    source      = "${path.module}/../compose_production_flask.yml"
    destination = "/home/ec2-user/docker-compose.yml"
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /home/ec2-user/nginx"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "chown -R ec2-user:ec2-user /home/ec2-user/nginx"
    ]
  }

  provisioner "file" {
    source      = "${path.module}/../compose/production/nginx/default.conf"
    destination = "/home/ec2-user/nginx.conf"
  }

  provisioner "remote-exec" {
    inline = [
      "chown ec2-user:ec2-user /home/ec2-user/docker-compose.yml",
      "chown ec2-user:ec2-user /home/ec2-user/nginx.conf"
    ]
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/.ssh/gsemi-key.pem")
    host        = self.public_ip
  }


user_data = <<-EOF
  #!/bin/bash
  yum update -y
  yum install -y git docker python3-pip nginx

  service docker start
  usermod -a -G docker ec2-user

  # Install Docker Compose v2
  mkdir -p /usr/local/lib/docker/cli-plugins/
  curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 -o /usr/local/lib/docker/cli-plugins/docker-compose
  chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

  # Verify installation
  docker compose version

  sudo mkdir -p /etc/letsencrypt
  sudo chown ec2-user:ec2-user /etc/letsencrypt

  sudo useradd --system --no-create-home --shell /sbin/nologin nginx

  # Create the acme-challenge directory
  mkdir -p /home/ec2-user/certbot-webroot
  chown ec2-user:ec2-user /home/ec2-user/certbot-webroot
  chmod 755 /home/ec2-user/certbot-webroot

  # Authenticate Docker to ECR
  aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin 223129826839.dkr.ecr.us-west-2.amazonaws.com

  sudo chown ec2-user:ec2-user /home/ec2-user/.env
  sudo chmod -R 755 /home/ec2-user/.env

  # Pull and run your ECR image
  docker pull ${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/flask:latest
  docker pull nginx:1.17.8-alpine

  # The ssl certificate and key files may not have survived the deploy process, so we will copy them again
  # we get them from an existing EBS volume

  # sudo mkdir -p /mnt/persisteddata

  # Mount the EBS volume
  # sudo mount /dev/xvdf /mnt/persisteddata

  # Copy the SSL certificate and key files
  # sudo cp -r /mnt/persisteddata/letsencrypt/* /etc/letsencrypt/

  # Renew the SSL certificate if needed. Renew only if the certificate is close to expiration
  sudo certbot renew --webroot -w /home/ec2-user/certbot-web

  # Start all services with Docker Compose
  cd /home/ec2-user
  docker compose up -d
EOF


  tags = {
    Name = "Flask"
  }
}

resource "aws_instance" "ollama_server" {
  ami           = data.aws_ami.amazon_linux_2_latest.id
  instance_type = "t3.large"
  subnet_id     = var.aws_subnet_id
  security_groups = var.aws_security_group_ids
  key_name      = "gsemi-key"
  iam_instance_profile = data.aws_iam_instance_profile.ec2_ecr_profile.name
  associate_public_ip_address = true

  provisioner "file" {
    source      = "${path.module}/../compose_production_ollama.yml"
    destination = "/home/ec2-user/docker-compose.yml"
  }

  provisioner "file" {
    source      = "${path.module}/../compose/production/ollama/entrypoint"
    destination = "/home/ec2-user/entrypoint"
  }

    provisioner "file" {
    source      = "${path.module}/../compose/production/ollama/.env"
    destination = "/home/ec2-user/.env"
  }

  provisioner "file" {
      source      = "${path.module}/../compose/production/ollama/Dockerfile"
      destination = "/home/ec2-user/Dockerfile"
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/.ssh/gsemi-key.pem")
    host        = self.public_ip
  }

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y docker
    service docker start
    usermod -a -G docker ec2-user

    # Install Docker Compose v2
    mkdir -p /usr/local/lib/docker/cli-plugins/
    curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 -o /usr/local/lib/docker/cli-plugins/docker-compose
    chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

    # Authenticate Docker to ECR if needed
    # aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin <your_account_id>.dkr.ecr.us-west-2.amazonaws.com

    # authenticate to Github Container Registry
    echo "var.github_token" | docker login ghcr.io -u "${var.github_username}" --password-stdin

    # The model data directory may not have survived the deploy process, so we will copy them again
    # we get them from an existing EBS volume

    sudo mkdir -p /mnt/model_data
    # Associate the EBS volume with the instance


    # Mount the EBS volume
    sudo mount /dev/xvdf /mnt/model_data

    cd /home/ec2-user
    docker compose up -d

  EOF

  tags = {
    Name = "Ollama"
  }
}


