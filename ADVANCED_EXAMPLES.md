# 🚀 Makefile - Ejemplos avanzados

## Casos de uso complejos y patrones

---

## 1. Deploy selectivo con validaciones

### Deploy solo si hay cambios

```bash
#!/bin/bash
cd infrastructure

# Detectar cambios en Backend Admin
cd ../Backend-Admin
if git diff --quiet HEAD; then
    echo "❌ No hay cambios, saltando deployment"
    exit 0
fi

# Si hay cambios, hacer deploy
cd ../infrastructure
make deploy-admin-back
```

### Deploy solo servicios específicos modificados

```bash
#!/bin/bash
cd infrastructure

# Detectar qué cambió
ADMIN_CHANGED=$(git diff --name-only HEAD | grep -i "Backend-Admin\|Frontend-Admin" | wc -l)
MYXP_CHANGED=$(git diff --name-only HEAD | grep -i "Prueba" | wc -l)

if [ $ADMIN_CHANGED -gt 0 ]; then
    echo "📝 Detectados cambios en Admin"
    make deploy-all-admin
fi

if [ $MYXP_CHANGED -gt 0 ]; then
    echo "📝 Detectados cambios en MyXperiences"
    make deploy-all-myxp
fi
```

---

## 2. Integración con GitHub Actions

### `.github/workflows/deploy-admin.yml`

```yaml
name: Deploy Admin Services

on:
  push:
    branches:
      - main
      - develop
    paths:
      - "Backend-Admin/**"
      - "Frontend-Admin/**"
      - ".github/workflows/deploy-admin.yml"

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1

      - name: Set up Docker
        uses: docker/setup-buildx-action@v2

      - name: Install Make
        run: |
          sudo apt-get update
          sudo apt-get install -y make jq

      - name: Deploy Admin Services
        run: |
          cd infrastructure
          make deploy-all-admin
```

### `.github/workflows/deploy-myxp.yml`

```yaml
name: Deploy MyXperiences Services

on:
  push:
    branches:
      - main
      - develop
    paths:
      - "Prueba/backend/**"
      - "Prueba/frontend/**"
      - ".github/workflows/deploy-myxp.yml"

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1

      - name: Set up Docker
        uses: docker/setup-buildx-action@v2

      - name: Install dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y make jq

      - name: Deploy MyXperiences Services
        run: |
          cd infrastructure
          make deploy-all-myxp
```

---

## 3. Deploy manual con confirmación

### Script: `deploy-with-confirmation.sh`

```bash
#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

SERVICE="${1:?Especifica: admin-back|admin-front|myxp-back|myxp-front}"

echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  🚀 DEPLOY CON CONFIRMACIÓN${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""

# Obtener info del deploy
case "$SERVICE" in
    "admin-back")
        SERVICE_LONG="mexp-admin-back-service"
        URL="https://admin-api.myxperiences.org"
        ;;
    "admin-front")
        SERVICE_LONG="mexp-admin-front-service"
        URL="https://admin.myxperiences.org"
        ;;
    "myxp-back")
        SERVICE_LONG="mexp-lanapp-back-service"
        URL="https://api.myxperiences.org"
        ;;
    "myxp-front")
        SERVICE_LONG="mexp-lanapp-front-service"
        URL="https://lanapp.myxperiences.org"
        ;;
    *)
        echo -e "${RED}❌ Servicio desconocido: $SERVICE${NC}"
        exit 1
        ;;
esac

echo -e "${YELLOW}📋 Información del deployment:${NC}"
echo "   Servicio: $SERVICE_LONG"
echo "   URL: $URL"
echo ""

# Confirmación
read -p "¿Continuar con el deployment? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}❌ Deployment cancelado${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}Iniciando deployment...${NC}"
echo ""

# Hacer deploy
if make deploy-$SERVICE; then
    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  ✅ DEPLOYMENT EXITOSO${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "   ${GREEN}$URL${NC}"
    echo ""
else
    echo ""
    echo -e "${RED}════════════════════════════════════════════════════════════${NC}"
    echo -e "${RED}  ❌ DEPLOYMENT FALLÓ${NC}"
    echo -e "${RED}════════════════════════════════════════════════════════════${NC}"
    exit 1
fi
```

**Uso:**

```bash
chmod +x deploy-with-confirmation.sh
./deploy-with-confirmation.sh admin-back
```

---

