## Namespaces
KONG_NS="kong"
PORTAINER_NS="portainer"
APP_NS="searchengine"

## Install Filebeat
helm upgrade --install --namespace ${APP_NS} filebeat elastic/filebeat --version 7.17.3 --values ./elk/filebeat/values.yaml

## Install Logstash
helm upgrade --install --namespace ${APP_NS} logstash elastic/logstash --version 7.17.3 --values ./elk/logstash/values.yaml


## Install Elastic Search
helm upgrade --install --namespace ${APP_NS} elasticsearch elastic/elasticsearch --version 7.17.3 --values ./elk/elasticsearch/values.yaml
echo "Wait for elastic search pods to reach ready..."
kubectl wait --for=condition=ready pod -l app=elasticsearch-master -n ${APP_NS} --timeout=180s

## Install Kibana
helm upgrade --install --namespace ${APP_NS} kibana elastic/kibana --version 7.17.3 --values ./elk/kibana/values.yaml
echo "Wait for kibana pods to reach ready..."
kubectl wait --for=condition=ready pod -l app=kibana -n ${APP_NS} --timeout=180s

## get Kibana pod name
KIBANA_POD=$(kubectl get pods -n ${APP_NS} -l app=kibana -o jsonpath='{.items[0].metadata.name}')

## Setup es templates
kubectl exec ${KIBANA_POD} -n ${APP_NS} -- /bin/sh -c "`cat ./es-templates/websites_pipeline.sh`"
kubectl exec ${KIBANA_POD} -n ${APP_NS} -- /bin/sh -c "`cat ./es-templates/index_template_websites.sh`"

## Install Redis
helm upgrade --install --namespace ${APP_NS} redis --set persistence.storageClass=nfs-client,redis.replicas.persistence.storageClass=nfs-client bitnami/redis --set volumePermissions.enabled=true
echo "Wait for redis pods to reach ready..."
kubectl wait --for=condition=ready pod redis-master-0 -n ${APP_NS} --timeout=180s
kubectl wait --for=condition=ready pod redis-replicas-0 -n ${APP_NS} --timeout=180s

## Extract password
export REDIS_PASSWORD=$(kubectl get secret --namespace ${APP_NS} redis -o jsonpath="{.data.redis-password}" | base64 -d)

## Install Rabbitmq
helm upgrade --install --namespace ${APP_NS} rabbitmq bitnami/rabbitmq --version 11.14.4
echo "Wait for rabbitmq pods to reach ready..."
kubectl wait --for=condition=ready pod rabbitmq-0 -n ${APP_NS} --timeout=180s

## Export password
export RABBITMQ_PASSWORD=$(kubectl get secret --namespace ${APP_NS} rabbitmq -o jsonpath="{.data.rabbitmq-password}" | base64 -d)

## Replace .env
envsubst < web-crawler/.env.template > web-crawler/.env

## Wait for monitoring stack

echo "Wait for logstash pods to reach ready..."
kubectl wait --for=condition=ready pod -l app=logstash-logstash -n ${APP_NS} --timeout=180s

echo "Wait for filebeat pods to reach ready..."
kubectl wait --for=condition=ready pod -l app=filebeat-filebeat -n ${APP_NS} --timeout=180s