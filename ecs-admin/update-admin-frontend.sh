#!/bin/bash
# =================================================================
# CONFIGURACIÓN BASE
# =================================================================
REGION="us-east-1"
CLUSTER_NAME="mexp-apps-shared-cluster"
SERVICE_NAME="mexp-admin-front-service"
TASK_FAMILY="mexp-admin-front"
TEMPLATE_FILE="admin-front-task-definition.json"
OUTPUT_FILE="admin-front-task-definition-var.json"

cp $TEMPLATE_FILE $OUTPUT_FILE

if [ -f .env_admin_frontend.template ]; then
  set -a
  source .env_admin_frontend.template
  set +a
else
  echo ".env_admin_frontend.template file not found"
  exit 1
fi

escape_sed_replacement() {
  printf '%s' "$1" | sed -e 's/[&|\\]/\\&/g'
}

replace_var() {
  local key="$1"
  local value="$2"
  sed -i "s|\$$key|$(escape_sed_replacement "$value")|g" "$OUTPUT_FILE"
}

replace_var "IMAGE_TAG" "$IMAGE_TAG"
replace_var "PORT" "$PORT"
replace_var "HOSTNAME" "$HOSTNAME"
replace_var "VITE_API_SERVICE" "$VITE_API_SERVICE"
replace_var "VITE_API_INTERNAL_API_KEY" "$VITE_API_INTERNAL_API_KEY"

echo "✅ Variables sustituidas con éxito ($IMAGE_TAG)"

if jq . $OUTPUT_FILE > /dev/null; then
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
