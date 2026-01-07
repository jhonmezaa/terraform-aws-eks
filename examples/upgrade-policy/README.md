# EKS Cluster Upgrade Policy with Extended Support Example

This example demonstrates how to configure Amazon EKS cluster upgrade policy with **Extended Support** for maintaining older Kubernetes versions beyond the standard support lifecycle.

## What is EKS Extended Support?

AWS EKS provides two support tiers for Kubernetes versions:

### Standard Support (Default)
- **Duration**: 14 months from version release
- **Cost**: Included in standard EKS pricing ($0.10/hour per cluster)
- **Includes**: Security patches, bug fixes, AWS optimization
- **Best for**: Regular upgrade cadence, modern applications

### Extended Support
- **Duration**: Up to 26 months (additional 12 months after standard)
- **Cost**: Additional charge per cluster-hour
- **Includes**: Critical security patches only
- **Best for**: Compliance requirements, complex migrations, legacy workloads

## Architecture

```
┌────────────────────────────────────────────────────────────────┐
│                     EKS Cluster Lifecycle                       │
│                                                                 │
│  Month 0-14: STANDARD SUPPORT                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ • Full feature updates                                   │  │
│  │ • Security patches                                       │  │
│  │ • Bug fixes                                              │  │
│  │ • AWS optimizations                                      │  │
│  │ • No additional cost                                     │  │
│  └──────────────────────────────────────────────────────────┘  │
│                          │                                      │
│                          ▼                                      │
│  Month 15-26: EXTENDED SUPPORT (Optional)                      │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ • Critical security patches only                         │  │
│  │ • No new features                                        │  │
│  │ • Additional cost applies                                │  │
│  │ • Compliance-friendly                                    │  │
│  └──────────────────────────────────────────────────────────┘  │
│                          │                                      │
│                          ▼                                      │
│  Month 27+: END OF SUPPORT                                     │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ • MUST upgrade to supported version                      │  │
│  │ • Cluster may become unstable                            │  │
│  │ • Security vulnerabilities not patched                   │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────┘
```

## Features Demonstrated

- **Extended Support Configuration**: Configure `EXTENDED` support type
- **Upgrade Tracking**: CloudWatch logging for upgrade events
- **Blue/Green Node Groups**: Multiple node groups for zero-downtime upgrades
- **Rolling Updates**: Controlled node group updates
- **Monitoring**: CloudWatch alarms for API server health

## Use Cases

### When to Use Extended Support

✅ **Good Fit:**
- Regulated industries (healthcare, finance) with change control requirements
- Complex applications requiring extensive testing for K8s upgrades
- Large-scale migrations needing extra time
- Vendor software certified only for specific K8s versions
- Compliance frameworks mandating controlled upgrade cycles

❌ **Not Recommended:**
- Development/staging environments
- Greenfield projects
- Cost-sensitive deployments
- Applications following latest K8s features

## Version Support Timeline

| Kubernetes Version | Release Date | Standard Support Ends | Extended Support Ends |
|-------------------|--------------|----------------------|---------------------|
| 1.31 | Sep 2024 | Nov 2025 | Nov 2026 |
| 1.30 | May 2024 | Jul 2025 | Jul 2026 |
| 1.29 | Jan 2024 | Mar 2025 | Mar 2026 |
| 1.28 | Sep 2023 | Nov 2024 | Nov 2025 |
| 1.27 | May 2023 | Jul 2024 | Jul 2025 |

Check latest: https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html

## Configuration

### Standard Support (Default)

```hcl
module "eks" {
  source = "../../eks"

  cluster_version = "1.31"

  cluster_upgrade_policy = {
    support_type = "STANDARD" # 14 months support
  }
}
```

### Extended Support

```hcl
module "eks" {
  source = "../../eks"

  cluster_version = "1.28" # Older version

  cluster_upgrade_policy = {
    support_type = "EXTENDED" # 26 months support (additional cost)
  }
}
```

## Cost Considerations

