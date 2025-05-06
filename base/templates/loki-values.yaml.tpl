loki:
  ingress:
    enabled: true
    ingressClassName: custom-nginx
    annotations:
      cert-manager.io/cluster-issuer: letsencrypt-prod
      nginx.ingress.kubernetes.io/ssl-redirect: "true"
      nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
      nginx.ingress.kubernetes.io/backend-protocol: "HTTP"
    hosts:
      - host: ${ENV_NAME}-${CLUSTER_NAME}-loki.${DNS_DOMAIN}
        paths:
          - /
    tls:
      - hosts:
          - ${ENV_NAME}-${CLUSTER_NAME}-loki.${DNS_DOMAIN}
        secretName: ${ENV_NAME}-${CLUSTER_NAME}-loki-tls
  datasource:
    name: Logs
    uid: loki
    jsonData: '{"derivedFields":[{"datasourceUid":"tempo","matcherRegex":"\"(?:traceID|traceId|trace_id)\":\"(\\w+)\"","name":"TraceID","url":"$${__value.raw}","urlDisplayLabel":"View Trace"}]}'
  persistence:
    enabled: true
    volumeClaimTemplate:
      spec:
        storageClassName: sbs-default
    accessModes:
      - ReadWriteOnce
    size: ${LOKI_STORAGE_SIZE}
  config:
    compactor:
      retention_enabled: true
    limits_config:
      retention_period: 30d
      max_query_series: 2000
      max_streams_per_user: 0
    ruler:
      storage:
        type: local
        local:
          directory: /rules
      rule_path: /tmp/scratch
      external_url: https://monitoring.jips.io
      alertmanager_url: http://kube-prometheus-stack-alertmanager:9093
      ring:
        kvstore:
          store: "inmemory"
      enable_api: true
  volume_enabled: true
  alerting_groups:
    - name: traceback
      rules:
        - alert: stack_trace
          expr: |
            sum by (app) (count_over_time({app=~"cas-admin-front|casbo|crm-api-gw|members-bi|events|members-bi-front|members-service|events-ui"} | json | stack_trace != `` | __error__=`` [5m]) > 0)
          for: 3m
          labels:
            severity: error
            category: logs
          annotations:
            message: "loki has encountered errors"
  resources:
    requests:
      cpu: 100m
      memory: 512Mi
    limits:
      cpu: 250m
      memory: 1Gi
  logFormat: "json"
  logLevel: "info"

promtail:
  enabled: true
  config:
    clients:
      - url: http://loki-stack.kube-prometheus-stack.svc.cluster.local:3100/loki/api/v1/push
    snippets:
      extraRelabelConfigs:
        - source_labels: [__meta_kubernetes_pod_label_team]
          action: replace
          target_label: team
        - source_labels: [__meta_kubernetes_pod_label_environment]
          action: replace
          target_label: environment
        - source_labels: [__meta_kubernetes_namespace]
          action: replace
          target_label: namespace  # Add this to label logs by namespace
      pipelineStages:
        - cri: {}
        - match:
            selector: '{team="webteam"}'
            stages:
              - drop:
                  expression: "kube-probe/1.28"
                  drop_counter_reason: "chatty_healthcheck"
              - json:
                  expressions:
                    timestamp: '"@timestamp"'
                    logger: logger
                    level: level
                    thread: thread
                    message: message
                    traceID: traceID
                    stack_trace: stack_trace
              - labels:
                  level:
                  message:
                  traceID:
                  stack_trace:
              - timestamp:
                  format: RFC3339
                  source: timestamp
                  fallback_format: ["2006-01-02T15:04:05-07:00.000Z"]
              - multiline:
                  firstline: '^({"@timestamp"|Hibernate:)'
  resources:
    requests:
      cpu: 50m
      memory: 256Mi
    limits:
      cpu: 100m
      memory: 512Mi
  logFormat: "json"
  logLevel: "debug"

common:
  labels:
    team: "jips"
    env: "${ENV_NAME}"
    cluster: "${CLUSTER_NAME}"