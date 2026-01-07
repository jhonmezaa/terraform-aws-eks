# IPv6 Dual-Stack Cluster Example

This example demonstrates an EKS cluster with IPv6 dual-stack networking. Pods receive both IPv4 and IPv6 addresses, enabling modern IPv6-native applications while maintaining IPv4 compatibility.

## Features

- Dual-stack (IPv4 + IPv6) cluster networking
- IPv6-enabled VPC-CNI configuration
- Pods with both IPv4 and IPv6 addresses
- IPv6 service CIDR
- Future-proof infrastructure

## Why IPv6?

### Benefits
1. **Address space**: Virtually unlimited IP addresses
2. **Future-proof**: Global IPv6 adoption increasing
3. **Direct connectivity**: No NAT required
4. **Modern protocols**: Better support for modern networking
5. **Cost savings**: Reduced NAT Gateway costs (egress-only IGW is free)

### Use Cases
- Large-scale deployments (>65k pods)
- IoT applications requiring unique IPs
- Modern cloud-native applications
- Compliance with IPv6 mandates
- Global services requiring IPv6

## Prerequisites

### VPC Requirements

Your VPC **must** have:
1. IPv6 CIDR block assigned to VPC
2. IPv6 CIDR blocks on all subnets
3. Route table entries for IPv6:
   - `::/0` -> Internet Gateway (public subnets)
   - `::/0` -> Egress-Only Internet Gateway (private subnets)

### Creating IPv6-Enabled VPC

If using the terraform-aws-vpc module:

```hcl
module "vpc" {
  source = "../../terraform-aws-vpc/vpc"

  # Enable IPv6
  enable_ipv6                     = true
  assign_ipv6_address_on_creation = true

  # Subnets will get both IPv4 and IPv6 CIDRs
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.11.0/24", "10.0.12.0/24"]

  # Egress-only IGW for private subnet IPv6
  enable_egress_only_internet_gateway = true
}
```

Or manually via AWS Console/CLI:
```bash
# Associate IPv6 CIDR to VPC
aws ec2 associate-vpc-cidr-block \
  --vpc-id vpc-xxx \
  --amazon-provided-ipv6-cidr-block

# Associate IPv6 CIDR to subnet
aws ec2 associate-subnet-cidr-block \
  --subnet-id subnet-xxx \
  --ipv6-cidr-block 2600:1f13:xxx::/64
```

## Usage

1. Ensure VPC has IPv6 enabled
2. Copy and configure:
```bash
cp terraform.tfvars.example terraform.tfvars
```

3. Deploy:
```bash
terraform init
terraform apply
```

4. Configure kubectl:
```bash
aws eks update-kubeconfig --name $(terraform output -raw cluster_name) --region us-east-1
```

5. Verify IPv6:
```bash
# Check node addresses
kubectl get nodes -o wide

# Deploy test pod
kubectl run ipv6-test --image=nginx

# Check pod IPs (should see both IPv4 and IPv6)
kubectl get pod ipv6-test -o jsonpath='{.status.podIPs}' | jq
```

## Networking Details

### Pod Addressing

Each pod receives:
- **IPv4 address**: From VPC CIDR (e.g., 10.0.11.5)
- **IPv6 address**: From subnet IPv6 CIDR (e.g., 2600:1f13:xxx::5)

Example pod status:
```yaml
status:
  podIPs:
  - ip: 10.0.11.5
  - ip: 2600:1f13:abd:8392::5
```

### Service Addressing

Services can use:
- **IPv4**: Traditional ClusterIP from service CIDR
- **IPv6**: ClusterIP from IPv6 service CIDR

Example service:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  ipFamilyPolicy: PreferDualStack
  ipFamilies:
  - IPv4
  - IPv6
  ports:
  - port: 80
```

### DNS Resolution

CoreDNS handles both IPv4 (A) and IPv6 (AAAA) records:

```bash
# From within pod
nslookup kubernetes.default
# Returns both IPv4 and IPv6 addresses
```

## Testing IPv6 Connectivity

### Test Pod-to-Pod IPv6

```bash
# Deploy 2 pods
kubectl run pod1 --image=nginx
kubectl run pod2 --image=busybox -- sleep 3600

# Get pod2's IPv6 address
POD2_IPV6=$(kubectl get pod pod2 -o jsonpath='{.status.podIPs[1].ip}')

