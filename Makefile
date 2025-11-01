# ===================================
# (0) Installer l'environnement k8s
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

## Build l'image Docker localement
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
	docker stop $(APP_NAME) || true
	docker rm $(APP_NAME) || true

## Supprime l'image locale
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

## Lance Minikube (si pas encore démarré)
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
	kubectl wait --for=condition=ready pod -l app=flask-app --timeout=60s || true
	kubectl get all

## Déploie en environnement PROD
deploy-prod:
	kubectl apply -k $(K8S_PROD)
	kubectl wait --for=condition=ready pod -l app=flask-app --timeout=60s || true
	kubectl get all

## Récupère l'URL pour accéder à l'application
get-url:
	minikube service flask-service --url

## Supprime les ressources DEV
delete-dev:
	kubectl delete -k $(K8S_DEV) || true
	kubectl delete service flask-deployment 2>/dev/null || true

## Supprime les ressources PROD
delete-prod:
	kubectl delete -k $(K8S_PROD) || true
	kubectl delete service flask-deployment 2>/dev/null || true

## Affiche les pods et services
status:
	kubectl get pods,svc,configmap,secret

## Ouvre l'application dans le navigateur via Minikube
open:
	minikube service flask-service


# ==============================
# (4.1) NETTOYAGE
# ==============================

## Arrêter k8s et tout nettoyer
k8s-clean:
	kubectl delete -k $(K8S_DEV) 2>/dev/null || true
	kubectl delete -k $(K8S_PROD) 2>/dev/null || true
	kubectl delete service flask-deployment 2>/dev/null || true
	minikube stop

## Nettoyage complet (supprime aussi Minikube)
k8s-purge:
	minikube delete


# ==============================
# (5) PUSH / AUTOMATION
# ==============================

## Push l'image vers un registre (optionnel)
push:
	# docker tag $(IMAGE) $(REGISTRY)/$(IMAGE)
	# docker push $(REGISTRY)/$(IMAGE)
	@echo "Pousse l'image avec 'docker push' si nécessaire."


# ==============================
# (6) CIBLES SPÉCIALES
# ==============================

## Relance tout de zéro (dev)
reset-dev: delete-dev
	$(MAKE) start-minikube
	eval $$(minikube docker-env) && $(MAKE) build
	$(MAKE) deploy-dev
	$(MAKE) open

## Relance tout de zéro (prod)
reset-prod: delete-prod
	$(MAKE) start-minikube
	eval $$(minikube docker-env) && $(MAKE) build
	$(MAKE) deploy-prod
	$(MAKE) open

## Déploiement automatique avec script
auto-deploy-dev:
	chmod +x run_system.sh
	./run_system.sh --dev

## Déploiement automatique avec script
auto-deploy-prod:
	chmod +x run_system.sh
	./run_system.sh --prod


# ==============================
# (7) POUSSER SUR GITHUB
# ==============================
github:
	git add .
	git commit -m "InsideKubernetes"
	git push

# ==============================
# (8) RÉDÉMARRER DOCKER
# ==============================
restart-docker:
	sudo systemctl restart docker.service
	sleep 5
	sudo systemctl restart docker.socket
	sleep 5
	sudo systemctl restart docker

# ==============================
# (9) AUTRES
# ==============================
# Show project structure
tree:
	@echo "Project Structure:"
	@echo "=================="
	@tree -I '__pycache__|*.pyc|outputs' -L 4 2>/dev/null || \
	(ls -R | grep ":$$" | sed -e 's/:$$//' -e 's/[^-][^\/]*\//--/g' -e 's/^/   /' -e 's/-/|/')

# ==============================
# (10) AIDE
# ==============================
help:
	@echo "Commandes disponibles:"
	@echo ""
	@echo "Installation:"
	@echo "  make install-k8s_env    - Installer l'environnement Kubernetes"
	@echo ""
	@echo "Docker local:"
	@echo "  make build              - Builder l'image Docker"
	@echo "  make launch             - Lancer le conteneur localement"
	@echo "  make delete             - Supprimer le conteneur"
	@echo "  make clean              - Supprimer l'image"
	@echo ""
	@echo "Kubernetes:"
	@echo "  make start-minikube     - Démarrer Minikube"
	@echo "  make deploy-dev         - Déployer en dev"
	@echo "  make deploy-prod        - Déployer en prod"
	@echo "  make auto-deploy-dev    - Déploiement automatique dev"
	@echo "  make auto-deploy-prod   - Déploiement automatique prod"
	@echo "  make delete-dev         - Supprimer ressources dev"
	@echo "  make delete-prod        - Supprimer ressources prod"
	@echo "  make status             - Voir l'état des ressources"
	@echo "  make get-url            - Obtenir l'URL de l'application"
	@echo "  make open               - Ouvrir l'application"
	@echo "  make k8s-clean          - Arrêter et nettoyer k8s"
	@echo ""
	@echo "Utilitaires:"
	@echo "  make restart-docker     - Redémarrer Docker"
	@echo "  make github             - Pousser sur GitHub"
	@echo "	 make tree				 - Donner la structure du projet"
