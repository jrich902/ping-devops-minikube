# Helm Local Lab

This guide is to provide you a quick way to deploy minikube and then apply the PingDevops Helm chart to the minikube instance.

This is intended to help us troubleshoot issues with customers my-values.yaml file on your local system.

## Prereq's
homebrew: https://brew.sh/

helm: `brew install helm`

minikube: `brew install minikube`

pingdevops: https://devops.pingidentity.com/get-started/pingDevopsUtil/

Have your PingDevops License, and have it applied via `pingdevops config` 
If you find the instructions for setting up pingdevops a little lacking, I wrote a guide here https://gitlab.corp.pingidentity.com/gso-labs/pingdevops

Depending how much ram your macbook has, It can limit the number of products you deploy at once. You can do things like deploy only 1 pod in a stateful set, or try and lower the ram or cpu requested by these using the values file. Reach out in the #pingdevops-gso chat if you have questions or are stuck with this.

## How to use the tool?

To use this tool you just need to clone the repo to your macbook where ever you keep your git projects. I keep mine in `~/projects` so the documentation will be based of this.

Clone this repo to your mac.
```bash
cd ~/projects
git@gitlab.corp.pingidentity.com:gso-labs/local_helm.git
cd local_helm
```

Run Make init to set up Helm and Minikube. 
```bash
make init
```

After the make init is competed, it will have downloaded the latest version of the values.yaml from the PingDevops Helm Repo. It will save the file as `ping-devops-values.yaml` You are now able to open this file with your editor of choice and make the changes required. Please note that the default values file does NOT deploy any of the products, You will have to modify this to have it deploy the products you require.

In the ping-devops-values.yaml file, look for lines of code _like_ the following for each one of our products you would like to deploy.
```yaml
#############################################################
# pingfederate-admin values
#############################################################
pingfederate-admin:
  enabled: false
  name: pingfederate-admin
  image:
    name: pingfederate
```
change the value of `enabled` to `true` on each of the products you need to deploy with the helm chart. Then save the file. 

After this is done you can use make to apply the changes to the minikube cluster
```
make apply
```

When the apply is completed you should be able to run `kubectl` or use `k9s` to explore the cluster and ensure the products pods are deployed and starting.

## What if I need to make changes to the values file and redeploy? 

All you need to do is make the required changes to the `ping-devops-values.yaml` file, then run `make redeploy` and it will delete the old helm release and redeploy a new release. 

## How to Cleanup?

To cleanup after using the tool, just run `make cleanup` and it will delete the helm chart from the cluster, and then delete the minikube cluster. This way your mac is not running the cluster 24/7 and you can save your ram for 20 more tabs in Chrome.