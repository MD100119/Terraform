provider "aws" {
    region = var.region
  
}

resource "aws_security_group" "web_sgnew" {
  name        = "web-security-group"
  description = "Allow SSH and HTTP"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]   # Replace with your IP for better security
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Web-SG"
  }
}


resource "aws_iam_role" "ec2_ssm_role" {
  name = "ec2-ssm-read-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "ssm_parameter_policy" {

  name = "SSMParameterReadPolicy"

  policy = jsonencode({

    Version = "2012-10-17"

    Statement = [

      {
        Effect = "Allow"

        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]

        Resource = "*"
      }

    ]
  })

}

resource "aws_iam_role_policy_attachment" "attach_policy" {

  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = aws_iam_policy.ssm_parameter_policy.arn

}

resource "aws_iam_instance_profile" "ec2_profile" {

  name = "ec2-ssm-profile"
  role = aws_iam_role.ec2_ssm_role.name

}

resource "aws_instance" "devops_project" {
  ami           = var.ami_id
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.web_sgnew.id]
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  user_data = <<-EOF
              #!/bin/bash
              exec > >(tee -a /var/log/user-data.log) 2>&1
              echo "Hello from instance"
              sudo apt-get update -y
              curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
              sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
              kubectl version --client
              sudo apt install unzip -y 
              sudo curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
              sudo unzip awscliv2.zip
              sudo ./aws/install
              aws --version 
              set -euo pipefail

              # Parameter Store names
              ACCESS_KEY_PARAM="/myapp/aws/access_key_id"
              SECRET_KEY_PARAM="/myapp/aws/secret_access_key"
              REGION_PARAM="/myapp/aws/region"
              
              # Fetch values from SSM Parameter Store
              ACCESS_KEY=$(aws ssm get-parameter --name "$ACCESS_KEY_PARAM" --query "Parameter.Value" --output text)
              SECRET_KEY=$(aws ssm get-parameter --name "$SECRET_KEY_PARAM" --with-decryption --query "Parameter.Value" --output text)
              REGION=$(aws ssm get-parameter --name "$REGION_PARAM" --query "Parameter.Value" --output text 2>/dev/null || echo "us-east-1")
              # Configure AWS CLI profile
              PROFILE="default"
              
              aws configure set aws_access_key_id "$ACCESS_KEY" --profile "$PROFILE"
              aws configure set aws_secret_access_key "$SECRET_KEY" --profile "$PROFILE"
              aws configure set region "$REGION" --profile "$PROFILE"
              
              echo "AWS CLI configured successfully for profile: $PROFILE"
              git clone https://github.com/open-telemetry/opentelemetry-demo.git
              curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" -o eksctl.tar.gz
              tar -xzf eksctl.tar.gz 
              sudo mv eksctl /usr/local/bin
              eksctl version

              curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
              helm version

              EOF

  tags = {
    Name = "DevOps-Project-Instance"}

}
