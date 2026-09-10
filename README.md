ola Juan DevOps

Laboratorio práctico de DevOps y Cloud construido para desplegar una
aplicación web completa sobre AWS, automatizando la infraestructura,
construcción de imágenes, publicación en ECR y despliegue en Kubernetes.

1. Objetivo

Construir una solución reproducible que permita:

Mostrar una aplicación web con el mensaje Hola Juan.

Consultar registros almacenados en PostgreSQL desde el frontend.

Desplegar infraestructura AWS mediante Terraform.

Construir imágenes Docker de frontend y backend.

Publicar las imágenes en Amazon ECR.

Ejecutar la aplicación en Kubernetes con Minikube sobre EC2.

Automatizar CI/CD mediante GitHub Actions.

Autenticar GitHub Actions contra AWS mediante OIDC.

Mantener los datos de PostgreSQL mediante un PersistentVolumeClaim.

Probar escalamiento, self-healing y persistencia.

2. Arquitectura

GitHub
  |
  | push
  v
GitHub Actions
  |
  | OIDC
  v
AWS
  |
  +-- Terraform --> VPC / Subnet / IGW / SG / EC2 / IAM / ECR
  |
  +-- Amazon ECR
  |      +-- frontend
  |      +-- backend
  |
  +-- EC2 Ubuntu
         |
         +-- Docker
         +-- Minikube / Kubernetes
               |
               +-- Frontend (Nginx + HTML)
               |      |
               |      +-- NodePort 30080
               |
               +-- Backend (Python + Flask)
               |      |
               |      +-- ClusterIP :5000
               |
               +-- PostgreSQL
                      |
                      +-- ClusterIP :5432
                      +-- PVC 1 GiB

Acceso externo:

Internet
   |
   v
EC2 :80
   |
   v
Nginx host
   |
   v
Minikube NodePort :30080
   |
   v
Frontend
   |
   v
Backend REST API
   |
   v
PostgreSQL + PVC

3. Tecnologías utilizadas

Tecnología            Uso

AWS                   Plataforma cloud
Terraform             Infraestructura como código
GitHub                Repositorio de código
GitHub Actions        CI/CD
OIDC                  Autenticación GitHub -> AWS sin Access Keys permanentes
Docker                Construcción de imágenes
Amazon ECR            Registro de imágenes
EC2 Ubuntu            Servidor del laboratorio
Minikube              Cluster Kubernetes
Kubernetes            Orquestación
Nginx                 Frontend y reverse proxy
Python / Flask        API REST
PostgreSQL            Base de datos
PVC                   Persistencia de PostgreSQL
AWS Systems Manager   Ejecución remota usada por el pipeline

4. Estructura del repositorio

hola-juan-devops/
├── .github/
│   └── workflows/
│       └── pipeline.yml
├── backend/
│   ├── app.py
│   ├── Dockerfile
│   └── requirements.txt
├── frontend/
│   ├── Dockerfile
│   ├── index.html
│   └── nginx.conf
├── kubernetes/
│   ├── backend.yaml
│   ├── frontend.yaml
│   ├── ingress.yaml
│   ├── namespace.yaml
│   └── postgres.yaml
├── terraform/
│   ├── ec2.tf
│   ├── ecr.tf
│   ├── iam-ec2.tf
│   ├── iam-github-ssm.tf
│   ├── network.tf
│   ├── outputs.tf
│   ├── providers.tf
│   ├── security.tf
│   ├── terraform.tfvars
│   ├── user-data.sh
│   └── variables.tf
├── bootstrap/
│   └── main.tf
├── .gitignore
└── README.md

5. Infraestructura AWS con Terraform

Terraform administra los componentes principales del laboratorio:

VPC 10.0.0.0/16.

Subred pública 10.0.1.0/24.

Internet Gateway.

Tabla de rutas con salida 0.0.0.0/0.

Security Group para SSH y HTTP.

Instancia EC2 Ubuntu.

IAM Role e Instance Profile para EC2.

Permisos de lectura de ECR desde EC2.

Integración con AWS Systems Manager.

Repositorios ECR para frontend y backend.

Backend remoto de Terraform en Amazon S3.

El servidor se inicializa mediante user-data.sh, instalando Docker,
kubectl, Minikube, AWS CLI y Nginx. Minikube se configura como servicio
systemd para iniciar automáticamente con la EC2.

6. Pipeline CI/CD

Flujo implementado:

git push
   |
   v
GitHub Actions
   |
   +--> Terraform validate/plan/apply
   |
   +--> Docker build
   |
   +--> Amazon ECR
   |
   +--> Despliegue Kubernetes por SSM
   |
   +--> Rollout / verificación

GitHub Actions se autentica contra AWS utilizando OIDC, evitando
almacenar Access Keys permanentes como secretos del repositorio.

Las imágenes se publican en ECR identificadas con el SHA del commit para
mejorar la trazabilidad del despliegue.

7. Kubernetes

