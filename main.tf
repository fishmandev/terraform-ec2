## Create vpc
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/24"
}

## Create Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id
}

## Create Custom Route Table
resource "aws_route_table" "route-table" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

## Create a Subnet 
resource "aws_subnet" "subnet" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "us-east-1a"
}

## Associate subnet with Route Table
resource "aws_route_table_association" "s-rtb" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.route-table.id
}

## Create Security Group to allow port 22
resource "aws_security_group" "security_group" {
  name        = "allow_ssh_traffic"
  description = "Allow SSH traffic"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "SSH"
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

## Create a network interface with an ip in the subnet that was created
resource "aws_network_interface" "nic" {
  subnet_id       = aws_subnet.subnet.id
  private_ips     = ["10.0.0.10"]
  security_groups = [aws_security_group.security_group.id]
}

## Assign an elastic IP to the network interface
resource "aws_eip" "eip" {
  vpc                       = true
  network_interface         = aws_network_interface.nic.id
  associate_with_private_ip = "10.0.0.10"
  depends_on                = [aws_internet_gateway.gw, aws_instance.ec2-instance]
}

## Create Amazon Linux 2023 server
resource "aws_instance" "ec2-instance" {
  ami               = "ami-02f3f602d23f1659d"
  instance_type     = "t2.micro"
  availability_zone = "us-east-1a"
  key_name          = "ec2"

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.nic.id
  }
}