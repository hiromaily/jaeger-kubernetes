#!/bin/sh

count=1
is_ok=false

while :
do
    MSG=`kubectl get pvc -o go-template='{{range .items}}{{.status.phase}}{{"\n"}}{{end}}'`
    #Bound
    #Bound
    for ret in ${MSG[@]}; do
        if [ ! -z "$ret" ] && [ "$ret" = "Bound" ]; then
            is_ok=true
            echo $ret
        else
            is_ok=false
            sleep 1s
            break
        fi
    done

    if "${is_ok}"; then
        break
    fi
done
