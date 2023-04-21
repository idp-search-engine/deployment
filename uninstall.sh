## Uninstall kong resources
helm uninstall minimal -n kong
kubectl delete namespace kong

## Uninstall portainer resources
helm uninstall portainer -n portainer
kubectl delete namespace portainer

## Remove configmaps
kubectl delete configmap proxy-ip-config -n searchengine

## Remove secrets
kubectl delete secret auth-secret -n searchengine

## Remove search engine resources
kubectl delete -f ./frontend/deployment.yaml
kubectl delete -f ./frontend/service.yaml
kubectl delete -f ./frontend/ingress.yaml

kubectl delete -f ./auth/deployment.yaml
kubectl delete -f ./auth/service.yaml
kubectl delete -f ./auth/ingress.yaml

kubectl delete namespace searchengine