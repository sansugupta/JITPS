apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: tempo
  namespace: kube-prometheus-stack
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    nginx.ingress.kubernetes.io/backend-protocol: "HTTP"
spec:
  ingressClassName: custom-nginx
  tls:
  - hosts:
    - ${ENV_NAME}-${CLUSTER_NAME}-tempo.${DNS_DOMAIN}
    secretName: ${ENV_NAME}-${CLUSTER_NAME}-tempo-tls
  rules:
  - host: ${ENV_NAME}-${CLUSTER_NAME}-tempo.${DNS_DOMAIN}
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: tempo
            port:
              number: 3100 