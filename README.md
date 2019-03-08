# homodigit.us

## Kubernetes orchestrated cluster. DevOps platform. Serves bucket storage over https. Production Node.js hosting.

The goal of this project is to provide a template for other to easily provide a full service production and development platform. This solution was designed with the modern full-stack JavaScript developer in mind and focuses on hosting pod-based node servers, serving client assets stored in cloud storage buckets over https, utilizing a cdn for edge caching all while minimizing cost and guaranteeing reliability.

### Starting from scratch - The Big Picture
1) Deploy Kubernetes cluster
2) Setup ssl for for Helm/Tiller
3) Install Helm/Tiller
4) Configure/Deploy nginx
5) Route traffic from static IP through ingress object to nginx
6) Deploy certbot to provide and maintain ssl certificate for nginx
7) Configure/Deploy Jenkins

Assumptions: You are familiar with Docker, Kubernetes and
- gcloud
- kubectl
  
---

## 1) Deploy a Kubernetes cluster
The discussion about how to size and setup your cluster goes beyond a simple do this or do that because costs can vary widely depending on what one actually needs.  The first question you should ask yourself is how available does your cluster need to be?  Can you get away with one of your applications going down for 15-20 seconds if it crashes, like for a sandbox website or for a non-critical environment?  Or, are you handling real-time transactions that happen on millisecond timescale?  We will shoot for something in the middle where there will be virtually no downtime but the idea of 99.99999% uptime isn't necessary.

We need to set up our project for the gcloud sdk.  We are greating a regional cluster so we need to set the compute/region, however if you are going with a zonal cluster you will want to set your compute/zone.  Here is the doc link for the [cloud config set](https://cloud.google.com/sdk/gcloud/reference/container/clusters/create) command.

`gcloud config set project PROJECT_NAME`

`gcloud config set compute/region us-central`


Next create a regional cluster.  Here is the doc link for the [gcloud container clusters create](https://cloud.google.com/sdk/gcloud/reference/container/clusters/create) command.

`gcloud container clusters create CLUSTER_NAME 
--machine-type=f1-micro
--num-nodes=3
--region us-central1
--preemptible`


## 2) Setup SSL for Helm/Tiller

We need to get our ssl certs sorted before we get ensure secure communication between Helm and Tiller.  You can find a script in /bin/ssl of this repository that will help create them for us.  You will need to enter some configuration details into rootCA.conf and X509.conf in the directory with the scripts.

Here is the link to the openssl website for writing a 

[X059 configuration file](https://docs.genesys.com/Documentation/PSDK/9.0.x/Developer/TLSOpenSSLConfigurationFile)

[Root CA configuration file](https://jamielinux.com/docs/openssl-certificate-authority/appendix/root-configuration-file.html)

The big picture will be creating a private certificate signing authority so that we can self-sign our own certificates for secured communication.  We will create a root CA cert, a signing cert so that we dont have to expose our private keys to our root cert and client certs for Helm and Tiller to utilize.

## 3) Install Helm/Tiller

Here is the doc link for the [kubectl apply](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#apply) command.

`kubectl apply -f kube/tiller/tiller.service-account.yaml`

`kubectl apply -f kube/tiller/tiller.role-binding.yaml`

Here is the doc link for the [helm init](https://helm.sh/docs/helm/#helm-init) command.

`helm init --service-account tiller --upgrade`

`helm init
--service-account tiller
--tiller-tls 
--tiller-tls-verify 
--tiller-tls-cert ssl/tiller.pem 
--tiller-tls-key ssl/tiller.key 
--tls-ca-cert ssl/ca.crt`
