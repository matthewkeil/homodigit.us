# homodigit.us

The big pieces we will work on together:
- focuses on developer ergonomics and efficiency so you can focus on coding
- describe big picture architectural patterns so you can understand *why* they were chosen should you choose differently
- utilize modern cloud-based architecture
- ensure [high-availability](https://en.wikipedia.org/wiki/High_availability)
- minimize cost
- serve static from bucket storage over https
- serve back-end api's over https
- automate production distribution and versioning
- automate sandbox/staging distribution for feature branch development

Why you ask?  Where the name comes from is another story entirely but in short this is a tool to help my fellow coders go smoothly down their own paths.

I was attempting to install Neo4j on my local machine to try it out.  I ran into numerous issues due to a Java Runtime dependencies. That led me to Docker. What a *fabulous and terrible* tool.  It sure is nice when it just works.  However, if you have ever tried to work with disk/file permissions and syncing content between your local file structure and the container you will understand the terrible part... I was [working on a development tool called docker-development](https://github.com/matthewkeil/docker-development) to help me solve some of these challenges and realized Docker is a mess of pipes, patches, port forwarding, etc.  Over numerous hours googling for solutions, I ran across this Kubernetes thing over and over.  I realized the goal of Kubernetes was to do container orchestration.  Precisely my aim, to simplify that process without knowing what I wanted was an industry identified problem with a production solution.  Then I heard it was ex-google technology that got open-sourced and has now gone viral.

The big guys out there have teams of people that help to do this sort of thing but now with the new tools that exist it is possible for small dev teams, and even individual developers, to enjoy the same workflow automation and flexibility.  Now that I am starting to get my feet under me, as a developer, I am starting to get requests from friends to "help them with their website."  Not only do I want to be able to host my own pet projects but I would also like to be able to provide high availability for my friends and their projects as well.  Insert homodigit.us.

In this repository you will find the full Helm chart necessary as well as many links to information resources that I found useful while building this.  They are a base resource to help successful deploy and secure your projects, and those of your friends/clients. I use this project personally and it is as much a resource for me to not have to look up commands as a tool for you to follow (after all im following it myself).  Good luck and feel free to reach out to me if you have any questions or run into any issues you can't seem to solve with a stack-overflow search.

## Kubernetes orchestrated cluster. DevOps platform. Serves bucket storage over https. Production Node.js hosting.

### Starting from scratch - The Big Picture
1) Deploy Kubernetes cluster
2) Setup ssl for for Helm/Tiller
3) Install Helm/Tiller
4) Configure/Deploy nginx
5) Route traffic from static IP through ingress object to nginx
6) Deploy certbot to provide and maintain ssl certificate for nginx
7) Configure/Deploy Jenkins

Assumptions: You will need the following installed
- Docker
- kubectl
- minikube
- gcloud


## 1) Deploy a Kubernetes cluster
The discussion about how to size and setup your cluster goes beyond a simple do this or do that because costs can vary widely depending on what one actually needs.  The first question you should ask yourself is how available does your cluster need to be?  Can you get away with one of your applications going down for 15-20 seconds if it crashes, like for a sandbox website or for a non-critical environment?  Or, are you handling real-time transactions that happen on millisecond timescale?  We will shoot for something in the middle where there will be virtually no downtime but the idea of 99.99999% uptime isn't necessary.

We need to set up our project for the gcloud sdk.  We are greating a regional cluster so we need to set the compute/region, however if you are going with a zonal cluster you will want to set your compute/zone. We will be creating a three node cluster, ie three VM's, and each will use an SSD boot disk. That isn't critical but I will be hosting a database from my cluster and I want my cache to served from SSD. We can also choose to have our persistent data on SSD also but that is another button we will need to push later. We can set up auto scale up and down but that is also for another time. For the moment know that we are using preemptible machines which means google can pull them at any point but we get a huge cost savings of about 70%!! If we schedule our workloads appropriately that wont matter because our cluster will self heal and spin up some new instances for us, and then rearrange our workloads without any interruption.  This is how we will should achieve at least five-nines of uptime. In theory, even if the node that has the master goes down, the cluster should be healed within the allowable downtime for 5-9's.  This also assumes the compute zone the cluster is in doesn't experience downtime which is unlikely but definitely not certain. If you want to ensure higher availability it is possible but you will need to set up multiple kubernetes masters in different compute zones, or even in different regions and set up a VPN or SSL tunnel to connect the lot. If it sounds like i dont know what im talking about then you are correct.  This is beyond my knowledge at the moment so I guess if I ever come up with a need we will learn together.

Each VM we create will be billed at the rates listed here. [Pricing for Google Compute Engine Instances](https://cloud.google.com/compute/pricing).  

[Docs Link: gcloud config set](https://cloud.google.com/sdk/gcloud/reference/container/clusters/create)

`gcloud config set project **PROJECT_NAME**`

`gcloud config set compute/region **REGION**`

[Docs Link: gcloud container clusters create](https://cloud.google.com/sdk/gcloud/reference/container/clusters/create)

`gcloud container clusters create **CLUSTER_NAME**
--region us-central1
--machine-type=n1-standard-1
--num-nodes=3
--disk-type=pd-ssd
--scopes=gke-default,storage-full
--preemptible`


## 2) Create self-signed SSL certs with which Helm and Tiller can securely communicate

Videos to watch
- [Securing Helm - Helm Summit 2018](https://www.youtube.com/watch?v=U8chk2s3i94&list=PLht8mj-Kzov2ZdAAzjA7r6PMAUKo3xFr5&index=3&t=0s)

We need to get our ssl certs sorted before we can ensure secure communication between Helm and Tiller.  You can find some info on what the heck X.509 is [here](https://en.wikipedia.org/wiki/X.509) [here](https://security.stackexchange.com/questions/36932/what-is-the-difference-between-ssl-and-x-509-certificates) and [here](http://www.sslauthority.com/x509-what-you-should-know/), what [self-signed ssl certificates are here](). There are a few ways to accomplish this and they are reviewed in the first video "Securing Helm." You can find a script in /bin/ssl of this repository that will help create them for us.  You will need to enter some configuration details into rootCA.conf and X509.conf in the directory with the scripts.

Here is the link to the openssl website for writing a 

[X059 configuration file](https://docs.genesys.com/Documentation/PSDK/9.0.x/Developer/TLSOpenSSLConfigurationFile)

[Root CA configuration file](https://jamielinux.com/docs/openssl-certificate-authority/appendix/root-configuration-file.html)

The big picture will be creating a private certificate signing authority so that we can self-sign our own certificates for secured communication.  We will create a root CA cert, a signing cert so that we dont have to expose our our root cert, and client certs for Helm and Tiller to utilize.

## 3) Install Helm/Tiller

Videos to watch
- [Getting Started with Helm and Kubernetes](https://www.youtube.com/watch?v=HTj3MMZE6zg&index=1&list=PLht8mj-Kzov2ZdAAzjA7r6PMAUKo3xFr5)
- [Building Helm Charts from the Ground Up](https://www.youtube.com/watch?v=vQX5nokoqrQ&list=PLht8mj-Kzov2ZdAAzjA7r6PMAUKo3xFr5&index=5)


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


