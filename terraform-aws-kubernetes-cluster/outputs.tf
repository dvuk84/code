output "server_id" {
  value = "${join(", ", aws_instance.kubernetes.*.id)}"
}

output "server_ip" {
  value = "${join(", ", aws_instance.kubernetes.*.public_ip)}"
}
