# 🚀 Makefile - Automatización ECS Deploy

Este Makefile automatiza el proceso completo de **build**, **push** a ECR y **deployment** en AWS ECS para todos los servicios (Admin Backend, Admin Frontend, MyXperiences Backend, MyXperiences Frontend).

## 📋 Requisitos

- **Docker**: Instalado y corriendo
- **AWS CLI**: Configurado con credenciales válidas
- **Make**: Instalado (viene por defecto en macOS/Linux, en Windows usar WSL o Git Bash)
- **jq**: Herramienta para parsear JSON (requerida por los scripts de update)

### Instalación en Windows (WSL)

```bash
# Instalar make y jq en WSL
sudo apt-get update
sudo apt-get install -y make jq
```

## ⚙️ Configuración

### Variables por defecto

El Makefile usa estas variables que pueden ser modificadas:

```makefile
AWS_ACCOUNT_ID = 991795763909    # ID de la cuenta AWS
AWS_REGION = us-east-1            # Región AWS
```

Para sobrescribir variables al ejecutar:

```bash
make deploy-all-admin AWS_REGION=us-west-2
```

### Rutas de los repositorios

El Makefile asume esta estructura:

```
infrastructure/
  ├─ Makefile                     # ← Aquí está
  ├─ ecs/
  ├─ ecs-admin/
  ├─ ../Backend-Admin/            # Backend Admin
  ├─ ../Frontend-Admin/           # Frontend Admin
  ├─ ../Prueba/backend/           # MyXperiences Backend
  └─ ../Prueba/frontend/          # MyXperiences Frontend
```

Si tus rutas son diferentes, edita el Makefile y ajusta estas variables:

```makefile
ADMIN_BACK_DIR := ../Backend-Admin
ADMIN_FRONT_DIR := ../Frontend-Admin
MYXP_BACK_DIR := ../Prueba/backend
MYXP_FRONT_DIR := ../Prueba/frontend
```

## 🎯 Comandos disponibles

### 🔨 Build (construcción local)

```bash
# Build individual
make build-admin-back              # Build Backend Admin
make build-admin-front             # Build Frontend Admin
make build-myxp-back               # Build Backend MyXperiences
make build-myxp-front              # Build Frontend MyXperiences

# Build todos
make build-all                     # Build todas las imágenes
```

### 📤 Push a ECR (subir imágenes)

```bash
# Antes de hacer push, asegúrate de estar autenticado:
make ecr-login

# Push individual
make push-admin-back
make push-admin-front
make push-myxp-back
make push-myxp-front
```

### 🚀 Deployment completo (Build + Push + Update)

```bash
# Deploy individual
make deploy-admin-back             # Build + Push + Update Backend Admin
make deploy-admin-front            # Build + Push + Update Frontend Admin
make deploy-myxp-back              # Build + Push + Update Backend MyXperiences
make deploy-myxp-front             # Build + Push + Update Frontend MyXperiences

# Deploy por grupo
make deploy-all-admin              # Deploy Admin Backend + Frontend
make deploy-all-myxp               # Deploy MyXperiences Backend + Frontend

# Deploy TODO (⚠️ cuidado con esto)
make deploy-all                    # Deploy todos los servicios
```

### 🔄 Update solamente (sin Build, requiere IMAGE_TAG en .env)

Si solo quieres actualizar el servicio sin rebuild:

```bash
make update-admin-back
make update-admin-front
make update-myxp-back
make update-myxp-front
```

### 🔐 AWS ECR

```bash
make ecr-login                     # Autenticarse en ECR
make ecr-logout                    # Desconectarse de ECR
```

### 📋 Información y utilidades

```bash
make info                          # Mostrar configuración
make show-tags                     # Mostrar tags de git actuales
make help                          # Mostrar esta ayuda
make clean                         # Limpiar imágenes locales
make prune                         # Limpiar imágenes + system prune
```

## 🔄 Flujo de trabajo típico

### Scenario 1: Deploy de Admin Backend solamente

```bash
cd infrastructure
make deploy-admin-back
```

**Qué hace:**

1. Build la imagen Docker del Backend Admin
2. Se autentica en ECR (si es necesario)
3. Push la imagen a ECR
4. Lee el `.env_admin_backend.template`
5. Copia y reemplaza variables en `admin-back-task-definition.json`
6. Registra nueva revisión en ECS
7. Actualiza el servicio con `--force-new-deployment`

### Scenario 2: Deploy de todos los servicios Admin

```bash
cd infrastructure
make deploy-all-admin
```

Deployea tanto Backend como Frontend Admin en secuencia.

### Scenario 3: Deploy completo (toda la aplicación)

```bash
cd infrastructure
make deploy-all
```

⚠️ **Cuidado**: Esto deployeará 4 servicios secuencialmente. Puede tomar 10-15 minutos.

## 🔧 Customización

### Cambiar ECR Registry

Si tu ECR está en otra cuenta o región:

```bash
make deploy-admin-back AWS_ACCOUNT_ID=123456789 AWS_REGION=eu-west-1
```

### Cambiar rutas de repositorios

Edita el Makefile y ajusta:

