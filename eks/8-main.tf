################################################################################
# Managed Node Groups
################################################################################

module "managed_node_group" {
  source = "./modules/managed-node-group"

  for_each = var.create ? var.managed_node_groups : {}

  create = try(each.value.create, true)

  cluster_name                       = aws_eks_cluster.this[0].name
  cluster_version                    = var.cluster_version
  cluster_endpoint                   = try(each.value.cluster_endpoint, aws_eks_cluster.this[0].endpoint)
  cluster_certificate_authority_data = try(each.value.cluster_certificate_authority_data, aws_eks_cluster.this[0].certificate_authority[0].data)

  node_group_name = try(each.value.name, each.key)
  subnet_ids      = try(each.value.subnet_ids, var.subnet_ids)

  # Scaling
  desired_size               = try(each.value.desired_size, 3)
  max_size                   = try(each.value.max_size, 5)
  min_size                   = try(each.value.min_size, 1)
  max_unavailable_percentage = try(each.value.max_unavailable_percentage, 33)

  # Compute
  capacity_type       = try(each.value.capacity_type, "ON_DEMAND")
  instance_types      = try(each.value.instance_types, ["t3.medium"])
  ami_type            = try(each.value.ami_type, "AL2_x86_64")
  ami_release_version = try(each.value.ami_release_version, null)

  # Labels and taints
  labels         = try(each.value.labels, {})
  cluster_labels = try(each.value.cluster_labels, var.enable_karpenter ? { "karpenter.sh/controller" = "true" } : {})
  taints         = try(each.value.taints, [])

  # Remote access
  enable_remote_access                    = try(each.value.enable_remote_access, false)
  remote_access_ec2_ssh_key               = try(each.value.remote_access_ec2_ssh_key, null)
  remote_access_source_security_group_ids = try(each.value.remote_access_source_security_group_ids, [])

  # Launch template
  block_device_mappings                        = try(each.value.block_device_mappings, [])
  metadata_options_http_tokens                 = try(each.value.metadata_options_http_tokens, "required")
  metadata_options_http_put_response_hop_limit = try(each.value.metadata_options_http_put_response_hop_limit, 2)
  enable_instance_metadata_tags                = try(each.value.enable_instance_metadata_tags, true)
  enable_monitoring                            = try(each.value.enable_monitoring, true)
  associate_public_ip_address                  = try(each.value.associate_public_ip_address, false)
  security_group_ids                           = try(each.value.security_group_ids, local.node_security_group_ids)

  # User data
  pre_bootstrap_user_data  = try(each.value.pre_bootstrap_user_data, "")
  post_bootstrap_user_data = try(each.value.post_bootstrap_user_data, "")
  bootstrap_extra_args     = try(each.value.bootstrap_extra_args, "")
  kubelet_extra_args       = try(each.value.kubelet_extra_args, "")

  launch_template_use_latest_version = try(each.value.launch_template_use_latest_version, true)

  # IAM
  create_iam_role               = try(each.value.create_iam_role, var.create_node_iam_role ? false : true)
  iam_role_arn                  = try(each.value.iam_role_arn, var.create_node_iam_role ? local.node_iam_role_arn : null)
  iam_role_permissions_boundary = try(each.value.iam_role_permissions_boundary, null)
  iam_role_policies             = try(each.value.iam_role_policies, var.node_iam_policies)
  iam_role_additional_policies  = try(each.value.iam_role_additional_policies, var.node_iam_additional_policies)

  # Tags
  tags            = merge(local.node_tags, try(each.value.tags, {}))
  node_group_tags = try(each.value.node_group_tags, {})
  instance_tags   = try(each.value.instance_tags, {})
  volume_tags     = try(each.value.volume_tags, {})
}

################################################################################
# Self-Managed Node Groups
################################################################################

module "self_managed_node_group" {
  source = "./modules/self-managed-node-group"

  for_each = var.create ? var.self_managed_node_groups : {}

  create = try(each.value.create, true)

  cluster_name                       = aws_eks_cluster.this[0].name
  cluster_version                    = var.cluster_version
  cluster_endpoint                   = try(each.value.cluster_endpoint, aws_eks_cluster.this[0].endpoint)
  cluster_certificate_authority_data = try(each.value.cluster_certificate_authority_data, aws_eks_cluster.this[0].certificate_authority[0].data)

  autoscaling_group_name = try(each.value.name, each.key)
  subnet_ids             = try(each.value.subnet_ids, var.subnet_ids)

