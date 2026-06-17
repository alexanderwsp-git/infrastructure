# ⚡ Quick Start - Deploy con Makefile

## 🚀 5 minutos para tu primer deploy

### Prerequisitos rápidos
```bash
# Verificar que tienes todo
docker --version          # ✅ Docker
aws --version             # ✅ AWS CLI
make --version            # ✅ Make (en WSL si es Windows)

# Autenticarse en AWS (si no lo has hecho)
aws configure
aws sts get-caller-identity  # Verifica que esté configurado
```

---

## 📝 Escenarios de uso rápido

### Opción A: Deploy Individual (Recomendado para testing)

```bash
cd infrastructure

# Deploy SOLO Backend Admin (más rápido)
make deploy-admin-back
```

**¿Qué hace?**
1. ✅ Build imagen Docker
2. ✅ Push a AWS ECR
3. ✅ Actualiza servicio en ECS
4. ⏳ ~3-5 minutos

**Espera a ver:**
```
✅ Build completado: a1b2c3d
✅ Autenticación exitosa en ECR
✅ Push completado: a1b2c3d
✅ Despliegue iniciado en AWS
✅ ADMIN BACKEND DEPLOYMENT COMPLETE
```

---

### Opción B: Deploy Admin Completo (Frontend + Backend)

```bash
cd infrastructure
make deploy-all-admin
```

⏳ ~6-10 minutos

---

### Opción C: Deploy TODO (⚠️ solo en producción)

```bash
cd infrastructure
make deploy-all
```

⏳ ~12-15 minutos (4 servicios)

---

## 🛠️ Troubleshooting rápido

### ❌ "command not found: make"
**Solución Windows:**
- Usa WSL o Git Bash
- Ejecuta desde terminal WSL

**Solución macOS/Linux:**
```bash
brew install make  # macOS
apt-get install make  # Linux
```

### ❌ "Docker daemon is not running"
```bash
# Windows: abre Docker Desktop
# macOS: brew services start docker
# Linux: sudo systemctl start docker
```

### ❌ "AWS credentials not configured"
```bash
aws configure
# Ingresa: Access Key ID, Secret Access Key, Region (us-east-1), Output (json)
```

### ❌ "jq: command not found"
En WSL:
```bash
sudo apt-get install -y jq
```

### ❌ Error en push a ECR
```bash
# Reautenticarse
make ecr-login

# Reintentar
make deploy-admin-back
```

---

## 📊 Monitorear deployment

### Mientras se despliega
```bash
# En otra terminal, ver logs de ECS
aws logs tail /ecs/mexp-admin-back --follow
```

### Después del deployment
```bash
# Ver estado del servicio
aws ecs describe-services \
  --cluster mexp-apps-shared-cluster \
  --services mexp-admin-back-service

# Ver tareas (contenedores)
aws ecs list-tasks \
  --cluster mexp-apps-shared-cluster \
  --service-name mexp-admin-back-service
```

---

## 🔄 Si algo sale mal - Rollback rápido

```bash
# Ver revisiones anteriores
aws ecs describe-task-definition --task-definition mexp-admin-back

# Rollback a revisión anterior (ej: 5)
aws ecs update-service \
  --cluster mexp-apps-shared-cluster \
  --service mexp-admin-back-service \
  --task-definition mexp-admin-back:5
```

---

## 💡 Pro Tips

### Actualizar IMAGE_TAG automáticamente
```bash
# Script bash/shell
./update-image-tags.sh admin

# O desde PowerShell (Windows)
.\update-image-tags.ps1 -Type admin
```

### Ver configuración de tu setup
```bash
make info
make show-tags
```

### Limpiar imágenes locales
```bash
make clean     # Limpia imágenes
make prune      # Limpia imágenes + Docker system prune
```

---

## 🎯 Flujo típico de un día

```bash
cd infrastructure

# 1. Comprobar tags actuales
make show-tags

# 2. Hacer cambios en Backend-Admin

# 3. Hacer commit + push
cd ../Backend-Admin
git add .
git commit -m "fix: algo importante"
git push

# 4. Volver a infrastructure y deployar
cd ../infrastructure
make deploy-admin-back

# ✅ ¡Listo!
```

---

## 📚 Documentación completa

Lee [MAKEFILE_README.md](./MAKEFILE_README.md) para:
- Configuración avanzada
- Todos los comandos disponibles
- Customización
- Troubleshooting detallado

---

## 🆘 En emergencias

```bash
# Contactar a equipo DevOps
# Revisar: MAKEFILE_README.md > Troubleshooting

# O ejecutar con debug
set -x  # Bash
bash -x ./ecs-admin/update-admin-backend.sh
```

---

## ✅ Checklist de primer deployment

- [ ] Docker instalado y corriendo
- [ ] AWS CLI configurado (`aws sts get-caller-identity`)
- [ ] WSL/Make instalado (si es Windows)
- [ ] Estoy en directorio `infrastructure/`
- [ ] He leído Quick Start (este documento)
- [ ] Cambios committeados en el repo
- [ ] Ejecuté `make deploy-admin-back` (o el servicio que quiera)
- [ ] ✅ ¡Deployment completado!

---

🎉 ¡Ahora estás listo! Comienza con `make deploy-admin-back`
