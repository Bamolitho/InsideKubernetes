# Comprendre l'architecture de Kubernetes avec Minikube

Quand on lance Minikube, plusieurs conteneurs apparaissent dans `docker ps`. Ce document explique à quoi ils servent et comment ils s'organisent pour faire fonctionner un cluster Kubernetes complet sur une machine locale.

------

## Vue d'ensemble de la sortie `docker ps`

Voici la sortie complète, réorganisée par namespace pour mieux comprendre la structure :

```less
CONTAINER ID   IMAGE                          COMMAND                  CREATED          STATUS          PORTS     NAMES
```

### Namespace `default` — Application Flask

```less
14360cdb1757   291e0854db36                   "python app.py"          10 minutes ago   Up 10 minutes             k8s_flask-container_flask-deployment-6dbf944f88-s9sbn_default_af3ab0c1-a23a-45da-b5c1-5d201887e6bc_0
e38e9711b084   registry.k8s.io/pause:3.10.1   "/pause"                 10 minutes ago   Up 10 minutes             k8s_POD_flask-deployment-6dbf944f88-s9sbn_default_af3ab0c1-a23a-45da-b5c1-5d201887e6bc_0
```

### Namespace `kube-system` — Composants Kubernetes

**Plan de contrôle (Control Plane)**

```less
911324e09c0a   90550c43ad2b                   "kube-apiserver --ad…"   15 minutes ago   Up 15 minutes             k8s_kube-apiserver_kube-apiserver-minikube_kube-system_b6c933ad799c2f2a606def4e86729f91_1
d6625f9eee61   5f1f5298c888                   "etcd --advertise-cl…"   15 minutes ago   Up 15 minutes             k8s_etcd_etcd-minikube_kube-system_21cc8bcb04e75417c1bf09639d887c65_1
dd2f59932aac   a0af72f2ec6d                   "kube-controller-man…"   15 minutes ago   Up 15 minutes             k8s_kube-controller-manager_kube-controller-manager-minikube_kube-system_e8825cdc0eb52956a20c4779932dbf93_1
c212e6f07559   46169d968e92                   "kube-scheduler --au…"   15 minutes ago   Up 15 minutes             k8s_kube-scheduler_kube-scheduler-minikube_kube-system_dc6cf0a7bcb54d1f95cecc4d7b6b7d67_1
```

**Réseau et DNS**

```less
44fd38c51c64   df0860106674                   "/usr/local/bin/kube…"   15 minutes ago   Up 15 minutes             k8s_kube-proxy_kube-proxy-b4z9w_kube-system_d2aafe53-df09-4ac2-86c1-46e65a787837_1
4f53efc80b87   52546a367cc9                   "/coredns -conf /etc…"   15 minutes ago   Up 15 minutes             k8s_coredns_coredns-66bc5c9577-7m489_kube-system_33b6985c-76a1-4e3f-bcc2-7957ce111dd4_1
```

**Stockage**

```less
58bc302d1377   6e38f40d628d                   "/storage-provisioner"   14 minutes ago   Up 14 minutes             k8s_storage-provisioner_storage-provisioner_kube-system_38ddade9-64cd-4a58-9eb9-a9a0cc2ac861_3
```

**Conteneurs pause (infrastructure des Pods)**

```less
61557e186b97   registry.k8s.io/pause:3.10.1   "/pause"                 15 minutes ago   Up 15 minutes             k8s_POD_kube-apiserver-minikube_kube-system_b6c933ad799c2f2a606def4e86729f91_2
35b298f99c0d   registry.k8s.io/pause:3.10.1   "/pause"                 15 minutes ago   Up 15 minutes             k8s_POD_etcd-minikube_kube-system_21cc8bcb04e75417c1bf09639d887c65_2
d9b8e9a3343f   registry.k8s.io/pause:3.10.1   "/pause"                 15 minutes ago   Up 15 minutes             k8s_POD_kube-controller-manager-minikube_kube-system_e8825cdc0eb52956a20c4779932dbf93_2
716961a2ae72   registry.k8s.io/pause:3.10.1   "/pause"                 15 minutes ago   Up 15 minutes             k8s_POD_kube-scheduler-minikube_kube-system_dc6cf0a7bcb54d1f95cecc4d7b6b7d67_2
94a03f235a83   registry.k8s.io/pause:3.10.1   "/pause"                 15 minutes ago   Up 15 minutes             k8s_POD_kube-proxy-b4z9w_kube-system_d2aafe53-df09-4ac2-86c1-46e65a787837_1
8d179ac9cc78   registry.k8s.io/pause:3.10.1   "/pause"                 15 minutes ago   Up 15 minutes             k8s_POD_coredns-66bc5c9577-7m489_kube-system_33b6985c-76a1-4e3f-bcc2-7957ce111dd4_1
e5b72362a990   registry.k8s.io/pause:3.10.1   "/pause"                 15 minutes ago   Up 15 minutes             k8s_POD_storage-provisioner_kube-system_38ddade9-64cd-4a58-9eb9-a9a0cc2ac861_1
```