  # Scaling
  min_size                  = try(each.value.min_size, 1)
  max_size                  = try(each.value.max_size, 5)
  desired_capacity          = try(each.value.desired_capacity, 3)
  health_check_type         = try(each.value.health_check_type, "EC2")
  health_check_grace_period = try(each.value.health_check_grace_period, 300)
  default_cooldown          = try(each.value.default_cooldown, 300)

  # ASG settings
  force_delete              = try(each.value.force_delete, false)
  termination_policies      = try(each.value.termination_policies, ["Default"])
  suspended_processes       = try(each.value.suspended_processes, [])
  placement_group           = try(each.value.placement_group, null)
  enabled_metrics           = try(each.value.enabled_metrics, [])
  metrics_granularity       = try(each.value.metrics_granularity, "1Minute")
  wait_for_capacity_timeout = try(each.value.wait_for_capacity_timeout, "10m")
  service_linked_role_arn   = try(each.value.service_linked_role_arn, null)
  max_instance_lifetime     = try(each.value.max_instance_lifetime, null)

  # Instance refresh
  instance_refresh = try(each.value.instance_refresh, null)
  warm_pool        = try(each.value.warm_pool, null)

  # Launch template
  ami_id                                       = try(each.value.ami_id, null)
  ami_architecture                             = try(each.value.ami_architecture, "x86_64")
  instance_type                                = try(each.value.instance_type, "t3.medium")
  key_name                                     = try(each.value.key_name, null)
  security_group_ids                           = try(each.value.security_group_ids, local.node_security_group_ids)
  block_device_mappings                        = try(each.value.block_device_mappings, [])
  metadata_options_http_tokens                 = try(each.value.metadata_options_http_tokens, "required")
  metadata_options_http_put_response_hop_limit = try(each.value.metadata_options_http_put_response_hop_limit, 2)
  enable_instance_metadata_tags                = try(each.value.enable_instance_metadata_tags, true)
  enable_monitoring                            = try(each.value.enable_monitoring, true)
  associate_public_ip_address                  = try(each.value.associate_public_ip_address, false)

  # User data
  pre_bootstrap_user_data  = try(each.value.pre_bootstrap_user_data, "")
  post_bootstrap_user_data = try(each.value.post_bootstrap_user_data, "")
  bootstrap_extra_args     = try(each.value.bootstrap_extra_args, "")
  kubelet_extra_args       = try(each.value.kubelet_extra_args, "")

  launch_template_use_latest_version = try(each.value.launch_template_use_latest_version, true)

  # IAM
  create_iam_role               = try(each.value.create_iam_role, var.create_node_iam_role ? false : true)
  iam_role_name                 = try(each.value.iam_role_name, var.create_node_iam_role ? try(aws_iam_role.node[0].name, null) : null)
  iam_role_permissions_boundary = try(each.value.iam_role_permissions_boundary, null)
  iam_role_policies             = try(each.value.iam_role_policies, var.node_iam_policies)
  iam_role_additional_policies  = try(each.value.iam_role_additional_policies, var.node_iam_additional_policies)

  # Advanced features
  credit_specification               = try(each.value.credit_specification, null)
  elastic_gpu_specifications         = try(each.value.elastic_gpu_specifications, null)
  capacity_reservation_specification = try(each.value.capacity_reservation_specification, null)
  enable_enclave                     = try(each.value.enable_enclave, false)
  instance_market_options            = try(each.value.instance_market_options, null)

  # Tags
  tags                   = merge(local.node_tags, try(each.value.tags, {}))
  autoscaling_group_tags = try(each.value.autoscaling_group_tags, {})
  instance_tags          = try(each.value.instance_tags, {})
  volume_tags            = try(each.value.volume_tags, {})
}

################################################################################
# Fargate Profiles
################################################################################

module "fargate_profile" {
  source = "./modules/fargate-profile"

  for_each = var.create ? var.fargate_profiles : {}

  create = try(each.value.create, true)

  cluster_name         = aws_eks_cluster.this[0].name
  fargate_profile_name = try(each.value.name, each.key)
  subnet_ids           = try(each.value.subnet_ids, var.subnet_ids)
  selectors            = each.value.selectors

  # IAM
  create_iam_role               = try(each.value.create_iam_role, true)
  pod_execution_role_arn        = try(each.value.pod_execution_role_arn, null)
  iam_role_permissions_boundary = try(each.value.iam_role_permissions_boundary, null)
  iam_role_additional_policies  = try(each.value.iam_role_additional_policies, {})

  # Timeouts
  timeouts = try(each.value.timeouts, {})

  # Tags
  tags                 = merge(local.tags, try(each.value.tags, {}))
  fargate_profile_tags = try(each.value.fargate_profile_tags, {})
}
