## Namespaces
KONG_NS="kong"
PORTAINER_NS="portainer"
APP_NS="searchengine"

## Install Elastic Search
helm repo add elastic https://helm.elastic.co
helm repo update
helm upgrade --install --namespace ${APP_NS} elasticsearch elastic/elasticsearch --version 7.17.3 --values ./elk/elasticsearch/values.yaml
echo "Wait for elastic search pods to reach ready..."
kubectl wait --for=condition=ready pod -l app=elasticsearch-master -n ${APP_NS} --timeout=180s

## Install Kibana
helm upgrade --install --namespace ${APP_NS} kibana elastic/kibana --version 7.17.3 --values ./elk/kibana/values.yaml
echo "Wait for kibana pods to reach ready..."
kubectl wait --for=condition=ready pod -l app=kibana -n ${APP_NS} --timeout=180s

## Install Logstash
helm upgrade --install --namespace ${APP_NS} logstash elastic/logstash --version 7.17.3 --values ./elk/logstash/values.yaml
echo "Wait for logstash pods to reach ready..."
kubectl wait --for=condition=ready pod -l app=logstash-logstash -n ${APP_NS} --timeout=180s

## Install Filebeat
helm upgrade --install --namespace ${APP_NS} filebeat elastic/filebeat --version 7.17.3 --values ./elk/filebeat/values.yaml
echo "Wait for filebeat pods to reach ready..."
kubectl wait --for=condition=ready pod -l app=filebeat-filebeat -n ${APP_NS} --timeout=180s

## Get Filebeat pod name
FILEBEAT_POD=$(kubectl get pods -n ${APP_NS} -l app=filebeat-filebeat -o jsonpath='{.items[0].metadata.name}')

# ## Setup dashboards
kubectl exec -it ${FILEBEAT_POD} -n ${APP_NS} -- bash -c "filebeat setup --index-management -E output.logstash.enabled=false -E 'output.elasticsearch.hosts=["elasticsearch-master:9200"]' -E setup.ilm.overwrite=true"
kubectl exec -it ${FILEBEAT_POD} -n ${APP_NS} -- bash -c "filebeat setup --dashboards"

## Get Kibana pod name
KIBANA_POD=$(kubectl get pods -n ${APP_NS} -l app=kibana -o jsonpath='{.items[0].metadata.name}')

## Setup es templates
kubectl exec ${KIBANA_POD} -n ${APP_NS} -- /bin/sh -c "`cat ./es-templates/websites_pipeline.sh`"
kubectl exec ${KIBANA_POD} -n ${APP_NS} -- /bin/sh -c "`cat ./es-templates/index_template_websites.sh`"

## Install Redis
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm upgrade --install --namespace ${APP_NS} redis --set auth.password=morbius --set persistence.storageClass=nfs-client,redis.replicas.persistence.storageClass=nfs-client bitnami/redis --set volumePermissions.enabled=true --values redis/values.yaml
echo "Wait for redis pods to reach ready..."
kubectl wait --for=condition=ready pod redis-master-0 -n ${APP_NS} --timeout=180s
kubectl wait --for=condition=ready pod redis-replicas-0 -n ${APP_NS} --timeout=180s

## Extract password
export REDIS_PASSWORD=$(kubectl get secret --namespace ${APP_NS} redis -o jsonpath="{.data.redis-password}" | base64 -d)

## Install Rabbitmq
helm upgrade --install rabbitmq bitnami/rabbitmq --version 11.14.4
echo "Wait for rabbitmq pods to reach ready..."
kubectl wait --for=condition=ready pod rabbitmq-0 --timeout=180s

## Export password
export RABBITMQ_PASSWORD=$(kubectl get secret rabbitmq -o jsonpath="{.data.rabbitmq-password}" | base64 -d)

## Replace .env
envsubst < web-crawler/.env.template > web-crawler/.env