# Ping from pod1 to pod2 via IPv6
kubectl exec pod1 -- ping6 -c 3 $POD2_IPV6
```

### Test Internet IPv6 Connectivity

```bash
# Test outbound IPv6 (requires Egress-Only IGW)
kubectl run ipv6-test --image=busybox --rm -it -- ping6 -c 3 google.com
```

### Test Service IPv6

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-ipv6
spec:
  ipFamilyPolicy: RequireDualStack
  selector:
    app: nginx
  ports:
  - port: 80
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx
```

```bash
# Check service IPs
kubectl get svc nginx-ipv6 -o jsonpath='{.spec.clusterIPs}' | jq

# Test from another pod
kubectl run test --image=busybox --rm -it -- wget -O- http://[<IPv6-ClusterIP>]
```

## IP Family Policies

Kubernetes supports three IP family policies:

### SingleStack (IPv4 only)
```yaml
ipFamilyPolicy: SingleStack
ipFamilies:
- IPv4
```

### PreferDualStack (default)
```yaml
ipFamilyPolicy: PreferDualStack
ipFamilies:
- IPv4  # Primary
- IPv6  # Secondary
```

### RequireDualStack (strict)
```yaml
ipFamilyPolicy: RequireDualStack
ipFamilies:
- IPv4
- IPv6
```

## Load Balancers with IPv6

### Network Load Balancer (NLB)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nlb-ipv6
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "external"
    service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "ip"
    service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing"
    service.beta.kubernetes.io/aws-load-balancer-ip-address-type: "dualstack"
spec:
  type: LoadBalancer
  ipFamilyPolicy: PreferDualStack
  selector:
    app: nginx
  ports:
  - port: 80
```

### Application Load Balancer (ALB)

Requires AWS Load Balancer Controller:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: alb-ipv6
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/ip-address-type: dualstack
spec:
  ingressClassName: alb
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nginx
            port:
              number: 80
```

## Troubleshooting

### Pods only have IPv4

Check VPC-CNI configuration:
```bash
kubectl set env daemonset aws-node -n kube-system ENABLE_IPv6=true
```

Verify subnet has IPv6 CIDR:
```bash
aws ec2 describe-subnets --subnet-ids subnet-xxx --query 'Subnets[0].Ipv6CidrBlockAssociationSet'
```

### IPv6 connectivity not working

1. Check route tables for IPv6 routes:
```bash
aws ec2 describe-route-tables --route-table-ids rtb-xxx
# Should see ::/0 -> igw-xxx or eigw-xxx
```

2. Check security groups allow IPv6:
```bash
# Add IPv6 rules
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxx \
  --ip-permissions IpProtocol=-1,Ipv6Ranges='[{CidrIpv6=::/0}]'
```

3. Verify Egress-Only IGW for private subnets:
```bash
aws ec2 create-egress-only-internet-gateway --vpc-id vpc-xxx
```

### Services not getting IPv6 addresses

Ensure `ipFamilyPolicy` is set:
```bash
kubectl patch svc my-service -p '{"spec":{"ipFamilyPolicy":"PreferDualStack"}}'
```

## Migration from IPv4 to Dual-Stack

1. **Plan**: Identify applications requiring IPv6
2. **VPC**: Add IPv6 CIDR blocks to VPC and subnets
3. **Routes**: Update route tables with IPv6 routes
4. **Deploy**: Create new dual-stack EKS cluster
5. **Test**: Verify IPv6 connectivity
6. **Migrate**: Move workloads to new cluster
7. **Update**: Modify services to use dual-stack

## Cost Considerations

IPv6 can **reduce costs**:

- **Egress-Only IGW**: Free (vs NAT Gateway $32-96/month)
- **Elastic IPs**: Not needed for IPv6
- **NAT costs**: Eliminated for IPv6 traffic

Estimated savings: $40-100/month per AZ

## Limitations

- Not all AWS services support IPv6
- Some third-party integrations may be IPv4-only
- Requires careful network planning
- Application code may need updates

## Best Practices

1. **Use PreferDualStack**: Maintains IPv4 compatibility
2. **Test thoroughly**: Verify all integrations support IPv6
3. **Monitor closely**: Track IPv6 vs IPv4 traffic
4. **Document**: Keep network diagrams up-to-date
5. **Gradual rollout**: Start with non-critical workloads

## Cleanup

```bash
terraform destroy
```

## Related Examples

- [basic-managed-nodes](../basic-managed-nodes) - Standard IPv4 cluster
- [private-cluster](../private-cluster) - Private endpoint configuration
- [complete](../complete) - All features enabled
