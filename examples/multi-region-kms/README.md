# EKS Multi-Region KMS Example

Demonstrates EKS cluster with multi-region KMS key for encryption.

## Features

- Multi-region KMS key (can replicate to other regions)
- Cluster secrets encryption
- CloudWatch logs encryption
- EBS volume encryption
- Automatic key rotation enabled

## Use Cases

- Multi-region disaster recovery
- Cross-region data replication
- Compliance requirements for encryption key availability

## Multi-Region Setup

### Primary Region (us-east-1)
```bash
terraform apply
```

### Replica Region (us-west-2)
```bash
# Create replica key in secondary region
aws kms replicate-key \
  --key-id <primary-key-id> \
  --replica-region us-west-2
```

Deploy EKS in replica region using replica key ARN.

## Benefits

- Single key management across regions
- Simplified disaster recovery
- Consistent encryption policies
- Automatic key synchronization
