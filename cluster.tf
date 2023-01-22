resource "aws_emr_cluster" "cluster" {
  name = var.name
  release_label = var.release_label
  applications = var.applications
  #public_ip = aws_eip.myeip

  additional_info = <<EOF
{
  "instanceAwsClientConfiguration": {
    "proxyPort": 8099,
    "proxyHost": "proxy.cloudgeeks.ca.com"
  }
}
EOF

  termination_protection = false
  keep_job_flow_alive_when_no_steps = true

  ec2_attributes {
    subnet_id = aws_subnet.my_public[0].id
    key_name = var.key_name
    emr_managed_master_security_group = aws_security_group.emr_master_sg.id
    emr_managed_slave_security_group = aws_security_group.emr_slave_sg.id
    instance_profile = aws_iam_instance_profile.emr_ec2_instance_profile.arn
  }

  ebs_root_volume_size = "20"

  master_instance_group {
    name = "EMR master"
    instance_type = var.master_instance
    instance_count = "1"

    ebs_config {
      size = var.master_ebs_vol
      type = "gp2"
      volumes_per_instance = 1
    }
  }

  core_instance_group {
    name = "EMR slave"
    instance_type = var.core_instance
    instance_count = "1"

    ebs_config {
      size = var.core_ebs_vol
      type = "gp2"
      volumes_per_instance = 1
    }
  }

  tags = {
    Name = "${var.name}"
  }

  service_role = aws_iam_role.emr_role.arn
  autoscaling_role = aws_iam_role.emr_autoscaling_role.arn


}
