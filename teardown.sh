## Namespaces
KONG_NS="kong"
PORTAINER_NS="portainer"
APP_NS="searchengine"

## Uninstall kong resources
helm uninstall minimal -n ${KONG_NS}
kubectl delete namespace ${KONG_NS}

## Uninstall portainer resources
helm uninstall portainer -n ${PORTAINER_NS}
kubectl delete namespace ${PORTAINER_NS}

## Remove configmaps
kubectl delete configmap proxy-ip-config -n ${APP_NS}

## Remove secrets
kubectl delete secret auth-secret -n ${APP_NS}

## Remove search engine resources
kubectl delete -f ./frontend/deployment.yaml -n ${APP_NS}
kubectl delete -f ./frontend/service.yaml -n ${APP_NS}
kubectl delete -f ./frontend/ingress.yaml -n ${APP_NS}

kubectl delete -f ./auth/deployment.yaml -n ${APP_NS}
kubectl delete -f ./auth/service.yaml -n ${APP_NS}
kubectl delete -f ./auth/ingress.yaml -n ${APP_NS}

kubectl delete namespace ${APP_NS}