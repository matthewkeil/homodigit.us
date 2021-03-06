# homodigit.us

Why you ask? Where the name comes from is another story entirely but in short this is a tool to help you, my fellow coder, go smoothly down your own path. [It didn't hurt to hear it is google's aptly named](https://blog.risingstack.com/the-history-of-kubernetes/) [borg](https://en.wikipedia.org/wiki/Borg) project that got open-sourced. [Short is, it went viral... go ahead, click me.](https://www.cncf.io/about/members/) If you did you are probably as blown away as I was.

This journey started for me because I was attempting to install Neo4j on my local machine to give it a shot. I ran into numerous issues due to a Java Runtime dependency conflict. That led me to Docker. What a _fabulous_ and **terrible** tool! It sure is nice when it just works. **However**, if you have ever tried to work with user/disk/file permissions like manually syncing content between the dev folder and the container you will understand the terrible part... I was [working on a development tool called docker-development](https://github.com/matthewkeil/docker-development) to help me solve some of these challenges and realized Docker is a mess of pipes, patches, port forwarding, etc. and I was still working on my local machine. Over numerous hours googling for solutions, I ran across this Kubernetes thing over and over. I realized the goal of Kubernetes was to do container orchestration, precisely my aim.

[The Cloud Native Computing Foundation](https://www.cncf.io) develops and manages all of what we are going to use. Which means it is as awesome as the combined budget of the [sponsor lineup which is like infinite.](https://www.cncf.io/about/members/) They want, nay expect, this stuff to just work.

A note on longevity and developer fatigue. If you read the sponsors list you will get that this is now the defacto standard for production architecture. Not likely that whole group will just up and stop. It's not a single company like Facebook choosing to stop supporting React. Nor is it like one company doing the ultimate breaking change like Angular 1 -> 2. Both of those sentences will one-day lend themselves to their own blog post I suppose. For now lets move on to what we will accomplish.

## Big Picture

- reliable server platform to provide scalable, available hosting
- CI/CD Platform to handle devops
  1. if one pushes changes to a master branch and those changes get tested and put into production
  2. if one pushes changes to a "git checkout -b new-feature" and add a 'git tag -a feature-name -m "added a great new feature"' it will build that branch in a staging area and create a routing rule to access it"

## The End Goals:

- focus on developer ergonomics and efficiency so coding time can be spent coding
- describe big picture architectural patterns so you can understand _why_ they were chosen should you choose differently
- utilize modern cloud-based architecture
- learn how to minimize cost
- ensure [high-availability](https://en.wikipedia.org/wiki/High_availability)
- limit static IP's and cloud load balancer rules
- serve all content over https with [free self-renewing certificates](https://letsencrypt.org/)
- serve api's from preemptible vm's
- serve static assets from bucket storage
- manage/automate production versioning and distribution
- manage/automate staging on production for feature verification

[containerd](https://containerd.io/): the base wrapper and plumbing with which Docker-like containers can be run and accessed. Their words are "It manages the complete container life-cycle of its host system, from image transfer and storage to container execution and supervision to low-level storage to network attachments and beyond."

[Kubernetes](https://kubernetes.io/): a set of objects that help aid, create, run, stop, replicate, version, communicate with, handle authorization and otherwise interact with "workloads" in the form of "containerd's". Their words are "Production-Grade Container Orchestration." yea... theirs is better

[Helm](https://helm.sh/): "The package manager for Kubernetes."

Before these tools, the big guys had huge teams of people that did this sort of thing. Now with the new tooling it is possible for small dev teams, and even individual developers to enjoy the same workflow automation and flexibility. Now that I am starting to get my feet under me as a developer, I am starting to get requests from friends to "help them with their website." Not only do I want to be able to host my own pet projects but I would also like to be able to provide high availability for my friends and their projects as well. Insert homodigit.us. Nice.

In this repository you will find everything you need, as well as many links to the information resources that I found useful while building this. They are a base resource so you can understand what is going on when you successful deploy and secure your projects, and those of your friends/clients. I use this project personally and it is as much a resource for me to not have to look up commands as a tool for you to follow (after all im following it myself). Good luck and feel free to reach out to me if you have any questions or run into any issues you can't seem to solve with a stack-overflow search.

---

## Kubernetes orchestrated cluster. DevOps platform. Static assets over https. Auto-scaling production server hosting (for when you go viral).

### To the technical part - The Big Picture

1. Deploy Kubernetes cluster
2. Install Helm/Tiller
3. Setup ssl for for Helm/Tiller to communicate
4. Configure/Deploy nginx
5. Route traffic from static IP through ingress object to nginx
6. Deploy certbot to provide and maintain ssl certificate for nginx
7. Configure/Deploy Jenkins

---

## Step 1) Deploy a Kubernetes cluster

The discussion about how to size and setup your cluster goes beyond a simple do this or do that, because needs and costs vary widely. The platform specific stuff from this step will be nuanced differently on different hosts but step 2 on its the all same no matter where there cluster lives. I use google now but I've actually chosen to make as many of the pieces platform agnostic so I wont be locked into them should pricing change suddenly.

The first question you should ask yourself is how available does your cluster need to be? Can you get away with one of your applications going down for 15-20 seconds if it crashes, like for a sandbox website or for a non-critical environment? Or, are you handling real-time transactions that happen on a millisecond timescale? We will shoot for something in the middle where there will be virtually no downtime but the idea of 99.999999% uptime isn't necessary.

Next, does the site's target client live in one region, like the US or Asia, or are they global? We will assume one region. To be fair, if you have a global audience and need high availability, this doc is a great executive overview to manage someone doing that, like as part of their full-time job. Wink. Coincidentally, I'm for hire as this is one of my projects for coding boot camp. What can I say, I'm an overachiever...

We have another choice to make is how many masters we want. That is silly to ask when I haven't introduced them. [Watch me](https://www.youtube.com/watch?v=DZ-Wv3XNoAk) and [read me.](https://github.com/kubernetes/community/blob/master/contributors/design-proposals/architecture/architecture.md#architecture) OK, you are back. Chances of a data center going down and taking your master with it are small but possible so placing redundant masters in different physical facilities can make sense depending on your use case. In google's case the master does not count toward your number of nodes, its sort of baked in, but if the data center goes offline so does your app. It's NOT a common thing but it's a point of note.

So to summarize, from least to most available:

- 1 node, 1 master, 1 zone, 1 region
- many nodes, 1 master, 1 zone, 1 region
- many nodes, many masters, 1 zone, 1 region
- many nodes, 1 master, many zones, 1 region
- many nodes, many masters, many zones, 1 region (regional cluster and the next topic up)
- many nodes, many masters, many zones, many regions

The default size for a cluster on gke is three nodes with one being the master. If you choose a regional cluster the default number of nodes will be three and all three will be masters. There is a sticky wicket here. On google creating a "1" node regional cluster means 1 node in each zone of the region with redundant masters. So if you try and to a "3" node regional cluster what you will get is is three node pools spread across three zones of the region and they will all have three nodes, of which one in each will be the a master.

We can also autoscale our pod VM count with the `--enable-autoscale` flag. [Here is the doc link.](https://cloud.google.com/sdk/gcloud/reference/container/clusters/create#--enable-autoscaling) It covers the `--max-nodes=` and `--min-nodes=` flags as well as a note about how it affects [node pools.](https://cloud.google.com/sdk/gcloud/reference/container/node-pools/create).

We are using [`--preemptible` machines](https://cloud.google.com/kubernetes-engine/docs/how-to/preemptible-vms) which means google can pull them at any point but we get a huge cost savings of about 70%!! We are using Kubernetes though so that doesn't matter. Unless you are serving persistent data or need to ensure a cache is always warm, swapping one identical, stateless process for another identical, stateless process doesn't matter by definition.

`http.createServer((req, res, next) => res.write('<h1>hello, this is pod ' + podName + ' reporting, yo...</h1>'));`

There are few levels of "persistent" data we should discuss. The fastest will be RAM storage. While not really persistent it affects the next type. Should memory run out it will overflow into a swap file.

The second fastest will be persistent disks. They can be sized with the `--disk-size=DISK_SIZE` [flag.](https://cloud.google.com/sdk/gcloud/reference/container/clusters/create#--disk-size) This is where disk access actually happens when the "file structure" is called from a workload. Like memory overruns that require swap files, and thus where your warmed cache will live, like a database. If you want your db "to be faster" you can reduce latency by caching some of the frequent query responses and returning that instead of a fresh query. At some point space in memory will run out and if the cache is set to save more than memory will allow it goes to the disk, as a swap file. To solve that problem you can either change the [`--machine-type` flag](https://cloud.google.com/sdk/gcloud/reference/container/clusters/create#--machine-type) to one with more memory or you can increase the disk speed so the cache will be quicker using the [`--disk-type=pd-ssd` flag.](https://cloud.google.com/sdk/gcloud/reference/container/clusters/create#--disk-type)

Persistent storage, like the database files that aren't in cache, are best handled by another method. We will get there. Serving stateful data (REDIS, SQL, etc.) no matter where it lives is a more advanced topic worthy of its own discussion. For now use mLab and follow me to read that post when it happens.

[This is the full google discussion about disks](https://cloud.google.com/compute/docs/disks/).

Each VM we create will be billed at the rates listed here.

[Pricing for Google Compute Engine Instances](https://cloud.google.com/compute/pricing).

We need to set up our project for the gcloud sdk. We are creating a regional cluster for better availability because the nodes will be spread across different zones (ie data centers) so we need to set the compute/region, however if you are going with a zonal cluster you will want to set your compute/zone. The minimum number of nodes for a regional cluster is 3 so if you want less than that go with a zone based cluster.

You will need an account with google because these are all billable services. Just for you, actually everyone you arent that special, they are giving away \$300 of free credit to try out the platform and see if you like it. [Go here for it.](https://console.cloud.google.com/freetrial)

[Fist things first, install gcloud](https://cloud.google.com/sdk/install) and while you are there poke around the commands a bit... If you are too busy for that you can

read the settings for the next command ['gcloud config set'](https://cloud.google.com/sdk/gcloud/reference/container/clusters/create)

`gcloud config set project **PROJECT_NAME**`

`gcloud config set compute/region **REGION**`

read the settings for the next command ['gcloud container clusters create'](https://cloud.google.com/sdk/gcloud/reference/container/clusters/create)

`gcloud container clusters create **CLUSTER_NAME** --region us-central1 --machine-type=n1-standard-1 --num-nodes=1 --scopes=gke-default,storage-full --enable-autorepair --enable-autoupgrade --preemptible`

/\*_
add section for gcloud commands to check status of cluster
_/

Now that we have a cluster up and running lets set up our machine to interact with it. The gcloud command is a way to provision and interact with the google cloud infrastructure. Ie stuff that is billable. A virtual machine is billable. Storage is billable.

The idea of having many instances of an app running is different. That is a workload. Workloads run on machines (or virtual machines in this case) and machines can run many different workloads. My computer can run a development instance of mongodb, a few nodejs servers and a webpack-dev-server right? "Hardware" is handled by gcloud whereas the workloads are handled by kubectl. kubectl is the command line tool that allows one to interact with a cluster and its workloads, etc.

This is a nuance and an important one so you know where to look for the right command. You can scale the number of nodes (virtual machines) you have running in your cluster with gcloud. Those cost money for each one right. You can also interact with bucket storage and other provider level objects through that command. Whereas one can scale the number of instances of a database [(replication)](https://www.youtube.com/watch?v=tpspO9K28PM&t=535s) from kubectl. That is scaling a workload and a topic for below.

For now we will need to transfer our cluster information from gcloud to kubectl. They are designed to work together and gcloud will help set up kubectl.

read the settings for the next command ['gcloud container clusters get-credentials'](https://cloud.google.com/sdk/gcloud/reference/container/clusters/get-credentials)

`gcloud container clusters get-credentials **CLUSTER_NAME** --region **REGION**`

read the settings for the next command ['kubectl config'](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#config) and will allow us to verify that the prior gcloud command worked as planned.

[`kubectl config current-context`](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#-em-current-context-em-) will show you what cluster you will communicate with when entering commands into kubectl.

[`kubectl config view`](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#-em-view-em-) will show you the complete config. You can find the full config file on disk with `cat ~/.kube/config`

---

## 2) Facilitate secure communication between Helm and Tiller

Videos to watch

- [MIT OpenCourseWare - SSL and HTTPS](https://www.youtube.com/watch?v=q1OF_0ICt9A) on youtube. It is MIT thorough as one would hope. Its also as long.
- [Intro to Digital Certificates](https://www.youtube.com/watch?v=qXLD2UHq2vk&t=10s). A shorter, less MIT version of the info above.
- [Creating self-signed ssl certificates](https://www.youtube.com/watch?v=T4Df5_cojAs)
- [Intro to gRPC](https://www.youtube.com/watch?v=RoXT_Rkg8LA) Not critical but nice to know.
- [Securing Helm - Helm Summit 2018](https://www.youtube.com/watch?v=U8chk2s3i94&list=PLht8mj-Kzov2ZdAAzjA7r6PMAUKo3xFr5&index=3&t=942s) - Fast forwarded to the section relevant for our use.

Info Links

- [filename extensions](https://en.wikipedia.org/wiki/X.509#Certificate_filename_extensions)
- [what is x.509](https://security.stackexchange.com/questions/36932/what-is-the-difference-between-ssl-and-x-509-certificates)
- [minimum x.509 conf](http://www.sslauthority.com/x509-what-you-should-know/)

These are tasks we need to complete

1. create a private key for our CA (Certificate Authority)
2. create a conf file for our CA
3. use the key and conf file to create a self signed certificate for the CA
4. create a conf file for our intermediate CA
5. use that conf file to create a CSR and key for the intermediate CA
6. use those plus the CA cert, key and password to create the intermediate CA cert
7. concat the certs in proper order to create the chain
8. create CSR, cert and key set using intermediate CA key and password for both Tiller and Helm

Or you can conveniently use the script I wrote to make the mundane easy. Its found in /bin/ssl/makeInitSet.sh. You will need to enter some configuration details into rootCA.conf and X509.conf in the directory with the script.

Here is the link to the openssl website for writing a [X059 configuration file](https://docs.genesys.com/Documentation/PSDK/9.0.x/Developer/TLSOpenSSLConfigurationFile) and for the [Root CA configuration file](https://jamielinux.com/docs/openssl-certificate-authority/appendix/root-configuration-file.html) and below are the commands we called in that script. Each is a link to the docs for info on the flags used.

read the settings for the next command [openssl genrsa](https://www.openssl.org/docs/manmaster/man1/genrsa.html) - RSA key generation utility

`openssl genrsa -out new.key 4096`

read the settings for the next command [openssl req](https://www.openssl.org/docs/manmaster/man1/req.html) - certificate generating utility

`cat rootCA.conf | openssl req -key ca.key -new -x509 -days 7300 -sha256 -out ca.crt -extensions v3_ca`

`openssl req -new -sha256 -nodes -newkey rsa:4096 -keyout new.key -out new.csr -config <( cat X509.conf )`

read the settings for the next command [openssl x509](https://www.openssl.org/docs/manmaster/man1/x509.html) - certificate signing utility

`openssl x509 -req -days 500 -sha256 -in new.csr -out new.crt -CA signatory.crt -CAkey signatory.key -CAcreateserial -extfile X509.conf -passin "pass:password"`

---

## 3) Install Helm/Tiller

Videos to watch

- [Getting Started with Helm and Kubernetes](https://www.youtube.com/watch?v=HTj3MMZE6zg&index=1&list=PLht8mj-Kzov2ZdAAzjA7r6PMAUKo3xFr5)
- [Building Helm Charts from the Ground Up](https://www.youtube.com/watch?v=vQX5nokoqrQ&list=PLht8mj-Kzov2ZdAAzjA7r6PMAUKo3xFr5&index=5)

The docs on the Helm website are extensive and well written.

[Installing Helm](https://helm.sh/docs/using_helm/#installing-helm)

The docs are for more than what we will need but they are good reference for the big picture. You can find all of the commands we will actually use below. Get Helm installed. After you are done read through this.

[Using SSL Between Helm and Tiller](https://helm.sh/docs/using_helm/#using-ssl-between-helm-and-tiller). You will notice that most of the instructions are for creating the ssl certificates that we did above. There are some commands that we will need to add as they are specific to our use case. They make brief mention of setting the [`--tiller-namespace` flag](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/) and [`--service-account` flag](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#service-account-permissions). The service account, with a role-binding is precisely what we will need to add first. Click on those links to see what kubernetes objects they are talking about, but you won't want to digest it all at the moment.

A thorough discussion on Roles Based Access Control is a full course on its own. So is the theory of namespace management and why/when they are applicable. It also happens that I haven't managed kubernetes at scale (ie google scale) and many of those features are for keeping Jr. Dev's on one team from killing the whole cluster of a large organization.

read the settings for the next command [kubectl apply](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#apply)

`kubectl apply -f kube/tiller/tiller.service-account.yaml`

`kubectl apply -f kube/tiller/tiller.role-binding.yaml`

That is one of the few times that you will want to apply cluster state with kubectl directly. From here on it will be easier to use Helm. Now you may have asked what the heck did I mean by apply state? [Kubernetes is declarative](https://www.youtube.com/watch?v=kadpRayoh7w), meaning "I want 3 copies of my node application to share the incoming web traffic evenly" so the system will go and make you three copies and make sure they are running with health checks. If one stops responding it will get rid of the pod and spin up a new one. Sounds simple. It's not, watch this for a great look [under the hood of how `kubectl apply` works](https://www.youtube.com/watch?v=CW3ZuQy_YZw).

read the settings for the next command [helm init](https://helm.sh/docs/helm/#helm-init)

`helm init --service-account tiller --upgrade`

`helm init --service-account tiller --tiller-tls --tiller-tls-verify --tiller-tls-cert ssl/tiller.pem --tiller-tls-key ssl/tiller.key --tls-ca-cert ssl/ca.crt`

---

## 4) Network Topology, Ingress and NGINX

Ingress is a simple idea in principle and can be solved very simply... and expensively. Just throw a Cloud Load Balancer in front of your cluster and have it do all the routing to the individual services for you. And then realize its as expensive as all of your VM's put together.

There are a HUGE number of solutions online that one can follow. All of them are different. Many use a different "plugin this" or different "addon that" and a bunch look to be hand coded! It's been exceedingly difficult to try and find an "industry consensus" I can point us all to and to. 

Ingress, as it appears is also quite a contentious issue online. And I quote a stack overflow troll, "Everyone's architecture is a snowflake and needs its own solution" followed by grumbles. It also is a really broad a rather complex set of problems that seem easy till you try. [Reading this](https://danielfm.me/posts/painless-nginx-ingress.html) gave great insight into some very sticky wickets. Here are some more resources to reference.

Videos

- [Four Distributed Systems Architectural Patterns](https://www.youtube.com/watch?v=tpspO9K28PM)
- [Switching From External Load Balancing to Ingress](https://www.youtube.com/watch?v=kadpRayoh7w)
- [Make Ingress-Nginx Work for you](https://www.youtube.com/watch?v=GDm-7BlmPPg&t=868s)

Blogs/Info

- [Kubernetes Ingress 101: NodePort, Load Balancers, and Ingress Controllers](https://blog.getambassador.io/kubernetes-ingress-nodeport-load-balancers-and-ingress-controllers-6e29f1c44f2d?fbclid=IwAR2STXLoUSQOssqKLqJ9cBTcKmh5kqZZamzHkZ_s-xqzWGYruizifFLiIlk). This one answered my most important question
- [kubernetes-ingress vs ingress-nginx](https://github.com/nginxinc/kubernetes-ingress/blob/master/docs/nginx-ingress-controllers.md)
- [Experience from running nginx in production](https://danielfm.me/posts/painless-nginx-ingress.html)


Big picture we are going to need to use a cloud load balancer with at a minimum, one forwarding rule. I have tried searching for nearly two days now and the best thing I can find are a couple of GCE and GKE examples similar to [this](https://serverfault.com/questions/863569/kubernetes-can-i-avoid-using-the-gce-load-balancer-to-reduce-cost). The technique relies on exposing a service via a hack using the internal IP of the node and calling it the external IP of the service.  It also requires setting up firewall rules and updating the DNS record every time a node is restarted. This is very cheesy and is most certainly for test situations.  The comments even note that "while this does work its not a production solution."  If you want to get a cluster online **that only you** use it will work. Sheesh...

We will need to pay for at least the bare minimum load balancing costs but we will get 5 routing rules included. One of which will route all traffic to our nginx ingress controllers.  We will deploy 3 pods and set the `antiaffinity` property on our deployment to motivate them to be one in each zone as apposed to potentially clustering on one node. The cloud load balancer will use its routing mechanisms to spread traffic amongst our three nginx instances and they will proxy all requests to our resources. They will also handle tls termination for the requests.




