#!/bin/bash
# =================================================================
# CONFIGURACIÓN BASE
# =================================================================
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

echo "🔍 Buscando identificadores de infraestructura en AWS ($REGION)..."

# =================================================================
# EXTRACCIÓN AUTOMÁTICA DE VARIABLES VÍA AWS CLI
# =================================================================

SUBNET_A=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=mexp-public-subnet-1a" --query "Subnets[0].SubnetId" --output text --region $REGION)
SUBNET_B=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=mexp-public-subnet-1b" --query "Subnets[0].SubnetId" --output text --region $REGION)
SECURITY_GROUP=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=mexp-ecs-containers-sg" --query "SecurityGroups[0].GroupId" --output text --region $REGION)
TARGET_GROUP_ARN=$(aws elbv2 describe-target-groups --names "mexp-lanapp-back-tg" --query "TargetGroups[0].TargetGroupArn" --output text --region $REGION)

# Validación rápida de que se encontraron los recursos
if [ "$SUBNET_A" == "None" ] || [ "$SECURITY_GROUP" == "None" ] || [ -z "$TARGET_GROUP_ARN" ]; then
    echo "❌ Error: No se pudo mapear la infraestructura base. Verifica que el Terraform se haya ejecutado con éxito."
    exit 1
fi

echo "📍 Recursos encontrados con éxito:"
echo "   - Subred A: $SUBNET_A"
echo "   - Subred B: $SUBNET_B"
echo "   - Security Group: $SECURITY_GROUP"
echo "   - Target Group: $TARGET_GROUP_ARN"
echo "-------------------------------------------------------------"

# =================================================================
# PROCESO DE DESPLIEGUE
# =================================================================

echo "🚀 Iniciando despliegue de $SERVICE_NAME en AWS ECS..."

# 1. Registrar la Task Definition
echo "📝 Registrando nueva Task Definition desde task-definition.json..."
aws ecs register-task-definition \
  --cli-input-json file://$FILE_NAME_BACKEND \
  --region $REGION

if [ $? -ne 0 ]; then
    echo "❌ Error al registrar la Task Definition. Abortando."
    exit 1
fi

# 2. Crear el Servicio de ECS
echo "🏗️ Creando el servicio Fargate y amarrándolo al balanceador..."
aws ecs create-service \
  --cluster $CLUSTER_NAME \
  --service-name $SERVICE_NAME \
  --task-definition $TASK_FAMILY \
  --desired-count 1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_A,$SUBNET_B],securityGroups=[$SECURITY_GROUP],assignPublicIp=ENABLED}" \
  --load-balancers "targetGroupArn=$TARGET_GROUP_ARN,containerName=lanapp-api,containerPort=3000" \
  --region $REGION

if [ $? -ne 0 ]; then
    echo "❌ Error al crear el servicio de ECS."
    exit 1
fi

echo "✅ ¡Servicio enviado a AWS con éxito!"
echo "⏳ AWS Fargate está levantando el contenedor..."
