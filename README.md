# Déployer une application Flask sur Kubernetes avec Minikube

## Objectif d'apprentissage

- Créer un **Pod**
- Déployer une **application Flask**
- La gérer via un **Deployment**
- L’exposer via un **Service**
- Et la visualiser dans son **navigateur via Minikube**

------

## Étape 1 : Préparation et installation

### Installer Docker

Kubernetes utilise un moteur de conteneur (Docker ou containerd) pour exécuter les Pods.

```bash
sudo apt update

sudo apt install docker.io -y

sudo systemctl enable docker

sudo systemctl start docker
```

Vérifier l'installation :

```bash
docker --version
```

### Installer kubectl

kubectl est l'outil de ligne de commande pour piloter le cluster.

```bash
sudo apt-get update

sudo apt-get install -y apt-transport-https ca-certificates curl gpg

sudo mkdir -p -m 755 /etc/apt/keyrings

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get install -y kubectl
```

Vérifier la version :

```basic
kubectl version --client
```

Sortie attendue :

```basic
Client Version: v1.30.14
Kustomize Version: v5.0.4-0.20230601165947-6ce0bf390ce3
```

### Installer Minikube

Minikube crée un cluster Kubernetes local sur la machine. C'est la solution idéale pour débuter, car elle montre clairement le fonctionnement d'un vrai cluster Kubernetes avec un master et un worker.

###### Installer VirtualBox

```bash
sudo apt install -y virtualbox virtualbox-ext-pack
```

#### **Attention importante concernant VirtualBox**

La commande `sudo apt install -y virtualbox virtualbox-ext-pack` réinstalle VirtualBox depuis les dépôts Ubuntu, ce qui peut remplacer ou écraser la version actuelle si elle avait été installée manuellement depuis le site d'Oracle ou via un autre dépôt. C'est pour ça que VirtualBox peut "disparaître" ou devenir inutilisable après cette commande.

**Pourquoi ça se produit**

- Ubuntu a sa propre version de VirtualBox (souvent plus ancienne)
- Si une version plus récente depuis le dépôt Oracle officiel était déjà installée, l'installation via `apt install virtualbox` va rétrograder ou remplacer cette version
- Quand ça arrive, le kernel module (vboxdrv) devient incompatible → VirtualBox ne démarre plus, et les VMs ne sont plus reconnues

**Ce qu'il faut faire à la place**

Si VirtualBox est déjà installé et fonctionne, ne pas le réinstaller. Installer simplement Minikube sans toucher à VirtualBox :

```bash
sudo apt install -y curl apt-transport-https

curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64

sudo install minikube-linux-amd64 /usr/local/bin/minikube
```

**Vérifier la version actuelle avant toute installation**

Avant d'installer quoi que ce soit :

```bash
vboxmanage --version
```

Si un numéro de version s'affiche (par exemple `7.0.18r162988`), VirtualBox est déjà bien installé. Dans ce cas, sauter l'étape d'installation de VirtualBox dans le tutoriel.

### Démarrer le cluster local

```bash
minikube start --driver=virtualbox
```

Sortie attendue :

```basic
😄  minikube v1.37.0 sur Ubuntu 24.04
✨  Utilisation du pilote virtualbox basé sur la configuration de l'utilisateur
💿  Téléchargement de l'image de démarrage de la VM...
    > minikube-v1.37.0-amd64.iso....:  65 B / 65 B [---------] 100.00% ? p/s 0s
    > minikube-v1.37.0-amd64.iso:  370.78 MiB / 370.78 MiB  100.00% 11.65 MiB p
👍  Démarrage du nœud "minikube" primary control-plane dans le cluster "minikube"
💾  Téléchargement du préchargement de Kubernetes v1.34.0...
    > preloaded-images-k8s-v18-v1...:  337.07 MiB / 337.07 MiB  100.00% 18.66 M
🔥  Création de VM virtualbox (CPUs=2, Mémoire=3072MB, Disque=20000MB)...
🐳  Préparation de Kubernetes v1.34.0 sur Docker 28.4.0...
🔗  Configuration de bridge CNI (Container Networking Interface)...
🔎  Vérification des composants Kubernetes...
    ▪ Utilisation de l'image gcr.io/k8s-minikube/storage-provisioner:v5
🌟  Modules activés: default-storageclass, storage-provisioner
🏄  Terminé ! kubectl est maintenant configuré pour utiliser "minikube" cluster et espace de noms "default" par défaut.
```

