#!/bin/bash
# =================================================================
# Update Admin Frontend Service in ECS
# Compatible with Git Bash on Windows
# =================================================================

set -e

# Configuration
REGION="us-east-1"
CLUSTER_NAME="mexp-apps-shared-cluster"
SERVICE_NAME="mexp-admin-front-service"
TASK_FAMILY="mexp-admin-front"
TEMPLATE_FILE="admin-front-task-definition.json"
OUTPUT_FILE="admin-front-task-definition-var.json"
FRONTEND_DIR="../../Frontend-Admin"

# Function to escape special characters for sed replacement
escape_sed_replacement() {
  echo "$1" | sed 's/[&/\]/\\&/g'
}

# Function to replace a variable in the task definition
replace_var() {
  local var_name="$1"
  local var_value="$2"
  local escaped_value
  escaped_value=$(escape_sed_replacement "$var_value")
  sed -i "s|\$$var_name|$escaped_value|g" "$OUTPUT_FILE"
}

# Get IMAGE_TAG from git
IMAGE_TAG=$(git -C "$FRONTEND_DIR" rev-parse --short HEAD 2>/dev/null || echo "manual")

# Load other variables from .env_admin_frontend.template
if [ -f .env_admin_frontend.template ]; then
  set -a
  source .env_admin_frontend.template
  set +a
else
  echo ".env_admin_frontend.template file not found"
  exit 1
fi

echo "🔄 Starting admin frontend update..."
echo "📦 Using IMAGE_TAG: $IMAGE_TAG"

# Copy template to output file
cp "$TEMPLATE_FILE" "$OUTPUT_FILE"

# Replace variables
replace_var "IMAGE_TAG" "$IMAGE_TAG"
replace_var "PORT" "$PORT"
replace_var "HOSTNAME" "$HOSTNAME"
replace_var "VITE_API_SERVICE" "$VITE_API_SERVICE"
replace_var "VITE_API_INTERNAL_API_KEY" "$VITE_API_INTERNAL_API_KEY"

echo "✅ Variables sustituidas con éxito ($IMAGE_TAG)"

if jq . $OUTPUT_FILE > /dev/null 2>&1; then
  echo "✅ JSON válido y listo para usarse."
else
  echo "❌ Error: El JSON final quedó mal estructurado."
  exit 1
fi

echo "📝 Registrando nueva revisión de la Task Definition..."
aws ecs register-task-definition \
  --cli-input-json file://$OUTPUT_FILE \
  --region $REGION

if [ $? -ne 0 ]; then
    echo "❌ Error al registrar la Task Definition."
    exit 1
fi

echo "🚀 Actualizando el servicio ECS..."
aws ecs update-service \
  --cluster "$CLUSTER_NAME" \
  --service "$SERVICE_NAME" \
  --task-definition "$TASK_FAMILY" \
  --force-new-deployment \
  --region "$REGION"

if [ $? -ne 0 ]; then
    echo "❌ Error al actualizar el servicio."
    exit 1
fi

echo "✅ Despliegue frontend iniciado."
echo "🌐 https://admin.myxperiences.org"
