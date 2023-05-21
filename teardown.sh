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

## Remove elk
helm uninstall elasticsearch -n ${APP_NS}
kubectl delete pvc elasticsearch-master-elasticsearch-master-0 -n ${APP_NS}
kubectl delete pvc elasticsearch-master-elasticsearch-master-1 -n ${APP_NS}
kubectl delete pvc elasticsearch-master-elasticsearch-master-2 -n ${APP_NS}

helm uninstall kibana -n ${APP_NS}
helm uninstall logstash -n ${APP_NS}
helm uninstall filebeat -n ${APP_NS}

## Remove Rabbitmq
helm uninstall rabbitmq
kubectl delete pvc  data-rabbitmq-0

## Remove Redis
helm uninstall redis -n ${APP_NS}

## Remove secrets
kubectl delete secret auth-secret -n ${APP_NS}
kubectl delete secret web-crawler-secret -n ${APP_NS}
kubectl delete secret es-interactor-secret -n ${APP_NS}

## Remove search engine resources
kubectl delete -f ./frontend/deployment.yaml -n ${APP_NS}
kubectl delete -f ./frontend/service.yaml -n ${APP_NS}
kubectl delete -f ./frontend/ingress.yaml -n ${APP_NS}

kubectl delete -f ./auth/deployment.yaml -n ${APP_NS}
kubectl delete -f ./auth/service.yaml -n ${APP_NS}
kubectl delete -f ./auth/ingress.yaml -n ${APP_NS}

kubectl delete -f ./es-interactor/deployment.yaml -n ${APP_NS}
kubectl delete -f ./es-interactor/service.yaml -n ${APP_NS}

kubectl delete -f ./web-crawler/api.yaml -n ${APP_NS}
kubectl delete -f ./web-crawler/flower.yaml -n ${APP_NS}
kubectl delete -f ./web-crawler/worker.yaml -n ${APP_NS}

kubectl delete namespace ${APP_NS}