## Install kong
kubectl create namespace kong
kubectl create secret generic kong-enterprise-license --from-literal=license="'{}'" -n kong --dry-run=client -o yaml | kubectl apply -f -

helm repo add kong https://charts.konghq.com
helm repo update
helm upgrade --install --namespace kong minimal kong/kong --values kong/values.yaml

## Wait for kong pods
echo "Wait for kong pod to reach ready..."
kubectl wait --for=condition=ready pod -l app=minimal-kong -n kong

## Extract Proxy IP
PROXY_IP=$(kubectl get -o jsonpath="{.status.loadBalancer.ingress[0].hostname}" service -n kong minimal-kong-proxy)

echo "Proxy IP is ${PROXY_IP}"

## Install Portainer
helm repo add portainer https://portainer.github.io/k8s/
helm repo update
helm upgrade --install --create-namespace -n portainer portainer portainer/portainer --values portainer/values.yaml

## Search engine namespace
kubectl create namespace searchengine

## Create configmap with Proxy IP
kubectl create configmap proxy-ip-config -n searchengine --from-literal=PROXY_IP=${PROXY_IP}

## Ceate secret with auth credentials
kubectl create secret generic auth-secret -n searchengine --from-env-file=./auth/.env

## Install frontend
kubectl apply -f ./frontend/deployment.yaml
kubectl apply -f ./frontend/service.yaml
kubectl apply -f ./frontend/ingress.yaml

## Install auth
kubectl apply -f ./auth/deployment.yaml
kubectl apply -f ./auth/service.yaml
kubectl apply -f ./auth/ingress.yaml

echo "Installation finished"