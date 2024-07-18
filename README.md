# infra-config

## How to use

### Prerequisites

You must have the following tools installed and available in your `PATH`:

- [terraform](https://developer.hashicorp.com/terraform/install)
- [aws-cli](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) - `aws` command
- [kubectl](https://kubernetes.io/docs/tasks/tools/) - If you want to interact with the cluster
- [jq](https://jqlang.github.io/jq/) - If you are using the AWS Academy Learner Lab & get the `role_arn` by command line
- [helm](https://helm.sh/zh/docs/intro/quickstart/)

> [!NOTE]
> All tools above could be installed using `choco` or `winget` on windows (may need to modify name a little bit, like aws-cli into awscli)

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

### Destroy

Destroy the resources to avoid unnecessary charges.

```bash
terraform destroy -auto-approve
```
<!-- 
## Partial Tests

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

> [!WARNING]
> If you are running redis or other device at local, do not use the same port since the traffic will collid and redirect to somewhere you don't mean it to be.

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
kubectl get secret --namespace postgres-operator postgresql-ha-pguser-test -o jsonpath="{.data.password}" | base64 --decode
```

2. Expose postgres cluster to local port (e.g. 5432):

```bash
kubectl port-forward svc/postgresql-ha-pgbouncer -n postgres-operator 5432:5432
```

> [!WARNING]
> If you are running postgres or other device at local, do not use the same port since the traffic will collid and redirect to somewhere you don't mean it to be.

3. Start another terminal, connect to postgres using psql:

```bash
psql postgres -h localhost -p 5432 -U test -W
```

Then input the password you got in step 1. (Or just do the command follow before using psql to auto input password)

```bash
PGPASSWORD=$(kubectl get secret --namespace postgres-operator postgres-ha-pguser-test -o jsonpath="{.data.password}" | base64 --decode)
```

If operate successfully, you will see the psql prompt like `postgres=> `.

4. Test postgres cluster:

```
postgres=> \dconfig
```

You should see the postgres configurations on the remote.

### Pulsar 
TODO to be tested

0. Prerequirity: [pulsarcli](https://github.com/streamnative/pulsarctl)


1. Expose pulsar service to local port (e.g. 6650):

```bash
kubectl port-forward svc/pulsar-local-proxy -n pulsar 6650:6650
```

> [!WARNING]
> If you are running pulsar or other device at local, do not use the same port since the traffic will collid and redirect to somewhere you don't mean it to be.

2. Then you can access pulsar service 

```bash
pulsarctl topic list
```

TODO configure pulsar manager & grafana

### Main API Service

TODO add main-api-service test

### AI Model Operator

- See Lab Test Video 
TODO to be configured

### Admin Panel

1. Expose Admin Panel to localhost:
```bash
kubectl port-forward service/admin-panel 3000:3000 -n admin-panel
```

> [!WARNING]
> If you are running other device at local, do not use the same port since the traffic will collid and redirect to somewhere you don't mean it to be.

2. Access Admin Panel through browser:
```bash
http://localhost:3000/admin
```

For more detailed instructions, refer to the [Admin Panel Repository](https://github.com/uplion/admin-panel).

### Frontend

1. Expose Admin Panel to localhost:
```bash
kubectl port-forward service/frontend 3001:3000 -n frontend
```

> [!WARNING]
> If you are running other device at local, do not use the same port since the traffic will collid and redirect to somewhere you don't mean it to be.

2. Access Admin Panel through browser:
```bash
http://localhost:3001
```

For more detailed instructions, refer to the [Frontend Repository](https://github.com/uplion/frontend).

### Ingress Gateway

TODO add ingress gateway test

### Overall

-  -->

## License

MIT