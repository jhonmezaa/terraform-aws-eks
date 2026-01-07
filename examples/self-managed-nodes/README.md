# Self-Managed Nodes Example

This example demonstrates how to deploy an EKS cluster with self-managed Auto Scaling Groups instead of EKS managed node groups. Self-managed nodes provide greater control over instance configuration, autoscaling policies, and lifecycle management.

## Features

- Self-managed Auto Scaling Groups with custom configurations
- Multiple node groups for different workload types:
  - General purpose (t3.large)
  - Compute-optimized with Spot instances (c6i.2xlarge)
  - Memory-optimized with warm pools (r6i.xlarge)
- Instance refresh for zero-downtime updates
- CloudWatch metrics for ASG monitoring
- Custom user data and kubelet arguments
- IRSA (IAM Roles for Service Accounts) enabled

## When to Use Self-Managed Nodes

Choose self-managed nodes when you need:

1. **Advanced ASG Features**:
   - Warm pools for faster scaling
   - Custom termination policies
   - Mixed instance types in single ASG
   - Lifecycle hooks

2. **Custom AMIs**:
   - Security-hardened images
   - Pre-baked applications
   - Custom kernel parameters

3. **Fine-Grained Control**:
   - Detailed monitoring and metrics
   - Custom bootstrap scripts
   - Instance refresh strategies

4. **Cost Optimization**:
   - Spot instance configurations
   - Reserved Instance utilization
   - Custom scaling policies

## Architecture

### Node Groups

1. **General** (ON_DEMAND):
   - Instance: t3.large
   - Capacity: 2-6 instances (desired: 3)
   - Features: Instance refresh, CloudWatch metrics
   - Use case: Standard workloads

2. **Compute** (SPOT):
   - Instance: c6i.2xlarge
   - Capacity: 1-10 instances (desired: 2)
   - Spot max price: $0.15/hour
   - Use case: CPU-intensive batch jobs

3. **Memory** (ON_DEMAND with warm pool):
   - Instance: r6i.xlarge
   - Capacity: 0-5 instances (desired: 2)
   - Warm pool: 1-2 stopped instances
   - Use case: Data processing, caching

## Prerequisites

- AWS account with appropriate permissions
- VPC with private subnets in at least 2 AZs
- EC2 SSH key pair (optional, for debugging)
- Terraform >= 1.0
- kubectl and AWS CLI installed

## Usage

1. Copy the example tfvars file:
```bash
cp terraform.tfvars.example terraform.tfvars
```

2. Edit `terraform.tfvars`:
```hcl
vpc_id = "vpc-xxx"
subnet_ids = ["subnet-xxx", "subnet-yyy", "subnet-zzz"]
ssh_key_name = "my-keypair"  # Optional
```

3. Deploy:
```bash
terraform init
terraform plan
terraform apply
```

4. Configure kubectl:
```bash
aws eks update-kubeconfig --name $(terraform output -raw cluster_name) --region us-east-1
```

5. Verify nodes:
```bash
kubectl get nodes -L workload,instance-type
```

## Key Features Explained

### Instance Refresh

Automatically replaces instances when launch template changes:

```hcl
instance_refresh = {
  strategy = "Rolling"
  preferences = {
    min_healthy_percentage = 66  # Keep 66% healthy during update
    instance_warmup        = 300 # Wait 5 minutes before next instance
  }
}
```

### Warm Pools

Pre-initialized instances for faster scaling:

```hcl
warm_pool = {
  pool_state                  = "Stopped"  # Instances are stopped
  min_size                    = 1          # At least 1 warm instance
  max_group_prepared_capacity = 2          # Maximum warm instances
}
```

Benefits:
- Faster scale-up (no AMI pulling or userdata execution)
- Lower costs (stopped instances only pay for EBS)
- Ideal for predictable traffic spikes

### Spot Instances

Cost-optimized compute for fault-tolerant workloads:

```hcl
instance_market_options = {
  market_type = "spot"
  spot_options = {
    max_price          = "0.15"  # Maximum price
    spot_instance_type = "one-time"
  }
}
```

Savings: ~70% compared to ON_DEMAND pricing

### Custom User Data

Run scripts before Kubernetes bootstrap:

```bash
pre_bootstrap_user_data = <<-EOT
  #!/bin/bash
  # Install CloudWatch agent
  yum install -y amazon-cloudwatch-agent

  # Configure system settings
  echo "net.ipv4.tcp_max_syn_backlog = 8096" >> /etc/sysctl.conf
  sysctl -p
EOT
```

