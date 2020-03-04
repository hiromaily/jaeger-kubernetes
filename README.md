# jaeger_kubernetes

Jaeger configration on Kubernetes

- [Jaeger Getting Started](https://www.jaegertracing.io/docs/1.17/getting-started/)
- [Jaeger Kubernetes Templates](https://github.com/jaegertracing/jaeger-kubernetes)
- [Jaeger Releases](https://github.com/jaegertracing/jaeger/releases)
- [Jaeger Docker Images](https://hub.docker.com/r/jaegertracing/all-in-one/tags)
- [Jaeger Operator](https://operatorhub.io/operator/jaeger)

## About Jaeger

Jaeger, inspired by Dapper and OpenZipkin, is a distributed tracing system released as open source by Uber Technologies. It is used for monitoring and troubleshooting microservices-based distributed systems, including:

- Distributed context propagation
- Distributed transaction monitoring
- Root cause analysis
- Service dependency analysis
- Performance / latency optimization

![Architecture](https://github.com/hiromaily/jaeger_kubernetes/raw/master/images/architecture-v1.png)

## Get kubernetes template

1. create StorageClass

```
kubectl apply -f k8s/sc/local_sc.yml
```

2. create PersistentVolume (required if it runs on local)

```
kubectl apply -f k8s/pv/local_lib_pv.yml
kubectl apply -f k8s/pv/local_log_pv.yml
```

3. create PersistentVolumeClaim  
   should wait until STATUS is Bound

```
kubectl apply -f k8s/pvc/local_lib_pvc.yml
kubectl apply -f k8s/pvc/local_log_pvc.yml
```

4. create StatefulSet, ConfigMap for Cassandra

```
kubectl apply -f k8s/cassandra/configmap.yml
kubectl apply -f k8s/cassandra/cassandra.yml
```

5-1. create Jaeger deployment for development use by all in one model

```
kubectl apply -f k8s/jaeger-all-in-one-template.yml
```

5-2. create Jaeger deployment for production use

```
kubectl apply -f k8s/cassandra/configmap.yml
kubectl apply -f k8s/cassandra/cassandra.yml
kubectl apply -f k8s/jaeger-production-template.yml
```

6. create sample apps for storing logs

```
kubectl apply -f k8s/apps/configmap.yml
kubectl apply -f k8s/apps/deployment.yml
```

7. create ingress

```
kubectl apply -f k8s/ing/local_ing.yml
```

## Manifest

### In jaeger-all-in-one-template.yml

- [Deployment] name:jaeger
- [Service] name:jaeger-query
- [Service] name:jaeger-collector
- [Service] name:jaeger-agent
- [Service] name:zipkin

### In jaeger-production-template.yml

- [Deployment] name:jaeger-collector
- [Service] name:jaeger-collector
- [Service] name:zipkin
- [Deployment] name:jaeger-query
- [Service] name:jaeger-query
- [DaemonSet] name:jaeger-agent

### In cassandra/configmap.yml

- [ConfigMap] name:jaeger-configuration

### In cassandra/cassandra.yml

- [Service] name:cassandra
- [StatefulSet] name:cassandra
- [Job] name:jaeger-cassandra-schema-job

### In elasticsearch/elasticsearch.yml

- [Service] name:elasticsearch
- [StatefulSet] name:elasticsearch

## Structures

jaeger-production-template.yml with cassandra.yml

```
NAME                                    READY   STATUS      RESTARTS   AGE
pod/cassandra-0                         1/1     Running     0          6m5s
pod/cassandra-1                         1/1     Running     0          5m59s
pod/cassandra-2                         1/1     Running     1          5m55s
pod/jaeger-agent-qvml8                  1/1     Running     0          6m3s
pod/jaeger-cassandra-schema-job-pvpv9   0/1     Completed   0          6m5s
pod/jaeger-collector-55fd49db78-xd8tv   1/1     Running     4          6m5s
pod/jaeger-query-576bd68cf-9fdft        1/1     Running     4          6m4s

NAME                       TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)                                        AGE
service/cassandra          ClusterIP      None             <none>        7000/TCP,7001/TCP,7199/TCP,9042/TCP,9160/TCP   6m6s
service/jaeger-collector   ClusterIP      10.98.7.49       <none>        14267/TCP,14268/TCP,9411/TCP                   6m5s
service/jaeger-query       LoadBalancer   10.107.224.164   localhost     80:31550/TCP                                   6m3s
service/kubernetes         ClusterIP      10.96.0.1        <none>        443/TCP                                        6m21s
service/zipkin             ClusterIP      10.102.180.103   <none>        9411/TCP                                       6m4s

NAME                          DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
daemonset.apps/jaeger-agent   1         1         1       1            1           <none>          6m3s

NAME                               READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/jaeger-collector   1/1     1            1           6m5s
deployment.apps/jaeger-query       1/1     1            1           6m4s

NAME                                          DESIRED   CURRENT   READY   AGE
replicaset.apps/jaeger-collector-55fd49db78   1         1         1       6m5s
replicaset.apps/jaeger-query-576bd68cf        1         1         1       6m4s

NAME                         READY   AGE
statefulset.apps/cassandra   3/3     6m5s

NAME                                    COMPLETIONS   DURATION   AGE
job.batch/jaeger-cassandra-schema-job   1/1           103s       6m5s
```

jaeger-all-in-one-template.yml

```
NAME                          READY   STATUS    RESTARTS   AGE
pod/jaeger-7d4bc949bf-6t8w5   1/1     Running   0          73s

NAME                       TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                               AGE
service/jaeger-agent       ClusterIP      None            <none>        5775/UDP,6831/UDP,6832/UDP,5778/TCP   73s
service/jaeger-collector   ClusterIP      10.102.137.89   <none>        14267/TCP,14268/TCP,9411/TCP          73s
service/jaeger-query       LoadBalancer   10.99.5.211     localhost     80:31712/TCP                          73s
service/kubernetes         ClusterIP      10.96.0.1       <none>        443/TCP                               2m50s
service/zipkin             ClusterIP      None            <none>        9411/TCP                              73s

NAME                     READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/jaeger   1/1     1            1           74s

NAME                                DESIRED   CURRENT   READY   AGE
replicaset.apps/jaeger-7d4bc949bf   1         1         1       73s
```

## Ingress settings on Docker for Mac Kubernetes

- [Set up Ingress on Minikube with the NGINX Ingress Controller](https://kubernetes.io/docs/tasks/access-application-cluster/ingress-minikube/)
- [NGINX Ingress Controller : Installation Guide](https://kubernetes.github.io/ingress-nginx/deploy/)

run `Make setup-ingress-for-mac` and  
modify service jaeger-query in jaeger-production-template to type: ClusterIP, but port:80 is not used for ClusterIP

```
     spec:
       ports:
         - name: jaeger-query
-          port: 80
+          #port: 80
+          port: 8080
           protocol: TCP
           targetPort: 16686
       selector:
         app.kubernetes.io/name: jaeger
         app.kubernetes.io/component: query
-      type: LoadBalancer
+      #type: LoadBalancer
+      type: ClusterIP
```

then

```
kubectl apply -f k8s/jaeger-production-template.yml
kubectl apply -f k8s/ing/local_ing.yml
kubectl describe ingress jaeger-ingress
kubectl get all --namespace=ingress-nginx
```

## Configure cluster by kind

kubernetes version depends on kind version. [releases](https://github.com/kubernetes-sigs/kind/releases)

## TODO

- [x] ~~update any container images latest~~
- [x] ~~modify StatefulSet to use Persistent Volumes on local~~
- [x] ~~create Ingress for jaeger-query to access from localhost~
- [x] ~~create sample apps to store logs(push log to jaeger-collector)
- [] DaemonSet as jaeger-agent is not used because apps call api to jaeger-collector directly
- [] adjust configuration for multiple cluster using kind

## Issues

1. Local Volume は他の Pod から共有で利用することができないため、statefulset が replica:1 でなければ動かない  
   => after running, 2 of 3 pods become CrashLoopBackOff

2. k get pvc  
   pvc を apply したあとは status を確認したほうがよさげ、pvc の作成には若干時間がかかる  
   \$ kubectl get pvc -o go-template='{{range .items}}{{.status}}{{"\n"}}{{end}}'

3. App から jaeger-collector に接続できない。 App 側に status.hostIP で IP を設定してみたが、これではないようだ  
   `dial tcp 192.168.65.3:14268: connect: connection refused`  
   これは、サービス名`jaeger-collector`だけでいいはず。
