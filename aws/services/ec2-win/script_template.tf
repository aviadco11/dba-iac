data "template_file" "sql_user_data" {
    template = "${file("${path.module}/files/sql_user_data.tpl")}"
    vars     = {
        s3_bootstrap_location = var.s3_bootstrap_location
    }
}