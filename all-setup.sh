## Namespaces
KONG_NS="kong"
PORTAINER_NS="portainer"
APP_NS="searchengine"

## Search engine namespace
kubectl create namespace ${APP_NS}

## Install kong
kubectl create namespace ${KONG_NS}

kubectl create secret generic kong-enterprise-license --from-literal=license="'{}'" -n ${KONG_NS} --dry-run=client -o yaml | kubectl apply -f -

helm repo add kong https://charts.konghq.com
helm repo update
helm upgrade --install --namespace ${KONG_NS} minimal kong/kong --values kong/values.yaml

## Wait for kong pods
echo "Wait for kong pods to reach ready..."
kubectl wait --for=condition=ready pod -l app=minimal-kong -n ${KONG_NS}

## Extract Proxy IPs
HOST=$(kubectl get -o jsonpath="{.status.loadBalancer.ingress[0].hostname}" service -n ${KONG_NS} minimal-kong-proxy)
PORT=$(kubectl get svc --namespace ${KONG_NS} minimal-kong-proxy -o jsonpath='{.spec.ports[0].port}')

if [ -z ${HOST} ]; then HOST=localhost; PORT=8000; EMPTY_HOST=1; fi

PROXY_IP=${HOST}:${PORT}

echo "Proxy IP is ${PROXY_IP}"

## Setup ELK Infra
./elk.sh

## Install Portainer
helm repo add portainer https://portainer.github.io/k8s/
helm repo update
helm upgrade --install --create-namespace -n ${PORTAINER_NS} portainer portainer/portainer --version 1.0.41 --values portainer/values.yaml

## Create configmap with Proxy IP
kubectl create configmap proxy-ip-config -n ${APP_NS} --from-literal=PROXY_IP=${PROXY_IP}

## Create configmap with frontend needed hosts
kubectl create configmap frontend-config -n ${APP_NS} --from-env-file=./frontend/.env

## Create secret with auth credentials
kubectl create secret generic auth-secret -n ${APP_NS} --from-env-file=./auth/.env

## Create es interactor secret
kubectl create secret generic es-interactor-secret -n ${APP_NS} --from-env-file=./es-interactor/.env

## Create web crawler secret
kubectl create secret generic web-crawler-secret -n ${APP_NS} --from-env-file=./web-crawler/.env

## Install es interactor
kubectl apply -f ./es-interactor/deployment.yaml -n ${APP_NS}
kubectl apply -f ./es-interactor/service.yaml -n ${APP_NS}

## Wait for es interactor
echo "Wait for es interactor pods to reach ready..."
kubectl wait --for=condition=ready pod -l app=es-interactor -n ${APP_NS}

## Install web crawler
kubectl apply -f ./web-crawler/api.yaml -n ${APP_NS}
kubectl apply -f ./web-crawler/flower.yaml -n ${APP_NS}
kubectl apply -f ./web-crawler/worker.yaml -n ${APP_NS}

## Wait for web crawler
echo "Wait for web crawler pods to reach ready..."
kubectl wait --for=condition=ready pod -l app=web-crawler-api -n ${APP_NS}
kubectl wait --for=condition=ready pod -l app=web-crawler-flower -n ${APP_NS}
kubectl wait --for=condition=ready pod -l app=web-crawler-worker -n ${APP_NS}

## Install frontend
kubectl apply -f ./frontend/deployment.yaml -n ${APP_NS}
kubectl apply -f ./frontend/service.yaml -n ${APP_NS}
kubectl apply -f ./frontend/ingress.yaml -n ${APP_NS}

## Wait for frontend
echo "Wait for frontend pods to reach ready..."
kubectl wait --for=condition=ready pod -l app=frontend -n ${APP_NS}

## Install auth
kubectl apply -f ./auth/deployment.yaml -n ${APP_NS}
kubectl apply -f ./auth/service.yaml -n ${APP_NS}
kubectl apply -f ./auth/ingress.yaml -n ${APP_NS}

## Wait for auth
echo "Wait for auth pods to reach ready..."
kubectl wait --for=condition=ready pod -l app=auth -n ${APP_NS}

echo "Installation finished"

if [ -n ${EMPTY_HOST} ]; then
echo "Forward port: kubectl port-forward --namespace ${KONG_NS} svc/minimal-kong-proxy ${PORT}:80";
fi