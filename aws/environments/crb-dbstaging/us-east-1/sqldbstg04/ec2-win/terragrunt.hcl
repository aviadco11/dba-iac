# Include the root terragrunt configuration
include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Set any module specific configuration and/or override values of any
variables
# defined in parent directories
inputs = {
  win_ami_id = "<<ami_id>>"
  ec2_key_name = "DBstg-EC2-key"
  allowed_zones = ["b"]
  security_groups ["<<sg_id>>","<<sg_id>>","<<sg_id>>","<<sg_id>>","<<sg_id>>"]
  instance_type = "r5a.xlarge"

  node_count = 1
  root_block_device = {
    volume_size = 256
    volume_type = "gp3"
  }
  ebs_volumes = {
    "xvdt" = {
      volume_size = 200
    }
    "/dev/sdl" = {
      volume_size = 500
      }
    "/dev/sdt" = {
      volume_size = 400
    }
  }
  ebs_kms_role_permissions = {
    "arn:aws:iam::<<aws_account_id>>:role/aws-reserved/
sso.amazonaws.com/AWSReservedSSO_AdministratorAccess_d4df0bdba43003ad" "ADMIN"
  }
}