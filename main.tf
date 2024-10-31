# Tạo VPC
resource "aws_vpc" "fresher_duylnd_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "fresher-duylnd-terraform"
  }
}

# Tạo Public và Private Subnets
resource "aws_subnet" "fresher_duylnd_public_az1" {
  vpc_id            = aws_vpc.fresher_duylnd_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "fresher-duylnd-public-az1"
  }
}

resource "aws_subnet" "fresher_duylnd_private_az1" {
  vpc_id            = aws_vpc.fresher_duylnd_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-west-2a"

  tags = {
    Name = "fresher-duylnd-private-az1"
  }
}

resource "aws_subnet" "fresher_duylnd_public_az2" {
  vpc_id            = aws_vpc.fresher_duylnd_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-west-2b"
  map_public_ip_on_launch = true

  tags = {
    Name = "fresher-duylnd-public-az2"
  }
}

resource "aws_subnet" "fresher_duylnd_private_az2" {
  vpc_id            = aws_vpc.fresher_duylnd_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-west-2b"

  tags = {
    Name = "fresher-duylnd-private-az2"
  }
}

# Tạo Internet Gateway và Route Table cho Public Subnet
resource "aws_internet_gateway" "fresher_duylnd_igw" {
  vpc_id = aws_vpc.fresher_duylnd_vpc.id

  tags = {
    Name = "fresher-duylnd-igw"
  }
}

resource "aws_route_table" "fresher_duylnd_public_rt" {
  vpc_id = aws_vpc.fresher_duylnd_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.fresher_duylnd_igw.id
  }

  tags = {
    Name = "fresher-duylnd-public-rt"
  }
}

# Route Table cho Private Subnet
resource "aws_route_table" "fresher_duylnd_private_rt" {
  vpc_id = aws_vpc.fresher_duylnd_vpc.id

  tags = {
    Name = "fresher-duylnd-private-rt"
  }
}
# Route Table Public cho các subnet public
resource "aws_route_table_association" "fresher_duylnd_public_rt_assoc_az1" {
  subnet_id      = aws_subnet.fresher_duylnd_public_az1.id
  route_table_id = aws_route_table.fresher_duylnd_public_rt.id
}

resource "aws_route_table_association" "fresher_duylnd_public_rt_assoc_az2" {
  subnet_id      = aws_subnet.fresher_duylnd_public_az2.id
  route_table_id = aws_route_table.fresher_duylnd_public_rt.id
}

# Route Table Private cho các subnet private
resource "aws_route_table_association" "fresher_duylnd_private_rt_assoc_az1" {
  subnet_id      = aws_subnet.fresher_duylnd_private_az1.id
  route_table_id = aws_route_table.fresher_duylnd_private_rt.id
}

resource "aws_route_table_association" "fresher_duylnd_private_rt_assoc_az2" {
  subnet_id      = aws_subnet.fresher_duylnd_private_az2.id
  route_table_id = aws_route_table.fresher_duylnd_private_rt.id
}

# Tạo NAT Instance cho Private Subnet
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "nat_instance" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3a.nano"
  subnet_id              = aws_subnet.fresher_duylnd_public_az1.id
  associate_public_ip_address = true
  security_groups        = [aws_security_group.fresher_duylnd_nat_sg.id]
  source_dest_check      = false
  tags = {
    Name = "fresher-duylnd-nat-instance"
  }

  user_data = <<-EOF
              #!/bin/bash
              echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
              sysctl -p
              iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
              EOF
}

# Tạo Elastic IP cho NAT Instance
resource "aws_eip" "nat_eip" {
  domain = "vpc" 
  tags = {
    Name = "fresher-duylnd-nat-eip"
  }
}

resource "aws_eip_association" "nat_eip_assoc" {
  instance_id   = aws_instance.nat_instance.id
  allocation_id = aws_eip.nat_eip.id
}

# Route cho Private Subnet thông qua NAT Instance
resource "aws_route" "private_route_to_nat" {
  route_table_id         = aws_route_table.fresher_duylnd_private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_instance.nat_instance.primary_network_interface_id
}

