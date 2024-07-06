# infra-config

## How to use

### Prerequisites

You must have the following tools installed and available in your `PATH`:

- [terraform](https://developer.hashicorp.com/terraform/install)
    - could be installed by `winget` or `choco`
- [aws-cli](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) - `aws` command
- [kubectl](https://kubernetes.io/docs/tasks/tools/) - If you want to interact with the cluster
- [jq](https://jqlang.github.io/jq/) - If you are using the AWS Academy Learner Lab & get the `role_arn` by command line
    - could be installed by `winget` or `choco`
- [helm](https://helm.sh/zh/docs/intro/quickstart/)
    - could be installed by `winget` or `choco`

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

## Example Application

Switch to the `bookinfo` branch:
```sh
git checkout origin/bookinfo
```

Deploy using the following commands:
```sh
terraform init
terraform apply -auto-approve
```

After a successful deployment, the example application should be running normally.

Export the `INGRESS_HOST` variable:
```sh
export INGRESS_HOST=$(kubectl -n istio-ingress get service istio-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
```

Send 100 requests to the application:
```sh
for i in $(seq 1 100); do curl -s -o /dev/null "http://$INGRESS_HOST/productpage"; done
```

Then, start the Kiali dashboard:
```sh
istioctl dashboard kiali
```

You should see the traffic graph in the Kiali dashboard.