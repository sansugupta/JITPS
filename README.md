# Monitoring Stack Setup on POC Cluster (`poc**************s`)

## Overview

This document provides a comprehensive guide to the monitoring stack setup for the POC cluster (`po***************ps`), designed to monitor applications running in the `odoo`, `keycloak`, and `jips` namespaces. The stack leverages industry-standard tools such as Prometheus, Loki, Tempo, and OpenTelemetry to provide metrics collection, log aggregation, distributed tracing, and alerting capabilities. The deployment follows a dynamic provisioning approach for storage, ensuring scalability and ease of maintenance. The setup is automated using a Bash script (`deploy.sh`) and Helm charts, with configurations templated for flexibility across environments.

### Objectives
- Monitor system and application metrics for services in `odoo`, `keycloak`, and `jips` namespaces.
- Aggregate and query logs for debugging and auditing.
- Enable distributed tracing for performance analysis.
- Send alerts to Slack for critical issues.
- Automate deployment with a script-driven approach using Helm and Kubernetes.

---

## Architecture

The monitoring stack consists of several interconnected components deployed in the `kube-prometheus-stack` namespace. Below is an overview of the components, their roles, and how they interact:

### Components and Their Roles
1. **Prometheus (via `kube-prometheus-stack`)**:
   - **Role**: Metrics collection and storage.
   - **What It Does**: Scrapes metrics from applications and infrastructure components (e.g., Node Exporter, Postgres Exporter) using ServiceMonitors.
   - **What It Tracks**: CPU, memory, network usage, application-specific metrics (e.g., HTTP request rates), and Kubernetes cluster health.
   - **Integration**: Stores metrics in a time-series database, exposes them via HTTP endpoints, and forwards them to Alertmanager for alerting.

2. **Alertmanager**:
   - **Role**: Alerting and notification.
   - **What It Does**: Receives alerts from Prometheus based on predefined rules, deduplicates them, and sends notifications to Slack.
   - **What It Tracks**: Alerts for high CPU usage, memory pressure, pod crashes, etc.
   - **Integration**: Configured to send alerts to a Slack channel (`#monitoring`) via a webhook.

3. **Loki (via `loki-stack`)**:
   - **Role**: Log aggregation and querying.
   - **What It Does**: Collects logs from all pods in the monitored namespaces using Promtail, stores them, and provides a query interface.
   - **What It Tracks**: Application logs, Kubernetes events, and container logs, with labels for namespaces (`odoo`, `keycloak`, `jips`).
   - **Integration**: Logs are ingested via Promtail, stored in Loki, and can be queried via HTTP endpoints (e.g., `ht********************************************.io`).

4. **Promtail**:
   - **Role**: Log collection agent for Loki.
   - **What It Does**: Runs as a DaemonSet, scrapes logs from pods, processes them (e.g., parsing JSON logs, adding labels), and forwards them to Loki.
   - **What It Tracks**: Logs from containers, with pipeline stages for filtering (e.g., dropping noisy health check logs) and parsing.
   - **Integration**: Sends processed logs to Loki for storage.

5. **Tempo**:
   - **Role**: Distributed tracing.
   - **What It Does**: Collects traces via OTLP (OpenTelemetry Protocol), stores them, and provides a query interface for trace analysis.
   - **What It Tracks**: Request traces across services, including latency, errors, and dependencies.
   - **Integration**: Receives traces from OpenTelemetry Collector, accessible via `h******************************************io`.

6. **OpenTelemetry Operator and Collector**:
   - **Role**: Instrumentation and trace/log collection.
   - **What It Does**: The Operator manages OpenTelemetry Collectors, which collect traces, metrics, and logs via OTLP, process them, and export them to Loki, Tempo, and Prometheus.
   - **What It Tracks**: Application traces (e.g., HTTP request spans), metrics (e.g., request counts), and logs (e.g., error messages).
   - **Integration**: Forwards traces to Tempo, logs to Loki, and metrics to Prometheus.

