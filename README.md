# infra-config

## How to use

### Prerequisites

You must have the following tools installed and available in your `PATH`:

- [terraform](https://developer.hashicorp.com/terraform/install)
- [aws-cli](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) - `aws` command
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [jq](https://jqlang.github.io/jq/) - If you are using the AWS Academy Learner Lab & get the `role_arn` by command line
- [helm](https://helm.sh/zh/docs/intro/quickstart/)

> [!NOTE]
> All tools above could be installed using `choco` or `winget` on windows (may need to modify name a little bit, like aws-cli into awscli)

### Deploy on an existing kubernetes cluster

Please note that the following steps is suitable for deployments such as minikube. The deployed applications can only be accessed using NodeIP. You may need to configure LoadBalancer yourself.

1. Ensure that kubectl is working properly: `kubectl get nodes`
2. Deploy the application: `bash run.sh demo`

After a successful deployment, check the output information to access the application.

### Deploy on AWS

The following steps will create eks and applications on AWS from scratch.

#### Configure AWS credentials

```bash
aws configure
```

or paste credentials in `~/.aws/credentials` file.

#### Get `role_arn`

##### If you are using the AWS Academy Learner Lab

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

##### If you are using a different account

Otherwise, you need to create a role with `AmazonEC2ContainerRegistryReadOnly`, `AmazonEKSClusterPolicy`, `AmazonEKSWorkerNodePolicy` and `AmazonSSMManagedInstanceCore`. Then run the above command with the role name you created.

#### Deploy

First, we need to initialize providers & modules used in the terraform:

```bash
terraform init
```

Then, we can do some basic check using `terraform validate` command:

```bash
terraform validate
```

Then, we can deploy the resources using `terraform apply` command:

```bash
terraform apply -auto-approve
```

> [!WARNING]
> The application may be failed, and in that case, you can just run `terraform apply -auto-approve` again to fix the issue in most scenarios.

> [!NOTE]
> If you don't want to input commands every step, you can just run `./run.sh terraform` as a one-time short-cut.

#### Destroy

Destroy the resources to avoid unnecessary charges.

```bash
terraform destroy -auto-approve
```

## License

[MIT](LICENSE)