### Kubelet Configuration

Custom node labels and settings:

```bash
kubelet_extra_args = "--node-labels=workload=general,managed-by=asg --max-pods=110"
```

## Monitoring

### CloudWatch Metrics

ASG metrics are automatically published:

```bash
# View ASG metrics
aws cloudwatch list-metrics \
  --namespace AWS/AutoScaling \
  --dimensions Name=AutoScalingGroupName,Value=$(terraform output -json self_managed_node_group_autoscaling_group_names | jq -r '.general')
```

### Node Health

```bash
# Check ASG instance health
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names $(terraform output -json self_managed_node_group_autoscaling_group_names | jq -r '.general') \
  --query 'AutoScalingGroups[0].Instances[*].[InstanceId,LifecycleState,HealthStatus]' \
  --output table
```

## Scaling Operations

### Manual Scaling

```bash
# Scale general node group to 5 instances
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name $(terraform output -json self_managed_node_group_autoscaling_group_names | jq -r '.general') \
  --desired-capacity 5
```

### Trigger Instance Refresh

```bash
# Manually trigger instance refresh
aws autoscaling start-instance-refresh \
  --auto-scaling-group-name $(terraform output -json self_managed_node_group_autoscaling_group_names | jq -r '.general')
```

## SSH Access (if key configured)

```bash
# Get node IP
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}')

# SSH to node
ssh -i ~/.ssh/my-keypair.pem ec2-user@$NODE_IP
```

## Cost Estimation

Estimated monthly costs (us-east-1):

| Resource | Quantity | Unit Cost | Total |
|----------|----------|-----------|-------|
| EKS Cluster | 1 | $73 | $73 |
| t3.large (general) | 3 | $60 | $180 |
| c6i.2xlarge (spot avg) | 2 | $50 | $100 |
| r6i.xlarge (memory) | 2 | $170 | $340 |
| EBS gp3 (700GB) | - | $0.08/GB | $56 |
| **Total** | | | **~$749/month** |

*Costs can be reduced significantly by:*
- Using more Spot instances (~70% savings)
- Scaling down memory nodes when not needed
- Adjusting instance types

## Troubleshooting

### Nodes not joining cluster

1. Check ASG launch template:
```bash
aws ec2 describe-launch-template-versions \
  --launch-template-id $(terraform output -json self_managed_node_group_launch_template_ids | jq -r '.general')
```

2. Verify user data and bootstrap script
3. Check security groups allow node-to-control-plane communication
4. Review CloudWatch logs on the instance

### Instance refresh stuck

```bash
# Check instance refresh status
aws autoscaling describe-instance-refreshes \
  --auto-scaling-group-name $(terraform output -json self_managed_node_group_autoscaling_group_names | jq -r '.general')

# Cancel if needed
aws autoscaling cancel-instance-refresh \
  --auto-scaling-group-name $(terraform output -json self_managed_node_group_autoscaling_group_names | jq -r '.general')
```

### Spot instances terminated

Spot instances can be interrupted with 2-minute notice:
- Deploy interruption handler: [AWS Node Termination Handler](https://github.com/aws/aws-node-termination-handler)
- Use mixed instance types for better availability
- Configure max price appropriately

## Comparison: Self-Managed vs Managed Node Groups

| Feature | Managed | Self-Managed |
|---------|---------|--------------|
| Setup complexity | Simple | Complex |
| Lifecycle management | Automated | Manual |
| Instance refresh | Built-in | Manual configuration |
| Warm pools | No | Yes |
| Custom AMIs | Limited | Full control |
| Spot support | Basic | Advanced |
| Maintenance | AWS managed | Self-managed |
| Cost | Standard | Optimizable |

## Migration from Managed to Self-Managed

1. Deploy self-managed node groups alongside managed
2. Cordon and drain managed nodes
3. Verify workloads on self-managed nodes
4. Remove managed node groups from Terraform

## Cleanup

```bash
# Drain nodes gracefully
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data

# Destroy infrastructure
terraform destroy
```

## Next Steps

- Add [Cluster Autoscaler](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler) for automatic scaling
- Implement custom scaling policies based on metrics
- Configure lifecycle hooks for graceful shutdown
- Set up monitoring and alerting for ASG events

## Related Examples

- [basic-managed-nodes](../basic-managed-nodes) - Simpler managed node groups
- [complete](../complete) - All features with managed nodes
- [karpenter-ready](../karpenter-ready) - Modern autoscaling alternative
