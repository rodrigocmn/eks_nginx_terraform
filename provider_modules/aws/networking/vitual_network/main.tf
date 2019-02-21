# Sample VPC Creation
#
# This is a sample code to quickly create a VPC for tests

# Using these data sources allows the configuration to be
# generic for any region.
data "aws_region" "current" {}

data "aws_availability_zones" "available" {}

# Create VPC
resource "aws_vpc" "virtual_network" {
  cidr_block = "10.0.0.0/16"

  tags = "${var.vpc_tags}"
}

# Create Subnets
resource "aws_subnet" "subnets" {
  count = 2

  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  cidr_block        = "10.0.${count.index}.0/24"
  vpc_id            = "${aws_vpc.virtual_network.id}"

  tags = "${var.subnet_tags}"
}

# Create Internet Gateway
resource "aws_internet_gateway" "internet_gatway" {
  vpc_id = "${aws_vpc.virtual_network.id}"

  tags = "${var.igw_tags}"
}

# Create Route Table
resource "aws_route_table" "route_table" {
  vpc_id = "${aws_vpc.virtual_network.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.internet_gatway.id}"
  }
}

resource "aws_route_table_association" "route_table_association" {
  count = 2

  subnet_id      = "${aws_subnet.subnets.*.id[count.index]}"
  route_table_id = "${aws_route_table.route_table.id}"
}