7. **Postgres Exporter**:
   - **Role**: Database metrics collection.
   - **What It Does**: Scrapes metrics from a PostgreSQL database (at `1******************2`) and exposes them for Prometheus.
   - **What It Tracks**: Database performance metrics (e.g., query latency, connection counts).
   - **Integration**: Metrics are scraped by Prometheus via a ServiceMonitor.

8. **NGINX Ingress Controller**:
   - **Role**: Ingress management for external access.
   - **What It Does**: Routes external traffic to monitoring services (e.g., Prometheus, Loki, Tempo) using custom ingress rules.
   - **What It Tracks**: N/A (infrastructure component).
   - **Integration**: Secured with TLS via cert-manager and the `letsencrypt-prod` ClusterIssuer.

9. **Cert-Manager**:
   - **Role**: TLS certificate management.
   - **What It Does**: Automatically provisions and renews TLS certificates for Ingress resources using Let’s Encrypt.
   - **What It Tracks**: N/A (infrastructure component).
   - **Integration**: Provides certificates for secure access to monitoring endpoints (e.g., `de*************************************io`).

### Workflow and Data Flow
1. **Metrics Collection**:
   - Applications in `odoo`, `keycloak`, and `jips` namespaces expose metrics via HTTP endpoints.
   - OpenTelemetry Collector and Postgres Exporter collect application and database metrics.
   - Prometheus scrapes these metrics using ServiceMonitors, stores them, and evaluates alerting rules.
   - Alertmanager sends notifications to Slack for critical alerts.

2. **Log Aggregation**:
   - Promtail collects logs from pods in all namespaces, processes them (e.g., JSON parsing, labeling), and forwards them to Loki.
   - Loki stores logs and makes them queryable via its HTTP API.

3. **Distributed Tracing**:
   - Applications are instrumented with OpenTelemetry (via auto-instrumentation for Java and Python).
   - OpenTelemetry Collector receives traces via OTLP, processes them, and forwards them to Tempo.
   - Tempo stores traces and provides a query interface for debugging.

4. **External Access**:
   - NGINX Ingress Controller routes traffic to Prometheus, Loki, and Tempo using domain names (e.g., `de*****************************************.io`).
   - Cert-Manager ensures secure TLS connections.

---

## Implementation Details

### Environment Configuration
The deployment uses environment-specific configurations defined in `environments/dev/poc-************env`:
- `ENV_NAME="dev"`, `CLUSTER_NAME="poc-odooswfjips"`, `DNS_DOMAIN="jips.io"`.
- Storage sizes: `PROMETHEUS_STORAGE_SIZE="35Gi"`, `LOKI_STORAGE_SIZE="10Gi"`, `ALERTMANAGER_STORAGE_SIZE="2Gi"`, `TEMPO_STORAGE_SIZE="10Gi"`.
- Resource limits and requests for all components (e.g., Prometheus CPU: 100m-500m, Memory: 1.9Gi).
- Postgres Exporter credentials for database monitoring.
- Slack webhook for Alertmanager notifications.

### Dynamic Storage Provisioning
To simplify management and ensure scalability, we adopted a dynamic provisioning approach:
- **Prometheus**, **Loki**, **Alertmanager**, and **Tempo** use `volumeClaimTemplates` to dynamically provision Persistent Volume Claims (PVCs) using the `sbs-default` storage class on Scaleway.
- Example PVCs created:
  - `prometheus-prom-stack-kube-prometheus-prometheus-db-prometheus-prom-stack-kube-prometheus-prometheus-0` (35Gi)
  - `storage-loki-stack-0` (10Gi)
  - `alertmanager-prom-stack-kube-prometheus-alertmanager-0` (2Gi)
  - `storage-tempo-0` (10Gi)

