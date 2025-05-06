#!/bin/bash
set -e

# Check if environment and cluster arguments are provided
if [ $# -lt 2 ]; then
    echo "Usage: $0 <environment> <cluster>"
    echo "Example: $0 devops odoo"
    exit 1
fi

ENVIRONMENT=$1
CLUSTER=$2

# Set the correct paths based on script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEMPLATES_DIR="$PROJECT_ROOT/base/templates"
ENV_FILE="../../environments/$ENVIRONMENT/$CLUSTER.env"

echo "Using environment file: $(realpath $ENV_FILE)"

if [ ! -f "$ENV_FILE" ]; then
    echo "Environment file $ENV_FILE not found!"
    exit 1
fi

# Source the environment file
source "$ENV_FILE"
echo "After sourcing, ENV_NAME=$ENV_NAME, CLUSTER_NAME=$CLUSTER_NAME"

# Debug: Print environment variables to verify they're loaded properly
echo "Debugging environment variables:"
echo "ENV_NAME: $ENV_NAME"
echo "CLUSTER_NAME: $CLUSTER_NAME"
echo "NFS_SERVER: $NFS_SERVER"
echo "LOKI_STORAGE_SIZE: $LOKI_STORAGE_SIZE"
echo "PROMETHEUS_STORAGE_SIZE: $PROMETHEUS_STORAGE_SIZE"

# Create temporary directory for rendered templates
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT
echo "Using temporary directory: $TMP_DIR"

render_template() {
    local template="$1"
    local output="$2"
    echo "Rendering template: $template -> $output"
    cp "$template" "$output"
    sed -i "s|\${ENV_NAME}|$ENV_NAME|g" "$output"
    sed -i "s|\${CLUSTER_NAME}|$CLUSTER_NAME|g" "$output"
    sed -i "s|\${LOKI_STORAGE_SIZE}|$LOKI_STORAGE_SIZE|g" "$output"
    sed -i "s|\${PROMETHEUS_STORAGE_SIZE}|$PROMETHEUS_STORAGE_SIZE|g" "$output"
    sed -i "s|\${ALERTMANAGER_STORAGE_SIZE}|$ALERTMANAGER_STORAGE_SIZE|g" "$output"
    sed -i "s|\${TEMPO_STORAGE_SIZE}|$TEMPO_STORAGE_SIZE|g" "$output"
    sed -i "s|\${DNS_DOMAIN}|$DNS_DOMAIN|g" "$output"
    echo "First few lines of rendered template:"
    head -n 5 "$output"
}

echo "Rendering templates for $ENVIRONMENT - $CLUSTER..."
# Render templates
render_template "$TEMPLATES_DIR/persistent-volumes.yaml.tpl" "$TMP_DIR/persistent-volumes.yaml"
render_template "$TEMPLATES_DIR/persistent-volume-claims.yaml.tpl" "$TMP_DIR/persistent-volume-claims.yaml"
render_template "$TEMPLATES_DIR/prometheus-values.yaml.tpl" "$TMP_DIR/prometheus-values.yaml"
render_template "$TEMPLATES_DIR/loki-values.yaml.tpl" "$TMP_DIR/loki-values.yaml"
render_template "$TEMPLATES_DIR/tempo-values.yaml.tpl" "$TMP_DIR/tempo-values.yaml"
render_template "$TEMPLATES_DIR/otel-collector.yaml.tpl" "$TMP_DIR/otel-collector.yaml"
render_template "$TEMPLATES_DIR/instrumentation.yaml.tpl" "$TMP_DIR/instrumentation.yaml"
render_template "$TEMPLATES_DIR/postgres-exporter-secret.yml.tpl" "$TMP_DIR/postgres-exporter-secret.yml"
render_template "$TEMPLATES_DIR/postgres-exporter.yaml.tpl" "$TMP_DIR/postgres-exporter.yaml"
render_template "$TEMPLATES_DIR/service-monitors.yaml.tpl" "$TMP_DIR/service-monitors.yaml"
render_template "$TEMPLATES_DIR/cluster-issuer.yaml.tpl" "$TMP_DIR/cluster-issuer.yaml"
render_template "$TEMPLATES_DIR/tempo-ingress.yaml.tpl" "$TMP_DIR/tempo-ingress.yaml"



# Create namespace if it doesn't exist
echo "Creating namespace kube-prometheus-stack if it doesn't exist..."
kubectl create namespace kube-prometheus-stack --dry-run=client -o yaml | kubectl apply -f -

# # # Apply Kubernetes resources
# echo "Applying Persistent Volumes and Claims..."
# kubectl apply -f "$TMP_DIR/persistent-volumes.yaml"
# kubectl apply -f "$TMP_DIR/persistent-volume-claims.yaml"

# Install or upgrade NGINX Ingress Controller
echo "Installing/Upgrading NGINX Ingress Controller..."
helm upgrade --install ingress ingress-nginx/ingress-nginx \
    --namespace ingress-nginx \
    --create-namespace --set controller.ingressClassResource.name=custom-nginx

# Apply cluster-issuer
echo "Applying cluster-issuer..."
kubectl apply -f "$TMP_DIR/cluster-issuer.yaml"

# Install or upgrade Prometheus Stack
echo "Installing/Upgrading Prometheus Stack..."
helm upgrade --install prom-stack prometheus-community/kube-prometheus-stack \
    --namespace kube-prometheus-stack \
    -f "$TMP_DIR/prometheus-values.yaml"

# Wait for ServiceMonitor CRD to be available
echo "Waiting for ServiceMonitor CRD to be available..."
start_time=$(date +%s)
timeout=300 # 5 minutes
while true; do
    if kubectl get crd servicemonitors.monitoring.coreos.com >/dev/null 2>&1; then
        echo "ServiceMonitor CRD is available."
        break
    fi
    elapsed=$(($(date +%s) - start_time))
    if [ "$elapsed" -gt "$timeout" ]; then
        echo "Timeout waiting for ServiceMonitor CRD."
        kubectl get crd servicemonitors.monitoring.coreos.com -o yaml
        exit 1
    fi
    echo "Waiting for ServiceMonitor CRD..."
    sleep 5
done

echo "Handling OpenTelemetry Operator CRDs..."

for crd in opentelemetrycollectors.opentelemetry.io instrumentations.opentelemetry.io; do
    if kubectl get crd $crd >/dev/null 2>&1; then
        echo "Patching CRD $crd..."
        kubectl patch crd $crd --type=merge -p '{
          "metadata": {
            "labels": {
              "app.kubernetes.io/managed-by": "Helm"
            },
            "annotations": {
              "meta.helm.sh/release-name": "opentelemetry-operator",
              "meta.helm.sh/release-namespace": "kube-prometheus-stack"
            }
          }
        }'
    fi
