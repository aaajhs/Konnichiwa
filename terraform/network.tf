/* ----------------------------------- VPC ---------------------------------- */

resource "aws_vpc" "main" {
  cidr_block = local.vpc_cidr
}

/* --------------------------------- Subnets -------------------------------- */

resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.subnet_cidr.public_a
  availability_zone = "${local.region}a"
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_subnet" "public_c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.subnet_cidr.public_c
  availability_zone = "${local.region}c"
}

resource "aws_route_table_association" "public_c" {
  subnet_id      = aws_subnet.public_c.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

/* ---------------------------- Internet Gateway ---------------------------- */

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}