```makefile
ADMIN_BACK_DIR := /ruta/a/Backend-Admin
ADMIN_FRONT_DIR := /ruta/a/Frontend-Admin
MYXP_BACK_DIR := /ruta/a/backend
MYXP_FRONT_DIR := /ruta/a/frontend
```

## 📝 Cómo funciona

### Build

```
git rev-parse --short HEAD → Obtiene el hash corto de git
docker build → Construye la imagen
docker tag → Etiqueta con el hash
```

### Push

```
docker push → Sube a ECR con el hash y latest
```

### Update (ECS)

```
Copia template → Reemplaza $IMAGE_TAG con hash
Reemplaza variables de .env → Genera JSON válido
aws ecs register-task-definition → Registra nueva revisión
aws ecs update-service → Actualiza servicio (fuerza nuevo deployment)
```

## ✅ Variables de entorno en .env

Cada servicio necesita un archivo `.env_*` con el `IMAGE_TAG`:

```bash
# .env_admin_backend.template
IMAGE_TAG=a1b2c3d  # ← Se actualiza automáticamente

# Otros variables...
PORT=3000
NODE_ENV=production
```

El Makefile **automáticamente** obtiene el `IMAGE_TAG` del hash corto de git:

```bash
IMAGE_TAG=$(git -C <REPO> rev-parse --short HEAD)
```

## 🐛 Troubleshooting

### "command not found: make"

**Solución**: Instala make o usa WSL en Windows

### "jq: command not found"

**Solución**: `sudo apt-get install jq` (requerido por los scripts de update)

### Error de autenticación ECR

**Solución**: Ejecuta `make ecr-login` primero

### Docker build falla

**Verificar**:

- Docker está corriendo: `docker ps`
- Dockerfile existe en la ruta correcta
- Archivos de dependencias (.env, package.json, etc.) existen

### ECS update falla

**Verificar**:

- AWS CLI está configurado: `aws sts get-caller-identity`
- Tienes permisos IAM para ECS
- Cluster y servicio existen: `aws ecs list-services --cluster mexp-apps-shared-cluster`

## 🎓 Ejemplos avanzados

### Deploy solo si hay cambios en git

```bash
# Verificar cambios
git status

# Si hay cambios, hacer deploy
make deploy-admin-back
```

### Deploy múltiple con diferentes regiones (manual)

```bash
# Verificar región actual
aws configure get region

# Deploy en región específica
make deploy-admin-back AWS_REGION=us-west-2
```

### Ver logs del deployment

```bash
# Ver logs del servicio
aws ecs describe-services \
  --cluster mexp-apps-shared-cluster \
  --services mexp-admin-back-service \
  --region us-east-1

# Ver logs en CloudWatch
aws logs tail /ecs/mexp-admin-back --follow
```

## 📚 Archivos involucrados

| Archivo                              | Propósito                                 |
| ------------------------------------ | ----------------------------------------- |
| `Makefile`                           | Automatización (este archivo)             |
| `ecs-admin/update-admin-backend.sh`  | Script de update para Admin Backend       |
| `ecs-admin/update-admin-frontend.sh` | Script de update para Admin Frontend      |
| `ecs/update-backend.sh`              | Script de update para MyXp Backend        |
| `ecs/update-frontend.sh`             | Script de update para MyXp Frontend       |
| `.env_admin_backend.template`        | Variables de Admin Backend                |
| `.env_admin_frontend.template`       | Variables de Admin Frontend               |
| `.env_backend`                       | Variables de MyXp Backend                 |
| `.env_frontend`                      | Variables de MyXp Frontend                |
| `admin-back-task-definition.json`    | Plantilla de ECS Task para Admin Backend  |
| `admin-front-task-definition.json`   | Plantilla de ECS Task para Admin Frontend |
| `lanapp-back-task-definition.json`   | Plantilla de ECS Task para MyXp Backend   |
| `lanapp-front-task-definition.json`  | Plantilla de ECS Task para MyXp Frontend  |

## 🚨 Notas importantes

1. **Bacups automáticos**: Los scripts de update crean archivos `-var.json` que son versiones modificadas de los templates. Estos se pueden limpiar después del deployment.

2. **Health Checks**: ECS ejecutará health checks automáticamente. Si el contenedor falla, se revertirá automáticamente (depende de la configuración del servicio).

3. **Downtime**: Con `--force-new-deployment`, habrá un breve downtime mientras ECS reemplaza la tarea. Usa Blue/Green deployments si necesitas zero-downtime.

4. **Rollback**: Si algo falla, puedes hacer rollback manualmente:

   ```bash
   aws ecs update-service \
     --cluster mexp-apps-shared-cluster \
     --service mexp-admin-back-service \
     --task-definition mexp-admin-back:<REVISION_ANTERIOR>
   ```

5. **Git tags**: Considera usar git tags en lugar de short hash para produccción:
   ```bash
   IMAGE_TAG=$(git -C $(ADMIN_BACK_DIR) describe --tags --always)
   ```

## 📞 Soporte

Si tienes problemas:

1. Verifica la salida del comando con `-v` verbose
2. Comprueba que todos los `.env_*` files tienen `IMAGE_TAG`
3. Verifica permisos de IAM en AWS
4. Revisa logs en CloudWatch: `aws logs tail <LOG_GROUP> --follow`
