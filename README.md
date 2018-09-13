
# Overview

DivvyCloud enforces security, compliance, and governance policy in your cloud and container based infrastructure.

Below you will find steps on how to deploy DivvyCloud to a Kubernetes cluster. 

# Installation

## Quick install with Google Cloud Marketplace

Get up and running with a few clicks! Install this DivvyCloud app to a Google
Kubernetes Engine cluster using Google Cloud Marketplace. Follow the on-screen
instructions:

## Acquiring and installing License 

DivvyCloud automatically generates and installs a 14-day trial license.

## Tool dependencies

- [gcloud](https://cloud.google.com/sdk/)
- [docker](https://docs.docker.com/install/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/). You can install
  this tool as part of `gcloud`.
- [make](https://www.gnu.org/software/make/)

## Authorization

This guide assumes you are using a local development environment. If you need
run these instructions from a GCE VM or use a service account identity
(e.g. for testing), see: [Advanced Authorization](#advanced-authorization)

Log in as yourself by running:

```shell
gcloud auth login
```

## Provisioning a GKE cluster and configuring kubectl to connect to it.

```
CLUSTER=cluster-1
ZONE=us-west1-a

# Create the cluster.
gcloud beta container clusters create "$CLUSTER" \
    --zone "$ZONE" \
    --machine-type "n1-standard-1" \
    --num-nodes "3"

# Configure kubectl authorization.
gcloud container clusters get-credentials "$CLUSTER" --zone "$ZONE"

# Bootstrap RBAC cluster-admin for your user.
# More info: https://cloud.google.com/kubernetes-engine/docs/how-to/role-based-access-control
kubectl create clusterrolebinding cluster-admin-binding \
  --clusterrole cluster-admin --user $(gcloud config get-value account)

# (Optional) Start up kubectl proxy.
kubectl proxy
```



### Building and installing 
	Clone down this repository and use the following make commands:

	* make crd/install to install the application CRD on the cluster. This needs to be done only once.
	* make app/install to build all the container images and deploy the app to a target namespace on the cluster.
	* make app/uninstall to delete the deployed app.

### Commands

Set environment variables (modify if necessary):
```
export APP_INSTANCE_NAME=divvycloud
export NAMESPACE=divvycloud
```

Expand manifest template:
```
helm template . --set APP_INSTANCE_NAME=$APP_INSTANCE_NAME,NAMESPACE=$NAMESPACE > expanded.yaml
```

Run kubectl:
```
kubectl apply -f expanded.yaml
```

## Connecting to admin console

By default DivvyCloud is only accessible from inside the kube cluster. As a result we must setup a port forward

```
kubectl port-forward svc/divvycloud-interfaceserver 8001

```

Next open http://localhost:8001/ in your web browser

## Exposing DivvyCloud using a GCP internal load balancer

In order to expose DivvyCloud using an internal load balancer. 

First we need to change our divvycloud-interfaceserver to a NodePort instead of a ClusterIP. 

To patch your existing divvycloud-interfaceserver service run the following commands:
```
kubectl patch svc divvycloud-interfaceserver --type='json' -p '[{"op":"replace","path":"/spec/type","value":"NodePort"}]'
```

Next we need to create a new load balancer service. This load balancer will use an annotation to tell GCP to create a new internal load balancer.

First copy the following to a yml file. In this example we will call the file internal-lb.yaml:
```
apiVersion: v1
kind: Service
metadata:
  annotations:
    cloud.google.com/load-balancer-type: "Internal"
  name: divvycloud-internal-lb
  labels:
    app: divvycloud-internal-lb
spec:
  type: LoadBalancer
  ports:
    - port: 80
      targetPort: 8001
  selector:
    app:  divvycloud-interfaceserver
```

Next create the above service by running :
```
kubectl create -f internal-lb.yaml
```

## Backup / Restore

MySQL dump and the MySQL client are used to backlup and restore a DivvyCloud database
First you need to get the IP address of the mysql service in your k8s deployment 

```
  MYSQL_IP=$(kubectl get \
    --namespace default \
    svc divvycloud-mysql\
    -o jsonpath='{.spec.clusterIP})

```

Next use the username and password
```
kubectl get secret divvycloud-secret -o jsonpath={'.data.DIVVY_MYSQL_USER'}  | base64 -D
kubectl get secret divvycloud-secret -o jsonpath={'.data.DIVVY_MYSQL_PASSWORD'}  | base64 -D
```

Finally to backup a database:
```
mysqldump -u [MYSQL_USER] -p -h [MYSQL_IP] divvy > divvy.sql
mysqldump -u [MYSQL_USER] -p -h [MYSQL_IP] divvykeys > divvykeys.sql
```

To restore a database:

```
mysql -u [MYSQL_USER] -p -h [MYSQL_IP] divvy < divvy.sql
mysql -u [MYSQL_USER] -p -h [MYSQL_IP] divvykeys < divvykeys.sql
```

## Upgrades

 Simply restart all containers , the latest image will pull automatically. Upgrade of database occures on boot.
 Please backup your database prior to upgrading

