#!/bin/bash
set -e

# Check if environment and cluster arguments are provided
if [ $# -lt 2 ]; then
    echo "Usage: $0  "
    echo "Example: $0 devops odoo"
    exit 1
fi

ENVIRONMENT=$1
CLUSTER=$2
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$BASE_DIR/environments/$ENVIRONMENT/$CLUSTER.env"

# Check if environment file exists
if [ ! -f "$ENV_FILE" ]; then
    echo "Environment file not found: $ENV_FILE"
    exit 1
fi

# Source the environment file
source "$ENV_FILE"

# Create temporary directory for rendered templates
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

# Function to render templates
render_template() {
    local template="$1"
    local output="$2"
    
    # Use envsubst to replace environment variables in the template
    envsubst < "$template" > "$output"
}

echo "Rendering templates for cleanup of $ENVIRONMENT - $CLUSTER..."

# Render templates for deletion
render_template "$BASE_DIR/templates/persistent-volume-claims.yaml.tpl" "$TMP_DIR/persistent-volume-claims.yaml"
render_template "$BASE_DIR/templates/persistent-volumes.yaml.tpl" "$TMP_DIR/persistent-volumes.yaml"
render_template "$BASE_DIR/templates/service-monitors.yaml.tpl" "$TMP_DIR/service-monitors.yaml"
render_template "$BASE_DIR/templates/postgres-exporter.yaml.tpl" "$TMP_DIR/postgres-exporter.yaml"
render_template "$BASE_DIR/templates/postgres-exporter-config.yaml.tpl" "$TMP_DIR/postgres-exporter-config.yaml"
render_template "$BASE_DIR/templates/otel-collector.yaml.tpl" "$TMP_DIR/otel-collector.yaml"
render_template "$BASE_DIR/templates/instrumentation.yaml.tpl" "$TMP_DIR/instrumentation.yaml"

# Uninstall Helm releases
echo "Uninstalling Tempo..."
helm uninstall tempo -n kube-prometheus-stack || true

echo "Uninstalling Loki Stack..."
helm uninstall loki-stack -n kube-prometheus-stack || true

echo "Uninstalling Prometheus Stack..."
helm uninstall prom-stack -n kube-prometheus-stack || true

# Delete Service Monitors
echo "Deleting Service Monitors..."
kubectl delete -f "$TMP_DIR/service-monitors.yaml" || true

# Delete Postgres Exporter
echo "Deleting Postgres Exporter..."
kubectl delete -f "$TMP_DIR/postgres-exporter.yaml" || true
kubectl delete -f "$TMP_DIR/postgres-exporter-config.yaml" || true

# Delete OpenTelemetry resources
echo "Deleting OpenTelemetry resources..."
kubectl delete -f "$TMP_DIR/instrumentation.yaml" || true
kubectl delete -f "$TMP_DIR/otel-collector.yaml" || true

# Delete PVCs
echo "Deleting Persistent Volume Claims..."
kubectl delete -f "$TMP_DIR/persistent-volume-claims.yaml" || true

# Delete PVs
echo "Deleting Persistent Volumes..."
kubectl delete -f "$TMP_DIR/persistent-volumes.yaml" || true

echo "Cleanup completed successfully!"