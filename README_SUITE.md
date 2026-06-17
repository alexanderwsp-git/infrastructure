# 📦 Makefile - Suite de Automatización ECS Deploy

## 🎉 Resumen de lo que se creó

He creado una suite completa de automatización para **build, push y deployment** de servicios ECS. Aquí está todo lo que incluye:

---

## 📁 Archivos creados en `infrastructure/`

### 1. **`Makefile`** ⭐ (Principal)

- **Descripción**: Automatización completa con targets para build, push y deployment
- **Tamaño**: ~500 líneas
- **Targets principales**:
  - `build-*`: Construir imágenes Docker
  - `push-*`: Subir a ECR
  - `deploy-*`: Build + Push + Update (completo)
  - `update-*`: Solo actualizar servicios ECS
  - `ecr-login/logout`: Autenticación AWS
- **Soporta**: Admin Backend/Frontend, MyXperiences Backend/Frontend
- **Uso**: `make help`, `make deploy-admin-back`

### 2. **`MAKEFILE_README.md`** 📖 (Documentación completa)

- **Secciones**:
  - Requisitos e instalación
  - Configuración
  - Referencia de todos los comandos
  - Flujos de trabajo típicos
  - Customización
  - Troubleshooting detallado
  - Ejemplos avanzados
  - Variables de entorno
- **Uso**: Lee primero para entender cómo funciona

### 3. **`QUICK_START.md`** ⚡ (Guía rápida)

- **Duración**: 5 minutos
- **Contenido**:
  - Prerequisitos rápidos
  - 3 opciones de deploy
  - Troubleshooting rápido
  - Monitoreo de deployment
  - Pro tips
  - Checklist de primer deployment
- **Para**: Usuarios que quieren empezar YA

### 4. **`ADVANCED_EXAMPLES.md`** 🚀 (Casos avanzados)

- **10 ejemplos incluidos**:
  - Deploy selectivo con validaciones
  - Integración GitHub Actions (2 workflows incluidos)
  - Deploy con confirmación
  - Deploy con notificaciones Slack/Email
  - Deploy con rollback automático
  - Deploy en horario específico
  - Limpieza de imágenes
  - Integración con Git hooks
  - Debugging avanzado
- **Para**: Automatización profesional y CI/CD

### 5. **`update-image-tags.sh`** 🔄 (Script auxiliar Bash)

- **Descripción**: Actualiza automáticamente IMAGE_TAG en todos los .env files
- **Uso**:
  ```bash
  ./update-image-tags.sh              # Todos los servicios
  ./update-image-tags.sh admin        # Solo Admin
  ./update-image-tags.sh admin-back   # Solo Admin Backend
  ```
- **Beneficio**: No necesitas actualizar manualmente los tags

### 6. **`update-image-tags.ps1`** 🔄 (Script auxiliar PowerShell)

- **Descripción**: Lo mismo que el script Bash pero para Windows/PowerShell
- **Uso**:
  ```powershell
  .\update-image-tags.ps1 -Type admin      # Solo Admin
  .\update-image-tags.ps1 -Type all        # Todos
  ```
- **Para**: Usuarios de Windows

---

## 🎯 Servicios soportados

| Servicio              | Build | Push | Deploy | Update |
| --------------------- | ----- | ---- | ------ | ------ |
| Admin Backend         | ✅    | ✅   | ✅     | ✅     |
| Admin Frontend        | ✅    | ✅   | ✅     | ✅     |
| MyXperiences Backend  | ✅    | ✅   | ✅     | ✅     |
| MyXperiences Frontend | ✅    | ✅   | ✅     | ✅     |

---

## 🚀 Flujo de trabajo (paso a paso)

### Opción 1: Deployment manual (más control)

```bash
cd infrastructure

# 1. Build la imagen
make build-admin-back

# 2. Verificar que se construyó
docker images | grep mexp-admin-back

# 3. Autenticarse en ECR
make ecr-login

# 4. Push a ECR
make push-admin-back

# 5. Actualizar IMAGE_TAG
./update-image-tags.sh admin-back

# 6. Actualizar servicio
make update-admin-back
```

### Opción 2: Deploy completo automático (recomendado)

```bash
cd infrastructure
make deploy-admin-back
```

_Hace todo automáticamente: build → push → update_

### Opción 3: Deploy múltiples servicios

```bash
cd infrastructure
make deploy-all-admin          # Admin (backend + frontend)
make deploy-all                # TODO (4 servicios)
```

---

## 📋 Variables configurables

```bash
# Cambiar AWS Account/Region
make deploy-admin-back AWS_ACCOUNT_ID=123456789 AWS_REGION=eu-west-1

# Cambiar rutas de repositorios (editar Makefile)
ADMIN_BACK_DIR := /ruta/personalizada/Backend-Admin
```

---

## ✅ Verificación de instalación

Verifica que tienes todo:

```bash
# Docker
docker --version          # ✅ Debe mostrar versión

# AWS CLI
aws --version
aws sts get-caller-identity  # ✅ Debe mostrar tu AWS account

# Make
make --version            # ✅ Debe mostrar versión

# En Windows (WSL)
make --version
```

---

## 🔐 AWS Credenciales

```bash
# Configurar AWS CLI
aws configure

# O usar variables de entorno
export AWS_ACCESS_KEY_ID=your_key
export AWS_SECRET_ACCESS_KEY=your_secret
export AWS_DEFAULT_REGION=us-east-1
```