------



## Pourquoi autant de conteneurs ?

Minikube crée un vrai cluster Kubernetes complet sur la machine locale. Ce cluster se compose de plusieurs éléments qui fonctionnent ensemble. C'est tout à fait normal de voir autant de conteneurs : chaque composant Kubernetes tourne dans son propre conteneur Docker.

Au total, on trouve :

- 1 conteneur pour l'application Flask
- 1 conteneur pause pour ce Pod
- Environ 10 à 12 conteneurs pour le système Kubernetes lui-même



## Sortie `docker ps` réorganisée pour être **ultra lisible** 

------

### **Application (code Flask)**

```less
14360cdb1757  flask-container         "python app.py"                  → Application Flask

e38e9711b084  pause                   "/pause"                         → Conteneur infra du Pod Flask (namespace réseau)
```

------

### Composants réseau & stockage

```less
44fd38c51c64  kube-proxy              "/usr/local/bin/kube-proxy"      → Routage réseau entre Pods et Services

4f53efc80b87  coredns                 "/coredns -conf /etc/..."        → DNS interne du cluster

58bc302d1377  storage-provisioner     "/storage-provisioner"           → Gestion dynamique du stockage
```

###  **Composants maîtres (control plane)**

```less
911324e09c0a  kube-apiserver          "kube-apiserver --ad..."         → API centrale du cluster

d6625f9eee61  etcd                    "etcd --advertise-cl..."         → Base de données clé-valeur (état du cluster)

dd2f59932aac  kube-controller-manager "kube-controller-man..."         → Maintien de l’état désiré du cluster

c212e6f07559  kube-scheduler          "kube-scheduler --au..."         → Décide sur quel nœud exécuter chaque Pod
```

------

### **Conteneurs "pause" (infrastructure)**

```less
61557e186b97  pause                   "/pause"  → Pod kube-apiserver
35b298f99c0d  pause                   "/pause"  → Pod etcd
d9b8e9a3343f  pause                   "/pause"  → Pod kube-controller-manager
716961a2ae72  pause                   "/pause"  → Pod kube-scheduler
94a03f235a83  pause                   "/pause"  → Pod kube-proxy
8d179ac9cc78  pause                   "/pause"  → Pod coredns
e5b72362a990  pause                   "/pause"  → Pod storage-provisioner
```

------

### **Résumé visuel**

```less
[Application]          → Flask + pause  
[Réseau & Stockage]    → kube-proxy, coredns, storage-provisioner  
[Control Plane]        → kube-apiserver, etcd, controller, scheduler  
[Infras Pods]          → Conteneurs "pause" (1 par Pod)
```

------



# Vue d’ensemble du cluster Minikube

Quand on démarre **Minikube**, il crée un **cluster Kubernetes complet**, mais **sur sa machine locale**. Ce cluster contient plusieurs composants essentiels au fonctionnement de Kubernetes. Chaque composant tourne dans un conteneur séparé (géré par Docker ici).

Les conteneurs se répartissent en **3 grandes familles** :

------

## 1️⃣ **L'application Flask**

| Type              | Nom / Commande  | Rôle concret                                                 |
| ----------------- | --------------- | ------------------------------------------------------------ |
| **App**           | `python app.py` | C’est **l'application Flask**, le cœur de du projet. Kubernetes la fait tourner dans un Pod (ici : `flask-deployment-...`). |
| **Infra (pause)** | `/pause`        | Gère le **namespace réseau** du Pod. Le conteneur Flask partage son IP grâce à lui. |

#### `python app.py` (flask-container)

C’est le **conteneur applicatif** :