### Extended Support Pricing

As of 2024, Extended Support costs approximately:
- **$0.60 per cluster per hour** (in addition to standard $0.10/hour)
- **~$432/month** or **~$5,184/year** per cluster

### Cost Calculation Example

```
Standard EKS Cluster: $0.10/hour * 730 hours/month = $73/month
+ Extended Support:   $0.60/hour * 730 hours/month = $438/month
─────────────────────────────────────────────────────────────
Total Monthly Cost:                                 $511/month
```

### Cost Optimization Strategies

1. **Minimize Extended Support Duration**: Plan upgrades to minimize time on extended support
2. **Batch Upgrades**: Consolidate testing and upgrades across multiple clusters
3. **Use for Critical Clusters Only**: Keep dev/staging on standard support
4. **Monitor Support End Dates**: Track and plan upgrades proactively

## Deployment

### Step 1: Configure Variables

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:

```hcl
account_name = "prod"
project_name = "eks-extended"

cluster_version = "1.28" # Older version requiring extended support

vpc_id = "vpc-xxx"
subnet_ids = ["subnet-xxx", "subnet-yyy", "subnet-zzz"]

# Enable extended support
upgrade_support_type = "EXTENDED"
support_end_date     = "2025-11-30" # Track when support ends

tags = {
  Environment    = "production"
  UpgradePolicy  = "extended"
  ComplianceTeam = "security-ops"
}
```

### Step 2: Deploy

```bash
terraform init
terraform plan
terraform apply
```

### Step 3: Verify Support Type

```bash
aws eks describe-cluster \
  --name <cluster-name> \
  --query 'cluster.upgradePolicy.supportType' \
  --output text
```

Expected output: `EXTENDED`

## Upgrade Strategy with Extended Support

### Phase 1: Testing (Months 1-3 of Extended Support)

1. Create test cluster with new K8s version
2. Deploy and test applications
3. Identify incompatibilities
4. Update application manifests

```bash
# Deploy test workloads to new version cluster
kubectl apply -f test-workloads/ --context test-cluster
```

### Phase 2: Migration Planning (Months 4-6)

1. Document upgrade procedure
2. Create rollback plan
3. Schedule maintenance windows
4. Notify stakeholders

### Phase 3: Blue/Green Upgrade (Months 7-9)

This example includes two node groups for blue/green upgrades:

```bash
# Scale up "secondary" node group with new version
terraform apply -var="secondary_desired=6"

# Cordon and drain "primary" nodes
kubectl cordon -l role=primary
kubectl drain -l role=primary --ignore-daemonsets --delete-emptydir-data

# Update cluster version
terraform apply -var="cluster_version=1.29"

# Verify workloads on new nodes
kubectl get pods -o wide

# Scale down old node group
terraform apply -var="primary_desired=0"
```

### Phase 4: Finalization (Month 10-12)

1. Monitor for 30 days
2. Document lessons learned
3. Transition to standard support
4. Remove extended support configuration

```hcl
cluster_upgrade_policy = {
  support_type = "STANDARD" # Back to standard support
}
```

## Monitoring and Alerts

### CloudWatch Logs

Enable all control plane logs to track upgrade issues:

```bash
aws logs tail /aws/eks/<cluster-name>/cluster --follow
```

### Key Metrics to Monitor

1. **API Server Errors**
   ```bash
   aws cloudwatch get-metric-statistics \
     --namespace AWS/EKS \
     --metric-name cluster/RequestCount \
     --dimensions Name=ClusterName,Value=<cluster-name> \
     --start-time 2024-01-01T00:00:00Z \
     --end-time 2024-01-02T00:00:00Z \
     --period 3600 \
     --statistics Sum
   ```

2. **Node Health**
   ```bash
   kubectl get nodes --watch
   ```

3. **Pod Disruptions**
   ```bash
   kubectl get events --all-namespaces --watch | grep -i disruption
   ```

## Best Practices

### 1. Document Everything

