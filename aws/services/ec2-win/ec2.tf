locals {
  nodes = merge([
    for node in range(var.node_count) :
{"${local.server_group_name}-${format("%02s",node+1)}" = {
      volumes = merge([
      for volume_name, volume in var.ebs_volumes :{"${volume_name}" = {
        volume_size         = volume.volume_size
        volume_type         = volume.volume_type
        volume_iops         = volume.volume_iops
        volume_throughput   = volume.volume_type == "gp3" ?
volume.volume_throughput : null #modfied to address default throughput for
io2 3/4/2025
      }}
    ]...)
    "subnet_id"           data.aws_subnet.subnet["${local.subnet_list[node %
length(local.subnet_list)]}"].id
    "availability_zone"   data.aws_subnet.subnet["${local.subnet_list[node %
length(local.subnet_list)]}"].availability_zone
    "server_name"         "${local.server_group_name}-${format("%02s",node+1)}"
    "node_count"          = node
    }}
  ]...)
  OU_type = var.env_OU_overide == "no_overide_set" ? var.env_type :
var.env_OU_overide ## check name, if updated value for check update here as
well. This checks if that (default) value exists, if it does exist use
var.env_type instead.
}

resource "aws_ebs_volume" "this" {
  for_each = merge([for node,meta in local.nodes : merge([for
volume,volmeta in meta.volumes: {"${meta.server_name}-${volume}" merge(volmeta,{"availability_zone" = meta.availability_zone})}]...)]...)
  size              = each.value.volume_size
  type              = each.value.volume_type
  iops              = each.value.volume_iops
  throughput        = each.value.volume_throughput
  availability_zone = each.value.availability_zone
  encrypted         = true
  kms_key_id        = module.ebs_key.key.arn

  tags = {
    Name = each.key
  }
}

resource "aws_network_interface" "win-server" {
    for_each        = local.nodes
    subnet_id       = each.value.subnet_id
    security_groups = var.security_groups

    tags = {
            Name = "${each.key}_network_interface"
    }
}

resource "aws_instance" "windows_server" {
    for_each            = local.nodes
    ami                 = var.win_ami_id
    instance_type       = var.instance_type
    availability_zone   = each.value.availability_zone
    ebs_optimized       = true
    key_name            = var.ec2_key_name
    user_data           = data.template_file.sql_user_data.rendered

    iam_instance_profile = aws_iam_instance_profile.instance_profile.name

    metadata_options {
        http_tokens = "required"
        http_put_response_hop_limit = "1"
        http_endpoint = "enabled"
    }

    root_block_device {
        volume_size = var.root_block_device.volume_size
        volume_type = var.root_block_device.volume_type
        encrypted   = true
        kms_key_id  = module.ebs_key.key.arn
    }

    tags  = {
        Name        =  each.key
        InitialOU   "OU=Servers,OU�tabases,OU=${local.OU_type},DC=<<domain>>"
    }

    # network_interface {
    #  network_interface_id  = aws_network_interface.win-server[each.key].id
    #  device_index          = 0
    # }

    primary_network_interface {
      network_interface_id = aws_network_interface.win-server[each.key].id
    }

    lifecycle {
        ignore_changes =[
          ami,
          tags["Clustername"],
          tags["Host_Name_Status"],
          tags["LocalFWrules"],
          tags["SQLServerInstall"]
        ]
    }
}

resource "aws_volume_attachment" "ebs_att" {
  for_each      = merge([for node,meta in local.nodes : merge([for
volume,volmeta in meta.volumes: {"${meta.server_name}-${volume}" merge({"volume"=volume},{"server_name"=meta.server_name})}]...)]...)
                  #merge([for node,ebs_volumes in local.nodes: merge([for
volume in ebs_volumes : {"${node}-${volume.volume_name}" = volume}]...)]...)
  device_name   = each.value.volume
  volume_id     = aws_ebs_volume.this[each.key].id
  instance_id   = aws_instance.windows_server[each.value.server_name].id
}
