#!/bin/sh

# create clusters
make setup-kind-jaeger-cluster
make setup-kind-apps-cluster

# change context to jaeger
kubectl config use-context kind-jaeger

# create sc, pv, pvc
make init-resources
# create cassandra
make create-cassandra
# create jaeger production
make create-prod-deployment
# create ingress
make create-jaeger-ing

# change context to apps
kubectl config use-context kind-apps

# create apps # FIXME: interconnection among different cluster
#make create-apps
# create ingress
#make create-go-tracer-ing