Create upgrade runbook:
```yaml
# upgrade-runbook.yaml
cluster_name: prod-eks-extended
current_version: 1.28
target_version: 1.29
support_end_date: 2025-11-30
upgrade_date: 2025-09-15
rollback_plan: scale-up-old-node-group.sh
stakeholders:
  - ops-team@company.com
  - dev-team@company.com
```

### 2. Test Thoroughly

```bash
# Run compatibility tests
kubectl apply --dry-run=server -f production-manifests/

# Test with kubectl-convert plugin
kubectl-convert -f old-manifest.yaml --output-version apps/v1
```

### 3. Use Pod Disruption Budgets

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: critical-app-pdb
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: critical-app
```

### 4. Implement Canary Deployments

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-canary
spec:
  replicas: 1
  selector:
    matchLabels:
      app: myapp
      version: new
  template:
    metadata:
      labels:
        app: myapp
        version: new
    spec:
      nodeSelector:
        role: secondary # New node group
```

### 5. Monitor Addon Compatibility

```bash
# Check addon versions
aws eks describe-addon-versions \
  --kubernetes-version 1.29 \
  --addon-name vpc-cni

# Update addons before cluster upgrade
aws eks update-addon \
  --cluster-name <cluster-name> \
  --addon-name vpc-cni \
  --addon-version <compatible-version>
```

## Compliance and Security

### Audit Trail

Extended support provides time for compliance audits:

```bash
# Export audit logs for compliance
aws logs filter-log-events \
  --log-group-name /aws/eks/<cluster-name>/cluster \
  --filter-pattern '{$.verb = "create" || $.verb = "delete" || $.verb = "update"}' \
  --start-time $(date -u -d '30 days ago' +%s)000 \
  --output json > audit-trail.json
```

### Security Scanning

Continue scanning during extended support:

```bash
# Scan for vulnerabilities
trivy k8s --report summary cluster

# Check for deprecated APIs
pluto detect-helm --target-versions k8s=v1.29
```

## Troubleshooting

### Issue: Cluster Not Accepting Extended Support

```bash
# Verify cluster eligibility
aws eks describe-cluster --name <cluster-name> \
  --query 'cluster.status'

# Check K8s version is within extended support window
aws eks describe-cluster --name <cluster-name> \
  --query 'cluster.version'
```

### Issue: High Costs

```bash
# Review CloudWatch billing metrics
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity DAILY \
  --metrics UnblendedCost \
  --filter file://eks-cost-filter.json
```

**eks-cost-filter.json:**
```json
{
  "Dimensions": {
    "Key": "SERVICE",
    "Values": ["Amazon Elastic Kubernetes Service"]
  }
}
```

## Transition to Standard Support

When ready to return to standard support:

1. **Update Configuration**
   ```hcl
   cluster_upgrade_policy = {
     support_type = "STANDARD"
   }
   ```

2. **Upgrade to Newer Version**
   ```bash
   terraform apply -var="cluster_version=1.31"
   ```

3. **Verify Support Type**
   ```bash
   aws eks describe-cluster --name <cluster-name> \
     --query 'cluster.upgradePolicy.supportType'
   ```

## Additional Resources

- [EKS Kubernetes Versions](https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html)
- [EKS Extended Support](https://docs.aws.amazon.com/eks/latest/userguide/extended-support.html)
- [EKS Upgrade Guide](https://docs.aws.amazon.com/eks/latest/userguide/update-cluster.html)
- [Kubernetes Deprecation Policy](https://kubernetes.io/docs/reference/using-api/deprecation-policy/)

## Example Output

```
cluster_name = "prod-eks-extended"
cluster_version = "1.28"
upgrade_support_type = "EXTENDED"
support_end_date = "2025-11-30"
cluster_endpoint = "https://ABC123.eks.us-east-1.amazonaws.com"
api_server_alarm_arn = "arn:aws:cloudwatch:us-east-1:123456789012:alarm:prod-eks-extended-eks-api-errors"
```
