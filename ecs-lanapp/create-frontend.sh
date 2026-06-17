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

echo "🔍 Buscando identificadores de infraestructura en AWS ($REGION)..."

SUBNET_A=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=mexp-public-subnet-1a" --query "Subnets[0].SubnetId" --output text --region $REGION)
SUBNET_B=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=mexp-public-subnet-1b" --query "Subnets[0].SubnetId" --output text --region $REGION)
SECURITY_GROUP=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=mexp-ecs-containers-sg" --query "SecurityGroups[0].GroupId" --output text --region $REGION)
TARGET_GROUP_ARN=$(aws elbv2 describe-target-groups --names "mexp-lanapp-front-tg" --query "TargetGroups[0].TargetGroupArn" --output text --region $REGION)

if [ "$SUBNET_A" == "None" ] || [ "$SECURITY_GROUP" == "None" ] || [ -z "$TARGET_GROUP_ARN" ]; then
    echo "❌ Error: No se pudo mapear la infraestructura base. Verifica que el Terraform se haya ejecutado con éxito."
    exit 1
fi

echo "📍 Recursos encontrados:"
echo "   - Subred A: $SUBNET_A"
echo "   - Subred B: $SUBNET_B"
echo "   - Security Group: $SECURITY_GROUP"
echo "   - Target Group: $TARGET_GROUP_ARN"
echo "-------------------------------------------------------------"

echo "🚀 Creando $SERVICE_NAME en ECS..."

aws ecs register-task-definition \
  --cli-input-json file://$FILE_NAME_FRONTEND \
  --region $REGION

if [ $? -ne 0 ]; then
    echo "❌ Error al registrar la Task Definition."
    exit 1
fi

aws ecs create-service \
  --cluster $CLUSTER_NAME \
  --service-name $SERVICE_NAME \
  --task-definition $TASK_FAMILY \
  --desired-count 1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_A,$SUBNET_B],securityGroups=[$SECURITY_GROUP],assignPublicIp=ENABLED}" \
  --load-balancers "targetGroupArn=$TARGET_GROUP_ARN,containerName=lanapp-ui,containerPort=3000" \
  --region $REGION

if [ $? -ne 0 ]; then
    echo "❌ Error al crear el servicio de ECS."
    exit 1
fi

echo "✅ Servicio frontend creado."
echo "🌐 https://lanapp.myxperiences.org"
