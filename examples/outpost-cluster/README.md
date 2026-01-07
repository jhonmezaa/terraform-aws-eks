# EKS on AWS Outposts Example

This example demonstrates how to deploy an Amazon EKS cluster on AWS Outposts for on-premises and edge computing workloads.

## What is AWS Outposts?

AWS Outposts extends AWS infrastructure, services, APIs, and tools to on-premises locations. It provides a consistent hybrid cloud experience for workloads that need to remain on-premises due to latency, data residency, or local data processing requirements.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         AWS Region                               │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │               EKS Control Plane (Managed)                  │  │
│  │  - API Server                                              │  │
│  │  - etcd                                                    │  │
│  │  - Controller Manager                                      │  │
│  │  - Scheduler                                               │  │
│  └───────────────────────────────────────────────────────────┘  │
│                            │                                      │
│                            │ (Encrypted Connection)               │
└────────────────────────────┼──────────────────────────────────────┘
                             │
┌────────────────────────────┼──────────────────────────────────────┐
│                   AWS Outpost (On-Premises)                       │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │               EKS Control Plane Instances                   │  │
│  │  - Running on EC2 instances on Outpost                     │  │
│  │  - Connected to managed control plane in region            │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │                   Worker Nodes (EC2)                        │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │  │
│  │  │ Node Group 1 │  │ Node Group 2 │  │ Node Group 3 │     │  │
│  │  │  On-Premises │  │     Edge     │  │   Compute    │     │  │
│  │  └──────────────┘  └──────────────┘  └──────────────┘     │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │                   Local Applications                        │  │
│  │  - Low latency workloads                                   │  │
│  │  - Data residency requirements                             │  │
│  │  - Local data processing                                   │  │
│  └────────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────────┘
```

## Features Demonstrated

- **EKS on Outposts**: Deploy EKS cluster with control plane instances on Outpost
- **On-Premises Compute**: Worker nodes running on Outpost hardware
- **Hybrid Connectivity**: Seamless integration between on-premises and cloud
- **Edge Computing**: Ultra-low latency for edge workloads
- **Consistent APIs**: Same EKS experience as cloud deployments

## Prerequisites

Before deploying this example, you must have:

1. **AWS Outpost Installed**: Physical Outpost hardware installed and configured at your location
2. **Outpost Subnet**: VPC subnets associated with the Outpost
3. **Local Gateway**: Configured for on-premises connectivity
4. **Supported Instance Types**: Verify EC2 instance types available on your Outpost
5. **Network Connectivity**: Reliable connection between Outpost and AWS Region

### Check Outpost Available Instance Types

```bash
aws outposts list-outposts --region us-east-1

aws ec2 describe-instance-type-offerings \
  --location-type availability-zone \
  --filters Name=location,Values=<outpost-id> \
  --region us-east-1
```

## Configuration

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `outpost_arn` | ARN of your AWS Outpost | `arn:aws:outposts:us-east-1:123456789012:outpost/op-xxx` |
| `outpost_subnet_ids` | Subnet IDs on the Outpost (min 2 AZs) | `["subnet-xxx", "subnet-yyy"]` |
| `control_plane_instance_type` | EC2 type for control plane | `m5.xlarge`, `c5.2xlarge` |
| `vpc_id` | VPC ID containing Outpost subnets | `vpc-xxx` |

### Instance Type Considerations

**Control Plane Instance Types:**
- Minimum: `m5.xlarge` (4 vCPU, 16 GB RAM)
- Recommended: `m5.2xlarge` or `c5.2xlarge` for production
- Must be available on your specific Outpost configuration

**Worker Node Instance Types:**
- General Purpose: `m5.large`, `m5.xlarge`
- Compute Optimized: `c5.large`, `c5.xlarge`
- Memory Optimized: `r5.large`, `r5.xlarge`

## Deployment

### Step 1: Configure Variables

Copy the example variables file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your Outpost details:

```hcl
account_name = "prod"
project_name = "outpost-eks"

cluster_version = "1.31"

vpc_id = "vpc-0123456789abcdef0"

# Your Outpost ARN
outpost_arn = "arn:aws:outposts:us-east-1:123456789012:outpost/op-0123456789abcdef0"

# Subnets on your Outpost (minimum 2 in different AZs)
outpost_subnet_ids = [
  "subnet-0123456789abcdef0",
  "subnet-0123456789abcdef1"
]

