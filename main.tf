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

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main"
  }
}

output "subnet"{
  value = module.subnets
  }


