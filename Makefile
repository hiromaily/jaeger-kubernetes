
get-template:
	wget https://raw.githubusercontent.com/jaegertracing/jaeger-kubernetes/master/all-in-one/jaeger-all-in-one-template.yml
	wget https://raw.githubusercontent.com/jaegertracing/jaeger-kubernetes/master/jaeger-production-template.yml

kubernetes-version:
	kubectl get nodes

###################################################
# For Kind settings
###################################################
install-kind:
	brew install kind

# read [document](https://kind.sigs.k8s.io/docs/user/ingress/#create-cluster)
setup-kind-jaeger-cluster:
	# Create Cluster 
	kind create cluster --name jaeger --config k8s/kind/jaeger/ingress-cluster.yml
	# Contour
	kubectl apply -f https://projectcontour.io/quickstart/contour.yaml
	kubectl patch daemonsets -n projectcontour envoy -p '{"spec":{"template":{"spec":{"nodeSelector":{"ingress-ready":"true"},"tolerations":[{"key":"node-role.kubernetes.io/master","operator":"Equal","effect":"NoSchedule"}]}}}}'
	# Ingress NGINX
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.30.0/deploy/static/mandatory.yaml
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.30.0/deploy/static/provider/baremetal/service-nodeport.yaml
	#  hostPort should be changed for your preference
	kubectl patch deployments -n ingress-nginx nginx-ingress-controller -p '{"spec":{"template":{"spec":{"containers":[{"name":"nginx-ingress-controller","ports":[{"containerPort":80,"hostPort":8080},{"containerPort":443,"hostPort":8443}]}],"nodeSelector":{"ingress-ready":"true"},"tolerations":[{"key":"node-role.kubernetes.io/master","operator":"Equal","effect":"NoSchedule"}]}}}}'
	# Sample app
	#kubectl apply -f https://kind.sigs.k8s.io/examples/ingress/usage.yaml

	#kubectl cluster-info --context kind-jaeger
	#kubectl config --kubeconfig=kind-jaeger view --minify
	#kubectl get -n ingress-nginx all

setup-kind-apps-cluster:
	# Create Cluster 
	kind create cluster --name apps --config k8s/kind/apps/ingress-cluster.yml
	# Contour
	kubectl apply -f https://projectcontour.io/quickstart/contour.yaml
	kubectl patch daemonsets -n projectcontour envoy -p '{"spec":{"template":{"spec":{"nodeSelector":{"ingress-ready":"true"},"tolerations":[{"key":"node-role.kubernetes.io/master","operator":"Equal","effect":"NoSchedule"}]}}}}'
	# Ingress NGINX
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.30.0/deploy/static/mandatory.yaml
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.30.0/deploy/static/provider/baremetal/service-nodeport.yaml
	#  hostPort should be changed for your preference
	kubectl patch deployments -n ingress-nginx nginx-ingress-controller -p '{"spec":{"template":{"spec":{"containers":[{"name":"nginx-ingress-controller","ports":[{"containerPort":80,"hostPort":8081},{"containerPort":443,"hostPort":8444}]}],"nodeSelector":{"ingress-ready":"true"},"tolerations":[{"key":"node-role.kubernetes.io/master","operator":"Equal","effect":"NoSchedule"}]}}}}'


remove-kind-cluster:
	kind delete cluster --name apps
	kind delete cluster --name jaeger

###################################################
# For Ingress　Controller / Not for Kind environment
###################################################
setup-ingress-for-mac:
	kubectl create namespace ingress-nginx
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.30.0/deploy/static/mandatory.yaml
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.30.0/deploy/static/provider/cloud-generic.yaml
	kubectl get all --namespace=ingress-nginx

remove-ingress-for-mac:
	kubectl -n ingress-nginx delete service ingress-nginx
	kubectl -n ingress-nginx delete deployment nginx-ingress-controller
	#kubectl delete all --namespace=ingress-nginx --all

###################################################
# For jaeger basic resources
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
# For jaeger middleware
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
#create-dev-deployment:
#	kubectl apply -f k8s/jaeger-all-in-one-template.yml

# For development for production
create-prod-deployment:
	kubectl apply -f k8s/jaeger-production-template.yml


create-prod-all: init-resources create-cassandra create-prod-deployment 


###################################################
# For go-tracer apps in apps cluster
###################################################
create-apps:
	kubectl apply -f k8s/apps/configmap.yml
	#kubectl apply -f k8s/apps/ing.yml
	kubectl apply -f k8s/apps/deployment.yml

	#kubectl logs pod/app-config-68b86c96cf-nnzdb
	#kubectl delete ingress go-tracer

create-apps-multi-cluster:
	kubectl apply -f k8s/apps/configmap_cluster.yml
	kubectl apply -f k8s/apps/deployment.yml

###################################################
# For jaeger Ingress Jaeger UI
###################################################
# for single cluster
create-ingress:
	kubectl apply -f k8s/ing/local_ing.yml
	kubectl describe ingress jaeger-ingress
	# wait until Address is allocated

# for multiple cluster / for jaeger-ui in jaeger cluster
create-jaeger-ing:
	kubectl apply -f k8s/ing/jaegerquery_ing.yml

#http://jaeger-ui.com:8080/

# for multiple cluster / for go-tracer in app cluster
create-go-tracer-ing:
	kubectl apply -f k8s/ing/go_tracer_ing.yml

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

	#kubectl delete all --namespace=ingress-nginx --all
	#kubectl delete all --all

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
