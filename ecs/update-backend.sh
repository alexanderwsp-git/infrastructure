#!/bin/bash

REGION="us-east-1"
CLUSTER_NAME="mexp-apps-shared-cluster"
SERVICE_NAME="mexp-lanapp-back-service"
TASK_FAMILY="mexp-lanapp-back"
TEMPLATE_FILE_NAME_BACKEND="lanapp-back-task-definition.json"
FILE_NAME_BACKEND="lanapp-back-task-definition-var.json"

cp $TEMPLATE_FILE_NAME_BACKEND $FILE_NAME_BACKEND

if [ -f .env_backend ]; then
  set -a
  source .env_backend
  set +a
else
  echo ".env_backend file not found"
  exit 1
fi

sed -i "" "s|\$IMAGE_TAG|$IMAGE_TAG|g" $FILE_NAME_BACKEND
sed -i "" "s|\$PORT|$PORT|g" $FILE_NAME_BACKEND
sed -i "" "s|\$NODE_ENV|$NODE_ENV|g" $FILE_NAME_BACKEND
sed -i "" "s|\$DATABASE_URL|$DATABASE_URL|g" $FILE_NAME_BACKEND
sed -i "" "s|\$DATABASE_SSL|$DATABASE_SSL|g" $FILE_NAME_BACKEND
sed -i "" "s|\$DATABASE_SCHEMA|$DATABASE_SCHEMA|g" $FILE_NAME_BACKEND
sed -i "" "s|\$API_PREFIX|$API_PREFIX|g" $FILE_NAME_BACKEND
sed -i "" "s|\$SKIP_AUTH|$SKIP_AUTH|g" $FILE_NAME_BACKEND
sed -i "" "s|\$COGNITO_USER_POOL_ID|$COGNITO_USER_POOL_ID|g" $FILE_NAME_BACKEND
sed -i "" "s|\$COGNITO_CLIENT_ID|$COGNITO_CLIENT_ID|g" $FILE_NAME_BACKEND

echo "✅ ¡Archivo original modificado con éxito $IMAGE_TAG!"

if jq . $FILE_NAME_BACKEND > /dev/null; then
  echo "✅ ¡Éxito! El archivo JSON es válido y está listo para usarse."
else
  echo "❌ Error crítico: El archivo JSON final quedó mal estructurado."
  exit 1
fi

echo "🔄 Detectando nuevo tag en task-definition.json..."

# 1. Registrar la NUEVA versión de la Task Definition
echo "📝 Registrando nueva revisión del contenedor..."
aws ecs register-task-definition \
  --cli-input-json file://$FILE_NAME_BACKEND \
  --region $REGION


if [ $? -ne 0 ]; then
    echo "❌ Error al registrar la Task Definition."
    exit 1
fi

# 2. Actualizar el servicio existente (Comando corregido en una sola línea)
echo "🚀 Actualizando el servicio ECS con la última revisión..."
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

echo "✅ ¡Despliegue iniciado en AWS!"
echo "⏳ AWS Fargate iniciará el nuevo contenedor, validará el Health Check y apagará el viejo automáticamente."