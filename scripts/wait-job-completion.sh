#!/bin/sh

count=1

while :
do
    MSG=`kubectl get job jaeger-cassandra-schema-job -o json | jq .status.succeeded`
    if [ ! -z "$MSG" ] && [ "$MSG" -eq 1 ]; then
        echo 'jaeger-cassandra-schema-job is done!'
        break
    else
        echo 'waiting...'
        count=$((++count))
        if [ "$count" -gt 60 ]; then
            echo 'timeout'
            exit 1
        fi
        sleep 10s
    fi
done
