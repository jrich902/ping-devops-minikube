.PHONEY: init check apply
init: 
	./minikube.sh init
	./helm.sh init

cleanup:
	./helm.sh cleanup
	./minikube.sh cleanup

redeploy: 
	./helm.sh cleanup
	./helm.sh apply
	
check:
	./helm.sh check

apply:
	./helm.sh apply
upgrade:
	./helm.sh upgrade
ip:
	./minikube.sh ip