# Application Load Balancer (ALB) và Target Group cho ECS
resource "aws_lb" "fresher_duylnd_alb" {
  name               = "fresher-duylnd-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.fresher_duylnd_alb_sg.id]
  subnets            = [
    aws_subnet.fresher_duylnd_public_az1.id,
    aws_subnet.fresher_duylnd_public_az2.id
  ]

  tags = {
    Name = "fresher-duylnd-alb"
  }
}

resource "aws_lb_target_group" "fresher_duylnd_tg" {
  name        = "fresher-duylnd-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.fresher_duylnd_vpc.id
  target_type = "ip"

  health_check {
    path                = "/healthcheck.html"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = {
    Name = "fresher-duylnd-tg"
  }
}

# HTTP Listener cho ALB trên port 80
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.fresher_duylnd_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      protocol    = "HTTPS"
      port        = "443"
      status_code = "HTTP_301"
    }
  }
}

# HTTPS Listener (Port 443) với SSL certificate
resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.fresher_duylnd_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.certificate_arn  # ARN của SSL certificate

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.fresher_duylnd_tg.arn
  }
}

# ECS Cluster và Service
resource "aws_ecs_cluster" "sv_terra_cluster" {
  name = "sv-terra"

  tags = {
    Name = "sv-terra"
  }
}
# resource "aws_iam_role" "ecs_task_execution_role" {
#   name = "ecsTaskExecutionRole"
#   assume_role_policy = jsonencode({
#     "Version": "2012-10-17",
#     "Statement": [
#       {
#         "Effect": "Allow",
#         "Principal": {
#           "Service": "ecs-tasks.amazonaws.com"
#         },
#         "Action": "sts:AssumeRole"
#       }
#     ]
#   })
# }

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = "ecsTaskExecutionRole"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "fresher_duylnd_task" {
  family                   = "fresher-duylnd-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = "nginx"
      image     = var.nginx_image
      cpu       = 512
      memory    = 1024
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "MYSQL_SERVER", value = "0.0.0.0"},
        { name = "MYSQL_DATABASE", value = "mysql" },
        { name = "MYSQL_USER", value = "test" },
        { name = "MYSQL_PASSWORD", value = "123456" }
      ],
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/fresher-duylnd"
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
          awslogs-create-group  = "true"
        }
      }
    },
    {
      name      = "mysql"
      image     = var.mysql_image
      cpu       = 512
      memory    = 1024
      essential = true
      portMappings = [
        {
          containerPort = 3306
          hostPort      = 3306
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "MYSQL_ROOT_PASSWORD", value = "123456" },
        { name = "MYSQL_DATABASE", value = "mysql" },
        { name = "MYSQL_USER", value = "test" },
        { name = "MYSQL_PASSWORD", value = "123456" }
      ],
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/fresher-duylnd/mysql"
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
          awslogs-create-group  = "true"
        }
      }
    }
  ])
}
resource "aws_cloudwatch_log_group" "mysql_log_group" {
  name              = "/ecs/fresher-duylnd/mysql"
  retention_in_days = 1
}
resource "aws_cloudwatch_log_group" "server_log_group" {
  name              = "/ecs/fresher-duylnd"
  retention_in_days = 1
}

resource "aws_ecs_service" "fresher_duylnd_service" {
  name            = "fresher-duylnd-service"
  cluster         = aws_ecs_cluster.sv_terra_cluster.id
  task_definition = aws_ecs_task_definition.fresher_duylnd_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.fresher_duylnd_private_az1.id, aws_subnet.fresher_duylnd_private_az2.id]
    security_groups = [aws_security_group.fresher_duylnd_server_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.fresher_duylnd_tg.arn
    container_name   = "nginx"
    container_port   = 80
  }
   deployment_controller {
    type = "ECS" # Chỉ áp dụng được khi type là ECS
  }
    deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  tags = {
    Name = "fresher-duylnd-service"
  }

  depends_on = [aws_lb_listener.http_listener]
}
