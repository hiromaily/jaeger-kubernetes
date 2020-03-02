get-template:
	wget https://raw.githubusercontent.com/jaegertracing/jaeger-kubernetes/master/all-in-one/jaeger-all-in-one-template.yml
	wget https://raw.githubusercontent.com/jaegertracing/jaeger-kubernetes/master/jaeger-production-template.yml

# this is not needed
create-sc:
	kubectl apply -f k8s/sc/local_sc.yml

# $ k get sc
# NAME                 PROVISIONER          AGE
# hostpath (default)   docker.io/hostpath   38h
# localmac             docker.io/hostpath   3m6s

create-pv:
	kubectl apply -f k8s/pv/local_lib_pv.yml
	kubectl apply -f k8s/pv/local_log_pv.yml

create-pvc:
	kubectl apply -f k8s/pvc/local_lib_pvc.yml
	kubectl apply -f k8s/pvc/local_log_pvc.yml
	#kubectl apply -f k8s/pvc/local_pvc.yml
# $ k get pv
# NAME        STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
# local-pvc   Bound    pvc-eb5d09b5-2212-49fe-927f-3bf595f5043d   3Gi        RWO            localmac       5s

create-cassandra:
	kubectl apply -f k8s/cassandra/configmap.yml
	kubectl apply -f k8s/cassandra/cassandra.yml
# if status remains ContainerCreating, check command below
# $ kubectl describe pod/cassandra-0
# $ kubectl get events

#create-elasticsearch:
#	kubectl apply -f k8s/elasticsearch/configmap.yml
#	kubectl apply -f k8s/elasticsearch/elasticsearch.yml

create-dev-deployment:
	kubectl apply -f k8s/jaeger-all-in-one-template.yml

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

# After creating pods, deployment, check Status
#pod/jaeger-collector-55fd49db78-wvdmd   0/1     CrashLoopBackOff   4          2m38s
#pod/jaeger-query-576bd68cf-7p8zp        0/1     CrashLoopBackOff   4          2m38s
# it would take more than 3 minutes
check:
	kubectl get all

check-ui-url:
	kubectl get service jaeger-query
