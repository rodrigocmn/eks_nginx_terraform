output "virtual_network_id" {
  value = "${aws_vpc.virtual_network.id}"
}

output "subnets_ids" {
  value = "${aws_subnet.subnets.*.id}"
}