# Instance types (verify availability on your Outpost)
control_plane_instance_type = "m5.xlarge"
node_instance_type          = "m5.large"
edge_instance_type          = "c5.large"
```

### Step 2: Initialize Terraform

```bash
terraform init
```

### Step 3: Plan Deployment

```bash
terraform plan
```

### Step 4: Deploy

```bash
terraform apply
```

Deployment takes approximately 15-20 minutes.

### Step 5: Configure kubectl

```bash
aws eks update-kubeconfig \
  --name <cluster-name> \
  --region <region>
```

## Use Cases

### 1. Low Latency Applications

Deploy applications that require ultra-low latency to on-premises systems:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: low-latency-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: low-latency
  template:
    metadata:
      labels:
        app: low-latency
    spec:
      nodeSelector:
        location: outpost
        workload: edge-computing
      containers:
      - name: app
        image: your-app:latest
        resources:
          requests:
            cpu: "500m"
            memory: "512Mi"
```

### 2. Data Residency

Keep data processing on-premises for compliance:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: local-data
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: gp2  # Uses Outpost EBS
  resources:
    requests:
      storage: 100Gi
```

### 3. Edge Computing

Process data locally before sending to cloud:

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: edge-processor
spec:
  selector:
    matchLabels:
      app: edge-processor
  template:
    metadata:
      labels:
        app: edge-processor
    spec:
      nodeSelector:
        location: outpost
      tolerations:
      - key: outpost
        operator: Exists
        effect: NoSchedule
      containers:
      - name: processor
        image: edge-processor:latest
```

## Important Considerations

### Network Requirements

- **Bandwidth**: Minimum 1 Gbps connection to AWS Region
- **Latency**: Less than 100ms RTT to region recommended
- **Reliability**: Redundant connections recommended for production

### Limitations

1. **Spot Instances**: Not available on Outposts
2. **Fargate**: Not supported on Outposts
3. **EBS Volume Types**: Limited to gp2 (check your Outpost)
4. **Instance Types**: Limited to what's provisioned on your Outpost
5. **Autoscaling**: Works but limited by physical Outpost capacity

### High Availability

- Deploy across multiple Outpost racks if available
- Use placement groups for control plane anti-affinity
- Configure pod disruption budgets for critical workloads

### Monitoring

Monitor both cloud and on-premises metrics:

```bash
# Check Outpost capacity
aws outposts get-outpost --outpost-id op-xxx

# Monitor node health
kubectl get nodes --show-labels

# Check pod placement
kubectl get pods -o wide --all-namespaces | grep outpost
```

## Cost Considerations

### EKS on Outposts Costs

- **Control Plane**: Same as standard EKS ($0.10/hour)
- **Control Plane Instances**: EC2 instances on Outpost (on-demand pricing)
- **Worker Nodes**: EC2 instances on Outpost
- **Outpost Capacity**: Monthly rental fee for Outpost hardware

### Cost Optimization

- Use appropriate instance sizes (no over-provisioning)
- Implement pod autoscaling (HPA/VPA)
- Monitor and optimize resource requests/limits
- Consider mixed workloads to maximize utilization

## Troubleshooting

### Control Plane Connection Issues

```bash
# Check Outpost connectivity
aws outposts list-outposts --region us-east-1

# Verify security groups allow required ports
# - 443 (HTTPS) for API server
# - 10250 (kubelet API)
```

### Node Registration Issues

```bash
# Check node logs
kubectl describe node <node-name>

# Verify IAM role permissions
aws iam get-role --role-name <node-role-name>

# Check security group rules
aws ec2 describe-security-groups --group-ids <sg-id>
```

### Capacity Issues

```bash
# Check Outpost available capacity
aws outposts get-outpost --outpost-id op-xxx

# List instance capacity
aws ec2 describe-instance-types \
  --filters Name=instance-type,Values=m5.* \
  --region us-east-1
```

## Clean Up

To destroy all resources:

```bash
terraform destroy
```

**Note**: Ensure no critical workloads are running before destroying the cluster.

## Additional Resources

- [EKS on Outposts User Guide](https://docs.aws.amazon.com/eks/latest/userguide/eks-on-outposts.html)
- [AWS Outposts Documentation](https://docs.aws.amazon.com/outposts/latest/userguide/)
- [EKS Best Practices for Outposts](https://aws.github.io/aws-eks-best-practices/outposts/)

## Example Output

```
cluster_name = "prod-outpost-eks"
cluster_endpoint = "https://ABC123.eks.us-east-1.amazonaws.com"
oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/ABC123"
outpost_arn = "arn:aws:outposts:us-east-1:123456789012:outpost/op-0123456789abcdef0"
control_plane_instance_type = "m5.xlarge"
```
