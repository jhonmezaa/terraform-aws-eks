#!/bin/bash
set -ex

# Pre-bootstrap user data
${pre_bootstrap_user_data}

# Bootstrap node to EKS cluster
/etc/eks/bootstrap.sh '${cluster_name}' \
  --b64-cluster-ca '${cluster_ca_data}' \
  --apiserver-endpoint '${cluster_endpoint}' \
  ${bootstrap_extra_args} \
  --kubelet-extra-args '${kubelet_extra_args}'

# Post-bootstrap user data
${post_bootstrap_user_data}
