#!/bin/bash

cd $(dirname $0)

image="registry.access.redhat.com/ubi8/nginx-118"
cname="rev-proxy"

docker rm -f ${cname}; 
docker run --name ${cname} -d --user 1001 -p 8080:8080 -v ${PWD}/conf/nginx.conf:/etc/nginx/nginx.conf ${image} 