done

echo "Installing/Upgrading OpenTelemetry Operator..."
helm upgrade --install opentelemetry-operator open-telemetry/opentelemetry-operator \
    --namespace kube-prometheus-stack \
    --create-namespace \
    --set admissionWebhooks.certManager.enabled=true \
    --set admissionWebhooks.autoGenerateCert.enabled=false \
    --set manager.collectorImage.repository=otel/opentelemetry-collector-contrib \
    --set manager.collectorImage.tag=0.91.0

echo "Waiting for Instrumentation CRD to be available..."
start_time=$(date +%s)
timeout=300
while true; do
    if kubectl get crd instrumentations.opentelemetry.io >/dev/null 2>&1; then
        echo "Instrumentation CRD is available."
        break
    fi
    elapsed=$(($(date +%s) - start_time))
    if [ "$elapsed" -gt "$timeout" ]; then
        echo "Timeout waiting for Instrumentation CRD."
        exit 1
    fi
    echo "Waiting for Instrumentation CRD..."
    sleep 5
done

echo "Restarting OpenTelemetry webhook to resolve TLS issue..."
kubectl delete deployment opentelemetry-operator-webhook -n kube-prometheus-stack || true
sleep 10

# Apply OpenTelemetry resources
echo "Applying OpenTelemetry resources..."
kubectl apply -f "$TMP_DIR/otel-collector.yaml"
kubectl apply -f "$TMP_DIR/instrumentation.yaml"

# Install Postgres Exporter
echo "Installing Postgres Exporter..."
kubectl apply -f "$TMP_DIR/postgres-exporter-secret.yml"
kubectl apply -f "$TMP_DIR/postgres-exporter.yaml"

# Service Monitors
echo "Installing Service Monitors..."
kubectl apply -f "$TMP_DIR/service-monitors.yaml"

# Install or upgrade Loki Stack
echo "Installing/Upgrading Loki Stack..."
helm upgrade --install loki-stack grafana/loki-stack \
    --namespace kube-prometheus-stack \
    -f "$TMP_DIR/loki-values.yaml"

# Install or upgrade Tempo
echo "Installing/Upgrading Tempo..."
helm upgrade --install tempo grafana/tempo \
    --namespace kube-prometheus-stack \
    -f "$TMP_DIR/tempo-values.yaml"
kubectl apply -f "$TMP_DIR/tempo-ingress.yaml"

echo "✅ Deployment completed successfully!"