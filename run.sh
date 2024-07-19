#!/bin/bash
# rm terraform.tfstate*

git pull origin main
if [ $1 == "terraform" ]; then
    terraform init
    if [ $? -ne 0 ]; then
    echo "Terraform initialization failed."
    exit 1
    fi
    echo "Terraform initialization successful."

    terraform validate
    if [ $? -ne 0 ]; then
    echo "Terraform validation failed."
    exit 1
    fi
    echo "Terraform validation successful."

    while true; do
    terraform apply -auto-approve
    if [ $? -eq 0 ]; then
        echo "Terraform apply successful."
        break
    else
        echo "Terraform apply failed. Retrying in 1 second..."
        sleep 1
    fi
    done
elif [ $1 == "demo" ]; then
    set -e

    # pulsar
    pushd modules/pulsar
    bash ./scripts/pulsar/prepare_helm_release.sh -n pulsar -k pulsar-local -c
    helm repo add apache https://pulsar.apache.org/charts
    helm repo update
    if helm list -n pulsar | grep -q pulsar-local; then
        echo "Pulsar already installed, skipping..."
    else
        helm install pulsar-local apache/pulsar --timeout 10m -f ../../demo/pulsar-values.yaml --namespace pulsar
    fi

    popd
    # PostgreSQL
    kubectl apply -k demo/postgresql

    # Frontend
    kubectl apply -f demo/frontend.yaml

    # Main API Service
    kubectl apply -f demo/main_api_service.yaml

    # AI Model Operator
    kubectl apply -k kustomize/ai-model-operator/default

    # AI Model Example
    kubectl apply -f demo/aimodel_test.yaml

    deployment_name="postgres"
    namespace="postgresql"
    elapsed_time=0
    while true; do
        ready_replicas=$(kubectl get deploy "$deployment_name" -n "$namespace" -o jsonpath='{.status.readyReplicas}')

        if [[ "$ready_replicas" -ge 1 ]]; then
            echo "Deployment $deployment_name is READY. Time elapsed: ${elapsed_time} seconds."
            break
        else
            echo "Waiting for deployment $deployment_name to become READY... Time elapsed: ${elapsed_time} seconds."
            sleep 10
            elapsed_time=$((elapsed_time + 10))
        fi
    done

    # Admin Panel
    kubectl apply -k demo/admin-panel



    interval=5
    check_statefulsets_ready() {
        local statefulsets_ready=true
        mapfile -t statefulsets < <(kubectl get statefulset -n "$namespace" -o jsonpath='{range .items[*]}{.metadata.name} {.status.readyReplicas}{"\n"}{end}')
        for statefulset in "${statefulsets[@]}"; do
            name=$(echo "$statefulset" | awk '{print $1}')
            ready_replicas=$(echo "$statefulset" | awk '{print $2}')
    
            if [[ -z "$ready_replicas" || "$ready_replicas" -lt 1 ]]; then
                statefulsets_ready=false
                break
            fi
        done
        
        echo "$statefulsets_ready"
    }

    check_deployments_ready() {
        local deployment_ready=true
        mapfile -t deployments < <(kubectl get deployments -A -o jsonpath='{range .items[*]}{.metadata.name} {.status.readyReplicas}{"\n"}{end}')
        for deployment in "${deployments[@]}"; do
            name=$(echo "$deployment" | awk '{print $1}')
            ready_replicas=$(echo "$deployment" | awk '{print $2}')
    
            if [[ -z "$ready_replicas" || "$ready_replicas" -lt 1 ]]; then
                deployment_ready=false
                break
            fi
        done
        
        echo "$deployment_ready"
    }

    elapsed_time=0
    namespace="pulsar"
    while true; do
    if [[ $(check_statefulsets_ready) == true ]]; then
        echo "Pulsar are READY. Time elapsed: ${elapsed_time} seconds."
        break
    else
        echo "Waiting for pulsar to become READY... Time elapsed: ${elapsed_time} seconds."
        sleep "$interval"
        elapsed_time=$((elapsed_time + interval))
    fi
    done

    elapsed_time=0
    namespace="redis-operator"
    while true; do
    if [[ $(check_statefulsets_ready) == true ]]; then
        echo "Redis are READY. Time elapsed: ${elapsed_time} seconds."
        break
    else
        echo "Waiting for pulsar to become READY... Time elapsed: ${elapsed_time} seconds."
        sleep "$interval"
        elapsed_time=$((elapsed_time + interval))
    fi
    done

    elapsed_time=0
    namespace="postgresql-ha"
    while true; do
    if [[ $(check_statefulsets_ready) == true && $(check_deployments_ready) == true ]]; then
        echo "PostgreSQL are READY. Time elapsed: ${elapsed_time} seconds."
        break
    else
        echo "Waiting for postgresql to become READY... Time elapsed: ${elapsed_time} seconds."
        sleep "$interval"
        elapsed_time=$((elapsed_time + interval))
    fi
    done

    elapsed_time=0
    namespace="keda"
    while true; do
    if [[ $(check_deployments_ready) == true ]]; then
        echo "KEDA are READY. Time elapsed: ${elapsed_time} seconds."
        break
    else
        echo "Waiting for postgresql to become READY... Time elapsed: ${elapsed_time} seconds."
        sleep "$interval"
        elapsed_time=$((elapsed_time + interval))
    fi
    done

    echo "UPLION demo is ready."
    echo -e "\tAdmin Panel: http://<NodeIP>:30008/admin"
    echo -e "\tFrontend: http://<NodeIP>:30009"

else
    echo "Invalid command: $1"
    echo "Usage: ./run.sh [terraform|demo]"
    exit 1
fi