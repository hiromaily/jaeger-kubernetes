get-template:
	wget https://raw.githubusercontent.com/jaegertracing/jaeger-kubernetes/master/all-in-one/jaeger-all-in-one-template.yml
	wget https://raw.githubusercontent.com/jaegertracing/jaeger-kubernetes/master/jaeger-production-template.yml

# For Ingress　Controller
setup-ingress-for-mac:
	kubectl create namespace ingress-nginx
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.30.0/deploy/static/mandatory.yaml
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.30.0/deploy/static/provider/cloud-generic.yaml

remove-ingress-for-mac:
	kubectl -n ingress-nginx delete service ingress-nginx
	kubectl -n ingress-nginx delete deployment nginx-ingress-controller

# For Ingress
	kubectl apply -f k8s/ing/local_ing.yml
	kubectl describe ingress hiromaily-ingress
	kubectl get all --namespace=ingress-nginx

# For Storage Class
create-sc:
	kubectl apply -f k8s/sc/local_sc.yml
# $ k get sc
# NAME                 PROVISIONER          AGE
# hostpath (default)   docker.io/hostpath   38h
# localmac             docker.io/hostpath   3m6s

# For PersistentVolume
create-pv:
	kubectl apply -f k8s/pv/local_lib_pv.yml
	kubectl apply -f k8s/pv/local_log_pv.yml

# For PersistentVolumeClaim
create-pvc:
	kubectl apply -f k8s/pvc/local_lib_pvc.yml
	kubectl apply -f k8s/pvc/local_log_pvc.yml
	#kubectl apply -f k8s/pvc/local_pvc.yml
# $ k get pv
# NAME        STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
# local-pvc   Bound    pvc-eb5d09b5-2212-49fe-927f-3bf595f5043d   3Gi        RWO            localmac       5s

# For Cassandra
create-cassandra:
	kubectl apply -f k8s/cassandra/configmap.yml
	kubectl apply -f k8s/cassandra/cassandra.yml
# if status remains ContainerCreating, check command below
# $ kubectl describe pod/cassandra-0
# $ kubectl get events

#create-elasticsearch:
#	kubectl apply -f k8s/elasticsearch/configmap.yml
#	kubectl apply -f k8s/elasticsearch/elasticsearch.yml

# For development for develoment 
create-dev-deployment:
	kubectl apply -f k8s/jaeger-all-in-one-template.yml

# For development for production
create-prod-deployment:
	kubectl apply -f k8s/jaeger-production-template.yml

init-resources: reset-disk create-sc create-pv create-pvc
	#kubectl get job jaeger-cassandra-schema-job -o json | jq .status.succeeded
	#null

create-prod-all: create-cassandra create-prod-deployment 

remove-all:
	kubectl delete --all jobs
	kubectl delete --all services
	kubectl delete --all daemonset
	kubectl delete --all statefulset
	kubectl delete --all deployments
	kubectl delete --all cm
	kubectl delete --all pvc
	kubectl delete --all pv
	kubectl delete --all sc

reset-disk:
	rm -rf /tmp/cassandra
	mkdir -p /tmp/cassandra/logs
	mkdir -p /tmp/cassandra/libs

check:
	kubectl get all

check-ui-url:
	kubectl get service jaeger-query
