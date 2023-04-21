## Uninstall kong resources
kubectl delete -f https://raw.githubusercontent.com/Kong/kubernetes-ingress-controller/v2.9.0/deploy/single/all-in-one-dbless-k4k8s-enterprise.yaml

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

kubectl apply -f ./auth/deployment.yaml
kubectl apply -f ./auth/service.yaml
kubectl apply -f ./auth/ingress.yaml

kubectl delete namespace searchengine