## 4. Deploy con notificaciones por email/Slack

### Script: `deploy-with-notifications.sh`

```bash
#!/bin/bash
set -e

SERVICE="${1:?Especifica el servicio}"
SLACK_WEBHOOK="${SLACK_WEBHOOK_URL}"
EMAIL="${NOTIFICATION_EMAIL}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Función para notificar por Slack
notify_slack() {
    local status="$1"
    local message="$2"

    if [ -z "$SLACK_WEBHOOK" ]; then
        return
    fi

    local color="good"  # verde
    if [ "$status" = "failure" ]; then
        color="danger"  # rojo
    fi

    curl -X POST "$SLACK_WEBHOOK" \
        -H 'Content-type: application/json' \
        --data "{
            \"attachments\": [{
                \"color\": \"$color\",
                \"title\": \"Deployment $status: $SERVICE\",
                \"text\": \"$message\",
                \"footer\": \"Deployment Bot\"
            }]
        }"
}

# Función para notificar por email
notify_email() {
    local status="$1"
    local message="$2"

    if [ -z "$EMAIL" ]; then
        return
    fi

    aws sns publish \
        --topic-arn "arn:aws:sns:us-east-1:991795763909:deployment-notifications" \
        --subject "Deployment $status: $SERVICE" \
        --message "$message"
}

echo "📤 Iniciando deployment de $SERVICE..."

if make deploy-$SERVICE; then
    MESSAGE="✅ Deployment de $SERVICE completado exitosamente"
    notify_slack "success" "$MESSAGE"
    notify_email "success" "$MESSAGE"
    echo "✅ $MESSAGE"
else
    MESSAGE="❌ Deployment de $SERVICE falló"
    notify_slack "failure" "$MESSAGE"
    notify_email "failure" "$MESSAGE"
    echo "❌ $MESSAGE"
    exit 1
fi
```

---

## 5. Deploy con rollback automático

### Script: `deploy-with-rollback.sh`

```bash
#!/bin/bash
set -e

SERVICE="${1:?Especifica el servicio}"
TIMEOUT="${2:300}"  # 5 minutos por defecto

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Configuración por servicio
case "$SERVICE" in
    "admin-back")
        CLUSTER="mexp-apps-shared-cluster"
        SERVICE_NAME="mexp-admin-back-service"
        TASK_FAMILY="mexp-admin-back"
        ;;
    "admin-front")
        CLUSTER="mexp-apps-shared-cluster"
        SERVICE_NAME="mexp-admin-front-service"
        TASK_FAMILY="mexp-admin-front"
        ;;
esac

echo "📝 Guardando revisión anterior..."
OLD_REVISION=$(aws ecs describe-services \
    --cluster "$CLUSTER" \
    --services "$SERVICE_NAME" \
    --region us-east-1 \
    --query 'services[0].taskDefinition' \
    --output text | awk -F':' '{print $NF}')

echo "   Revisión anterior: $OLD_REVISION"

echo ""
echo "🚀 Iniciando deployment..."

if make deploy-$SERVICE; then
    echo ""
    echo "✅ Deployment completado"
    echo "⏳ Esperando que el servicio esté healthy ($TIMEOUT segundos)..."

    # Esperar a que las tareas estén running
    START_TIME=$(date +%s)
    while true; do
        RUNNING=$(aws ecs describe-services \
            --cluster "$CLUSTER" \
            --services "$SERVICE_NAME" \
            --region us-east-1 \
            --query 'services[0].runningCount' \
            --output text)

        if [ "$RUNNING" -gt 0 ]; then
            echo "✅ Servicio está running"
            break
        fi

        ELAPSED=$(($(date +%s) - START_TIME))
        if [ $ELAPSED -gt $TIMEOUT ]; then
            echo ""
            echo "❌ Timeout esperando servicio"
            echo "🔄 Iniciando rollback a revisión $OLD_REVISION..."

            aws ecs update-service \
                --cluster "$CLUSTER" \
                --service "$SERVICE_NAME" \
                --task-definition "$TASK_FAMILY:$OLD_REVISION" \
                --region us-east-1

            echo "✅ Rollback completado"
            exit 1
        fi

        sleep 5
    done
else
    echo ""
    echo "❌ Deployment falló, sin cambios en ECS"
    exit 1
fi
```

---

## 6. Deploy en horario específico

### Script: `deploy-scheduled.sh`

