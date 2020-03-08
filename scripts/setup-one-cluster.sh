#!/bin/sh

# create clusters
make setup-kind-jaeger-cluster

# create sc, pv, pvc
make init-resources
# create cassandra
make create-cassandra
# create jaeger production
make create-prod-deployment

# create apps
make create-apps

# create ingress
make create-ingress
