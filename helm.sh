#! /bin/bash
helm_chart_name=$(pwd | sed 's#.*/##' | awk '{print tolower($0)}')
echo $helm_chart_name
pwd=$(pwd | sed 's#.*/##')
pwd=$(echo $pwd | sed 's/_/-/g')
profile="Minikube-$pwd"
#check for helm, 
function set_context {
    echo "Setting kubectl context to: $profile"
    if ! kubectx $profile
    then
        echo "Failed to change context."
    fi
}

function helm_check {
    if helm version | grep Version:\"v3 > /dev/null
    then
        echo "Helm is installed..."
    else
        echo "Helm is missing, please install it with the following"
        echo "brew install helm"
        exit 1
    fi
    echo "checking for ping identity helm repo in local config..."
    if helm repo list | grep pingidentity > /dev/null
    then
        echo "Ping Identity Helm repo found!"
    else
        echo "Please add the Ping Identity Helm Repo with the following cmd:"
        echo "helm repo add pingidentity https://helm.pingidentity.com/"
        exit 1
    fi
    }
#check that minikubes up
function minikube_check {
    dir_name=$(pwd | sed 's#.*/##') ## pop's off the right most dir in the path.
    if minikube profile list | grep $dir_name > /dev/null
    then
        echo "Minikube installed"
    else 
        echo "Minikube not found or not configured for this directory."
        echo "Try re-running the make command to reconfigure minikube"
        exit 1
    fi
}
#generate secrets for the cluster with `ping-devops`

function pingdevops_check {
    chk_pingdevops=$(ping-devops info -v)
    if [[ -n $chk_pingdevops ]]
    then
        echo "ping-devops installed..."
    else
        echo "ERR: ping-devops is missing see below url for a guide on how to install it."
        echo "https://devops.pingidentity.com/get-started/pingDevopsUtil/"
        exit 1
    fi    
}

function secrets_check {
    echo "Checking Kubernetes Cluster for PingDevOps secrets"
    if kubectl get secrets | grep devops-secret > /dev/null; then 
        echo "Located Devops Secret!"
        echo "Below is the secret described."
        echo "================================="
        kubectl describe secret devops-secret
    else
        echo "Unable to find devops-secret in the K8's cluster!"
    fi 
}

function values_check {
    if [[ -e ping-devops-values.yaml ]]
    then
        echo "Ping-Devops Values file found!"
    else 
        echo "EER: ping-devops-values.yaml is missing!"
        echo "Please view the following link for details on how to create a ping-devops-values file."
        echo "https://helm.pingidentity.com/config/"
        exit 1
    fi
}

function init_secrets {
    #chk for secrets file.
    if [[ -s devops_secrets.yaml ]]
    then 
        echo "Devops secret file found! Skipping creation of file"
    else
        echo "Generating devops_secrets.yaml"
        ping-devops generate devops-secret  > devops_secrets.yaml
    fi
    echo "Applying devops_secrets.yaml to the K8 Cluster."
    if ! kubectl apply -f devops_secrets.yaml
    then
        echo "Failed to apply devops secrets to cluster!"
        exit 1
    fi
}

function init_helm {
    if helm version | grep Version:\"v3 > /dev/null
    then
        echo "Helm is installed, Skipping..."
    else
        echo "Helm not installed, installing..."
        brew install helm
    fi
    echo "Adding Ping Identity Chart to Helm"
    if helm repo list | grep pingidentity > /dev/null
    then
        echo "Ping Identity Helm repo is already added, skipping..."
    else
        echo "Please add the Ping Identity Helm Repo with the following cmd:"
        helm repo add pingidentity https://helm.pingidentity.com/
    fi
}

function init_values {
    if [[ -e ping-devops-values.yaml ]]    
    then 
        echo "Values file found, skipping..."
    else
        echo "Downloading Values file"
        curl https://helm.pingidentity.com/examples/everything.yaml > ping-devops-values.yaml
    fi
}

#apply chart
function apply_chart {
    echo "Applying Helm chart to K8's Cluster"
    if ! helm install "$helm_chart_name" pingidentity/ping-devops -f ping-devops-values.yaml
    then
        echo "ERR: Failed to apply helm chart."
        echo "Please see error log above."
        exit 1
    fi
    while true
    do 
        echo "Helm chart deployed. Waiting for pods to deploy."
        sleep 1
        if ! kubectl get pods > /dev/null
        then 
            echo "Unable to list Pods..."
            sleep 1
        else
            echo "Pods found."
            Echo "Displaying all deployed resources in Kubernetes"
            kubectl get all --selector=app.kubernetes.io/instance="$helm_chart_name"
            break
        fi
    done
}

function cleanup_chart {
    echo "Deleting Chart from the Kuberentes Cluster..."
    if helm uninstall "$helm_chart_name"
    then
        echo "Removed $helm_chart_name Chart form the cluster!"
    else
        echo "Failed to remove Chart, the Chart may already be deleted"
        echo "please check Helm docs for more info"
        echo "https://helm.sh/docs/helm/helm_uninstall/"
    fi
}

function upgrade_chart {
    echo "Deleting Chart from the Kuberentes Cluster..."
    if helm upgrade "$helm_chart_name" pingidentity/ping-devops -f ping-devops-values.yaml
    then
        echo "Upgraded $helm_chart_name Chart form the cluster!"
    else
        echo "Failed to upgrade Chart"
        echo "please check Helm docs for more info"
        echo "https://helm.sh/docs/helm/"
    fi
}
set_context
case $1 in 
check)
    echo "Checking system and current dir for Helm requirements..."
    helm_check
    minikube_check
    pingdevops_check
    values_check
    secrets_check
    ;;
init)
    echo "Initial set up..."
    init_helm
    init_values
    init_secrets
    ;;
apply)
    echo "Applying chart..."
    apply_chart
    ;;
cleanup)
    echo "Cleaning up chart..."
    cleanup_chart
    ;;
upgrade)
    echo "Upgrading chart..."
    upgrade_chart
    ;;
*)
    echo "Help msg here"
    ;;
esac