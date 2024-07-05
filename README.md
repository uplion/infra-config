# cluster-config

## How to use

### Prerequisites

- [terraform](https://developer.hashicorp.com/terraform/install)
- [aws-cli](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [kubectl](https://kubernetes.io/docs/tasks/tools/) - If you want to interact with the cluster

### Get `role_arn`

If you are using the AWS Academy Learner Lab, I assume you have a role called `LabRole` that has the required permissions. So you can save the role ARN in `terraform.tfvars` with the following command:

```bash
echo "role_arn = `aws iam get-role --role-name LabRole | jq -r .Role.Arn`" | tee terraform.tfvars
```
Otherwise, you need to create a role with `AmazonEC2ContainerRegistryReadOnly`, `AmazonEKSClusterPolicy`, `AmazonEKSWorkerNodePolicy` and `AmazonSSMManagedInstanceCore`. Then run the above command with the role name you created.

### Deploy

```bash
terraform init
terraform apply -auto-approve
```