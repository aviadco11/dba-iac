# Include the root terragrunt configuration
include "root" {
  path = find_in_parent_folders("root.hcl")
}
# this is a POC instance to test dag replication from sql 2022 to 2025.  we
want to see if the dbs are readable
# Set any module specific configuration and/or override values of any
variables
# defined in parent directories
inputs = {
  win_ami_id = "<<ami_id>>" #windows server 2019 base to match the Arix
prod Installing sql 2017 seperately
  ec2_key_name = "DBstg-EC2-key" #changeme
  security_groups = ["<<sg_id>>",#crb-standards
  "<<sg_id>>",#ServiceNow
  "<<sg_id>>",#CA-Certificates
  "<<sg_id>>",#CRB-SCCM
  "<<sg_id>>"] # sqlserver-sg
  instance_type = "x2iedn.8xlarge" #changeme
  allowed_zones = ["a","b"]
  node_count = 1
  root_block_device = {
    volume_size = 256
    volume_type = "gp3"
  }
  ebs_volumes = {
    "/dev/sdd" = {    #cosdata
      volume_size = 20000
      volume_iops = 16000
      volume_throughput = 1000
    }
    "/dev/sdl" = {    #coslog
      volume_size = 3000
      volume_iops = 16000
      volume_throughput = 1000
      }
    "/dev/sdt" = {
      volume_size = 1000
      volume_iops = 16000
      volume_throughput = 1000
    }
    "/dev/sdg" = {    #localbackup
      volume_size = 8000
      volume_iops = 16000
      volume_throughput = 1000
    }
    "/dev/sdh" = {    #p2p data
      volume_size = 2000
      volume_iops = 16000
      volume_throughput = 1000
    }
    "/dev/sdi" = {    #p2plog
      volume_size = 500
      volume_iops = 16000
      volume_throughput = 1000
    }
  }
  ebs_kms_role_permissions = {
    "arn:aws:iam::<<aws_account_id>>:role/aws-reserved/
sso.amazonaws.com/AWSReservedSSO_AdministratorAccess_d4df0bdba43003ad" "ADMIN" #changemeGiveitMyroleArn
   }
}