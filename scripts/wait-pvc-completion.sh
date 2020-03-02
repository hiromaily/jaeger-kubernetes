#!/bin/sh

count=1

while :
do
    MSG=`kubectl get pvc -o go-template='{{range .items}}{{.status.phase}}{{"\n"}}{{end}}'`
    #Bound
    #Bound
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