### Synchroniser kubectl local

Pour que kubectl pointe bien vers le bon cluster :

```bash
kubectl config use-context minikube
```

Vérifier que tout fonctionne :

```bash
kubectl get nodes
```

Sortie attendue :

```basic
NAME       STATUS   ROLES           AGE     VERSION
minikube   Ready    control-plane   2m20s   v1.34.0
```

------

## Alternative (script d'automatisation)

Il y a le script [install_kubernetes_env.sh](./install_kubernetes_env.sh) qui automatise l'installation

Voici ce qu'il fait :

**Fonctionnalités principales :**

1. **Vérification avant installation** : Chaque composant est vérifié avant d'être installé
2. **Messages clairs** : Indique ce qui est déjà installé ou ce qui va être installé
3. **Sécurité pour VirtualBox** : Ne touche pas à VirtualBox s'il est déjà présent
4. **Résumé final** : Affiche l'état de tous les composants à la fin

**Pour l'utiliser :**

```bash
make install-k8s_env
```

Le script ne réinstallera jamais un composant déjà présent. Il affichera simplement sa version et passera au suivant.


## Étape 2 : Créer l'application Flask

### Créer un dossier de projet

```bash
mkdir InsideKubernetes/app && cd InsideKubernetes/app
```

### Fichier app.py

Contenu : [app.py](./app/app.py)

### Fichier requirements.txt

Contenu : [requirements.txt](./requirements.txt)

### Fichier Dockerfile

Contenu : [Dockerfile](./Dockerfile)

### Construire et tester l'image Docker

Construire l'image :

```bash
docker build -t flask-hello:v1 .
```

Tester localement :

```bash
docker run -p 5600:5600 flask-hello:1.0
```

Ouvrir le navigateur sur `http://localhost:5600`. Le message `Hello World from Kubernetes!` doit s'afficher.

------

## Étape 3 : Déployer sur Kubernetes

Deux modes de déploiment possible : 

1. **Développement** : lancer automatiquement le script [run_system.sh](./run_system.sh) en mode dev

   ```bash
   make auto-deploy-dev
   ```

2. **Production **: lancer automatiquement le script [run_system.sh](./run_system.sh) en mode prod

   ```bash
   make auto-deploy-prod
   ```

------

#### Sortie attendue pour make auto-deploy-prod :

