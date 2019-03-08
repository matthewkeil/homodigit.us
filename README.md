# homodigit.us
## `Kubernetes orchestrated cluster. DevOps platform. Serves bucket storage over https. Production Node.js hosting.`

The goal of this project is to provide a template for other to easily provide a full service production and development platform. This solution was designed with modern full-stack JavaScript developer in mind and focuses on hosting pod-based node servers, serving client assets stored in cloud storage buckets over https, utilizing a cdn for edge caching all while minimizing cost and guaranteeing six-nines of reliability.

---

### `Starting from scratch - The Big Picture`
1) Deploy Kubernetes cluster
2) Setup ssl for for Helm/Tiller
3) Install Helm/Tiller
4) Configure/Deploy nginx
5) Route traffic from static IP through ingress object to nginx
6) Deploy certbot to provide and maintain ssl certificate for nginx
7) Configure/Deploy Jenkins

---

## `1) Deploy a Kubernetes cluster`
  



