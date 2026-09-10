#!/bin/bash

set -e

export DEBIAN_FRONTEND=noninteractive

# ============================================================
# LOG DEL BOOTSTRAP
# ============================================================

exec > >(tee /var/log/hola-juan-bootstrap.log | logger -t user-data -s 2>/dev/console) 2>&1

echo "============================================================"
echo "INICIANDO BOOTSTRAP HOLA JUAN DEVOPS"
echo "============================================================"


# ============================================================
# 1. ACTUALIZAR SISTEMA
# ============================================================

apt-get update -y


# ============================================================
# 2. INSTALAR HERRAMIENTAS BASICAS
# ============================================================

apt-get install -y \
  ca-certificates \
  curl \
  gnupg \
  unzip \
  git \
  nginx


# ============================================================
# 3. INSTALAR DOCKER
# ============================================================

install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  -o /etc/apt/keyrings/docker.asc

chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  > /etc/apt/sources.list.d/docker.list

apt-get update -y

apt-get install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin


# ============================================================
# 4. CONFIGURAR DOCKER
# ============================================================

usermod -aG docker ubuntu

systemctl enable docker
systemctl start docker


# ============================================================
# 5. INSTALAR KUBECTL
# ============================================================

curl -L \
  "https://dl.k8s.io/release/v1.37.0/bin/linux/amd64/kubectl" \
  -o /tmp/kubectl

install \
  -o root \
  -g root \
  -m 0755 \
  /tmp/kubectl \
  /usr/local/bin/kubectl

rm -f /tmp/kubectl


# ============================================================
# 6. INSTALAR MINIKUBE
# ============================================================

curl -L \
  https://github.com/kubernetes/minikube/releases/download/v1.39.0/minikube-linux-amd64 \
  -o /tmp/minikube-linux-amd64

install \
  /tmp/minikube-linux-amd64 \
  /usr/local/bin/minikube

rm -f /tmp/minikube-linux-amd64


# ============================================================
# 7. INSTALAR AWS CLI V2
# ============================================================

curl \
  "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
  -o /tmp/awscliv2.zip

cd /tmp

unzip -q awscliv2.zip

./aws/install

rm -rf /tmp/aws
rm -f /tmp/awscliv2.zip


# ============================================================
# 8. ESPERAR DOCKER
# ============================================================

echo "Esperando Docker..."

until docker info >/dev/null 2>&1
do
  sleep 5
done

echo "Docker disponible."


# ============================================================
# 9. CREAR SERVICIO SYSTEMD PARA MINIKUBE
# ============================================================

cat > /etc/systemd/system/minikube.service <<'EOF'
[Unit]
Description=Minikube Kubernetes Cluster
Requires=docker.service
After=docker.service network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
User=ubuntu
Group=ubuntu
Environment=HOME=/home/ubuntu

ExecStart=/usr/local/bin/minikube start --driver=docker --cpus=2 --memory=1800mb
ExecStop=/usr/local/bin/minikube stop

TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable minikube.service


# ============================================================
# 10. INICIAR MINIKUBE
# ============================================================

echo "Iniciando Minikube mediante systemd..."

systemctl start minikube.service


# ============================================================
# 11. VERIFICAR MINIKUBE
# ============================================================

sudo -u ubuntu -H minikube status


# ============================================================
# 12. OBTENER IP DE MINIKUBE
# ============================================================

MINIKUBE_IP=$(sudo -u ubuntu -H minikube ip)

echo "IP Minikube: ${MINIKUBE_IP}"


# ============================================================
# 13. CONFIGURAR NGINX COMO REVERSE PROXY
# ============================================================

cat > /etc/nginx/sites-available/hola-juan <<EOF
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://${MINIKUBE_IP}:30080;

        proxy_http_version 1.1;

        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF


# ============================================================
# 14. HABILITAR CONFIGURACION NGINX
# ============================================================

ln -sf \
  /etc/nginx/sites-available/hola-juan \
  /etc/nginx/sites-enabled/hola-juan

rm -f /etc/nginx/sites-enabled/default


# ============================================================
# 15. VALIDAR NGINX
# ============================================================

nginx -t


# ============================================================
# 16. HABILITAR E INICIAR NGINX
# ============================================================

systemctl enable nginx
systemctl restart nginx


# ============================================================
# 17. MOSTRAR VERSIONES
# ============================================================

echo "============================================================"
echo "VERSIONES INSTALADAS"
echo "============================================================"

docker --version
kubectl version --client
minikube version
aws --version
nginx -v


# ============================================================
# FINAL
# ============================================================

echo "============================================================"
echo "BOOTSTRAP HOLA JUAN DEVOPS TERMINADO"
echo "============================================================"