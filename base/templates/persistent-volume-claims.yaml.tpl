apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ${ENV_NAME}-${CLUSTER_NAME}-loki-pvc
  namespace: kube-prometheus-stack
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: ${LOKI_STORAGE_SIZE}
  volumeName: ${ENV_NAME}-${CLUSTER_NAME}-loki-pv
  volumeMode: Filesystem
  storageClassName: sbs-default
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ${ENV_NAME}-${CLUSTER_NAME}-prometheus-pvc
  namespace: kube-prometheus-stack
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: ${PROMETHEUS_STORAGE_SIZE}
  volumeName: ${ENV_NAME}-${CLUSTER_NAME}-prometheus-pv
  volumeMode: Filesystem
  storageClassName: sbs-default
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ${ENV_NAME}-${CLUSTER_NAME}-alertmanager-pvc
  namespace: kube-prometheus-stack
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: ${ALERTMANAGER_STORAGE_SIZE}
  volumeName: ${ENV_NAME}-${CLUSTER_NAME}-alertmanager-pv
  volumeMode: Filesystem
  storageClassName: sbs-default
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ${ENV_NAME}-${CLUSTER_NAME}-tempo-pvc
  namespace: kube-prometheus-stack
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: ${TEMPO_STORAGE_SIZE}
  volumeName: ${ENV_NAME}-${CLUSTER_NAME}-tempo-pv
  volumeMode: Filesystem
  storageClassName: sbs-default