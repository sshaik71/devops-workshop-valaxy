#Create VPC
resource "aws_vpc" "dpw-vp" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "dpw-vp"
  }
}
#create a subnet
resource "aws_subnet" "dpw-public_subent_01" {
  vpc_id     = aws_vpc.dpw-vp.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = "true"
  availability_zone = "us-east-1a"
  tags = {
    Name = "Main"
  }
}

#create a internet gateway
resource "aws_internet_gateway" "dpw-gw" {
  vpc_id = aws_vpc.dpw-vp.id

  tags = {
    Name = "dpw-gw"
  }
}

#create a route table
resource "aws_route_table" "dpw-public-rt" {
  vpc_id = aws_vpc.dpw-vp.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dpw-gw.id
  }

  tags = {
    Name = "dpw-public-rt"
  }
}

resource "aws_route_table_association" "dpw-rta-public-subent-1" {
  subnet_id      = aws_subnet.dpw-public_subent_01.id
  route_table_id = aws_route_table.dpw-public-rt.id
}


#create a security group
resource "aws_security_group" "allow_hts" {
  name        = "allow_hts"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.dpw-vp.id
  
    tags = {
    Name = "allow_hts"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_https_ipv4" {
  security_group_id = aws_security_group.allow_hts.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "allow_https_ipv6" {
  security_group_id = aws_security_group.allow_hts.id
  cidr_ipv6         = "::/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ipv4" {
  security_group_id = aws_security_group.allow_hts.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_ipv4" {
  security_group_id = aws_security_group.allow_hts.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_hts.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv6" {
  security_group_id = aws_security_group.allow_hts.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}
#creating a instance
resource "aws_instance" "web-server" {
  ami           = "ami-04b70fa74e45c3917"
  instance_type = "t3.micro"
  key_name      = "Centos Shell"
  subnet_id     = aws_subnet.dpw-public_subent_01.id
  vpc_security_group_ids = [aws_security_group.allow_hts.id]
  for_each = toset(["jenkins-master", "jenkins-slave", "ansible"])

  tags = {
    Name = "${each.key}"
  }
}