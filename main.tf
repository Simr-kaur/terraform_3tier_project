resource "aws_vpc" "demovpc" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"

  tags = {
    Name = "Demo-VPC"
  }
}

resource "aws_subnet" "public-subnet-1" {
  vpc_id                  = aws_vpc.demovpc.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = "ap-northeast-1a"

  tags = {
    Name = "Web-Subnet- 1"
  }
}


resource "aws_subnet" "public-subnet-2" {
  vpc_id                  = aws_vpc.demovpc.id
  cidr_block              = var.subnet1_cidr
  map_public_ip_on_launch = true
  availability_zone       = "ap-northeast-1c"

  tags = {
    Name = "Web-Subnet-2"
  }
}


resource "aws_subnet" "application-subnet-1" {
  vpc_id                  = aws_vpc.demovpc.id
  cidr_block              = var.subnet2_cidr
  map_public_ip_on_launch = false
  availability_zone       = "ap-northeast-1a"

  tags = {
    Name = "Application-Subnet-1"
  }
}


resource "aws_subnet" "application-subnet-2" {
  vpc_id                  = aws_vpc.demovpc.id
  cidr_block              = var.subnet3_cidr
  map_public_ip_on_launch = false
  availability_zone       = "ap-northeast-1c"

  tags = {
    Name = "Application-Subnet-2"
  }
}


resource "aws_subnet" "database-subnet-1" {
  vpc_id            = aws_vpc.demovpc.id
  cidr_block        = var.subnet4_cidr
  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "Database Subnet 1"
  }
}


resource "aws_subnet" "database-subnet-2" {
  vpc_id            = aws_vpc.demovpc.id
  cidr_block        = var.subnet5_cidr
  availability_zone = "ap-northeast-1c"

  tags = {
    Name = "Database-Subnet-2"
  }
}

resource "aws_internet_gateway" "demogateway" {
  vpc_id = aws_vpc.demovpc.id
}

resource "aws_route_table" "route" {
  vpc_id = aws_vpc.demovpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demogateway.id
  }

  tags = {
    Name = "Route to internet"
  }
}

resource "aws_route_table_association" "rt1" {
  subnet_id      = aws_subnet.public-subnet-1.id
  route_table_id = aws_route_table.route.id
}


resource "aws_route_table_association" "rt2" {
  subnet_id      = aws_subnet.public-subnet-2.id
  route_table_id = aws_route_table.route.id
}


resource "aws_security_group" "demosg" {
  vpc_id = aws_vpc.demovpc.id


  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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

  tags = {
    Name = "Web-SG"
  }
}
resource "aws_security_group" "database-sg" {
  name        = "Database SG"
  description = "Allow inbound traffic from application layer"
  vpc_id      = aws_vpc.demovpc.id

  ingress {
    description     = "Allow traffic from application layer"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.demosg.id]
  }

  egress {
    from_port   = 32768
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Database-SG"
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = "key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC9Snot6rldLjElKFUctU1eM6NshLh6GTI2B6dKd9rtWYhY/zVB/KQW7qVSvM1i6TxBZA+mWUsPatDWkK+QJFYGFONlkLrM0c0nZ2p9mysqMAzDJlHgwravts9zYGYumOjZkF8AdzgADxUO9tKVIyI1hCN+YQ2UZdmeuQUrLvN+DPGIyUyKMcj9BMtRFXK3E0tRq2y8mLRfcwZhqKbulfN7s6EDwbq7Te0PPS4d0ept+B2RyJFvY5u+z1b45H4lZ0I6HxIMIXqQragBE99oDgf7nyp0XqteWwovPi8jQy2ar7tnyn3WgABWbwERYv1+43Bd6LC0hirHX+iyOQRKjoGj root@ip-172-31-2-51.ap-northeast-1.compute.internal"
}

resource "aws_instance" "demoinstance" {
  ami                         = "ami-0ffac3e16de16665e"
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.deployer.id
  vpc_security_group_ids      = ["${aws_security_group.demosg.id}"]
  subnet_id                   = aws_subnet.public-subnet-1.id
  associate_public_ip_address = true
  user_data                   = file("data.sh")

  tags = {
    Name = "Terraform-Project-Public-Instance-1"
  }
}


resource "aws_instance" "demoinstance1" {
  ami                         = "ami-0ffac3e16de16665e"
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.deployer.id
  vpc_security_group_ids      = ["${aws_security_group.demosg.id}"]
  subnet_id                   = aws_subnet.public-subnet-2.id
  associate_public_ip_address = true
  user_data                   = file("data.sh")


  tags = {
    Name = "Terraform-Project-Public-Instance-2"
  }
}
resource "aws_db_subnet_group" "default" {
  name       = "my"
  subnet_ids = ["${aws_subnet.database-subnet-1.id}", "${aws_subnet.database-subnet-2.id}", "${aws_subnet.application-subnet-1.id}", "${aws_subnet.application-subnet-2.id}"]

  tags = {
    Name = "My-DB-subnet-group"
  }
}

resource "aws_db_instance" "default" {
  identifier             = "default"
  allocated_storage      = 20
  db_subnet_group_name   = aws_db_subnet_group.default.id
  engine                 = "mysql"
  engine_version         = "8.0.28"
  instance_class         = "db.t2.micro"
  multi_az               = true
  db_name                = "mydb"
  username               = "username"
  password               = "password"
  skip_final_snapshot    = true
  vpc_security_group_ids = ["${aws_security_group.database-sg.id}"]
}


resource "aws_lb" "external-alb" {
  name               = "External-LB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.demosg.id]
  subnets            = ["${aws_subnet.public-subnet-1.id}", "${aws_subnet.public-subnet-2.id}"]
}

resource "aws_lb_target_group" "target-elb" {
  name     = "ALB-TG-1"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.demovpc.id
}

resource "aws_lb_target_group_attachment" "attachment-1" {
  target_group_arn = aws_lb_target_group.target-elb.arn
  target_id        = aws_instance.demoinstance.id
  port             = 80

  depends_on = [
    aws_instance.demoinstance,
  ]
}

resource "aws_lb_target_group_attachment" "attachment-2" {
  target_group_arn = aws_lb_target_group.target-elb.arn
  target_id        = aws_instance.demoinstance1.id
  port             = 80

  depends_on = [
    aws_instance.demoinstance1,
  ]
}

resource "aws_lb_listener" "external-elb-listener" {
  load_balancer_arn = aws_lb.external-alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target-elb.arn
  }
}
