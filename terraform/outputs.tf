name: Terraform + Docker + ECR

on:
  workflow_dispatch:
  push:
    branches:
      - main

permissions:
  id-token: write
  contents: read

env:
  AWS_REGION: us-east-1
  AWS_ACCOUNT_ID: "014668143169"
  BACKEND_REPOSITORY: hola-juan-devops-backend
  FRONTEND_REPOSITORY: hola-juan-devops-frontend

jobs:

  # ==========================================================
  # JOB 1 - TERRAFORM
  # ==========================================================
  terraform-deploy:
    name: Terraform Plan and Apply
    runs-on: ubuntu-latest

    defaults:
      run:
        working-directory: terraform

    steps:

      # ======================================================
      # 1. DESCARGAR REPOSITORIO
      # ======================================================
      - name: Checkout
        uses: actions/checkout@v4


      # ======================================================
      # 2. AUTENTICACION AWS MEDIANTE OIDC
      # ======================================================
      - name: Autenticarse en AWS
        uses: aws-actions/configure-aws-credentials@v5
        with:
          role-to-assume: arn:aws:iam::014668143169:role/devops-juan
          aws-region: ${{ env.AWS_REGION }}


      # ======================================================
      # 3. VERIFICAR IDENTIDAD AWS
      # ======================================================
      - name: Verificar identidad AWS
        run: aws sts get-caller-identity
        working-directory: .


      # ======================================================
      # 4. INSTALAR TERRAFORM
      # ======================================================
      - name: Instalar Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.15.8


      # ======================================================
      # 5. TERRAFORM INIT
      # ======================================================
      - name: Terraform Init
        run: terraform init


      # ======================================================
      # 6. TERRAFORM FORMAT
      # ======================================================
      - name: Terraform Format
        run: terraform fmt -check


      # ======================================================
      # 7. TERRAFORM VALIDATE
      # ======================================================
      - name: Terraform Validate
        run: terraform validate


      # ======================================================
      # 8. TERRAFORM PLAN
      # ======================================================
      - name: Terraform Plan
        run: terraform plan -input=false -out=tfplan


      # ======================================================
      # 9. TERRAFORM APPLY
      # ======================================================
      - name: Terraform Apply
        run: terraform apply -input=false -auto-approve tfplan


      # ======================================================
      # 10. MOSTRAR OUTPUTS
      # ======================================================
      - name: Terraform Outputs
        run: terraform output


  # ==========================================================
  # JOB 2 - BUILD Y PUSH DE IMAGENES DOCKER A ECR
  # ==========================================================
  docker-ecr:
    name: Docker Build and Push to ECR
    runs-on: ubuntu-latest

    # Docker solo comienza si Terraform termino correctamente
    needs: terraform-deploy

    steps:

      # ======================================================
      # 1. DESCARGAR REPOSITORIO
      # ======================================================
      - name: Checkout
        uses: actions/checkout@v4


      # ======================================================
      # 2. AUTENTICACION AWS MEDIANTE OIDC
      # ======================================================
      - name: Autenticarse en AWS
        uses: aws-actions/configure-aws-credentials@v5
        with:
          role-to-assume: arn:aws:iam::014668143169:role/devops-juan
          aws-region: ${{ env.AWS_REGION }}


      # ======================================================
      # 3. LOGIN EN AMAZON ECR
      # ======================================================
      - name: Login Amazon ECR
        uses: aws-actions/amazon-ecr-login@v2


      # ======================================================
      # 4. BUILD BACKEND
      # ======================================================
      - name: Docker Build Backend
        run: |
          docker build \
            -t $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$BACKEND_REPOSITORY:${{ github.sha }} \
            -t $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$BACKEND_REPOSITORY:latest \
            ./backend


      # ======================================================
      # 5. PUSH BACKEND A ECR
      # ======================================================
      - name: Docker Push Backend
        run: |
          docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$BACKEND_REPOSITORY:${{ github.sha }}
          docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$BACKEND_REPOSITORY:latest


      # ======================================================
      # 6. BUILD FRONTEND
      # ======================================================
      - name: Docker Build Frontend
        run: |
          docker build \
            -t $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$FRONTEND_REPOSITORY:${{ github.sha }} \
            -t $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$FRONTEND_REPOSITORY:latest \
            ./frontend


      # ======================================================
      # 7. PUSH FRONTEND A ECR
      # ======================================================
      - name: Docker Push Frontend
        run: |
          docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$FRONTEND_REPOSITORY:${{ github.sha }}
          docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$FRONTEND_REPOSITORY:latest


      # ======================================================
      # 8. MOSTRAR IMAGENES PUBLICADAS
      # ======================================================
      - name: Mostrar imagenes publicadas
        run: |
          echo "============================================"
          echo "BACKEND"
          echo "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$BACKEND_REPOSITORY:${{ github.sha }}"
          echo ""
          echo "FRONTEND"
          echo "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$FRONTEND_REPOSITORY:${{ github.sha }}"
          echo "============================================"