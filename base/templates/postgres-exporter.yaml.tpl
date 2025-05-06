apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres-exporter
  namespace: kube-prometheus-stack
  labels:
    app: postgres-exporter
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres-exporter
  template:
    metadata:
      labels:
        app: postgres-exporter
    spec:
      containers:
      - name: postgres-exporter
        image: quay.io/prometheuscommunity/postgres-exporter:latest
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "500m"
        env:
        - name: DATA_SOURCE_NAME
          valueFrom:
            secretKeyRef:
              name: postgres-exporter-secret
              key: DATA_SOURCE_NAME
        ports:
        - containerPort: 9187
          name: metrics
---
apiVersion: v1
kind: Service
metadata:
  name: postgres-exporter
  namespace: kube-prometheus-stack
  labels:
    app: postgres-exporter
spec:
  selector:
    app: postgres-exporter
  ports:
  - port: 9187
    targetPort: 9187
    name: metrics





# apiVersion: apps/v1
# kind: Deployment
# metadata:
#   name: postgres-exporter
#   namespace: kube-prometheus-stack
#   labels:
#     app: postgres-exporter
# spec:
#   replicas: 1
#   selector:
#     matchLabels:
#       app: postgres-exporter
#   template:
#     metadata:
#       labels:
#         app: postgres-exporter
#     spec:
#       containers:
#       - name: postgres-exporter
#         image: quay.io/prometheuscommunity/postgres-exporter:latest
#         resources:
#           requests:
#             memory: "128Mi"
#             cpu: "100m"
#           limits:
#             memory: "256Mi"
#             cpu: "500m"
#         env:
#         - name: DATA_SOURCE_NAME
#           valueFrom:
#             configMapKeyRef:
#               name: postgres-exporter-config
#               key: DATA_SOURCE_NAME
#         ports:
#         - containerPort: 9187
#           name: metrics
# ---
# apiVersion: v1
# kind: Service
# metadata:
#   name: postgres-exporter
#   namespace: kube-prometheus-stack
#   labels:
#     app: postgres-exporter
# spec:
#   selector:
#     app: postgres-exporter
#   ports:
#   - port: 9187
#     targetPort: 9187
#     name: metrics