### Deployment Script (`deploy.sh`)
The deployment is automated using `deploy.sh`, which performs the following steps:
1. **Load Environment Variables**: Sources the environment file (e.g., `environments/dev/poc-odooswfjips.env`).
2. **Render Templates**: Uses `sed` to replace placeholders in template files with environment variables.
3. **Create Namespace**: Ensures the `kube-prometheus-stack` namespace exists.
4. **Install NGINX Ingress Controller**: Deploys the controller with a custom ingress class (`custom-nginx`).
5. **Apply ClusterIssuer**: Sets up `letsencrypt-prod` for TLS certificates.
6. **Install Prometheus Stack**: Deploys `kube-prometheus-stack` with custom values from `prometheus-values.yaml`.
7. **Install OpenTelemetry Operator**: Deploys the operator and applies custom resources (`otel-collector.yaml`, `instrumentation.yaml`).
8. **Install Postgres Exporter**: Deploys the exporter with a secret for database credentials.
9. **Install ServiceMonitors**: Configures Prometheus to scrape metrics from OpenTelemetry Collector and Postgres Exporter.
10. **Install Loki Stack**: Deploys Loki and Promtail with custom values from `loki-values.yaml`.
11. **Install Tempo**: Deploys Tempo with custom values from `tempo-values.yaml` and applies an Ingress resource.

### Configuration Files

#### `prometheus-values.yaml`
- **Purpose**: Configures the `kube-prometheus-stack` chart.
- **Key Settings**:
  - Disables unnecessary components (e.g., `kubeEtcd`, `kubeControllerManager`).
  - Enables Prometheus features like `exemplar-storage`.
  - Configures dynamic storage for Prometheus and Alertmanager using `volumeClaimTemplate`.
  - Sets up Ingress for Prometheus (`dev******************************o`) with TLS.
  - Configures Alertmanager to send notifications to Slack, ignoring `InfoInhibitor` and `Watchdog` alerts.
  - Defines resource limits/requests for Prometheus, Alertmanager, and Node Exporter.

#### `loki-values.yaml`
- **Purpose**: Configures the `loki-stack` chart.
- **Key Settings**:
  - Enables Ingress for Loki (`dev*******************o`) with TLS.
  - Configures dynamic storage using `volumeClaimTemplate`.
  - Sets retention period to 30 days and enables compaction.
  - Configures Promtail to collect logs from all namespaces, parse JSON logs, and drop noisy health check logs.
  - Adds labels (`team`, `environment`, `namespace`) to logs for better querying.

#### `tempo-values.yaml`
- **Purpose**: Configures the `tempo` chart.
- **Key Settings**:
  - Enables metrics generation and forwards metrics to Prometheus.
  - Configures OTLP receivers for traces (ports 4317 for gRPC, 4318 for HTTP).
  - Uses dynamic storage via `volumeClaimTemplate`.
  - Defines resource limits/requests for Tempo.

#### `otel-collector.yaml`
- **Purpose**: Defines the OpenTelemetry Collector configuration.
- **Key Settings**:
  - Receives traces, metrics, and logs via OTLP.
  - Processes data (e.g., batching, memory limiting) and adds labels (`cluster`, `environment`).
  - Exports traces to Tempo, logs to Loki, and metrics to Prometheus.

#### `instrumentation.yaml`
- **Purpose**: Configures auto-instrumentation for applications.
- **Key Settings**:
  - Enables auto-instrumentation for Java and Python applications.
  - Forwards telemetry data to the OpenTelemetry Collector.

#### `postgres-exporter.yaml` and `postgres-exporter-secret.yml`
- **Purpose**: Deploys Postgres Exporter to monitor a PostgreSQL database.
- **Key Settings**:
  - Connects to the database at `17**************32` using credentials stored in a Secret.
  - Exposes metrics on port 9187 for Prometheus to scrape.

#### `service-monitors.yaml`
- **Purpose**: Defines ServiceMonitors for Prometheus to scrape metrics.
- **Key Settings**:
  - Monitors OpenTelemetry Collector and Postgres Exporter in the `kube-prometheus-stack`, `odoo`, `keycloak`, and `jips` namespaces.
  - Scrapes metrics every 30 seconds.

