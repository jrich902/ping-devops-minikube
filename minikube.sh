#! /bin/bash
function profile_name {
    #setting up profile name
    if [ -n "$1" ]; then
        profile=$1
    else 
        pwd=$(pwd | sed 's#.*/##')
        pwd=$(echo $pwd | sed 's/_/-/g')
        profile="Minikube-$pwd"
    fi
}
function init {
    profile_name
    echo "Creating minikube profile:"
    echo $profile
    

    if minikube status -p $profile &> /dev/null; then
        echo "Minikube is running, use:\n kubectl get nodes\n to ensure you can interact with the minikube instance."
    else
        echo "Starting Minikube"
        minikube start -p $profile --cpus 6 --memory 12g --vm=true
        minikube addons enable ingress -p $profile
    fi
}

function cleanup {
    profile_name
    echo "Cleaning up Profile $profile..."
    if minikube status -p $profile | grep Running; then
        echo "Stopping Minikube.."
        minikube stop -p $profile
    else
        echo "$profile isn't running..."
    fi
    echo "Deleting current profile..."
    if minikube status -p $profile | grep Stopped; then
        echo "Deleting Minikube..."
        minikube delete -p $profile
    else
        echo "Minikube profile already Deleted!"
    fi
}

function ip {
    profile_name
    minikube -p $profile ip
}

case $1 in 
init) 
    init $2
    ;;
cleanup)
    cleanup $2
    ;;
ip)
    ip $2
    ;;
*)
    echo "Help:"
    echo "./minikube.sh <action> <instance name>"
    echo "actions:"
    echo "  init: start or create a minikube instance."
    echo "  cleanup: stop minikube if running."
    echo "instance name:"
    echo "  a name for your instance, if none is set it will name the cluster 'Minikube-<current directory name>'"
    echo "  if the file name has underscores, they will be converted to dashes due to minikube"
    ;;
esac