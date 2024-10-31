
resource "aws_security_group" "fresher_duylnd_nat_sg" {
  vpc_id = aws_vpc.fresher_duylnd_vpc.id

  # Inbound Rule: SSH từ một địa chỉ IP cụ thể
  ingress {
    description = "Allow SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["14.176.232.122/32"]
  }

  # Inbound Rule: Cho phép tất cả lưu lượng từ VPC
  ingress {
    description = "Allow all traffic within VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # Outbound Rule: Cho phép tất cả lưu lượng ra ngoài
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "fresher-duylnd-nat"
  }
}

# Security Group cho Application Load Balancer (ALB)
resource "aws_security_group" "fresher_duylnd_alb_sg" {
  vpc_id = aws_vpc.fresher_duylnd_vpc.id

  # Inbound Rule: HTTPS từ một địa chỉ IP cụ thể
  ingress {
    description = "Allow HTTPS from specific IP"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["14.176.232.122/32"]
  }

  # Inbound Rule: HTTP từ một địa chỉ IP cụ thể
  ingress {
    description = "Allow HTTP from specific IP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["14.176.232.122/32"]
  }

  # Outbound Rule: Cho phép tất cả lưu lượng ra ngoài
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "fresher-duylnd-alb"
  }
}

# Security Group cho Server Instances
resource "aws_security_group" "fresher_duylnd_server_sg" {
  vpc_id = aws_vpc.fresher_duylnd_vpc.id

  # Inbound Rule: Cho phép tất cả lưu lượng từ VPC
  ingress {
    description = "Allow all traffic within VPC CIDR"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/24"]
  }

  # Inbound Rule: Cho phép HTTP và HTTPS từ ALB Security Group
  ingress {
    description     = "Allow HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.fresher_duylnd_alb_sg.id]
  }

  ingress {
    description     = "Allow HTTPS from ALB"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.fresher_duylnd_alb_sg.id]
  }

  # Outbound Rule: Cho phép tất cả lưu lượng ra ngoài
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "fresher-duylnd-server"
  }
}