- Il exécute ton code Flask (`app.py`).
- Il a été créé à partir de ton image `flask-hello:1.0`.
- Kubernetes le gère dans un **pod** (ici `flask-deployment-xxxxx`).
- S’il tombe, Kubernetes le redémarre automatiquement (grâce au Deployment).
  

## 2️⃣ **Les services essentiels de Kubernetes **

### 🧠 **Composants maîtres (control plane)**

C’est **le cerveau** du cluster.

| Conteneur                 | Rôle                                                         |
| ------------------------- | ------------------------------------------------------------ |
| `kube-apiserver`          | - C’est **l’API centrale** de Kubernetes. <br />- Tous les outils (`kubectl`, `dashboard`, etc.) passent par lui.. <br />- C’est le **cerveau du cluster**, celui qui reçoit et applique les ordres (déployer un pod, exposer un service, etc.). |
| `etcd`                    | - C’est la **base de données clé-valeur** du cluster. <br />- Il stocke **tout l’état du cluster** (pods, services, secrets, configs...). <br />- Si on perd `etcd`, on perd la mémoire de son cluster. |
| `kube-controller-manager` | - Vérifie en continu que **l’état réel = état désiré**  <br />- Il gère les **boucles de contrôle** (“control loops”) qui maintiennent l’état du cluster.<br /> - **Exemple** : si un pod crash, le controller le recrée. |
| `kube-scheduler`          | - Il décide **sur quel nœud** (machine virtuelle, minikube ici) exécuter chaque pod. <br />- Il se base sur les ressources disponibles, les affinités, etc. |

### **Plan de données (data plane) et réseau**

C’est **la partie opérationnelle** du cluster.

| Conteneur             | Rôle                                                         |
| --------------------- | ------------------------------------------------------------ |
| `kube-proxy`          | - Gère le **routage réseau entre pods et services**. <br />- **Concrètement** : c’est grâce à lui qu’un pod peut parler à un autre pod (ou à l’extérieur). <br />- Il installe des règles iptables pour diriger le trafic vers le bon conteneur. |
| `coredns`             | - Serveur **DNS interne** au cluster: traduit les noms en adresses IP internes. <br />- Quand le conteneur Flask veut contacter `flask-service`, `mongodb-service`, c’est `coredns` qui résout ce nom en IP du service. |
| `storage-provisioner` | - Gère le **stockage dynamique** dans Minikube. <br /><br />- Crée les **volumes de stockage** automatiques quand un Pod en demande.  <br />- Si on demande un PersistentVolumeClaim, c’est lui qui crée le volume local associé. |



## 3️⃣ **Les conteneurs "pause"**

| Nom / Image                    | Rôle                                                         |
| ------------------------------ | ------------------------------------------------------------ |
| `registry.k8s.io/pause:3.10.1` | - Il ne fait *rien* visiblement, mais il est **le conteneur racine du Pod**.<br />- **Conteneurs "infrastructures"** créés automatiquement par Kubernetes pour isoler l'application du système. <br />- Chaque pod a un conteneur `pause` pour créer et maintenir le namespace réseau et IPC. <br />- Sans lui, les conteneurs du Pod seraient isolés. <br />-  Les autres conteneurs du Pod (comme `python app.py`) s’exécutent **dans le même namespace** que lui, partageant le même IP et les ports. |

**Exemples** :
 `k8s_POD_flask-deployment-...`, `k8s_POD_coredns-...`

> **Concretement** : sans le `pause`, le conteneur Flask aurait son propre réseau séparé — impossible de partager l’adresse IP du Pod.



## En résumé 

- 1 conteneur pour **l'application Flask**
- 1 conteneur `pause` pour ce pod
- et environ **10–12 conteneurs pour Kubernetes lui-même**

Donc, **rien d’anormal** : c’est juste le cluster local complet qui tourne.

```less
+---------------------------------------------------------------+
|                      CLUSTER MINIKUBE                         |
|---------------------------------------------------------------|
|  Control Plane : kube-apiserver, etcd, scheduler, controller  |
|  Data Plane    : kube-proxy, coredns, storage-provisioner     |
|---------------------------------------------------------------|
|  Application Pods :                                           |
|     flask-deployment --> [ pause + python app.py ]            |
|---------------------------------------------------------------|
|  Chaque composant tourne dans un conteneur Docker distinct    |
+---------------------------------------------------------------+
```



