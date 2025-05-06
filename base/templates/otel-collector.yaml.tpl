apiVersion: opentelemetry.io/v1beta1
kind: OpenTelemetryCollector
metadata:
  name: otel-collector
  namespace: kube-prometheus-stack
  finalizers: null
spec:
  image: otel/opentelemetry-collector-contrib:0.91.0
  mode: deployment
  resources:
    requests:
      cpu: "100m"
      memory: "512Mi"
    limits:
      cpu: "500m"
      memory: "1Gi"
  config:
    receivers:
      otlp:
        protocols:
          grpc:
            endpoint: "0.0.0.0:4317"
          http:
            endpoint: "0.0.0.0:4318"
    processors:
      batch: {}
      memory_limiter:
        check_interval: 1s
        limit_mib: 400
        spike_limit_mib: 100
      resource:
        attributes:
          - key: cluster
            value: "${CLUSTER_NAME}"  # e.g., odooswfjips
            action: insert
          - key: environment
            value: "${ENV_NAME}"  # e.g., poc
            action: insert
    exporters:
      prometheus:
        endpoint: "0.0.0.0:8889"
        namespace: "${ENV_NAME}-${CLUSTER_NAME}"  # e.g., poc-odooswfjips
      loki:
        endpoint: http://loki-stack.kube-prometheus-stack.svc.cluster.local:3100/loki/api/v1/push
      otlp/tempo:
        endpoint: tempo:4317
        tls:
          insecure: true
      logging:
        loglevel: debug
    service:
      pipelines:
        traces:
          receivers:
            - otlp
          processors:
            - memory_limiter
            - batch
          exporters:
            - otlp/tempo
            - logging
        metrics:
          receivers:
            - otlp
          processors:
            - memory_limiter
            - batch
          exporters:
            - prometheus
        logs:
          receivers:
            - otlp
          processors:
            - memory_limiter
            - batch
            - resource  # Add the resource processor to the logs pipeline
          exporters:
            - loki
      telemetry:
        logs:
          level: "debug"