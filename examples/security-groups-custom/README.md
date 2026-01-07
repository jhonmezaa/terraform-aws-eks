# EKS Custom Security Groups Example

This example demonstrates using custom security groups instead of module-generated ones.

## Features

- Custom cluster security group
- Custom node security group
- Manual security group rule configuration
- Disable auto-creation with `create_cluster_security_group = false`

## Use Cases

- Pre-existing security groups required
- Strict network security policies
- Compliance requirements for security group naming/tagging
- Shared security groups across multiple clusters

## Deployment

```bash
terraform init
terraform apply
```
