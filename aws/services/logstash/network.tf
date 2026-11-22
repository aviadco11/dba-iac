data "aws_subnets" "selected" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
  filter {
    name   = "state"
    values = ["available"]
  }
  filter {
    name   = "availability-zone"
    values = ["us-east-1a"]
  }
}

data "aws_subnet" "info_selected_subnet_ids" {
  count = length(data.aws_subnets.selected.ids)
  id    = data.aws_subnets.selected.ids[count.index]
}