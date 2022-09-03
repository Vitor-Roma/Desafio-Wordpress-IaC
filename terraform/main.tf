provider "aws" {
  profile = var.profile
  region  = var.region
}

resource "aws_subnet" "public_subnet_a" {
  vpc_id            = var.vpn_id_security_group
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
}
#
resource "aws_subnet" "public_subnet_b" {
  vpc_id            = var.vpn_id_security_group
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
}

resource "aws_subnet" "private_subnet_a" {
  vpc_id            = var.vpn_id_security_group
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "private_subnet_b" {
  vpc_id            = var.vpn_id_security_group
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"
}

resource "aws_security_group" "allow_ssh" {
  name        = var.name_security_group
  description = "Allow ssh inbound traffic"
  vpc_id      = var.vpn_id_security_group

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "MYSQL"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "memchace-cluster"
    from_port   = 11211
    to_port     = 11211
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    description      = "MYSQL"
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_SSH"
  }
}

resource "aws_instance" "minha_maquina" {
  ami                         = var.ami_aws_instance
  instance_type               = var.type_aws_instance
  subnet_id                   = aws_subnet.public_subnet_a.id
  key_name                    = var.key_aws_instance
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.allow_ssh.id]
  user_data                   = file("userdata.tpl")
  tags                        = {
    Name = "wordpress"
  }
}

resource "aws_db_instance" "meu_database" {
  instance_class        = "db.t2.micro"
  allocated_storage     = 10
  max_allocated_storage = 20
  engine                = "mysql"
  engine_version        = "5.7"
  identifier            = "meu-db-terraform"
  name                  = "terraformdb"
  username              = "vitor"
  password              = "vitor123"
  skip_final_snapshot   = true
  publicly_accessible   = true
  db_subnet_group_name  = aws_db_subnet_group.subnet_db.id
}

resource "aws_db_subnet_group" "subnet_db" {
  subnet_ids = [aws_subnet.public_subnet_a.id, aws_subnet.public_subnet_b.id]
}

resource "aws_elasticache_cluster" "example" {
  cluster_id           = "terraform-cluster"
  engine               = "memcached"
  node_type            = "cache.t2.micro"
  num_cache_nodes      = 2
  parameter_group_name = "default.memcached1.6"
  port                 = 11211
  subnet_group_name    = aws_elasticache_subnet_group.subnet_cluster.name
  security_group_ids   = [aws_security_group.allow_ssh.id]
}

resource "aws_elasticache_subnet_group" "subnet_cluster" {
  name       = "subnet-cluster"
  subnet_ids = [aws_subnet.public_subnet_a.id, aws_subnet.public_subnet_b.id]
}

resource "aws_lb" "terraform-lb" {
  name               = "terraform-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_ssh.id]
  subnets            = [aws_subnet.public_subnet_a.id, aws_subnet.public_subnet_b.id]


  enable_deletion_protection = false

  tags = {
    Environment = "test"
  }
}
resource "aws_lb_listener" "terraform-lb-listeners" {
  load_balancer_arn = aws_lb.terraform-lb.arn
  protocol          = "HTTP"
  port              = 80


  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.terraform-tg.arn
  }
}

resource "aws_lb_target_group" "terraform-tg" {
  name        = "terraform-target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = var.vpn_id_security_group
      health_check {
        protocol = "HTTP"
        path = "/"
      }
}

resource "aws_lb_target_group_attachment" "target-group-instance" {
  target_group_arn = aws_lb_target_group.terraform-tg.arn
  target_id        = aws_instance.minha_maquina.id
  port             = 80
}

resource "aws_autoscaling_group" "terraform-autoscale" {
  min_size             = 1
  desired_capacity     = 2
  max_size             = 2
  launch_configuration = aws_launch_configuration.autoscale-config.id
  target_group_arns = [aws_lb_target_group.terraform-tg.id]
  vpc_zone_identifier  = [aws_subnet.public_subnet_b.id, aws_subnet.public_subnet_a.id]
  health_check_type = "EC2"
  name = "wordpress"

  tag {
    key                 = "name"
    propagate_at_launch = false
    value               = "terraform-autoscale"
  }
}


resource "aws_launch_configuration" "autoscale-config" {
  image_id        = var.auto_scale_ami
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.allow_ssh.id]
  key_name        = var.key_aws_instance

}

