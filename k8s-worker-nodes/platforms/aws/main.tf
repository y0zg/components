module "workers" {
  source = "../../modules/aws/worker-asg"

  autoscaling_group_extra_tags = "${var.asi_autoscaling_group_extra_tags}"
  base_domain                  = "${var.base_domain}"
  cluster_name                 = "${var.cluster_name}"
  node_type                    = "${var.node_type}"
  container_linux_channel      = "${var.asi_container_linux_channel}"
  container_linux_version      = "${var.asi_container_linux_version}"
  ec2_type                     = "${var.worker_instance_type}"
  spot_price                   = "${var.worker_spot_price}"
  extra_tags                   = "${var.asi_aws_extra_tags}"
  instance_count               = "${var.worker_count}"
  load_balancers               = "${var.asi_aws_worker_load_balancers}"
  root_volume_iops             = "${var.asi_aws_worker_root_volume_iops}"
  root_volume_size             = "${var.asi_aws_worker_root_volume_size}"
  root_volume_type             = "${var.asi_aws_worker_root_volume_type}"
  s3_bucket                    = "${var.aws_s3_files_worker_bucket}"
  sg_ids                       = "${var.aws_worker_sg_ids}"
  subnet_ids                   = "${var.aws_worker_subnet_ids}"
  worker_iam_role              = "${var.aws_worker_iam_role}"
  ec2_ami                      = "${var.asi_aws_ec2_ami_override}"
  ssh_key                      = "${var.keypair}"
}
