
get-template:
	wget https://raw.githubusercontent.com/jaegertracing/jaeger-kubernetes/master/all-in-one/jaeger-all-in-one-template.yml
	wget https://raw.githubusercontent.com/jaegertracing/jaeger-kubernetes/master/jaeger-production-template.yml

###################################################
# For Ingress　Controller
###################################################
setup-ingress-for-mac:
	kubectl create namespace ingress-nginx
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.30.0/deploy/static/mandatory.yaml
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.30.0/deploy/static/provider/cloud-generic.yaml
	kubectl get all --namespace=ingress-nginx

remove-ingress-for-mac:
	kubectl -n ingress-nginx delete service ingress-nginx
	kubectl -n ingress-nginx delete deployment nginx-ingress-controller

###################################################
# For basic resources
###################################################
# For Storage Class
create-sc:
	kubectl apply -f k8s/sc/local_sc.yml

# For PersistentVolume
create-pv:
	kubectl apply -f k8s/pv/local_lib_pv.yml
	kubectl apply -f k8s/pv/local_log_pv.yml

# For PersistentVolumeClaim
create-pvc:
	kubectl apply -f k8s/pvc/local_lib_pvc.yml
	kubectl apply -f k8s/pvc/local_log_pvc.yml
	# wait until STATUS is Bound
	sh ./scripts/wait-pvc-completion.sh

init-resources: reset-disk create-sc create-pv create-pvc


###################################################
# For middleware
###################################################
# For Cassandra
create-cassandra:
	kubectl apply -f k8s/cassandra/configmap.yml
	kubectl apply -f k8s/cassandra/cassandra.yml
	#kubectl get job jaeger-cassandra-schema-job -o json | jq .status.succeeded
	# wait until JOB's Completions is 1
	sh ./scripts/wait-job-completion.sh

# if status remains ContainerCreating, check command below
# $ kubectl describe pod/cassandra-0
# $ kubectl get events

#create-elasticsearch:
#	kubectl apply -f k8s/elasticsearch/configmap.yml
#	kubectl apply -f k8s/elasticsearch/elasticsearch.yml

###################################################
# For jaeger components
###################################################
# For development for develoment 
create-dev-deployment:
	kubectl apply -f k8s/jaeger-all-in-one-template.yml

# For development for production
create-prod-deployment:
	kubectl apply -f k8s/jaeger-production-template.yml


create-prod-all: init-resources　create-cassandra create-prod-deployment 


###################################################
# For go-tracer apps
###################################################
create-apps:
	kubectl apply -f k8s/apps/configmap.yml
	#kubectl apply -f k8s/apps/ing.yml
	kubectl apply -f k8s/apps/deployment.yml

	#kubectl logs pod/app-config-68b86c96cf-nnzdb
	#kubectl delete ingress go-tracer

###################################################
# For Ingress Jaeger UI
###################################################
create-ingress:
	kubectl apply -f k8s/ing/local_ing.yml
	kubectl describe ingress jaeger-ingress
	# wait until Address is allocated

#kubectl get ingress jaeger-ingress -o jsonpath={.status.loadBalancer.ingress}
#kubectl get ingress jaeger-ingress -o json | jq .status.loadBalancer.ingress
# [
#   {
#     "hostname": "localhost"
#   }
# ]

###################################################
# remove
###################################################
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
	kubectl delete --all ing

reset-disk:
	rm -rf /tmp/cassandra
	mkdir -p /tmp/cassandra/logs
	mkdir -p /tmp/cassandra/libs

check:
	kubectl get all

# check-ui-url:
# 	kubectl get service jaeger-query

# jaeger-url:
# 	jaeger-ui.com
# go-tracer-url:
# 	go-tracer.com
