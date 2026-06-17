# Deployment Guide - myxperiences

## Overview

Este documento describe los pasos para deployar backend y frontend de myxperiences a AWS ECS.

## Pre-requisitos

- AWS CLI configurado con credenciales válidas
- Docker instalado y corriendo
- Git Bash (Windows) o terminal Bash compatible
- Terraform aplicado (infrastructure actualizada)

## Archivos creados

### Dockerfiles actualizados

- `Prueba/backend/Dockerfile` - Backend optimizado con Alpine Linux y Puppeteer
- `Prueba/frontend/Dockerfile` - Frontend con build en dos etapas usando serve

### Scripts de build

- `infrastructure/scripts/myxperiences/build-myxperiences-backend-image.sh`
- `infrastructure/scripts/myxperiences/build-myxperiences-frontend-image.sh`

### Task Definitions

- `infrastructure/ecs/myxperiences-back-task-definition.json`
- `infrastructure/ecs/myxperiences-front-task-definition.json`

### Scripts de deploy

- `infrastructure/ecs/create-myxperiences-backend.sh`
- `infrastructure/ecs/create-myxperiences-frontend.sh`
- `infrastructure/ecs/update-myxperiences-backend.sh`
- `infrastructure/ecs/update-myxperiences-frontend.sh`

### Environment templates

- `infrastructure/ecs/.env_myxperiences_backend.template`
- `infrastructure/ecs/.env_myxperiences_frontend.template`

## Configuración de Terraform

### Cambios aplicados

1. **Target Groups actualizados** (3_compute_storage.tf):
   - `myxperiences_back_tg`: Puerto 4000, health check `/api/healthCheck/health`
   - `myxperiences_front_tg`: Puerto 3000, health check `/`

2. **Routing activado** (2_routing_ssl.tf):
   - Frontend: `myxperiences.org` → target group frontend
   - Backend: `api.myxperiences.org` → target group backend
   - DNS records creados para ambos subdominios

3. **IAM Roles creados** (3_compute_storage.tf):
   - `mexp-myxperiences-back-task-role` con permisos S3
   - Política de S3 para acceso al bucket `mexp-imagenes-myxperiences-unique-id`

4. **CloudWatch Log Groups**:
   - `/ecs/mexp-myxperiences-back`
   - `/ecs/mexp-myxperiences-front`

5. **ECR Repositories** (ya existían):
   - `mexp-myxperiences-back`
   - `mexp-myxperiences-front`

## Pasos de Deployment

### 1. Aplicar cambios de Terraform

```bash
cd infrastructure/infra
terraform plan
terraform apply
```

Esto creará/actualizará:

- Target groups con health checks correctos
- Routing rules para myxperiences.org y api.myxperiences.org
- IAM roles y políticas
- CloudWatch log groups

### 2. Configurar variables de entorno

Copiar los templates y completar con valores reales:

```bash
cd infrastructure/ecs-myxperiences
cp .env_myxperiences_backend.template .env_myxperiences_backend
cp .env_myxperiences_frontend.template .env_myxperiences_frontend
```

Editar archivos `.env_myxperiences_backend` y `.env_myxperiences_frontend` con valores de producción:

**Backend:**

- Credenciales de base de datos RDS (mismo RDS que admin, schema `myxperiences`)
- Secrets de JWT
- Configuración de email
- AWS S3 credentials
- **BACKEND_ADMIN_URL** e **INTERNAL_API_KEY** (crítico para sincronización con backend admin)
- Google Sheets API keys (si aplica)

**Frontend:**

- VITE_API_SERVICE para frontend

### 3. Build y push de imágenes Docker

Los scripts automáticamente etiquetan las imágenes con el hash del commit git (primeros 7 caracteres).

#### Backend

```bash
cd infrastructure/scripts/myxperiences
./build-myxperiences-backend-image.sh
# Opcional: especificar un tag personalizado
./build-myxperiences-backend-image.sh v1.0.0
```

El script mostrará el IMAGE_TAG generado (ej: `a1b2c3d`). **Actualiza este tag** en tu archivo `.env_myxperiences_backend`:

```bash
IMAGE_TAG=a1b2c3d  # Usa el tag del output del build
```

Esto hará:

- Autenticar con ECR
- Construir imagen Docker del backend con tag versionado
- Push directo a ECR: `991795763909.dkr.ecr.us-east-1.amazonaws.com/mexp-myxperiences-back:a1b2c3d`

#### Frontend

```bash
cd infrastructure/scripts/myxperiences
./build-myxperiences-frontend-image.sh
# Opcional: especificar un tag personalizado
./build-myxperiences-frontend-image.sh v1.0.0
```

El script mostrará el IMAGE_TAG generado. **Actualiza este tag** en tu archivo `.env_myxperiences_frontend`:

```bash
IMAGE_TAG=a1b2c3d  # Usa el tag del output del build
```

Esto hará:

- Cargar VITE_API_SERVICE del archivo .env
- Construir imagen con variables de build-time y tag versionado
- Push directo a ECR: `991795763909.dkr.ecr.us-east-1.amazonaws.com/mexp-myxperiences-front:a1b2c3d`

