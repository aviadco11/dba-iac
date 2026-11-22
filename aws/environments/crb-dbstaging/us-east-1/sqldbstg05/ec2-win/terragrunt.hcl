# Include the root terragrunt configuration
include "root" {
  path = find_in_parent_folders("root.hcl")
}


# Set any module specific configuration and/or override values of any
variables
# defined in parent directories
inputs = {
  win_ami_id = "<<ami_id>>" #changeme #f0b3 is
Windows_Server-2022-English-Full-Base-2024.10.09 #ami-015f002db921fbf07 is
in CPQA base not core base
  ec2_key_name = "DBstg-EC2-key" #changeme
  security_groups = ["<<sg_id>>",#crb-standards
  "<<sg_id>>",#ServiceNow
  "<<sg_id>>",#CA-Certificates
  "<<sg_id>>",#CRB-SCCM
  "<<sg_id>>"] # sqlserver-sg
  instance_type = "x2iedn.2xlarge" #changeme #8cpu256GBMemory
  allowed_zones = ["a","b"]
  node_count = 2
  root_block_device = {
    volume_size = 256
    volume_type = "gp3"
  }
  ebs_volumes = {
    "/dev/sdd" = {
      volume_size = 4400
      volume_iops = 16000
      volume_throughput = 1000
    }
    "/dev/sdl" = {
      volume_size = 800
      volume_iops = 16000
      volume_throughput = 1000
      }
    "/dev/sdt" = {
      volume_size = 400
      volume_iops = 16000
      volume_throughput = 1000
    }
  }
  ebs_kms_role_permissions = {
    "arn:aws:iam::<<aws_account_id>>:role/aws-reserved/
sso.amazonaws.com/AWSReservedSSO_AdministratorAccess_d4df0bdba43003ad" "ADMIN" #changemeGiveitMyroleArn
   }
}