```basic
amolitho@amolitho:~/InsideKubernetes$ make auto-deploy-prod 
chmod +x run_system.sh
./run_system.sh --prod
==========================================
Déploiement en environnement: PROD
==========================================

[1/6] Vérification de Minikube...
Démarrage de Minikube...
😄  minikube v1.37.0 sur Ubuntu 24.04
✨  Utilisation du pilote virtualbox basé sur le profil existant
👍  Démarrage du nœud "minikube" primary control-plane dans le cluster "minikube"
🔄  Redémarrage du virtualbox VM existant pour "minikube" ...
🐳  Préparation de Kubernetes v1.34.0 sur Docker 28.4.0...
🔗  Configuration de bridge CNI (Container Networking Interface)...
🔎  Vérification des composants Kubernetes...
    ▪ Utilisation de l'image gcr.io/k8s-minikube/storage-provisioner:v5
🌟  Modules activés: default-storageclass, storage-provisioner

❗  /usr/bin/kubectl est la version 1.30.14, qui peut comporter des incompatibilités avec Kubernetes 1.34.0.
    ▪ Vous voulez kubectl v1.34.0 ? Essayez 'minikube kubectl -- get pods -A'
🏄  Terminé ! kubectl est maintenant configuré pour utiliser "minikube" cluster et espace de noms "default" par défaut.
✓ Minikube démarré

[2/6] Configuration de Docker pour Minikube...
✓ Docker pointe sur: minikube

[3/6] Build de l'image Docker...
✓ Image flask-hello:1.0 existe déjà, skip du build
✓ Image flask-hello:1.0 disponible

[4/6] Nettoyage des anciennes ressources...
Aucune ressource à supprimer

[5/6] Déploiement Kubernetes (prod)...
configmap/flask-config created
secret/flask-secret created
service/flask-service created
deployment.apps/flask-deployment created
Attente du démarrage des pods...
pod/flask-deployment-6dbf944f88-58xwl condition met
pod/flask-deployment-6dbf944f88-clslf condition met
pod/flask-deployment-6dbf944f88-f4sfs condition met
⚠ Timeout ou pods pas encore prêts, vérifiez avec 'kubectl get pods'

[6/6] État du déploiement:
==========================
NAME                                READY   STATUS    RESTARTS   AGE
flask-deployment-6dbf944f88-58xwl   1/1     Running   0          60s
flask-deployment-6dbf944f88-clslf   1/1     Running   0          60s
flask-deployment-6dbf944f88-f4sfs   1/1     Running   0          60s

NAME            TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
flask-service   NodePort    10.102.5.179   <none>        5600:31181/TCP   61s

==========================================
✓ Application déployée avec succès!
==========================================

URL d'accès:
http://192.168.59.101:31181

Commandes utiles:
  minikube service flask-service      # Ouvrir dans le navigateur
  kubectl logs -l app=flask-app       # Voir les logs
  kubectl get all                     # Voir toutes les ressources
  make delete-prod                  # Nettoyer
==========================================
```



**Voir toutes les ressources : *kubectl get all***

**Sortie attendue:** 

```basic
amolitho@amolitho:~/InsideKubernetes$ kubectl get all
NAME                                    READY   STATUS    RESTARTS   AGE
pod/flask-deployment-6dbf944f88-58xwl   1/1     Running   0          5m2s
pod/flask-deployment-6dbf944f88-clslf   1/1     Running   0          5m2s
pod/flask-deployment-6dbf944f88-f4sfs   1/1     Running   0          5m2s

NAME                    TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
service/flask-service   NodePort    10.102.5.179   <none>        5600:31181/TCP   5m3s
service/kubernetes      ClusterIP   10.96.0.1      <none>        443/TCP          5d1h

NAME                               READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/flask-deployment   3/3     3            3           5m3s

NAME                                          DESIRED   CURRENT   READY   AGE
replicaset.apps/flask-deployment-6dbf944f88   3         3         3       5m3s

```

## Résumé des concepts pratiqués

| Élément            | Rôle                                                         |
| ------------------ | ------------------------------------------------------------ |
| Pod                | Contient le conteneur Flask                                  |
| Deployment         | Définit le nombre de réplicas et gère le redémarrage automatique |
| Service (NodePort) | Expose l'application Flask en dehors du cluster              |
| Minikube           | Fournit un cluster Kubernetes local pour les tests           |
| kubectl            | Permet d'interagir avec le cluster                           |

------

## Architecture de déploiement

```basic
[ Navigateur ]
        │
        ▼
[ minikube service flask-deployment ]
        │
        ▼
[ Service (NodePort 31181) ]
        │
        ▼
[ Deployment flask-deployment ]
        │
        ├─────────────────┐
        ▼                 ▼
[ Pod replica 1 ]   [ Pod replica 2 ]
        │                 │
        ▼                 ▼
[ flask-container ]  [ flask-container ]
   port 5600            port 5600
```

Le Deployment crée et maintient 2 réplicas du Pod. Le Service distribue le trafic entre ces réplicas. Si un Pod tombe, Kubernetes le recrée automatiquement pour respecter le nombre de réplicas défini.