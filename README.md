
# Testing out OpenShift route


## Example 1 - Edge route to https kube svc

This example is a workaround for a situation where only Edge termination based ingress is possible.  Edge routers expect to send http in the clear to the target service 

However, kube svcs (such as zen's ibm-nginx-svc) only expose HTTPs ports.  So - the edge sending out http to such https services will fail.


### Approach

We will deploy an nginx server "rev-proxy"  with http only exposed into the same namespace as the "target" kubernetes svc. 
This nginx server will in turn just reverse proxy to the real https service.

We then create an edge route to the rev-proxy-svc.

The result -  from browser access the exposed edge route -> which forwards http to the `rev-proxy` pod --> this pod reverse proxies to the "target" service using https


### Samples

Under k8s/ - you will see the following yamls:


- rev-proxy-nginx-conf-cm.yaml

This configmap is essentially an nginx conf that proxies to the real target kubernetes services.

**Note 1** - the resolver is required inside of the OpenShift pod to lookup the kubernetes svc.  It is set to `172.30.0.10` - but change to the resolver used in your cluster. For example, in a running pod, look at /etc/resolv.conf and grab the `nameserver` entry for the resolver's IP.

**Note 2** - there is one proxy_pass to a `https://ibm-nginx-svc.cpd-202.svc.cluster.local` kubernetes svc.  Change this to the fully qualified name of the service you intend to reverse proxy too. Note - even if the rev-proxy pods run in the same namespace as that ibm-nginx-svc kube service, I still needed to fully qualify the name _and_  needed the resolver.

- rev-proxy-deployment.yaml

This deploys a http based nginx server. It mounts nginx.conf from the `rev-proxy-nginx-conf-cm` configmap .

** Note 3** - The image used is one (quay.io/opencloudio/icp4data-nginx-repo) that should already exist in the cluster from the zen service installation. Change the image digest to one that you already have replicated into your private registry (say via: `oc get deployment ibm-nginx -o yaml | grep "image:"`). 


- rev-proxy-svc.yaml

This creates a kubernetes service, called `rev-proxy-svc` selecting the rev-proxy-deployment pods

- rev-proxy-route.yaml

This creates an openshift _edge_ route called `rev-proxy-route` to the kube svc `rev-proxy-svc`.  Alter this to create the edge route as needed for that environment.


### Running the sample

Remember to alter the nginx conf and image digest as described above

use `oc create -f` to run the yamls in order shown above.  

**Tips**: 

- if you need to change the nginx.conf in the configmap, you can `oc apply -f` the changed configmap and then delete the rev-proxy pod (`oc delete pod $(oc get pods -l app=rev-proxy --no-headers | cut -f1 -d\ ) `) to force the new pod to load the changed configmap

- You can use `oc logs $(oc get pods -l app=rev-proxy --no-headers | cut -f1 -d\ ) -f` to trace the rev-proxy pod logs

Once the pod is running and the edge route has been created, use the host associated with that route to access from the browser. 

For example

```
oc get route rev-proxy-route
NAME              HOST/PORT                                                 PATH   SERVICES        PORT             TERMINATION     WILDCARD
rev-proxy-route   rev-proxy-route-cpd-202.apps.zen-dev-02.cp.fyre.ibm.com          rev-proxy-svc   rev-proxy-http   edge/Redirect   None
```

access `https://rev-proxy-route-cpd-202.apps.zen-dev-02.cp.fyre.ibm.com` from the browser and you should see the target kubernetes svc (ibm-nginx-svc) being reverse proxied.




