# Basic Managed Nodes Example

This example demonstrates how to deploy a simple EKS cluster with managed node groups.

## Features

- EKS cluster with managed node groups
- IRSA (IAM Roles for Service Accounts) enabled
- Essential EKS addons (vpc-cni, coredns, kube-proxy)
- Single general-purpose node group with t3.medium instances
- Encrypted EBS volumes with gp3 storage

## Architecture

This example creates:

- EKS cluster (latest stable version)
- 1 managed node group with:
  - t3.medium instances (ON_DEMAND)
  - 2 desired nodes (min: 1, max: 4)
  - 100GB encrypted gp3 volumes
- OIDC provider for IRSA
- Essential EKS addons with proper deployment ordering

## Prerequisites

- AWS account with appropriate permissions
- VPC with private subnets in at least 2 availability zones
- Terraform >= 1.0
- AWS CLI configured with credentials

## Usage

1. Copy the example tfvars file:
```bash
cp terraform.tfvars.example terraform.tfvars
```

2. Edit `terraform.tfvars` with your VPC and subnet IDs:
```hcl
vpc_id = "vpc-0123456789abcdef0"
subnet_ids = [
  "subnet-0123456789abcdef0",
  "subnet-0123456789abcdef1",
  "subnet-0123456789abcdef2"
]
```

3. Initialize Terraform:
```bash
terraform init
```

4. Review the execution plan:
```bash
terraform plan
```

5. Apply the configuration:
```bash
terraform apply
```

6. Configure kubectl:
```bash
aws eks update-kubeconfig --name $(terraform output -raw cluster_name) --region us-east-1
```

7. Verify the cluster:
```bash
kubectl get nodes
kubectl get pods -A
```

## Customization

### Change instance types:
```hcl
managed_node_groups = {
  general = {
    instance_types = ["t3.large"]  # Change to larger instance
  }
}
```

### Adjust node capacity:
```hcl
managed_node_groups = {
  general = {
    desired_size = 3
    min_size     = 2
    max_size     = 6
  }
}
```

### Add additional node groups:
```hcl
managed_node_groups = {
  general = { ... }

  compute = {
    desired_size   = 2
    min_size       = 1
    max_size       = 4
    instance_types = ["c5.xlarge"]
    capacity_type  = "SPOT"

    labels = {
      workload = "compute"
    }
  }
}
```

## Costs

Estimated monthly costs (us-east-1):
- EKS cluster: $73
- 2 x t3.medium (ON_DEMAND): ~$60
- 2 x 100GB gp3 volumes: ~$16
- **Total: ~$149/month**

## Cleanup

To destroy all resources:
```bash
terraform destroy
```

## Next Steps

After deploying this basic cluster, consider:

1. **Add Helm addons**: Deploy monitoring, autoscaling, etc.
2. **Configure IRSA**: Create IAM roles for service accounts
3. **Deploy workloads**: Use kubectl or Helm to deploy applications
4. **Enable logging**: Add CloudWatch logging for control plane
5. **Add autoscaling**: Configure Cluster Autoscaler or Karpenter

## Related Examples

- [complete](../complete) - All features enabled (logging, KMS, access entries, etc.)
- [karpenter-ready](../karpenter-ready) - Cluster optimized for Karpenter autoscaling
- [private-cluster](../private-cluster) - Private API endpoint configuration
