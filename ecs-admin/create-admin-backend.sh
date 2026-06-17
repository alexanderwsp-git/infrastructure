#!/bin/bash
# =================================================================
# CONFIGURACIÓN BASE
# =================================================================
REGION="us-east-1"
CLUSTER_NAME="mexp-apps-shared-cluster"
SERVICE_NAME="mexp-admin-back-service"
TASK_FAMILY="mexp-admin-back"
TEMPLATE_FILE="admin-back-task-definition.json"
OUTPUT_FILE="admin-back-task-definition-var.json"

cp $TEMPLATE_FILE $OUTPUT_FILE

if [ -f .env_admin_backend.template ]; then
  set -a
  source .env_admin_backend.template
  set +a
else
  echo ".env_admin_backend.template file not found"
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
replace_var "NODE_ENV" "$NODE_ENV"
replace_var "POSTGRES_DB" "$POSTGRES_DB"
replace_var "POSTGRES_USER" "$POSTGRES_USER"
replace_var "POSTGRES_PASSWORD" "$POSTGRES_PASSWORD"
replace_var "POSTGRES_HOST" "$POSTGRES_HOST"
replace_var "POSTGRES_PORT" "$POSTGRES_PORT"
replace_var "JWT_SEED" "$JWT_SEED"
replace_var "SYNCALTER" "$SYNCALTER"
replace_var "MAILER_HOST" "$MAILER_HOST"
replace_var "MAILER_PORT" "$MAILER_PORT"
replace_var "MAILER_USER" "$MAILER_USER"
replace_var "MAILER_PASS" "$MAILER_PASS"
replace_var "MAILER_FROM" "$MAILER_FROM"
replace_var "DOMINIO_EXPERIENCES" "$DOMINIO_EXPERIENCES"
replace_var "AWS_BUCKET_NAME" "$AWS_BUCKET_NAME"
replace_var "AWS_BUCKET_REGION" "$AWS_BUCKET_REGION"
replace_var "INTERNAL_API_KEY" "$INTERNAL_API_KEY"
replace_var "BACKEND_MYXPERIENCES_URL" "$BACKEND_MYXPERIENCES_URL"
replace_var "NGTECO_USERNAME" "$NGTECO_USERNAME"
replace_var "NGTECO_PASSWORD" "$NGTECO_PASSWORD"
replace_var "NGTECO_API_URL" "$NGTECO_API_URL"
replace_var "GOOGLE_SHEET_ID" "$GOOGLE_SHEET_ID"
replace_var "GOOGLE_SERVICE_ACCOUNT_EMAIL" "$GOOGLE_SERVICE_ACCOUNT_EMAIL"
replace_var "GOOGLE_PRIVATE_KEY" "$GOOGLE_PRIVATE_KEY"

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
TARGET_GROUP_ARN=$(aws elbv2 describe-target-groups --names "mexp-admin-back-tg" --query "TargetGroups[0].TargetGroupArn" --output text --region $REGION)

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
  --load-balancers "targetGroupArn=$TARGET_GROUP_ARN,containerName=admin-api,containerPort=3000" \
  --region $REGION

if [ $? -ne 0 ]; then
    echo "❌ Error al crear el servicio."
    exit 1
fi

echo "✅ Servicio $SERVICE_NAME creado con éxito."
echo "🌐 https://admin-api.myxperiences.org"
