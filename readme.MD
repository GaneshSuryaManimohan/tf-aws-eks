# Installing AWS Load Balancer Controller in EKS

* Official documentation:
    - https://kubernetes-sigs.github.io/aws-load-balancer-controller/latest/deploy/installation/

The AWS Load Balancer Controller helps Kubernetes manage AWS Application Load Balancers (ALB) and Network Load Balancers (NLB) automatically for Kubernetes services and ingresses.

It is required when using:
1. Kubernetes Ingress with AWS ALB
2. TargetGroupBinding
3. AWS-managed load balancing for EKS applications

### Step 1: Associate IAM OIDC Provider

```bash
eksctl utils associate-iam-oidc-provider --region us-east-1 --cluster expense --approve 
```

* **Purpose**: This command associates an IAM OIDC (OpenID Connect) provider with the EKS cluster.

* **Why It Is Required?**
AWS Load Balancer Controller uses IAM Roles for Service Accounts (IRSA) to securely access AWS resources.

* Without OIDC:
    - Kubernetes pods cannot assume IAM roles
    - AWS APIs cannot be accessed securely from pods

* What Happens Internally
    - Creates an IAM identity provider in AWS IAM
    - Links the EKS cluster with IAM
    - Enables Kubernetes service accounts to use IAM roles

### Step 2: Download IAM Policy

```bash 
curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.5.4/docs/install/iam_policy.json
```

* **Purpose**: Downloads the recommended IAM policy required by the AWS Load Balancer Controller.

* **Why It Is Required?**
The controller needs permissions to:
    - Create ALBs/NLBs
    - Manage Target Groups
    - Register EC2 instances
    - Modify Security Groups
    - Read VPC/Subnet information

* **Output**:
    This command downloads: `iam_policy.json` which contains all required AWS permissions.

### Step 3: Create IAM Policy

```bash 
aws iam create-policy \ --policy-name AWSLoadBalancerControllerIAMPolicy \ --policy-document file://iam_policy.json
```

* **Purpose**: Creates a custom IAM policy in AWS using the downloaded JSON policy file.

* **Why It Is Required?**
    This IAM policy will later be attached to the Kubernetes service account so the controller can interact with AWS services securely.

* **Result**:
    - Creates an IAM policy similar to: AWSLoadBalancerControllerIAMPolicy


### Step 4: Create IAM Service Account

```bash
eksctl create iamserviceaccount \
  --cluster=expense \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::328342418911:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve
```

* **Purpose**: Creates a Kubernetes Service Account and attaches an IAM role to it.

* **Why It Is Required?**
    The AWS Load Balancer Controller pod runs inside Kubernetes and requires AWS permissions.
This step:
    - Creates a Kubernetes Service Account
    - Creates an IAM Role
    - Attaches the IAM policy
    - Links the IAM role to the Kubernetes Service Account using IRSA

### Step 5: Add EKS Helm Repository

```bash helm repo add eks https://aws.github.io/eks-charts ```

* **Purpose**: Adds the official AWS EKS Helm chart repository.

* **Why It Is Required?**
    Helm uses repositories to download Kubernetes application charts.
This repository contains:
    - AWS Load Balancer Controller
    - Other AWS EKS-related Helm charts

### Step 6: Install AWS Load Balancer Controller

```bash 
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=expense
```

* **Purpose**: Installs the AWS Load Balancer Controller into the EKS cluster.

* **Why It Is Required?**
    The controller watches Kubernetes resources such as:
    - Ingress
    - Service
    - TargetGroupBinding
    and automatically creates/manages AWS load balancers.

* **What Happens Internally?**
    The controller:
    - Runs as a deployment inside kube-system
    - Monitors Kubernetes resources
    - Calls AWS APIs using the IAM role attached earlier
    - Creates ALBs/NLBs automatically

#### Verification
**Verify Controller Pods**
```bash 
kubectl get pods -n kube-system
```

**Expected output:**
aws-load-balancer-controller-xxxxx Running


-------------------------------------------------

terraform destroy -target=aws_security_group_rule.eks_managed_node_to_db
terraform destroy -target=aws_security_group_rule.node_to_ingress