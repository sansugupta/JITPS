tempo:
  metricsGenerator:
    enabled: true
    remoteWriteUrl: "http://kube-prometheus-stack-prometheus:9090/api/v1/write"

  resources:
    requests:
      cpu: 100m
      memory: 512Mi
    limits:
      cpu: 200m
      memory: 1Gi

  storage:
    trace:
      backend: local
      local:
        path: /var/tempo/traces

  # Configure OTLP receivers
  receivers:
    otlp:
      protocols:
        grpc:
          endpoint: "0.0.0.0:4317"
        http:
          endpoint: "0.0.0.0:4318"

persistence:
    enabled: true
    volumeClaimTemplate:
      spec:
        storageClassName: sbs-default
        accessModes: ["ReadWriteOnce"]
        resources:
          requests:
            storage: ${TEMPO_STORAGE_SIZE}
service:
  type: ClusterIP
  annotations: {}





# tempo:
#   metricsGenerator:
#     enabled: true
#     remoteWriteUrl: "http://kube-prometheus-stack-prometheus:9090/api/v1/write"
  
#   resources:
#     requests:
#       cpu: 100m
#       memory: 512Mi
#     limits:
#       cpu: 200m
#       memory: 1Gi
  
#   storage:
#     trace:
#       backend: local
#       local:
#         path: /var/tempo/traces
  
#   # Configure OTLP receivers
#   receivers:
#     otlp:
#       protocols:
#         grpc:
#           endpoint: "0.0.0.0:4317"
#         http:
#           endpoint: "0.0.0.0:4318"

# persistence:
#   enabled: true
#   # existingClaim: ${ENV_NAME}-${CLUSTER_NAME}-tempo-pvc
#   existingClaim: devops-sre-tempo-pvc

# service:
#   type: ClusterIP
#   annotations: {}

# # Enable tempo-query component which has ingress support
# tempoQuery:
#   enabled: false
#   # service:
#   #   enabled: true
#   #   type: ClusterIP
#   #   port: 16686
#   #   targetPort: 16686
#   #   name: tempo-query
#   # tempo:
#   #   backend: tempo:3100
#   # Configure ingress for the tempo-query component
#   ingress:
#     enabled: true
#     ingressClassName: nginx
#     annotations:
#       cert-manager.io/cluster-issuer: letsencrypt-prod
#       nginx.ingress.kubernetes.io/ssl-redirect: "true"
#       nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
#       nginx.ingress.kubernetes.io/backend-protocol: "HTTP"
#     paths:
#       - path: /
#         pathType: Prefix
#         backend:
#           service: 
#             name: tempo
#             port:
#               number: 3100
#       hosts:
#         # - ${ENV_NAME}-${CLUSTER_NAME}-tempo.${DNS_DOMAIN}
#         - devops-sre-tempo.jips.io
#       tls:
#         - secretName: devops-sre-tempo-tls
#           # secretName: ${ENV_NAME}-${CLUSTER_NAME}-tempo-tls
#           hosts:
#             # - ${ENV_NAME}-${CLUSTER_NAME}-tempo.${DNS_DOMAIN}
#             - devops-sre-tempo.jips.io