---

## 🛟 Primeros pasos recomendados

1. **Lee**: `QUICK_START.md` (5 minutos)
2. **Verifica**: `make help` en terminal
3. **Intenta**: `make show-tags` (sin hacer cambios)
4. **Prueba**: `make deploy-admin-back` (en un servicio no-crítico)
5. **Lee completo**: `MAKEFILE_README.md` (para entender a fondo)

---

## 📊 Estructura de directorios esperada

```
infrastructure/
├── Makefile                           ← Principal
├── MAKEFILE_README.md                 ← Documentación completa
├── QUICK_START.md                     ← Guía rápida
├── ADVANCED_EXAMPLES.md               ← Casos avanzados
├── update-image-tags.sh               ← Script auxiliar (Bash)
├── update-image-tags.ps1              ← Script auxiliar (PowerShell)
├── ecs/                               ← MyXperiences
│   ├── update-backend.sh
│   ├── update-frontend.sh
│   ├── .env_backend
│   ├── .env_frontend
│   ├── lanapp-back-task-definition.json
│   └── lanapp-front-task-definition.json
├── ecs-admin/                         ← Admin
│   ├── update-admin-backend.sh
│   ├── update-admin-frontend.sh
│   ├── .env_admin_backend.template
│   ├── .env_admin_frontend.template
│   ├── admin-back-task-definition.json
│   └── admin-front-task-definition.json
└── [otros archivos existentes...]

Backend-Admin/
├── Dockerfile
├── src/
└── [otros archivos...]

Frontend-Admin/
├── Dockerfile
├── src/
└── [otros archivos...]

Prueba/
├── backend/
│   ├── Dockerfile
│   └── [otros archivos...]
└── frontend/
    ├── Dockerfile
    └── [otros archivos...]
```

---

## 🎓 Ejemplos rápidos

### Deploy Admin Backend

```bash
cd infrastructure
make deploy-admin-back
```

### Deploy Admin Frontend

```bash
cd infrastructure
make deploy-admin-front
```

### Deploy MyXperiences Backend

```bash
cd infrastructure
make deploy-myxp-back
```

### Deploy MyXperiences Frontend

```bash
cd infrastructure
make deploy-myxp-front
```

### Deploy TODO

```bash
cd infrastructure
make deploy-all
```

### Solo BUILD (sin deploy)

```bash
cd infrastructure
make build-all
```

### Apenas PUSH (build ya está hecho)

```bash
cd infrastructure
make ecr-login
make push-admin-back
```

### Apenas UPDATE (imagen ya está en ECR)

```bash
cd infrastructure
./update-image-tags.sh admin-back
make update-admin-back
```

---

## 🔄 Actualizar IMAGE_TAG automáticamente

```bash
# Bash/Shell
cd infrastructure
./update-image-tags.sh admin

# PowerShell (Windows)
cd infrastructure
.\update-image-tags.ps1 -Type admin
```

---

## 🔍 Ver información

```bash
# Ver configuración
make info

# Ver tags de git actuales
make show-tags

# Ver ayuda de todos los targets
make help
```

---

## 🧹 Limpiar

```bash
# Limpiar imágenes Docker locales
make clean

# Limpiar imágenes + Docker system prune
make prune
```

---

## 📊 Monitorear deployment

```bash
# Ver logs en tiempo real
aws logs tail /ecs/mexp-admin-back --follow

# Ver estado del servicio
aws ecs describe-services \
  --cluster mexp-apps-shared-cluster \
  --services mexp-admin-back-service

# Ver tareas en ejecución
aws ecs list-tasks \
  --cluster mexp-apps-shared-cluster \
  --service-name mexp-admin-back-service
```

---

## 🆘 Si algo falla

1. **Lee**: `MAKEFILE_README.md` > Troubleshooting
2. **Verifica**: `make info` y credenciales AWS
3. **Intenta**: `make ecr-login` y reintentar
4. **Debugea**: Lee logs con `aws logs tail /ecs/...`

---

## 🚀 Próximos pasos

1. **Integración CI/CD**: Ver `ADVANCED_EXAMPLES.md` para GitHub Actions
2. **Automatización**: Crear scripts de deploy con confirmación/notificaciones
3. **Monitoreo**: Agregar CloudWatch alarmas
4. **Rollback**: Implementar rollback automático

---

## 📚 Archivos de documentación

- **`QUICK_START.md`**: Empezar rápido (5 min)
- **`MAKEFILE_README.md`**: Referencia completa
- **`ADVANCED_EXAMPLES.md`**: 10 casos avanzados
- **Este archivo**: Resumen general

---

## 💡 Tips finales

✅ **Hazlo**: `cd infrastructure && make deploy-admin-back`
✅ **Lee primero**: `QUICK_START.md`
✅ **Personaliza**: Edita Makefile si necesitas rutas diferentes
✅ **Automatiza**: Ver `ADVANCED_EXAMPLES.md` para CI/CD
✅ **Mantén**: Actualiza IMAGE_TAG con `./update-image-tags.sh`

---

## 📞 Soporte

Si tienes problemas:

1. Verifica: `make help`
2. Lee: `MAKEFILE_README.md`
3. Busca en: `ADVANCED_EXAMPLES.md`
4. Debugea: `make info` + credenciales AWS

---

🎉 **¡Ya estás listo para usar la suite de automatización!**

Comienza con: `cd infrastructure && make deploy-admin-back`
