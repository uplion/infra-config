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

### Istio

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
for i in $(seq 1 100); do curl -s -o /dev/null "http://$INGRESS_HOST/productpage" ; done
```

Then, start the Kiali dashboard:
```sh
istioctl dashboard kiali
```

You should see the traffic graph in the Kiali dashboard.

### Redis Cluster

0. Prerequirity: [redis-cli](https://redis.io/docs/latest/operate/rs/references/cli-utilities/redis-cli/)

1. Get redis cluster password using command below:

```bash
export REDIS_PASSWORD=$(kubectl get secret --namespace redis-cluster redis-cluster -o jsonpath="{.data.redis-password}" | base64 --decode)
```

2. Expose redis-cluster service to local port (e.g. 6379):

```bash
kubectl port-forward svc/redis-cluster -n redis-cluster 6379:6379
```

3. Start another terminal, connect to redis using redis-cli:

```bash
redis-cli -h localhost -p 6379 -a $REDIS_PASSWORD
```

if operate successfully, you will see the redis-cli prompt like `localhost:6379> `.

4. Test redis-cluster:

```
localhost:6379> info
```

You should see the redis information like `cluster_enabled:1`.

### PostgreSQL HA

0. Prerequirity: [postgresql](https://www.postgresql.org/download/linux/debian/)
    - postgresql
    - postgresql-common
    - postgresql-client-\[version\]

1. Get postgresql password using command below:

```bash
kubectl get secret --namespace postgresql-ha postgresql-ha-postgresql -o jsonpath="{.data.password}" | base64 --decode
```

2. Expose redis-cluster service to local port (e.g. 5432):

```bash
kubectl port-forward svc/postgresql-ha-pgpool -n postgresql-ha 5432:5432
```

3. Start another terminal, connect to redis using redis-cli:

```bash
psql api_server -h localhost -p 5432 -U postgres -W
```

Then input the password you got in step 1.
If operate successfully, you will see the psql prompt like `api_server=# `.

4. Test redis-cluster:

```
api_server=# \dconfig
```

You should see the redis information like `cluster_enabled:1`.

### Pulsar

2. Expose pulsar service to local port (e.g. 5432):

```bash
kubectl port-forward svc/pulsar-proxy -n pulsar 6650:6650
```

3. 

## License

MIT