## Comment Kubernetes organise les conteneurs à l’intérieur d’un Pod

Voici une **représentation visuelle simplifiée** d’un **Pod** (le plus petit élément déployable dans Kubernetes) :

```less
+-------------------------------------------------------+
|                      POD (flask-pod)                  |
|-------------------------------------------------------|
|  [pause container]  -> crée le namespace réseau, PID  |
|-------------------------------------------------------|
|  [flask-container]  -> exécute "python app.py"        |
|-------------------------------------------------------|
|  Shared resources:                                    |
|   - Same IP address                                   |
|   - Same hostname                                     |
|   - Shared volumes (/data, /tmp...)                   |
+-------------------------------------------------------+
```

### Textuellement :

- Chaque **Pod** a **une seule adresse IP**, commune à tous ses conteneurs.
- Le conteneur `pause` sert de **processus parent** pour tout le Pod (il maintient le namespace).
- Tous les autres conteneurs (l'app, sidecars, etc.) **vivent dans ce namespace**.
- Kubernetes ne gère **jamais des conteneurs seuls**, mais **des Pods**.

> En gros : un Pod = un mini “ordinateur” isolé, avec plusieurs conteneurs qui coopèrent dans le même espace réseau.

### Exemple concret avec le Pod Flask

Le Pod `flask-deployment-6dbf944f88-s9sbn` contient :

- Un conteneur `pause` qui configure le réseau du Pod (par exemple `10.244.x.x`)
- Un conteneur `python app.py` qui écoute sur le port 5600 dans ce réseau

Kubernetes, via `kube-proxy`, redirige le trafic du Service `flask-service` vers ce Pod. 

**Réseultat** : on exécute `minikube service flask-service`, le navigateur accède indirectement au Pod via le proxy.

## Architecture complète du cluster Minikube

```
                           ╔══════════════════════════════════════════╗
                           ║              MINIKUBE NODE               ║
                           ║   (Machine virtuelle du cluster local)   ║
                           ╚══════════════════════════════════════════╝
                                          │
                ┌─────────────────────────┼─────────────────────────┐
                │                         │                         │
     ╔═══════════════════════╗            │              ╔══════════════════════╗
     ║ Namespace: kube-system║            │              ║ Namespace: default   ║
     ╚═══════════════════════╝            │              ╚══════════════════════╝
                │                         │                      │
 ┌──────────────────────────────────┐     │       ┌──────────────────────────────┐
 │         PLAN DE CONTRÔLE         │     │       │     APPLICATION FLASK        │
 └──────────────────────────────────┘     │       └──────────────────────────────┘
 │  • kube-apiserver      → point d'entrée API   				 │
 │  • etcd                → base de données clés:valeurs		 │
 │  • controller-manager  → maintient l'état désiré				 |
 │  • scheduler           → planifie les Pods   			     │
 │                                              			     │
 │  • kube-proxy          → gère le routage réseau				 |
 │  • coredns             → DNS interne (résolution				 |
 │                          service → pod)        				 │
 │  • storage-provisioner → gère les volumes      				 │
 │                                               				 │
 │                 	                                    ╔═══════════════════╗
 │                                                      ║ Deployment: flask ║
 │          	                                        ╚═══════════════════╝
 │                                               				 │
 │                                        					crée et gère
 │                                      				  des Pods identiques
 │                                      	        		     │
 │                                                      ╔═══════════════════════╗
 │                                                      ║ Pod: flask-deployment ║
 │                                                      ║-----------------------║
 │                                                      ║ • flask-container     ║
 │                                                      ║   (python app.py)     ║
 │                                                      ║ • pause (infra réseau)║
 │                                                      ╚═══════════════════════╝
 │                                                				 │
 │                                  				 exposé via un Service
 │                                               				 │
 │                                                      ╔═════════════════════╗
 │                                                      ║ Service: flask-svc  ║
 │                                                      ║ type: ClusterIP     ║
 │                                                      ╚═════════════════════╝
 │                                                				 │
 │                            				 redirigé par kube-proxy vers le Pod
 │                                                				 │
 │                          				 accessible depuis l'extérieur via Minikube
 │                                                				 │
 │                                                ╔═══════════════════════════════════╗
 │                                                ║ minikube service flask-service    ║
 │                                                ║ → ouvre http://localhost:5600     ║
 │                                                ╚═══════════════════════════════════╝
 │
 └───────────────────────────────────────────────────────────────────────────┘
```

------



## Comment Kubernetes orchestre une application

## 1️⃣ Le **Deployment**

C’est **le chef d’orchestre** de l'application.

**Rôle concret :**

- Il décrit **combien de Pods** on veut (par exemple `replicas: 2`).
- Il garantit que son Pod tourne toujours (si un crash → il le redéploie).
- Il définit **l’image Docker à utiliser**, les ports exposés, les labels, etc.

**Exemple simplifié (flask-deployment.yaml)** :

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: flask-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: flask
  template:
    metadata:
      labels:
        app: flask
    spec:
      containers:
      - name: flask-container
        image: flask-hello:1.0
        ports:
        - containerPort: 5600
```

**Effet concret :**
 → Kubernetes lit ça et crée 1 Pod (nommé par exemple `flask-deployment-6dbf944f88-s9sbn`)
 → Ce Pod contient son conteneur Flask et son conteneur `pause`

------

## 2️⃣ Le **Pod**

C’est **l’unité d’exécution réelle** de son app dans le cluster.

**Rôle concret :**

- Il contient le conteneur Flask (avec `python app.py`).
- Il écoute sur le port interne `5600` (défini dans `containerPort`).
- Il a **une IP interne unique** dans le cluster, par exemple `10.244.0.12`.

Mais : cette IP n’est **pas stable** !
Si le Pod est redémarré, il change d’adresse IP → donc on ne peut pas le contacter directement.

------

## 3️⃣ Le **Service**

C’est **le point d’entrée stable** pour atteindre un ou plusieurs Pods.

**Rôle concret :**

- Il agit comme un **load balancer interne**.
- Il possède une **IP fixe dans le cluster** (ClusterIP).
- Il redirige les requêtes vers les Pods dont les **labels** correspondent (ici `app: flask`).

**Exemple :**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: flask-service
spec:
  type: NodePort
  selector:
    app: flask
  ports:
    - port: 5600        # Port du Service
      targetPort: 5600  # Port du conteneur Flask
      nodePort: 30008   # Port exposé sur Minikube (entre 30000 et 32767)
```

**Effet concret :**
 → Le service s’associe automatiquement au Pod `flask-deployment-...`
 → Toute requête envoyée au port `30008` (NodePort) sera redirigée vers le conteneur Flask (port 5600)

------

## 4️⃣ `minikube service`

C’est la **passerelle** entre son ordinateur et le cluster Kubernetes.

**Quand tu fais :**

```bash
minikube service flask-service --url
```

Minikube :

1. Cherche le port `NodePort` du service (`30008` dans cet exemple),

2. Crée un tunnel entre son **navigateur local** et le **nœud Kubernetes**,

3. Et te renvoie une URL du type :

   ```
   http://127.0.0.1:xxxxx
   ```

4. Cette URL redirige son trafic vers son conteneur Flask via Kubernetes.

------

## Chaîne de communication complète

Du navigateur jusqu'au code Flask, voici le parcours d'une requête :

```
[ Navigateur ]
        │
        ▼
(1) minikube service flask-service
        │
        ▼
[ NodePort Service (30008) sur le nœud Minikube ]
        │
        ▼
[ Service "flask-service" (ClusterIP) ]
        │
        ▼
Sélectionne les Pods avec label app=flask
        │
        ▼
[ Pod : flask-deployment-6dbf944f88-s9sbn ]
        │
        ▼
[ Conteneur Flask → python app.py → écoute sur port 5600 ]
        │
        ▼
[ Réponse HTTP renvoyée au navigateur ]
```

------

## Hiérarchie des composants

```
Deployment (gère la stratégie et le nombre de Pods)
    ↓
Pod(s) (unité d'exécution avec conteneurs)
    ↓
Service (point d'accès stable, load balancer interne)
    ↓
minikube service (ouvre le port vers la machine locale)
```

------



## 💡Commandes utiles

Voir uniquement l'application :

```bash
kubectl get pods
```

Filtrer les conteneurs Flask :

```bash
docker ps | grep flask
```

Voir la hiérarchie Pods et Containers :

```bash
kubectl describe pod flask-deployment-...
```