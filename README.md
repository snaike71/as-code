# TP Docker Registry AWS (Terraform + Ansible)

Ce projet deploie automatiquement un registre Docker prive sur AWS.

## Architecture cible

- Une instance EC2 `t3.micro` (Ubuntu 24.04)
- Registre Docker sur le port `5000`
- Interface web sur le port `80`
- Authentification basique `htpasswd`

## Structure

- `infra/` : code Terraform (provisioning AWS)
- `config/` : code Ansible (configuration serveur + stack Docker)

## Etapes du TP

### 1. Provisioning Terraform

```bash
cd infra
terraform init
terraform apply -auto-approve
```

Resultat attendu :
- Instance EC2 creee
- Fichier `registry-key.pem` genere
- IP publique affichee dans l'output `public_ip`

### 2. Mettre a jour l'inventaire Ansible

Dans `config/inventory.ini`, remplacer l'IP :

```ini
[registry]
registry-host ansible_host=<PUBLIC_IP> ansible_user=ubuntu ansible_ssh_private_key_file=../infra/registry-key.pem
```

### 3. Deploiement Ansible

```bash
cd ../config
chmod 400 ../infra/registry-key.pem
ansible-playbook -i inventory.ini deploy.yml
```

Resultat attendu :
- Docker installe
- Dossiers `/home/ubuntu/registry/...` crees
- Fichier d'authentification genere
- Services `registry` et `ui` demarres

### 4. Test client Docker local

Ajouter le registre en insecure (daemon Docker local), puis :

```bash
docker login <PUBLIC_IP>:5000
docker pull hello-world
docker tag hello-world <PUBLIC_IP>:5000/test-aws:v1
docker push <PUBLIC_IP>:5000/test-aws:v1
```

## Identifiants par defaut

- Utilisateur : `admin`
- Mot de passe : `password`
