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
# Rendre le script exécutable
chmod +x install_kubernetes_env.sh

# Lancer l'installation
./install_kubernetes_env.sh
```

**Ou plus simplement** (via Makefile)

```bash
make install-k8s_env
```

Le script ne réinstallera jamais un composant déjà présent. Il affichera simplement sa version et passera au suivant.


## Étape 2 : Créer l'application Flask

### Créer un dossier de projet

```bash
mkdir flask-on-kubernetes/app && cd flask-on-kubernetes/app
```

### Fichier app.py

```python
from flask import Flask
app = Flask(__name__)

@app.route('/')
def hello():
    return "Hello World from Kubernetes!"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5600)
```

### Fichier requirements.txt

```
flask==3.0.0
```

### Fichier Dockerfile

```dockerfile
# Image de base
FROM python:3.10-slim

# Définir le répertoire de travail
WORKDIR /app

# Copier les fichiers nécessaires
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY /app .

# Exposer le port 5600
EXPOSE 5600

# Commande de lancement
ENTRYPOINT [ "python" ]
CMD [ "app.py" ]

```

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

### Utiliser le Docker de Minikube

Lancer `./run_system.sh` ou exécuter chacune des commandes suivantes manuellement l'une après l'autre :

```bash
# Dire au terminal d'utiliser le Docker de Minikube
eval $(minikube docker-env)

# Vérifier que Docker pointe bien sur Minikube
docker info | grep "Name"

# Rebuild l'image dans Minikube
docker build -t flask-hello:1.0 .

# Vérifier que l'image est bien dans Minikube
docker images | grep flask-hello
```

------

## Étape 3 : Déployer sur Kubernetes

### Création du Deployment

Créer un fichier `flask-deployment.yaml` :

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: flask-deployment
spec:
  replicas: 2
  selector:
    matchLabels:
      app: flask-app
  template:
    metadata:
      labels:
        app: flask-app
    spec:
      containers:
        - name: flask-container
          image: flask-hello:1.0
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: 5600
```

Appliquer la configuration :

```bash
kubectl apply -f flask-deployment.yaml
```

Si des pods sont en erreur, les supprimer et relancer le déploiement :

```bash
kubectl delete pod --all
kubectl apply -f flask-deployment.yaml
```

Vérifier les pods :

```bash
kubectl get pods
```

Sortie attendue :

```basic
NAME                                READY   STATUS    RESTARTS   AGE
flask-deployment-6cc97d48bc-d55nm   1/1     Running   0          67s
flask-deployment-6cc97d48bc-qv9c6   1/1     Running   0          67s
```

Deux Pods `flask-deployment-...` doivent être en cours d'exécution.

### Exposer le Service

Kubernetes ne permet pas d'accéder directement à un Pod, donc il faut l'exposer via un Service :

```bash
kubectl expose deployment flask-deployment --type=NodePort --port=5600
```

Sortie attendue :

```basic
service/flask-deployment exposed
```

Vérifier les services :

```bash
kubectl get services
```

Sortie attendue :

```basic
NAME               TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
flask-deployment   NodePort    10.96.241.63   <none>        5600:31181/TCP   29s
kubernetes         ClusterIP   10.96.0.1      <none>        443/TCP          8m4s
```

Un port du type 30000–32767 est ouvert.

------

## Étape 4 : Accéder à l'application

Récupérer l'URL :

```bash
minikube service flask-deployment --url
```

Sortie attendue :

```basic
http://192.168.x.y:31181
```

Ouvrir le lien dans le navigateur. Le message `Hello World from Kubernetes!` doit s'afficher.

------

## Étape 5 : Vérifier la haute disponibilité

Arrêter un pod :

```bash
kubectl get pods
```

Sortie :

```basic
NAME                                READY   STATUS    RESTARTS   AGE
flask-deployment-6cc97d48bc-d55nm   1/1     Running   0          5m24s
flask-deployment-6cc97d48bc-qv9c6   1/1     Running   0          5m24s
```

Supprimer un pod :

```bash
kubectl delete pod flask-deployment-6cc97d48bc-qv9c6
```

Sortie :

```basic
pod "flask-deployment-6cc97d48bc-qv9c6" deleted
```

Vérifier à nouveau les pods :

```bash
kubectl get pods
```

Sortie :

```basic
NAME                                READY   STATUS    RESTARTS   AGE
flask-deployment-6cc97d48bc-d55nm   1/1     Running   0          6m27s
flask-deployment-6cc97d48bc-mlvjg   1/1     Running   0          43s
```

Kubernetes recrée automatiquement un pod pour maintenir 2 réplicas. C'est le restart automatique géré par le Deployment.

------

## Étape 6 : Nettoyage

Pour supprimer tous les éléments créés :

```bash
kubectl delete service flask-deployment
kubectl delete deployment flask-deployment
minikube stop
```

Sortie attendue :

```basic
service "flask-deployment" deleted
deployment.apps "flask-deployment" deleted
✋  Nœud d'arrêt "minikube" ...
🛑  1 nœud arrêté.
```

------

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