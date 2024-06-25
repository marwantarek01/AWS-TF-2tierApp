
output "primary_endpoint" {
  value = aws_db_instance.db.endpoint
}

output "read_replica_endpoint" {
  value = aws_db_instance.read_replica.endpoint
}  