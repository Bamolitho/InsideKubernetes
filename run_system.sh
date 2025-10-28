# Dis à ton terminal d’utiliser le Docker de Minikube
eval $(minikube docker-env)

# Vérifie que Docker pointe bien sur Minikube
docker info | grep "Name"

# Rebuild l’image dans Minikube
docker build -t flask-hello:1.0 .

# Vérifie que l’image est bien dans Minikube
docker images | grep flask-hello

# Supprime les pods en erreur et relance le déploiement
kubectl delete pod --all
kubectl apply -f flask-deployment.yaml
