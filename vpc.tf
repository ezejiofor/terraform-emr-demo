data "aws_availability_zones" "azs" {
    state = "available"
}

locals {
  az_names       = data.aws_availability_zones.azs.names
  public_sub_ids = aws_subnet.my_public.*.id
  
  #master_ports = [4040, 22, 8888, 20888]
  master_ports = [22]
  slave_ports = [22]
}


resource "aws_vpc" "myvpc" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Environment = var.environment
    Team        = "Network"
    Name        = "myVPC"
  }
}
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.myvpc.id
  tags = {
    Environment = var.environment
    Team        = "Network"
    Name        = "myGW"
  }
}

resource "aws_eip" "myeip" {
  vpc      = true
}

resource "aws_subnet" "my_public" {

  count                   = length(slice(local.az_names, 0, 2))
  vpc_id                  = aws_vpc.myvpc.id
  availability_zone       = local.az_names[count.index]
  cidr_block              = cidrsubnet(var.cidr_block, 4, count.index)
  map_public_ip_on_launch = true
  
  tags = {
    Environment = var.environment
    Team        = "Network"
    Name        = "myPUBSUBNET"
  }
}

resource "aws_route_table" "my_publicrt" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }

  
  tags = {
    Environment = var.environment
    Team        = "Network"
    Name        = "my-public-subnet"
  }
}


resource "aws_route_table_association" "my_pub_subnet_association" {
  count          = length(slice(local.az_names, 0, 2))
  subnet_id      = aws_subnet.my_public.*.id[count.index]
  route_table_id = aws_route_table.my_publicrt.id
}



#===========security-group=========================

resource "aws_security_group" "emr_master_sg" {
  name                   = "${var.name} - EMR-master"
  description            = "EMR master SG"
  vpc_id                 = aws_vpc.myvpc.id
  revoke_rules_on_delete = true

  dynamic "ingress" {
    for_each = local.master_ports
    content {
      description = "description ${ingress.key}"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "EMR_master_sg"
  }
}

resource "aws_security_group" "emr_slave_sg" {
  name                   = "${var.name} - EMR-slave"
  description            = "EMR slave SG"
  vpc_id                 = aws_vpc.myvpc.id
  revoke_rules_on_delete = true

  dynamic "ingress" {
    for_each = local.slave_ports
    content {
      description = "description ${ingress.key}"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "EMR_slave_sg"
  }
}


