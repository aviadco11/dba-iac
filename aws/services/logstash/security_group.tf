resource "aws_security_group" "logstash_Security_group" {
    vpc_id = var.vpc_id
    name = "ec2 logstash security group"
    description = "allow access on port 8080,443,8443 and 22"

    # allow http access on port 9600
    ingress {
        description = "http access"
        from_port = 9600
        to_port = 9600
        protocol = "tcp"
        cidr_blocks = ["<<ip_address>>", "<<ip_address>>"]
    }

    # allow ssh access on port 22 from cvm and lvm
    ingress {
        description = "ssh access"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["<<ip_address>>", "<<ip_address>>"]
    }

    egress {
        description = "traffic out"
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "logstash_sg"
    }
}