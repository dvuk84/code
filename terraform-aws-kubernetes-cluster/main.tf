# Terraform AWS provider
provider "aws" {
  region                  = var.region
  shared_credentials_file = var.credentials
}

# Create VPC
resource "aws_vpc" "kubernetes" {
  cidr_block              = var.cidr
}

# Create Internet Gateway
resource "aws_internet_gateway" "kubernetes" {
  vpc_id                  = "${aws_vpc.kubernetes.id}"
}

# Create Route
resource "aws_route" "internet_access" {
  route_table_id          = "${aws_vpc.kubernetes.main_route_table_id}"
  destination_cidr_block  = "0.0.0.0/0"
  gateway_id              = "${aws_internet_gateway.kubernetes.id}"
}

# Create Subnet
resource "aws_subnet" "kubernetes" {
  vpc_id                  = "${aws_vpc.kubernetes.id}"
  cidr_block              = var.subnet
  map_public_ip_on_launch = true
}

# Create Security Group
resource "aws_security_group" "kubernetes" {
  name                    = "kubernetes"
  vpc_id                  = "${aws_vpc.kubernetes.id}"

  # Inbound traffic 
  ingress {
    from_port             = 22
    to_port               = 22
    protocol              = "tcp"
    cidr_blocks           = ["0.0.0.0/0"]
  }

  # Outbound traffic
  egress {
    from_port             = 0
    to_port               = 0
    protocol              = "-1"
    cidr_blocks           = ["0.0.0.0/0"]
  }
}

# Create SSH key pair
resource "aws_key_pair" "kubernetes" {
  key_name                = var.keyname
  public_key              = file(var.keypath)
}

# Create instances
resource "aws_instance" "kubernetes" {
  count                   = 3
  instance_type           = var.instance
  ami                     = var.ami
  vpc_security_group_ids  = [aws_security_group.kubernetes.id]
  subnet_id               = "${aws_subnet.kubernetes.id}"
  key_name                = "${aws_key_pair.kubernetes.id}"
}
