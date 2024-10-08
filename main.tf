resource "aws_vpc" "main" {
      cidr_block = var.cidr
      tags = {
         Name = "dev-vpc"
      }

}

module "subnets" {
  source  = "./subnets"
  for_each = var.subnets
  subnets = each.value
  vpc_id = aws_vpc.main.id
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main"
  }
}
resource "aws_route" "igw" {
  count = length(local.public_subnet_ids)
  route_table_id            = element(local.public_subnet_ids,count.index)
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw.id
}

resource "aws_eip" "lb" {
  count = length(local.public_subnet_ids)
  domain   = "vpc"
}

resource "aws_nat_gateway" "ngw" {
  count = length(local.public_subnet_ids)
  allocation_id = element(aws_eip.lb.*.id,count.index)
  subnet_id     = element(local.public_subnet_ids,count.index)
  }
resource "aws_route" "ngw" {
  count = length(local.private_route_table_ids)
  route_table_id            = element(local.private_route_table_ids,count.index)
  destination_cidr_block    = "0.0.0.0/0"
  nat_gateway_id = element(aws_nat_gateway.ngw.*.id,count.index)
}

resource "aws_vpc_peering_connection" "peering" {
    peer_vpc_id   = aws_vpc.main.id
    vpc_id        = var.default_vpc_id
  auto_accept = true
}

resource "aws_route" "peering" {
  count = length(local.private_route_table_ids)
  route_table_id            = element(local.private_route_table_ids,count.index)
  destination_cidr_block    = var.default_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peering.id
}

resource "aws_route" "default_vpc_peering" {

  route_table_id            = var.default_vpc_route_table_id
  destination_cidr_block    = var.default_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peering.id
}


output "subnet"{
  value = module.subnets
  }


