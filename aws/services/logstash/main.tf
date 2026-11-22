# Create an EC2 instance for the Logstash server
resource "aws_instance" "logstash" {
  ami           = var.ami_id
  instance_type = var.instance_type
  count = var.cnt_instances

  tags = {
    Name        = var.cnt_instances == 1 ? local.app_name :
"${local.app_name}0${count.index+1}"
    Description = "Logstash server"
    environment = var.environment
  }
  subnet_id = var.subnet_id
  key_name = var.key_name
  vpc_security_group_ids = [aws_security_group.logstash_Security_group.id]
  user_data = file("${path.module}/user_data.sh")
  user_data_replace_on_change = true

  # root disk
  root_block_device {
    volume_size           = var.vol_size
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted = true
  }

}
