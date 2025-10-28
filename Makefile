# ===================================
# (O) Installer l'environnement k8s
# ===================================

install-k8s_env:
	chmod +x install_kubernetes_env.sh 
	./install_kubernetes_env.sh

# ==============================
# (1) CONFIGURATION DU PROJET
# ==============================
APP_NAME = flask-hello
IMAGE_TAG = 1.0
IMAGE = $(APP_NAME):$(IMAGE_TAG)

# Pour utiliser Docker Hub ou un registry privé :
# REGISTRY = amomo
# IMAGE = $(REGISTRY)/$(APP_NAME):$(IMAGE_TAG)

K8S_BASE = k8s/base
K8S_DEV = k8s/overlays/dev
K8S_PROD = k8s/overlays/prod


# ===========================================
# (2) GESTION DES IMAGES & CONTENEURS DOCKER
# ===========================================

## Build l’image Docker localement
build:
	docker build -t $(IMAGE) .

## Lancer le conteneur localement
launch:
	docker run -d -p 5600:5600 --name $(APP_NAME) $(IMAGE)
	@echo "[Running] http://localhost:5600"

## Vérifie les images existantes
images:
	docker images | grep $(APP_NAME)

## Supprime le conteneur
delete:
	docker stop $(APP_NAME)
	docker rm $(APP_NAME)

## Supprime l’image locale
clean:
	docker rmi -f $(IMAGE) || true


# =====================================
# (3) CONFIGURATION MINIKUBE / DOCKER
# =====================================

## Rendre l'image Docker visible par Minikube
minikube-env:
	@echo "Run this command in your terminal:"
	@echo "eval \$$(minikube docker-env)"

## Vérifie que Docker pointe bien sur Minikube
docker-pointer:
	docker info | grep "Name"

## 1. Lance Minikube (si pas encore démarré)
start-minikube:
	minikube start --driver=virtualbox
	minikube status
	kubectl get nodes


# ==============================
# (4) DÉPLOIEMENT KUBERNETES
# ==============================

## Déploie en environnement DEV
deploy-dev:
	kubectl apply -k $(K8S_DEV)
	kubectl get all

## Déploie en environnement PROD
deploy-prod:
	kubectl apply -k $(K8S_PROD)
	kubectl get all

## Expose le service
expose:
	kubectl expose deployment flask-deployment --type=NodePort --port=5600

## Récupère l'URL pour accéder à l'application
get-url:
	minikube service flask-deployment --url

## Supprime les ressources DEV
delete-dev:
	kubectl delete -k $(K8S_DEV)

## Supprime les ressources PROD
delete-prod:
	kubectl delete -k $(K8S_PROD)

## Affiche les pods et services
status:
	kubectl get pods,svc

## Ouvre l’application dans le navigateur via Minikube
open:
	minikube service flask-service



# ==============================
# (4.1) NETTOYAGE
# ==============================

## Arreter k8s
k8s-clean:
	kubectl delete service flask-deployment
	kubectl delete deployment flask-deployment
	minikube stop


# ==============================
# (5) PUSH / AUTOMATION
# ==============================

## Push l’image vers un registre (optionnel)
push:
	# docker tag $(IMAGE) $(REGISTRY)/$(IMAGE)
	# docker push $(REGISTRY)/$(IMAGE)
	@echo "Pousse ton image avec 'docker push' si nécessaire."


# ==============================
# (6) CIBLES SPÉCIALES
# ==============================

## Relance tout de zéro (dev)
reset-dev: clean start-minikube build deploy-dev open

## Relance tout de zéro (prod)
reset-prod: clean start-minikube build deploy-prod open