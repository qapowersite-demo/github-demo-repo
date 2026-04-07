provider "aws" {
  region = "us-west-2" # Change this to your desired AWS region
}

# Define the security group
resource "aws_security_group" "example" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Define the EC2 instance
resource "aws_instance" "example" {
  ami           = "ami-0c55b159cbfafe1f0" # Change this to your desired AMI ID
  instance_type = "t2.micro"
  key_name      = "your-key-pair-name"   # Replace with your actual key pair name
  security_groups = [aws_security_group.example.name]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<html><body><h1>Hello, World!</h1></body></html>" > /var/www/html/index.html
              EOF
}

# Output the public IP of the EC2 instance
output "public_ip" {
  value = aws_instance.example.public_ip
}
