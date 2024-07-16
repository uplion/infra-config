### TODO add cert-manager support
# https://github.com/OT-CONTAINER-KIT/helm-charts/tree/main/charts/redis-operator

locals {
  node_conf_storage_size = "100Mi"
}

resource "helm_release" "redis_operator" {
  name       = var.redis_operator_name
  repository = "https://ot-container-kit.github.io/helm-charts"
  chart      = "redis-operator"
  version    = "0.18.0"

  namespace        = var.namespace
  create_namespace = true

  values = [yamlencode({
    redisOperator = {
      name = var.redis_operator_name # Operator name
      #   imageName = "ghcr.io/ot-container-kit/redis-operator/redis-operator:v0.17.0" # Image repository	
      #   imageTag = "{{appVersion}}" # Image tag
      #   imagePullPolicy = "Always"        # Image pull policy
      #   podAnnotations  = {}              # Additional pod annotations
      #   podLabels       = {}              # Additional Pod labels
      #   extraArgs       = {}              # Additional arguments for the operator
      #   watch_namespace = "redis-cluster" # Namespace for the operator to watch
      #   env             = {}              # Environment variables for the operator
      #   webhook         = false           # Enable webhook
    }
    # resources = {
    #   limits = {
    #     cpu    = "500m"  # CPU limit
    #     memory = "500Mi" # Memory limit
    #   }
    #   requests = {
    #     cpu    = "500m"  # CPU request
    #     memory = "500Mi" # Memory request
    #   }
    # }
    # replicas           = 1                # Number of replicas
    # serviceAccountName = "redis-operator" # Service account name
    # certificate = {
    #   name       = "serving-cert"        # Certificate name
    #   secretName = "webhook-server-cert" # Certificate Secret name
    # }
    # issuer = {
    #   type                 = "selfSigned"                                     # Issuer type
    #   name                 = "redis-operator-issuer"                          # Issuer name
    #   email                = "shubham.gupta@opstree.com"                      # Issuer email
    #   server               = "https://acme-v02.api.letsencrypt.org/directory" # Issuer server URL
    #   privateKeySecretName = "letsencrypt-prod"
    # }
    # certManager = {
    #   enable = false # Enable cert-manager
    # }

    # # Scheduling Parameters
    # priorityClassName = ""    # Priority class name for the pods
    # nodeSelector      = {}    # Labels for pod assignment
    # tolerateAllTaints = false # Whether to tolerate all node taints	
    # tolerations       = []    # Taints to tolerate
    # affinity          = {}    # Affinity rules for pod assignment
  })]
}

# redis cluster
resource "helm_release" "redis_cluster" {
  name       = var.redis_name
  repository = "https://ot-container-kit.github.io/helm-charts"
  chart      = "redis-cluster"
  version    = "0.16.0"

  namespace        = var.namespace
  create_namespace = true

  depends_on = [helm_release.redis_operator]

  values = [yamlencode({
    # imagePullSecrets = [] # List of image pull secrets, in case redis image is getting pull from private registry
    redisCluster = {
      clusterSize = var.redis_cluster_size # Size of the redis cluster leader and follower nodes
      resources = {
        limits = {
          cpu    = "500m"  # CPU limit for redis pods
          memory = "500Mi" # Memory limit for redis pods
        }
        requests = {
          cpu    = "500m"  # CPU request for redis pods
          memory = "500Mi" # Memory request for redis pods
        }
      }
      #   clusterVersion      = "v7"                    # Major version of Redis setup, values can be v6 or v7
      #   persistenceEnabled  = true                    # Persistence should be enabled or not in the Redis cluster setup
      #   secretName          = "redis-secret"          # Name of the existing secret in Kubernetes
      #   secretKey           = "password"              # Name of the existing secret key in Kubernetes
      #   image               = "quay.io/opstree/redis" # Name of the redis image
      #   tag                 = "v6.2"                  # Tag of the redis image
      #   imagePullPolicy     = "IfNotPresent"          # Image Pull Policy of the redis image
      #   leaderServiceType   = "ClusterIP"             # Kubernetes service type for Redis Leader
      #   followerServiceType = "ClusterIP"             # Kubernetes service type for Redis Follower
      #   name                = ""                      # Overwrites the name for the charts resources instead of the Release name
    }
    # externalService = {
    #   enabled     = false      # If redis service needs to be exposed using LoadBalancer or NodePort
    #   annotations = {}         # Kubernetes service related annotations
    #   serviceType = "NodePort" # Kubernetes service type for exposing service, values - ClusterIP, NodePort, and LoadBalancer
    #   port        = 6379       # Port number on which redis external service should be exposed
    # }
    # serviceMonitor = {
    #   enabled       = false        # Servicemonitor to monitor redis with Prometheus
    #   interval      = "30s"        # Interval at which metrics should be scraped.
    #   scrapeTimeout = "10s"        # Timeout after which the scrape is ended
    #   namespace     = "monitoring" # Namespace in which Prometheus operator is running
    # }
    # redisExporter = {
    #   enabled         = true                             # Redis exporter should be deployed or not
    #   image           = "quay.io/opstree/redis-exporter" # Name of the redis exporter image
    #   tag             = "v6.2"                           # Tag of the redis exporter image
    #   imagePullPolicy = "IfNotPresent"                   # Image Pull Policy of the redis exporter image
    #   env             = []                               # Extra environment variables which needs to be added in redis exporter
    # }
    # sidecars          = [] # Sidecar for redis pods
    # nodeSelector      = {} # NodeSelector for redis statefulset
    # priorityClassName = "" # Priority class name for the redis statefulset
    storageSpec = { # Storage configuration for redis setup
      nodeConfVolumeClaimTemplate = {
        spec = {
          storageClassName = var.redis_storage_class_name # Storage class name for the volume
          accessModes      = ["ReadWriteOnce"]            # Access mode for the volume
          resources = {
            requests = {
              storage = local.node_conf_storage_size # Storage size for the volume
            }
          }
        }
      }
      volumeClaimTemplate = {
        spec = {
          storageClassName = var.redis_storage_class_name # Storage class name for the volume
          accessModes      = ["ReadWriteOnce"]            # Access mode for the volume
          resources = {
            requests = {
              storage = var.redis_storage_size # Storage size for the volume
            }
          }
        }
      }
    }
    # securityContext = {} # Security Context for redis pods for changing system or kernel level parameters
    # affinity        = {} # Affinity for node and pods for redis statefulset
    # tolerations     = [] # Tolerations for redis statefulset
  })]
}
