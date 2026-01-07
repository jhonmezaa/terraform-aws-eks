# Private Cluster Example

This example demonstrates a fully private EKS cluster with no public access to the Kubernetes API. This configuration is ideal for security-sensitive workloads and compliance requirements.

## Features

- **Private-only API endpoint**: No public access to Kubernetes API
- **Encrypted secrets**: KMS encryption for cluster secrets
- **VPC endpoints**: Private access to AWS services (S3, ECR)
- **CloudWatch logging**: Audit and API logs
- **Private nodes**: All EC2 instances in private subnets
- **No public IPs**: Complete network isolation

## Security Benefits

1. **No public exposure**: API endpoint not accessible from internet
2. **Defense in depth**: Multiple layers of network isolation
3. **Compliance**: Meets strict security and compliance requirements
4. **Reduced attack surface**: No public-facing components
5. **Audit trail**: Complete logging for compliance

## Access Requirements

To access a private cluster, you need:

1. **VPN Connection**: AWS Client VPN or Site-to-Site VPN
2. **Direct Connect**: Dedicated network connection to AWS
3. **Bastion Host**: EC2 instance in the same VPC
4. **Cloud9**: AWS Cloud9 IDE in the VPC
5. **Transit Gateway**: Multi-VPC connectivity

## Prerequisites

### Network Infrastructure

Required:
- VPC with private subnets
- NAT Gateway for outbound internet (pod images, updates)
- VPN or Direct Connect for cluster access
- Route tables properly configured

### VPC Endpoints (Recommended)

For private access to AWS services without NAT:
- S3 (Gateway endpoint - free)
- ECR API (Interface endpoint)
- ECR DKR (Interface endpoint)
- EC2 (Interface endpoint)
- CloudWatch Logs (Interface endpoint)

## Usage

### Option 1: Access via VPN

```bash
# 1. Connect to VPN
# 2. Deploy cluster
terraform init
terraform apply

# 3. Configure kubectl (requires VPN connection)
aws eks update-kubeconfig --name $(terraform output -raw cluster_name) --region us-east-1

# 4. Verify access
kubectl get nodes
```

### Option 2: Access via Bastion Host

```bash
# 1. SSH to bastion in same VPC
ssh -i key.pem ec2-user@bastion-ip

# 2. Configure kubectl on bastion
aws eks update-kubeconfig --name cluster-name --region us-east-1

# 3. Use kubectl from bastion
kubectl get nodes
```

### Option 3: Access via AWS Cloud9

```bash
# 1. Launch Cloud9 in same VPC
# 2. Install kubectl in Cloud9
# 3. Configure kubectl
aws eks update-kubeconfig --name cluster-name --region us-east-1

# 4. Use Cloud9 as development environment
kubectl apply -f deployment.yaml
```

## VPC Endpoints Configuration

This example creates VPC endpoints for:

### S3 (Gateway Endpoint)
- Free of charge
- For pulling container images from S3-backed registries
- For application S3 access

### ECR (Interface Endpoints)
- ECR API: For registry authentication
- ECR DKR: For pulling container images
- $7/month per endpoint + data transfer

### Cost Estimation

VPC Endpoint costs (us-east-1):
- S3 Gateway: $0 (free)
- ECR API Interface: ~$7/month
- ECR DKR Interface: ~$7/month
- Data transfer: ~$0.01/GB

Vs NAT Gateway for same traffic:
- NAT Gateway: ~$32/month + $0.045/GB

## Network Architecture

```
┌─────────────────────────────────────────────────────┐
│                      VPC                            │
│  ┌──────────────────────────────────────────────┐  │
│  │         Private Subnet AZ-a                   │  │
│  │  ┌────────────┐  ┌──────────────┐            │  │
│  │  │ EKS Nodes  │  │ VPC Endpoint │            │  │
│  │  └────────────┘  └──────────────┘            │  │
│  └──────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────┐  │
│  │         Private Subnet AZ-b                   │  │
│  │  ┌────────────┐  ┌──────────────┐            │  │
│  │  │ EKS Nodes  │  │ VPC Endpoint │            │  │
│  │  └────────────┘  └──────────────┘            │  │
│  └──────────────────────────────────────────────┘  │
│                                                     │
│  ┌──────────────┐                                  │
│  │ NAT Gateway  │──────> Internet (for updates)   │
│  └──────────────┘                                  │
│                                                     │
│  ┌──────────────┐                                  │
│  │ VPN Gateway  │◄────── Corporate Network        │
│  └──────────────┘                                  │
└─────────────────────────────────────────────────────┘
```

## Deploying Workloads

Since the cluster is private, deploy via:

### 1. GitOps (Recommended)

