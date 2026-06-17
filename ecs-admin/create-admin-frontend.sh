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

echo "🔍 Buscando infraestructura en AWS ($REGION)..."

SUBNET_A=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=mexp-public-subnet-1a" --query "Subnets[0].SubnetId" --output text --region $REGION)
SUBNET_B=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=mexp-public-subnet-1b" --query "Subnets[0].SubnetId" --output text --region $REGION)
SECURITY_GROUP=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=mexp-ecs-containers-sg" --query "SecurityGroups[0].GroupId" --output text --region $REGION)
TARGET_GROUP_ARN=$(aws elbv2 describe-target-groups --names "mexp-admin-front-tg" --query "TargetGroups[0].TargetGroupArn" --output text --region $REGION)

if [ "$SUBNET_A" == "None" ] || [ "$SECURITY_GROUP" == "None" ] || [ -z "$TARGET_GROUP_ARN" ]; then
    echo "❌ Error: No se pudo mapear la infraestructura. Verifica que Terraform se haya ejecutado."
    exit 1
fi

echo "📍 Recursos encontrados:"
echo "   - Subred A: $SUBNET_A"
echo "   - Subred B: $SUBNET_B"
echo "   - Security Group: $SECURITY_GROUP"
echo "   - Target Group: $TARGET_GROUP_ARN"
echo "-------------------------------------------------------------"

echo "🚀 Iniciando despliegue de $SERVICE_NAME en AWS ECS..."

echo "📝 Registrando Task Definition..."
aws ecs register-task-definition \
  --cli-input-json file://$OUTPUT_FILE \
  --region $REGION

if [ $? -ne 0 ]; then
    echo "❌ Error al registrar la Task Definition."
    exit 1
fi

echo "🏗️ Creando el servicio ECS..."
aws ecs create-service \
  --cluster $CLUSTER_NAME \
  --service-name $SERVICE_NAME \
  --task-definition $TASK_FAMILY \
  --desired-count 1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_A,$SUBNET_B],securityGroups=[$SECURITY_GROUP],assignPublicIp=ENABLED}" \
  --load-balancers "targetGroupArn=$TARGET_GROUP_ARN,containerName=admin-ui,containerPort=3000" \
  --region $REGION

if [ $? -ne 0 ]; then
    echo "❌ Error al crear el servicio."
    exit 1
fi

echo "✅ Servicio $SERVICE_NAME creado con éxito."
echo "🌐 https://admin.myxperiences.org"
