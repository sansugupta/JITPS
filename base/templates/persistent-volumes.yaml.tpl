apiVersion: v1
kind: PersistentVolume
metadata:
  name: ${ENV_NAME}-${CLUSTER_NAME}-loki-pv
  namespace: kube-prometheus-stack
spec:
  capacity:
    storage: ${LOKI_STORAGE_SIZE}
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: sbs-default
  volumeMode: Filesystem
  csi:
    driver: csi.scaleway.com
    volumeHandle: ${ENV_NAME}-${CLUSTER_NAME}-loki-pv
    volumeAttributes:
      storage: block
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: ${ENV_NAME}-${CLUSTER_NAME}-prometheus-pv
  namespace: kube-prometheus-stack
spec:
  capacity:
    storage: ${PROMETHEUS_STORAGE_SIZE}
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: sbs-default
  volumeMode: Filesystem
  csi:
    driver: csi.scaleway.com
    volumeHandle: ${ENV_NAME}-${CLUSTER_NAME}-prometheus-pv
    volumeAttributes:
      storage: block
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: ${ENV_NAME}-${CLUSTER_NAME}-alertmanager-pv
  namespace: kube-prometheus-stack
spec:
  capacity:
    storage: ${ALERTMANAGER_STORAGE_SIZE}
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: sbs-default
  volumeMode: Filesystem
  csi:
    driver: csi.scaleway.com
    volumeHandle: ${ENV_NAME}-${CLUSTER_NAME}-alertmanager-pv
    volumeAttributes:
      storage: block
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: ${ENV_NAME}-${CLUSTER_NAME}-tempo-pv
  namespace: kube-prometheus-stack
spec:
  capacity:
    storage: ${TEMPO_STORAGE_SIZE}
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: sbs-default
  volumeMode: Filesystem
  csi:
    driver: csi.scaleway.com
    volumeHandle: ${ENV_NAME}-${CLUSTER_NAME}-tempo-pv
    volumeAttributes:
      storage: block