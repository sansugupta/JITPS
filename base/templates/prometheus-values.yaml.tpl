defaultRules:
  rules:
    etcd: false
    windows: false
    kubeControllerManager: false
    kubeProxy: false
    kubeSchedulerAlerting: false
    kubelet: true
    kubeApiserverAvailability: true
    kubeApiserverBurnrate: true
    kubeApiserverHistogram: true
    kubeApiserverSlos: true

kubeEtcd:
  enabled: false
kubeControllerManager:
  enabled: false
kubeScheduler:
  enabled: false
kubeProxy:
  enabled: false

kube-state-metrics:
  resources:
    requests:
      cpu: 10m
      memory: 100Mi
    limits:
      cpu: 50m
      memory: 100Mi

prometheus:
  ingress:
    enabled: true
    ingressClassName: custom-nginx
    annotations:
      cert-manager.io/cluster-issuer: letsencrypt-prod
      nginx.ingress.kubernetes.io/ssl-redirect: "true"
      nginx.ingress.kubernetes.io/backend-protocol: "HTTP"
    hosts:
      - ${ENV_NAME}-${CLUSTER_NAME}-prometheus.${DNS_DOMAIN}
    tls:
      - hosts:
          - ${ENV_NAME}-${CLUSTER_NAME}-prometheus.${DNS_DOMAIN}
        secretName: ${ENV_NAME}-${CLUSTER_NAME}-prometheus-tls
  prometheusSpec:
    image:
      tag: "v2.48.1"
    ruleSelectorNilUsesHelmValues: false
    serviceMonitorSelectorNilUsesHelmValues: false
    podMonitorSelectorNilUsesHelmValues: false
    probeSelectorNilUsesHelmValues: false
    enableRemoteWriteReceiver: true
    tracingConfig:
      endpoint: tempo.kube-prometheus-stack.svc.cluster.local:4317
      insecure: true
    enableFeatures:
      - exemplar-storage
    storageSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: sbs-default
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: ${PROMETHEUS_STORAGE_SIZE}
    resources:
      requests:
        cpu: 100m
        memory: 1.9Gi
      limits:
        cpu: 500m
        memory: 1.9Gi

prometheus-node-exporter:
  resources:
    requests:
      cpu: 100m
      memory: 100Mi
    limits:
      cpu: 300m
      memory: 100Mi

alertmanager:
  service:
    type: NodePort
    nodePort: 30093
  config:
    route:
      routes:
        - receiver: 'slack'
          matchers:
            - alertname !~ "InfoInhibitor|Watchdog"
        - receiver: 'null'
          matchers:
            - alertname =~ "InfoInhibitor|Watchdog"
    receivers:
      - name: 'null'
      - name: 'slack'
        slack_configs:
          - api_url: '${SLACK_WEBHOOK_URL}'
            channel: '${SLACK_CHANNEL}'
            send_resolved: true
            title: '{{ range .Alerts }}{{ .Annotations.summary }}{{ end }}'
            text: '{{ range .Alerts }}*Description:* {{ .Annotations.description }}\n*Details:* {{ range .Labels.SortedPairs }}- {{ .Name }}: {{ .Value }}\n{{ end }}{{ end }}'
  alertmanagerSpec:
    storage:
      volumeClaimTemplate:
        spec:
          storageClassName: sbs-default
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: ${ALERTMANAGER_STORAGE_SIZE}
    resources:
      requests:
        cpu: 10m
        memory: 100Mi
      limits:
        cpu: 100m
        memory: 100Mi

grafana:
  enabled: false

prometheusOperator:
  enabled: true
  # image:
  #   tag: "v0.69.0"
  # resources:
  #   limits:
  #     cpu: 250m
  #     memory: 512Mi
  #   requests:
  #     cpu: 100m
  #     memory: 256Mi
  # extraArgs:
  #   - --web.listen-address=:8080
  #   - --web.enable-http2=false
crds:
  enabled: true

common:
  labels:
    team: "jips"
    env: "${ENV_NAME}"
    cluster: "${CLUSTER_NAME}"