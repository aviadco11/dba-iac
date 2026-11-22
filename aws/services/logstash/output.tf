output "logstash" {
  value = {
    key_name = aws_instance.logstash[*].key_name
    ipaddress = aws_instance.logstash[*].private_ip
    ebs_block_device = aws_instance.logstash[*].ebs_block_device
    name = aws_instance.logstash[*].tags.Name
    ssh-connect = join("", ["ssh -i ~/.ssh/id_rsa", " ec2-user@",
aws_instance.logstash[0].private_ip])
    subnet_info_selected_id = data.aws_subnet.info_selected_subnet_ids[0].id
    }
}
