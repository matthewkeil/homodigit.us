# homodigit.us

Why you ask?  Where the name comes from is another story entirely but in short this is a tool to help my fellow coders go smoothly down their own paths.  [It didn't hurt when I heard it was ex-google technology,](https://blog.risingstack.com/the-history-of-kubernetes/) that got open-sourced and has now [gone viral with the big guys.](https://www.cncf.io/about/members/).

It seems like a lot, I know. But trust me, it's worth it. This journey started for me because I was attempting to install Neo4j on my local machine to give it a shot.  I ran into numerous issues due to a Java Runtime dependency conflict. That led me to Docker. What a *fabulous and terrible* tool.  It sure is nice when it just works.  However, if you have ever tried to work with disk/file permissions and syncing content between your local file structure and the container you will understand the terrible part... I was [working on a development tool called docker-development](https://github.com/matthewkeil/docker-development) to help me solve some of these challenges and realized Docker is a mess of pipes, patches, port forwarding, etc and I was still working on my local machine.  I cringed at thinking what i faced over ssh during deployment.  Over numerous hours googling for solutions, I ran across this Kubernetes thing over and over.  I realized the goal of Kubernetes was to do container orchestration.  Precisely my aim, to simplify that process without knowing what I wanted was an industry identified problem with a production solution.

With platinum sponsored the likes of Cisco, AWS, GoogleCloud, IBM Cloud, the [Cloud Native Computing Foundation](https://www.cncf.io) develops and manages all of what we are going to use.  Which means it is as awesome as the combined budget of the [sponsor lineup which is like infinite.](https://www.cncf.io/about/members/) They want, nay expect, this stuff to just work.

The big pieces we will work on together:
- focus on developer ergonomics and efficiency so coding time can be spent coding
- describe big picture architectural patterns so you can understand *why* they were chosen should you choose differently
- minimize cost
- utilize modern cloud-based architecture
- ensure [high-availability](https://en.wikipedia.org/wiki/High_availability)
- limit static IP's and cloud load balancer rules
- serve all content over https with [free self-renewing certificates](https://letsencrypt.org/)
- serve api's from preemptible vm's
- serve static assets from bucket storage
- manage/automate production versioning and distribution
- manage/automate staging on production for feature verification

[containerd](https://containerd.io/): they base wrapper and plumbing with which Docker containers can be run and accessed.  Their words are "It manages the complete container life-cycle of its host system, from image transfer and storage to container execution and supervision to low-level storage to network attachments and beyond."

[Kubernetes](https://kubernetes.io/): a set of objects that help create, run, stop, replicate, manage versioning, facilitate communication and handler authorization with "containerd's". Their words are "Production-Grade Container Orchestration."  yea... theirs is better

[Helm](https://helm.sh/): "The package manager for Kubernetes."

Before these tools the big guys had huge teams of people that did this sort of thing but now with the new tooling that exist it is possible for small dev teams, and even individual developers, to enjoy the same workflow automation and flexibility.  Now that I am starting to get my feet under me, as a developer, I am starting to get requests from friends to "help them with their website."  Not only do I want to be able to host my own pet projects but I would also like to be able to provide high availability for my friends and their projects as well.  Insert homodigit.us. Nice.

In this repository you will find everything you need, as well as many links to the information resources that I found useful while building this.  They are a base resource so you can understand what is going on when you successful deploy and secure your projects, and those of your friends/clients. I use this project personally and it is as much a resource for me to not have to look up commands as a tool for you to follow (after all im following it myself).  Good luck and feel free to reach out to me if you have any questions or run into any issues you can't seem to solve with a stack-overflow search.

----
## Kubernetes orchestrated cluster. DevOps platform. Static assets over https. Auto-scaling production server hosting (for when you go viral).

### To the technical part - The Big Picture
1) Deploy Kubernetes cluster
2) Install Helm/Tiller
3) Setup ssl for for Helm/Tiller to communicate
4) Configure/Deploy nginx
5) Route traffic from static IP through ingress object to nginx
6) Deploy certbot to provide and maintain ssl certificate for nginx
7) Configure/Deploy Jenkins

