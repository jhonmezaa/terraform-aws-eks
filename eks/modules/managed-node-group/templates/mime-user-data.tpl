MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="//"

%{ if include_nodeconfig ~}
--//
Content-Type: application/node.eks.aws

---
apiVersion: node.eks.aws/v1alpha1
kind: NodeConfig
spec:
  kubelet:
    flags:
${kubelet_flags_formatted}

%{ endif ~}
%{ if include_script ~}
--//
Content-Type: text/x-shellscript; charset="us-ascii"

${script}

%{ endif ~}
--//--
