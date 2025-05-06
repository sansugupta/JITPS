apiVersion: v1
kind: Secret
metadata:
  name: postgres-exporter-secret
  namespace: kube-prometheus-stack
type: Opaque
stringData:
  DATA_SOURCE_NAME: "postgresql://root:RHdWm@t1Td8sKroH@172.16.16.12:5432/rdb?sslmode=disable"