```bash
# Install FluxCD or ArgoCD
# Automated deployments from Git

# Example: FluxCD
flux bootstrap github \
  --owner=myorg \
  --repository=fleet-infra \
  --path=clusters/private-cluster \
  --personal
```

### 2. CI/CD Pipeline

```yaml
# GitHub Actions example
- name: Deploy to EKS
  run: |
    # Runs in VPC via self-hosted runner
    aws eks update-kubeconfig --name $CLUSTER_NAME
    kubectl apply -f manifests/
```

### 3. Bastion Host

```bash
# Deploy from bastion
kubectl apply -f deployment.yaml
```

## Pulling Container Images

### From ECR (Recommended)

With VPC endpoints:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-app
spec:
  containers:
  - name: app
    image: 123456789012.dkr.ecr.us-east-1.amazonaws.com/my-app:latest
```

### From Public Registries

Requires NAT Gateway:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  containers:
  - name: nginx
    image: nginx:latest  # Pulls via NAT Gateway
```

## Monitoring and Logging

### CloudWatch Logs

Control plane logs are in CloudWatch:
```bash
aws logs tail "/aws/eks/$(terraform output -raw cluster_name)/cluster" --follow
```

### Container Insights

Enable Container Insights:
```bash
aws eks create-addon \
  --cluster-name $(terraform output -raw cluster_name) \
  --addon-name amazon-cloudwatch-observability
```

### Accessing CloudWatch from Private Cluster

Create VPC endpoint for CloudWatch Logs:
```hcl
resource "aws_vpc_endpoint" "cloudwatch_logs" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.us-east-1.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  private_dns_enabled = true
}
```

## Troubleshooting

### Cannot connect to cluster

Verify you have network access:
```bash
# Test connectivity to API endpoint
CLUSTER_ENDPOINT=$(terraform output -raw cluster_endpoint | sed 's|https://||')
telnet $CLUSTER_ENDPOINT 443
```

If connection fails:
1. Check VPN/Direct Connect is active
2. Verify security groups allow your IP
3. Confirm you're on correct network

### Pods cannot pull images

Check VPC endpoints:
```bash
# Verify ECR endpoints exist
aws ec2 describe-vpc-endpoints \
  --filters "Name=vpc-id,Values=$(terraform output -raw vpc_id)" \
  --query 'VpcEndpoints[*].[ServiceName,State]' \
  --output table
```

If missing, enable:
```hcl
create_vpc_endpoints = true
```

### Pods cannot reach internet

Check NAT Gateway:
```bash
# Verify NAT in route table
aws ec2 describe-route-tables \
  --filters "Name=vpc-id,Values=vpc-xxx" \
  --query 'RouteTables[*].Routes[?DestinationCidrBlock==`0.0.0.0/0`]'
```

Ensure route: `0.0.0.0/0 -> nat-xxxxx`

### kubectl hangs

Connection timeout usually means:
1. Not connected to VPN/network
2. Security group blocking access
3. Endpoint is truly private (no public access)

## Cost Optimization

### Reduce NAT Costs

Use VPC endpoints for AWS services:
- Savings: ~$30-40/month per NAT Gateway
- Trade-off: ~$14/month for 2 interface endpoints

### Right-size Nodes

Private clusters often have steady workloads:
- Use Reserved Instances for 40% savings
- Consider Savings Plans

## Compliance Considerations

This architecture helps meet:

- **PCI-DSS**: No public exposure of infrastructure
- **HIPAA**: Network isolation for PHI data
- **SOC 2**: Strong access controls
- **FedRAMP**: Government security requirements

Document:
- Network diagrams
- Access procedures
- Audit logs retention
- Incident response plans

## Migration from Public to Private

1. **Assess**: Identify external dependencies
2. **Plan**: Design VPC endpoint strategy
3. **Deploy**: Create private cluster
4. **Test**: Verify all functionality
5. **Migrate**: Move workloads
6. **Decommission**: Remove public cluster
7. **Document**: Update runbooks

## Cleanup

```bash
# Must be connected to VPN or bastion
terraform destroy
```

**Note**: Destroy may take longer due to private endpoint cleanup.

## Best Practices

1. **Always use VPC endpoints**: Minimize NAT costs
2. **Implement GitOps**: Automated deployments
3. **Use private ECR**: Keep images in AWS
4. **Enable VPC Flow Logs**: Monitor traffic
5. **Regular access audits**: Review who can access
6. **Backup restore plans**: Test recovery procedures
7. **Document procedures**: Clear access instructions

## Related Examples

- [complete](../complete) - Full-featured public cluster
- [basic-managed-nodes](../basic-managed-nodes) - Simple public cluster
- [karpenter-ready](../karpenter-ready) - Autoscaling configuration