### 4. Deploy a ECS

#### Backend (primera vez)

```bash
cd infrastructure/ecs-myxperiences
./create-myxperiences-backend.sh
```

Esto hará:

- Generar task definition con variables sustituidas
- Registrar task definition en ECS
- Crear servicio ECS con 1 réplica
- Conectar al target group y ALB

#### Frontend (primera vez)

```bash
cd infrastructure/ecs-myxperiences
./create-myxperiences-frontend.sh
```

### 5. Verificar deployment

```bash
# Ver status del servicio backend
aws ecs describe-services \
  --cluster mexp-apps-shared-cluster \
  --services mexp-myxperiences-back-service \
  --region us-east-1

# Ver status del servicio frontend
aws ecs describe-services \
  --cluster mexp-apps-shared-cluster \
  --services mexp-myxperiences-front-service \
  --region us-east-1

# Ver logs del backend
aws logs tail /ecs/mexp-myxperiences-back --follow --region us-east-1

# Ver logs del frontend
aws logs tail /ecs/mexp-myxperiences-front --follow --region us-east-1
```

### 6. Verificar health checks

```bash
# Verificar target health
aws elbv2 describe-target-health \
  --target-group-arn $(aws elbv2 describe-target-groups --names mexp-myxperiences-back-tg --query 'TargetGroups[0].TargetGroupArn' --output text) \
  --region us-east-1

aws elbv2 describe-target-health \
  --target-group-arn $(aws elbv2 describe-target-groups --names mexp-myxperiences-front-tg --query 'TargetGroups[0].TargetGroupArn' --output text) \
  --region us-east-1
```

### 7. Verificar acceso

Una vez que los health checks pasen:

- Frontend: https://myxperiences.org
- Backend API: https://api.myxperiences.org/api/healthCheck/health

## Actualizaciones posteriores

Para actualizar servicios existentes:

```bash
# Build nueva imagen (genera nuevo IMAGE_TAG)
cd infrastructure/scripts/myxperiences
./build-myxperiences-backend-image.sh  # o frontend

# Actualiza IMAGE_TAG en .env_myxperiences_backend (o frontend)
# con el valor del output del build

# Deploy actualización
cd infrastructure/ecs-myxperiences
./update-myxperiences-backend.sh       # o frontend
```

Los scripts de update harán:

- Registrar nueva task definition con el nuevo IMAGE_TAG
- Forzar nuevo deployment con rolling update
- ECS reemplazará tasks gradualmente

## Troubleshooting

### Container no inicia

```bash
# Ver eventos del servicio
aws ecs describe-services \
  --cluster mexp-apps-shared-cluster \
  --services mexp-myxperiences-back-service \
  --query 'services[0].events' \
  --region us-east-1

# Ver logs recientes
aws logs tail /ecs/mexp-myxperiences-back --since 5m --region us-east-1
```

### Health check falla

- Verificar que el container está escuchando en el puerto correcto (4000 backend, 3000 frontend)
- Verificar health check path: `/api/healthCheck/health` para backend, `/` para frontend
- Revisar security groups permiten tráfico
- Ver logs para errores de startup

### Variables de entorno incorrectas

1. Editar `.env_myxperiences_backend` o `.env_myxperiences_frontend`
2. Ejecutar `./update-myxperiences-backend.sh` o `./update-myxperiences-frontend.sh`
3. ECS redeployará con nuevos valores

### DNS no resuelve

- Verificar Route53 records creados por Terraform
- Esperar propagación DNS (puede tomar hasta 5 minutos)
- Verificar ALB listener rules tienen prioridad correcta

## Architecture Summary

```
Internet
   ↓
Route53 (myxperiences.org, api.myxperiences.org)
   ↓
Application Load Balancer (shared)
   ↓
├─→ Target Group (mexp-myxperiences-front-tg:3000) → ECS Service (frontend)
└─→ Target Group (mexp-myxperiences-back-tg:4000) → ECS Service (backend)
                                                         ↓
                                                    RDS PostgreSQL
                                                    S3 Bucket
```

## Notas importantes

- **Puerto backend**: 4000 (diferente de admin/lanapp que usan 3000)
- **Health check backend**: `/api/healthCheck/health` (ruta específica de myxperiences)
- **Scripts portables**: Todos usan sintaxis compatible con Git Bash en Windows
- **VITE variables**: Se baken en build-time, no se pueden cambiar en runtime
- **Database**: PostgreSQL (Sequelize), puerto 5432
- **Puppeteer**: Incluido en backend para generación de PDFs

## Variables de entorno requeridas

### Backend

- `POSTGRES_*` (PostgreSQL database connection)
- `SECRET_JWT_SEED`
- `MAILER_*`
- `AWS_*` (S3 credentials)
- `GOOGLE_*` (Google Sheets API)
- `DOMINIO_EXPERIENCES`
- `PROD`, `SYNCALTER`, `SYNCFORCE`

### Frontend

- `VITE_API_SERVICE` (URL del backend API)
- `PORT`, `NODE_ENV`, `HOSTNAME` (runtime)
