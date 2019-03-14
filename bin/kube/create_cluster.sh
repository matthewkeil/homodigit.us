#!/bin/bash

gcloud config set compute/zone us-central1-c

gcloud container clusters create homodigitus --machine-type=f1-micro --num-nodes=3

kubectl apply -f ../tiller/tiller.service-account.yaml

kubectl apply -f ../tiller/tiller.role-binding.yaml

helm init --service-account tiller --upgrade




[[ ! "$(kubectl get deployments -n kube-system 2> /dev/null | grep -e 'tiller-deploy')" ]] \
    && echo "error getting tiller running" && exit 1

kubectl run hello-app --image=gcr.io/google-samples/hellp-app:1.0 --port=8080
kubectl expose deployment hello-app

[[ $? -ne 0 ]] && echo "deployment of hello app failed" && exit 1



 
helm install --name nginx-ingress stable/nginx-ingress

sleep 300

kubectl get service nginx-ingress-controller

kubectl apply -f <<EOF
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: ingress-resource
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  rules:
  - http:
      paths:
      - path: /hello
        backend:
          serviceName: hello-app
          servicePort: 8080
EOF

sleep 300

[[ ! "$(kubectl get ingress ingress-resource | grep -e 'ingress-resource')" ]] && exit 1

