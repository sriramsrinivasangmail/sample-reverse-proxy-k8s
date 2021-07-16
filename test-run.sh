#!/bin/bash

cd $(dirname $0)

image="quay.io/opencloudio/icp4data-nginx-repo@sha256:187bf65a5c6b5f950cd3a71afd7845d5a22f1adc395c8fec8be9bb9af8416629"
cname="rev-proxy"

which podman
if [ X$? == X0 ]
then
  exe=podman
else
  exe=docker
fi

${exe} rm -f ${cname}; 
${exe} run --name ${cname} -d --user 1001 -p 8080:8080 -v ${PWD}/conf/nginx.conf:/usr/local/openresty/nginx/conf/nginx.conf --entrypoint nginx ${image} -g "daemon off;"
