## Install kong
kubectl create namespace kong
kubectl create secret generic kong-enterprise-license --from-literal=license="'{}'" -n kong --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f https://raw.githubusercontent.com/Kong/kubernetes-ingress-controller/v2.9.0/deploy/single/all-in-one-dbless-k4k8s-enterprise.yaml

## Wait for kong pods
echo "Wait for proxy kong to reach ready..."
kubectl wait --for=condition=ready pod -l app=proxy-kong -n kong

echo "Wait for ingress kong to reach ready..."
kubectl wait --for=condition=ready pod -l app=ingress-kong -n kong

## Extract Proxy IP
PROXY_IP=$(kubectl get -o jsonpath="{.status.loadBalancer.ingress[0].hostname}" service -n kong kong-proxy)

echo "Proxy IP is ${PROXY_IP}"

## Install Portainer
helm upgrade --install --create-namespace -n portainer portainer portainer/portainer \
     --set enterpriseEdition.enabled=false \
     --set service.type=ClusterIP \
     --set ingress.enabled=true \
     --set ingress.ingressClassName=kong \
     --set ingress.hosts[0].paths[0].path="/portainer" \
     --set image.pullPolicy="IfNotPresent"

kubectl annotate ingress portainer konghq.com/strip-path=true -n portainer

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