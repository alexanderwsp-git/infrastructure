#!/bin/bash

REGION="us-east-1"
CLUSTER_NAME="mexp-apps-shared-cluster"
SERVICE_NAME="mexp-lanapp-front-service"
TASK_FAMILY="mexp-lanapp-front"
TEMPLATE_FILE_NAME_FRONTEND="lanapp-front-task-definition.json"
FILE_NAME_FRONTEND="lanapp-front-task-definition-var.json"

cp $TEMPLATE_FILE_NAME_FRONTEND $FILE_NAME_FRONTEND

if [ -f .env_frontend ]; then
  set -a
  source .env_frontend
  set +a
else
  echo ".env_frontend file not found"
  exit 1
fi

sed -i "" "s|\$IMAGE_TAG|$IMAGE_TAG|g" $FILE_NAME_FRONTEND
sed -i "" "s|\$PORT|$PORT|g" $FILE_NAME_FRONTEND
sed -i "" "s|\$NODE_ENV|$NODE_ENV|g" $FILE_NAME_FRONTEND
sed -i "" "s|\$HOSTNAME|$HOSTNAME|g" $FILE_NAME_FRONTEND
sed -i "" "s|\$AWS_REGION|$AWS_REGION|g" $FILE_NAME_FRONTEND
sed -i "" "s|\$COGNITO_USER_POOL_ID|$COGNITO_USER_POOL_ID|g" $FILE_NAME_FRONTEND
sed -i "" "s|\$COGNITO_CLIENT_ID|$COGNITO_CLIENT_ID|g" $FILE_NAME_FRONTEND
sed -i "" "s|\$COGNITO_CLIENT_SECRET|$COGNITO_CLIENT_SECRET|g" $FILE_NAME_FRONTEND

echo "✅ ¡Archivo original modificado con éxito $IMAGE_TAG!"

if jq . $FILE_NAME_FRONTEND > /dev/null; then
  echo "✅ ¡Éxito! El archivo JSON es válido y está listo para usarse."
else
  echo "❌ Error crítico: El archivo JSON final quedó mal estructurado."
  exit 1
fi

echo "🔄 Registrando nueva revisión del frontend..."

aws ecs register-task-definition \
  --cli-input-json file://$FILE_NAME_FRONTEND \
  --region $REGION

if [ $? -ne 0 ]; then
    echo "❌ Error al registrar la Task Definition."
    exit 1
fi

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
echo "🌐 https://lanapp.myxperiences.org"