Namespace utilizado:

kubectl get pods -n hola-juan

Workloads principales:

frontend: Nginx + HTML.

backend: API REST Flask.

postgres: PostgreSQL 17.

Servicios:

Frontend: NodePort 30080.

Backend: ClusterIP 5000.

PostgreSQL: ClusterIP 5432.

8. Persistencia PostgreSQL

Se creó:

PersistentVolumeClaim: postgres-pvc
StorageClass: standard
Capacidad: 1Gi
Access Mode: ReadWriteOnce
Estado esperado: Bound

El volumen se monta en:

/var/lib/postgresql/data

Comandos de verificación:

kubectl get pvc -n hola-juan
kubectl get pv

Resultado comprobado durante el laboratorio:

postgres-pvc   Bound   1Gi   RWO   standard

Prueba de persistencia

Se insertó un registro adicional:

INSERT INTO personas (nombre, profesion)
VALUES ('PruebaPVC', 'DevOps');

Después se eliminó el pod de PostgreSQL. Kubernetes creó un nuevo pod y
el registro continuó existiendo.

Resultado: persistencia mediante PVC comprobada.

9. Escalamiento

Se escaló el frontend de una a tres réplicas:

kubectl scale deployment frontend -n hola-juan --replicas=3
kubectl get pods -n hola-juan -l app=frontend -o wide

Resultado: tres pods Running.

Después de la prueba se regresó a una réplica:

kubectl scale deployment frontend -n hola-juan --replicas=1

10. Self-healing

Se eliminó manualmente un pod del frontend:

kubectl delete pod <frontend-pod> -n hola-juan

El Deployment detectó que faltaba una réplica y el ReplicaSet creó
automáticamente un nuevo pod.

Resultado: self-healing comprobado.

11. Verificaciones finales

Estado final comprobado:

Backend       1/1 Running
Frontend      1/1 Running
PostgreSQL    1/1 Running
postgres-pvc  Bound

Pruebas realizadas:

Prueba                            Resultado

Terraform / AWS                   OK
GitHub Actions                    OK
OIDC GitHub -> AWS               OK
Docker Build                      OK
Push Amazon ECR                   OK
Deploy Kubernetes                 OK
Frontend                          OK
Backend REST API                  OK
PostgreSQL                        OK
PVC 1 GiB                         OK
Persistencia tras recrear pod     OK
Escalamiento 1 -> 3              OK
Self-healing                      OK
Acceso web público                OK
Minikube auto-start con systemd   OK

12. Comandos útiles

# Estado general
kubectl get pods -n hola-juan
kubectl get svc -n hola-juan
kubectl get pvc -n hola-juan

# Despliegues
kubectl get deployments -n hola-juan

# Logs
kubectl logs -n hola-juan deployment/backend
kubectl logs -n hola-juan deployment/frontend
kubectl logs -n hola-juan deployment/postgres

# Escalamiento
kubectl scale deployment frontend -n hola-juan --replicas=3

# Rollout
kubectl rollout status deployment/frontend -n hola-juan
kubectl rollout status deployment/backend -n hola-juan

# PostgreSQL
kubectl exec -n hola-juan deployment/postgres -- \
  psql -U juan -d holajuan -c "SELECT * FROM personas;"

# Persistencia
kubectl get pvc -n hola-juan
kubectl get pv

13. Resultados y aprendizajes

El laboratorio demuestra de forma práctica la integración entre Cloud,
IaC, contenedores, CI/CD y Kubernetes.

Se implementaron y probaron:

Aprovisionamiento reproducible con Terraform.

Autenticación federada mediante OIDC.

Construcción y versionamiento de imágenes.

Registro privado con Amazon ECR.

Despliegues automatizados.

Orquestación con Kubernetes.

Comunicación frontend -> backend -> PostgreSQL.

Persistencia mediante PVC.

Escalamiento horizontal manual.

Recuperación automática de pods.

Automatización del inicio de Minikube mediante systemd.

14. Consideraciones

Este entorno es un laboratorio de aprendizaje, no una arquitectura
productiva.

Minikube ejecuta Kubernetes dentro de una única EC2, por lo que no
proporciona alta disponibilidad real de nodos. El PVC usa el
StorageClass minikube-hostpath; protege los datos frente a la
recreación del pod, pero no debe considerarse almacenamiento productivo
frente a la pérdida completa del nodo/cluster.

En producción podrían utilizarse servicios como Amazon EKS, Amazon EBS
CSI, Amazon RDS, balanceadores administrados, AWS Secrets Manager y una
estrategia de observabilidad centralizada.

15. Limpieza

Cuando ya no se necesite el laboratorio, revisar primero las evidencias
y posteriormente destruir los recursos administrados por Terraform para
evitar costos innecesarios.

terraform plan -destroy
terraform destroy

No ejecutar la destrucción hasta confirmar que el laboratorio y sus
evidencias ya no son necesarios.# devops
practica de devops
