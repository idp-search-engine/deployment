if [ -nz ${EMPTY_HOST} ]; then
echo "Forward port: kubectl port-forward --namespace ${KONG_NS} svc/minimal-kong-proxy ${PORT}:80";
fi