#### `tempo-ingress.yaml`
- **Purpose**: Configures Ingress for Tempo.
- **Key Settings**:
  - Routes traffic to `d********************io` with TLS enabled.

#### `cluster-issuer.yaml`
- **Purpose**: Sets up a ClusterIssuer for cert-manager.
- **Key Settings**:
  - Uses Let’s Encrypt to provision TLS certificates for Ingress resources.

---

## Monitoring and Tracing Details

### Metrics (Prometheus)
- **What’s Tracked**:
  - Node-level metrics (via Prometheus Node Exporter): CPU, memory, disk, and network usage.
  - Kubernetes cluster metrics: Pod status, API server performance.
  - Application metrics: HTTP request rates, error rates, latency (via OpenTelemetry Collector).
  - Database metrics: PostgreSQL query performance, connection counts (via Postgres Exporter).
- **Access**: Metrics are queryable at `https://***********************************.io`.

### Logs (Loki)
- **What’s Tracked**:
  - Container logs from all pods in `odoo`, `keycloak`, and `jips` namespaces.
  - Parsed JSON logs with fields like `level`, `message`, `traceID`, and `stack_trace`.
  - Labels: `namespace`, `team`, `environment`.
- **Access**: Logs are queryable at `https://dev-poc-odooswfjips-loki.jips.io`.

### Traces (Tempo)
- **What’s Tracked**:
  - Distributed traces for requests across services in `odoo`, `keycloak`, and `jips`.
  - Span data including latency, errors, and service dependencies.
- **Access**: Traces are queryable at `https://dev-poc-odooswfjips-tempo.jips.io`.

### Alerts (Alertmanager)
- **What’s Tracked**:
  - Alerts for critical conditions (e.g., high CPU usage, pod crashes).
  - Ignores informational alerts (`InfoInhibitor`, `Watchdog`).
- **Notifications**: Sent to the `#monitoring` Slack channel.

---

## Deployment Workflow

1. **Prerequisites**:
   - Kubernetes cluster (`poc-od*******`) with Helm installed.
   - Scaleway CSI driver for dynamic storage provisioning (`sbs-default` storage class).
   - Access to the `odoo`, `keycloak`, and `jips` namespaces.

2. **Clone the Repository**:
   ```bash
   git clone <repository-url>
   cd monitoring-setup-deployment
   ```

3. **Set Up Environment**:
   - Ensure the `environments/dev/poc-odooswfjips.env` file is configured with the correct values.

4. **Run the Deployment Script**:
   ```bash
   bash ./base/scripts/deploy.sh dev poc-odooswfjips
   ```

5. **Verify the Deployment**:
   - Check pod status:
     ```bash
     kubectl get pods -n kube-prometheus-stack
     ```


---

## Troubleshooting

- **Pod Not Running**:
  - Check pod events: `kubectl describe pod <pod-name> -n kube-prometheus-stack`.
  - Verify resource limits and storage availability.
- **Metrics/Logs/Traces Not Available**:
  - Ensure ServiceMonitors are correctly configured.
  - Check OpenTelemetry Collector logs: `kubectl logs -n kube-prometheus-stack -l app.kubernetes.io/name=otel-collector`.
- **Ingress Not Working**:
  - Verify the NGINX Ingress Controller pod is running.
  - Check certificate issuance: `kubectl describe certificate -n kube-prometheus-stack`.

---

## Conclusion

The monitoring stack on the `poc-odooswfjips` cluster provides a robust solution for observability, covering metrics, logs, traces, and alerts. The dynamic provisioning approach simplifies storage management, while the automated deployment script ensures consistency and repeatability. The stack is now fully operational, monitoring applications in the `odoo`, `keycloak`, and `jips` namespaces, with secure external access via Ingress and TLS.

For further assistance, contact the JIPS SRE Team - Sanskar Gupta (Sanskar.gupta@alyssum.global).
