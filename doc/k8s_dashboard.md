# Kubernetes Dashboard on AWS EKS
This is a quick guide to install and access Kubernetes Dashboard on AWS EKS.

## Install Kubernetes Dashboard

Use the following command to install Kubernetes Dashboard on your EKS cluster:

```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v1.10.1/src/deploy/recommended/kubernetes-dashboard.yaml
```


## EKS Admin service account

We need to create an user with admin privileges. This lab already comes with a configuration file, so you just need to run the following command:

```
kubectl apply -f k8s_config/eks-admin-service-account.yaml
```

Retrieve an authentication token with the following command:

```
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep eks-admin | awk '{print $1}')
```

Copy the authentication token to connect to the dashboard.

## Kubernetes HTTP proxy

The following command will start a proxy to the Kubernetes API server:

```
kubectl proxy
```

You can access the dashboard via this URL:

http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/#!/login


