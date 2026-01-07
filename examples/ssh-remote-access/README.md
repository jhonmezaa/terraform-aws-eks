# EKS SSH Remote Access Example

This example demonstrates how to configure SSH access to EKS managed node groups for debugging and troubleshooting.

## Features

- **SSH Access via EC2 Key Pair**: Direct SSH access for development
- **AWS Systems Manager (SSM)**: Secure access without public IPs
- **Security Group Configuration**: Controlled access from bastion/VPN
- **Two Access Methods**: SSH and SSM demonstrated

## Prerequisites

1. **EC2 Key Pair**: Create key pair in AWS console or CLI
   ```bash
   aws ec2 create-key-pair --key-name my-keypair --query 'KeyMaterial' --output text > my-keypair.pem
   chmod 400 my-keypair.pem
   ```

2. **Bastion Host or VPN** (recommended): For secure SSH access

## Configuration

### Basic SSH Access (Development)

```hcl
managed_node_groups = {
  ssh_enabled = {
    key_name                 = "my-ec2-keypair"
    associate_public_ip_address = true  # Dev only
  }
}
```

### SSM Access (Production)

```hcl
managed_node_groups = {
  ssm_access = {
    key_name                 = "my-ec2-keypair"  # Emergency access
    associate_public_ip_address = false  # No public IP, use SSM
  }
}
```

## Usage

### SSH Access

```bash
# Get node public IP
kubectl get nodes -o wide

# SSH to node
ssh -i ~/.ssh/my-keypair.pem ec2-user@<node-public-ip>
```

### SSM Access (Recommended)

```bash
# Get instance ID
aws ec2 describe-instances \
  --filters "Name=tag:kubernetes.io/cluster/<cluster-name>,Values=owned" \
  --query 'Reservations[*].Instances[*].[InstanceId,PrivateIpAddress,State.Name]' \
  --output table

# Start SSM session
aws ssm start-session --target <instance-id>
```

## Security Best Practices

1. **Use SSM Instead of SSH**: No open ports, session logging
2. **Restrict Source IPs**: Use `ssh_source_security_groups` or `ssh_allowed_cidrs`
3. **Disable Public IPs**: Set `associate_public_ip_address = false`
4. **Rotate Keys**: Regularly update EC2 key pairs
5. **Enable Session Logging**: Configure SSM session logs to S3/CloudWatch

## Troubleshooting

### Cannot SSH to Node

```bash
# Check security groups allow SSH
aws ec2 describe-security-groups --group-ids <node-sg-id>

# Verify key pair
aws ec2 describe-key-pairs --key-names my-keypair
```

### SSM Session Won't Start

```bash
# Verify IAM role has SSM permissions
aws iam get-role --role-name <node-role-name>

# Check SSM agent status on node (via SSH)
sudo systemctl status amazon-ssm-agent
```

## Clean Up

```bash
terraform destroy
```

## Additional Resources

- [EKS Node SSH Access](https://docs.aws.amazon.com/eks/latest/userguide/node-ssh-access.html)
- [AWS Systems Manager Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html)
