output "web_sg_id" {
  value = aws_security_group.web.id
}

output "ssh_sg_id" {
  value = aws_security_group.ssh.id
}