---
## Step 1) Deploy a Kubernetes cluster
The discussion about how to size and setup your cluster goes beyond a simple do this or do that because costs can vary widely depending on what one actually needs.  The first question you should ask yourself is how available does your cluster need to be?  Can you get away with one of your applications going down for 15-20 seconds if it crashes, like for a sandbox website or for a non-critical environment?  Or, are you handling real-time transactions that happen on millisecond timescale?  We will shoot for something in the middle where there will be virtually no downtime but the idea of 99.99999% uptime isn't necessary. I use google for hosting but this will work just as well on AWS or any of the other big hosts with a Kubernetes interface.  The platform specific sdk stuff from this step will be different but past here its all the same.

We will be creating a three node cluster, ie three VM's, and each will use an SSD boot disk. That isn't critical but I will be hosting a database from my cluster and I want my cache to served from SSD. We can also choose to have our persistent data on SSD also but that is another button we will need to push later. We can set up auto scale up and down but that is also for another time. For the moment know that we are using preemptible machines which means google can pull them at any point but we get a huge cost savings of about 70%!! If we schedule our workloads appropriately that wont matter because our cluster will self heal and spin up some new instances for us, and then rearrange our workloads without any interruption.  This is how we will should achieve at least five-nines of uptime. In theory, even if the node that has the master goes down, the cluster should be healed within the allowable downtime for 5-9's.  This also assumes the compute zone the cluster is in doesn't experience downtime which is unlikely but definitely not certain. If you want to ensure higher availability it is possible but you will need to set up multiple kubernetes masters in different compute zones, or even in different regions and set up a VPN or SSL tunnel to connect the lot. If it sounds like i dont know what im talking about then you are correct.  This is beyond my knowledge at the moment so I guess if I ever come up with a need we will learn together. Each VM we create will be billed at the rates listed here. 

[Pricing for Google Compute Engine Instances](https://cloud.google.com/compute/pricing).  

We need to set up our project for the gcloud sdk.  We are creating a regional cluster for better availability because the nodes will be spread across different zones (ie data centers) so we need to set the compute/region, however if you are going with a zonal cluster you will want to set your compute/zone.  The minimum number of nodes for a regional cluster is 3 so if you want less than that go with a zone based cluster.

[Fist things first, install gcloud](https://cloud.google.com/sdk/install) and while you are there poke around the commands a bit... If you are too busy for that you can

read the settings for the next command 'gcloud config set' [here](https://cloud.google.com/sdk/gcloud/reference/container/clusters/create)

`gcloud config set project **PROJECT_NAME**`

`gcloud config set compute/region **REGION**`

read the settings for the next command 'gcloud container clusters create' [here](https://cloud.google.com/sdk/gcloud/reference/container/clusters/create)

`gcloud container clusters create **CLUSTER_NAME**
--zone us-central1-a
--machine-type=n1-standard-1
--num-nodes=3
--disk-type=pd-ssd
--scopes=gke-default,storage-full
--preemptible`

---
## 2) Create self-signed SSL certs with which Helm and Tiller can securely communicate

Videos to watch
- [Securing Helm - Helm Summit 2018](https://www.youtube.com/watch?v=U8chk2s3i94&list=PLht8mj-Kzov2ZdAAzjA7r6PMAUKo3xFr5&index=3&t=0s)

We need to get our ssl certs sorted before we can ensure secure communication between Helm and Tiller.  You can find some info on what the heck X.509 is [here](https://en.wikipedia.org/wiki/X.509) [here](https://security.stackexchange.com/questions/36932/what-is-the-difference-between-ssl-and-x-509-certificates) and [here](http://www.sslauthority.com/x509-what-you-should-know/), what [self-signed ssl certificates are here](). There are a few ways to accomplish this and they are reviewed in the first video "Securing Helm." You can find a script in /bin/ssl of this repository that will help create them for us.  You will need to enter some configuration details into rootCA.conf and X509.conf in the directory with the scripts.

Here is the link to the openssl website for writing a 

[X059 configuration file](https://docs.genesys.com/Documentation/PSDK/9.0.x/Developer/TLSOpenSSLConfigurationFile)

[Root CA configuration file](https://jamielinux.com/docs/openssl-certificate-authority/appendix/root-configuration-file.html)

The big picture will be creating a private certificate signing authority so that we can self-sign our own certificates for secured communication.  We will create a root CA cert, a signing cert so that we dont have to expose our our root cert, and client certs for Helm and Tiller to utilize.

---
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


