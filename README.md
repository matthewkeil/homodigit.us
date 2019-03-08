# homodigit.us

## Kubernetes orchestrated cluster. DevOps platform. Serves bucket storage over https. Production Node.js hosting.

The goal of this project is to provide a template for other to easily provide a full service production and development platform. This solution was designed with modern full-stack JavaScript developer in mind and focuses on hosting pod-based node servers, serving client assets stored in cloud storage buckets over https, utilizing a cdn for edge caching all while minimizing cost and guaranteeing reliability.

### Starting from scratch - The Big Picture
1) Deploy Kubernetes cluster
2) Setup ssl for for Helm/Tiller
3) Install Helm/Tiller
4) Configure/Deploy nginx
5) Route traffic from static IP through ingress object to nginx
6) Deploy certbot to provide and maintain ssl certificate for nginx
7) Configure/Deploy Jenkins

Assumptions: You are familiar with kubernetes and this stuff
- gcloud sdk
- kubectl
  
---

## 1) Deploy a Kubernetes cluster
The discussion about how to size and setup your cluster goes beyond a simple do this or do that because costs can vary widely depending on what one actually needs.  The first question you should ask yourself is how available does your cluster need to be?  Can you get away with one of your applications going down for 15-20 seconds if it crashes, like for a sandbox website or for a non-critical environment?  Or, are you handling real-time transactions that happen on millisecond timescale?  We will shoot for something in the middle where there will be virtually no downtime but the idea of 99.99999% uptime isn't necessary.

Here is the doc link for the [cloud config set](https://cloud.google.com/sdk/gcloud/reference/container/clusters/create) command.
`gcloud config set project homodigitus`

`gcloud config set compute/region us-central`


Next create a regional cluster.  Here is the doc link for the [gcloud container clusters create](https://cloud.google.com/sdk/gcloud/reference/container/clusters/create) command.

`gcloud container clusters create homodigitus 
--machine-type=f1-micro
--num-nodes=3
--region us-central1
--preemptible`

## 2) Setup SSL for Helm/Tiller
Before we deploy any workloads to the cluster it is best practice to secure communications with the cluster through ssl.  We will first create our ssl certs using the scripts found in /bin/ssl of this repository.  Instructions for use can be found with the scripts.