```bash
#!/bin/bash

# Deploy solo en horario permitido (ej: 10:00-18:00)
HOUR=$(date +%H)
MIN_HOUR=10
MAX_HOUR=18

if [ $HOUR -lt $MIN_HOUR ] || [ $HOUR -ge $MAX_HOUR ]; then
    echo "❌ Deployments permitidos solo entre $MIN_HOUR:00 y $MAX_HOUR:00"
    exit 1
fi

# Evitar deployments en viernes (4) y fin de semana
DOW=$(date +%w)  # 0=domingo, 5=viernes
if [ $DOW -eq 5 ] || [ $DOW -eq 0 ] || [ $DOW -eq 6 ]; then
    echo "❌ No se permiten deployments los viernes o fin de semana"
    exit 1
fi

# Proceder con el deployment
make deploy-admin-back
```

---

## 7. Build y push sin update automático

```bash
# Hacer build de todas las imágenes
make build-all

# Revisar que se construyeron correctamente
docker images | grep mexp-

# Hacer login en ECR
make ecr-login

# Push de imagen específica
make push-admin-back

# Verificar en ECR
aws ecr describe-images \
    --repository-name mexp-admin-back \
    --region us-east-1
```

---

## 8. Deploy de prueba antes de producción

```bash
# Primero en un ambiente de testing
cd infrastructure
make deploy-admin-back AWS_ACCOUNT_ID=123456789  # Otra cuenta/región

# Probar cambios
# ...

# Luego en producción
make deploy-admin-back AWS_ACCOUNT_ID=991795763909
```

---

## 9. Limpiar y reorganizar deployments

```bash
# Ver todas las revisiones de una task
aws ecs describe-task-definition \
    --task-definition mexp-admin-back \
    --region us-east-1

# Listar todas las imágenes en ECR
aws ecr describe-images \
    --repository-name mexp-admin-back \
    --region us-east-1

# Eliminar imágenes antiguas (>30 días)
aws ecr batch-delete-image \
    --repository-name mexp-admin-back \
    --image-ids $(aws ecr describe-images \
        --repository-name mexp-admin-back \
        --query 'sort_by(imageDetails,&imagePushedAt)[:-10].imageId' \
        --output json) \
    --region us-east-1
```

---

## 10. Integración con Git hooks

### `.git/hooks/post-commit`

```bash
#!/bin/bash
# Auto-deploy después de commit a main

BRANCH=$(git rev-parse --abbrev-ref HEAD)

if [ "$BRANCH" != "main" ]; then
    exit 0
fi

echo "🔔 Post-commit hook: Branch es main"

# Detectar qué cambió
if git diff HEAD~1 --name-only | grep -q "Backend-Admin"; then
    echo "📝 Detectados cambios en Backend-Admin"
    cd infrastructure
    make deploy-admin-back
fi
```

**Activar:**

```bash
chmod +x .git/hooks/post-commit
```

---

## 📊 Comparativa de estrategias

| Estrategia             | Pros          | Contras            | Cuándo usar            |
| ---------------------- | ------------- | ------------------ | ---------------------- |
| Manual                 | Control total | Requiere atención  | Cambios críticos       |
| CI/CD (GitHub Actions) | Automático    | Setup inicial      | Deployments frecuentes |
| Con confirmación       | Seguro        | Requiere respuesta | Producción             |
| Scheduled              | Predictable   | Menos flexible     | Equipo distribuido     |
| Rollback automático    | Seguro        | Complejo           | Alta disponibilidad    |

---

## 🆘 Debugging avanzado

```bash
# Ver logs detallados del ECS
aws ecs describe-task-definition \
    --task-definition mexp-admin-back:123 \
    --region us-east-1 \
    --query 'taskDefinition' | jq .

# Ver logs en CloudWatch
aws logs tail /ecs/mexp-admin-back --follow --since 10m

# Conectar a contenedor en ejecución (ECS Exec)
aws ecs execute-command \
    --cluster mexp-apps-shared-cluster \
    --task <TASK_ID> \
    --container admin-api \
    --command "/bin/sh" \
    --interactive
```

---

## 📚 Recursos

- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Docker Documentation](https://docs.docker.com/)
- [Makefile Tutorial](https://www.gnu.org/software/make/manual/)

---

💡 **Recuerda:** Siempre testa en un ambiente no-producción primero.
