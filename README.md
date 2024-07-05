# infra-config

## How to use

### Prerequisites

- [terraform](https://developer.hashicorp.com/terraform/install)
- [aws-cli](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [kubectl](https://kubernetes.io/docs/tasks/tools/) - If you want to interact with the cluster

### Configure AWS credentials

```bash
aws configure
```

or paste credentials in `~/.aws/credentials` file.


### Get `role_arn`

#### If you are using the AWS Academy Learner Lab

If you are using the AWS Academy Learner Lab, I assume you have a role called `LabRole` that has the required permissions. So you can save the role ARN in `terraform.tfvars` with the following command:

Bash:
```bash
echo "role_arn = \"`aws iam get-role --role-name LabRole | jq -r .Role.Arn`\"" | tee terraform.tfvars
```
Powershell:
```powershell
echo "role_arn = `"$(aws iam get-role --role-name LabRole | jq -r .Role.Arn)`"" | tee terraform.tfvars
```

or you can get the role ARN from the AWS console (search IAM -> Roles -> LabRole -> Copy ARN) and paste it in the `terraform.tfvars` file.

Then the `terraform.tfvars` file should look like this:

```
role_arn = "arn:aws:iam::123456789012:role/LabRole"
```

#### If you are using a different account

Otherwise, you need to create a role with `AmazonEC2ContainerRegistryReadOnly`, `AmazonEKSClusterPolicy`, `AmazonEKSWorkerNodePolicy` and `AmazonSSMManagedInstanceCore`. Then run the above command with the role name you created.

### Deploy

```bash
terraform init
terraform apply -auto-approve
```

### Destroy

Destroy the resources to avoid unnecessary charges.

```bash
terraform destroy -auto-approve
```