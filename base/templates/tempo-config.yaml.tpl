cat <<EOF | kubectl apply -n kube-prometheus-stack -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: tempo-query-config
data:
  tempo-query.yaml: |
    query:
      http_api_prefix: ""
      http_port: 16686
    tempo:
      server: "tempo:3100"
EOF