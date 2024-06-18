output "azs" {
  value = data.aws_availability_zones.available_zones.names
}
