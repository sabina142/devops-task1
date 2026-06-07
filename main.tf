terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

resource "aws_vpc" "placemux_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "placemux-vpc"
    Project     = "PlaceMux"
    Environment = "dev"
    Owner       = "Sabina"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.placemux_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name        = "public-subnet"
    Project     = "PlaceMux"
    Environment = "dev"
    Owner       = "Sabina"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.placemux_vpc.id

  tags = {
    Name        = "placemux-igw"
    Project     = "PlaceMux"
    Environment = "dev"
    Owner       = "Sabina"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.placemux_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name        = "public-route-table"
    Project     = "PlaceMux"
    Environment = "dev"
    Owner       = "Sabina"
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.placemux_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name        = "private-subnet"
    Project     = "PlaceMux"
    Environment = "dev"
    Owner       = "Sabina"
  }
}

resource "aws_security_group" "web_sg" {
  name        = "web-security-group"
  description = "Allow SSH and HTTP"
  vpc_id      = aws_vpc.placemux_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5432
    to_port     = 5432
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
    Name        = "web-security-group"
    Project     = "PlaceMux"
    Environment = "dev"
    Owner       = "Sabina"
  }
}

resource "aws_secretsmanager_secret" "app_secret" {
  name = "placemux-app-secret"

  tags = {
    Project     = "PlaceMux"
    Environment = "dev"
    Owner       = "Sabina"
  }
}

resource "aws_db_subnet_group" "postgres_subnet_group" {
  name = "placemux-postgres-subnet-group"

  subnet_ids = [
    aws_subnet.public_subnet.id,
    aws_subnet.private_subnet.id
  ]

  tags = {
    Name        = "placemux-postgres-subnet-group"
    Project     = "PlaceMux"
    Environment = "dev"
    Owner       = "Sabina"
  }
}

resource "aws_db_instance" "dev_postgres" {
  identifier = "placemux-dev-postgres"

  engine         = "postgres"
  engine_version = "15"

  instance_class = "db.t3.micro"

  allocated_storage = 20

  db_name  = "placemux"
  username = "postgres"
  password = "Placemux123!"

  publicly_accessible = true

  skip_final_snapshot = true

  db_subnet_group_name = aws_db_subnet_group.postgres_subnet_group.name

  vpc_security_group_ids = [
    aws_security_group.web_sg.id
  ]

  tags = {
    Name        = "placemux-dev-postgres"
    Project     = "PlaceMux"
    Environment = "dev"
    Owner       = "Sabina"
  }
}