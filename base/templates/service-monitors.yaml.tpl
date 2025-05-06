apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: otel-collector
  namespace: kube-prometheus-stack
  labels:
    env: ${ENV_NAME}
    cluster: ${CLUSTER_NAME}
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: otel-collector
  namespaceSelector:
    matchNames:
      - kube-prometheus-stack
      - odoo
      - keycloak
      - jips
  endpoints:
    - port: metrics
      interval: 30s

---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: postgres-exporter
  namespace: kube-prometheus-stack
  labels:
    env: ${ENV_NAME}
    cluster: ${CLUSTER_NAME}
spec:
  selector:
    matchLabels:
      app: postgres-exporter
  namespaceSelector:
    matchNames:
      - kube-prometheus-stack
      - odoo
      - keycloak
      - jips
  endpoints:
    - port: metrics
      interval: 30s
      path: /metrics