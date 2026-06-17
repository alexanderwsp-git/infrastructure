#!/bin/bash
# =================================================================
# Create myxperiences backend service in ECS
# Compatible with Git Bash on Windows
# =================================================================

set -e

# Configuration
REGION="us-east-1"
CLUSTER_NAME="mexp-apps-shared-cluster"
SERVICE_NAME="mexp-myxperiences-back-service"
TASK_FAMILY="mexp-myxperiences-back"
TEMPLATE_FILE="myxperiences-back-task-definition.json"
OUTPUT_FILE="myxperiences-back-task-definition-var.json"

# Function to escape special characters for sed replacement
escape_sed_replacement() {
  echo "$1" | sed 's/[&/\*]/\\&/g'
}

# Function to replace a variable in the task definition
replace_var() {
  local var_name="$1"
  local var_value="$2"
  local escaped_value
  escaped_value=$(escape_sed_replacement "$var_value")
  sed -i "s|\$$var_name|$escaped_value|g" "$OUTPUT_FILE"
}

echo "🚀 Starting myxperiences backend deployment..."

# Copy template to output file
cp "$TEMPLATE_FILE" "$OUTPUT_FILE"

# Load environment variables
if [ -f .env_myxperiences_backend ]; then
  set -a
  source .env_myxperiences_backend
  set +a
else
  echo "❌ .env_myxperiences_backend file not found"
  exit 1
fi

# Replace all environment variables
echo "📝 Replacing environment variables in task definition..."
replace_var "IMAGE_TAG" "$IMAGE_TAG"
replace_var "PORT" "$PORT"
replace_var "NODE_ENV" "$NODE_ENV"
replace_var "POSTGRES_PORT" "$POSTGRES_PORT"
replace_var "POSTGRES_DB" "$POSTGRES_DB"
replace_var "POSTGRES_USER" "$POSTGRES_USER"
replace_var "POSTGRES_PASSWORD" "$POSTGRES_PASSWORD"
replace_var "POSTGRES_HOST" "$POSTGRES_HOST"
replace_var "POSTGRES_SCHEMA" "$POSTGRES_SCHEMA"
replace_var "SECRET_JWT_SEED" "$SECRET_JWT_SEED"
replace_var "MAILER_HOST" "$MAILER_HOST"
replace_var "MAILER_PORT" "$MAILER_PORT"
replace_var "MAILER_USER" "$MAILER_USER"
replace_var "MAILER_PASS" "$MAILER_PASS"
replace_var "MAILER_FRONT" "$MAILER_FRONT"
replace_var "DOMINIO_EXPERIENCES" "$DOMINIO_EXPERIENCES"
replace_var "AWS_BUCKET_NAME" "$AWS_BUCKET_NAME"
replace_var "AWS_BUCKET_REGION" "$AWS_BUCKET_REGION"
replace_var "AWS_ACCESS_KEY_ID" "$AWS_ACCESS_KEY_ID"
replace_var "AWS_SECRET_ACCESS_KEY" "$AWS_SECRET_ACCESS_KEY"
replace_var "PROD" "$PROD"
replace_var "SYNCALTER" "$SYNCALTER"
replace_var "SYNCFORCE" "$SYNCFORCE"
replace_var "MAKE_WEBHOOK_URL" "$MAKE_WEBHOOK_URL"
replace_var "BACKEND_ADMIN_URL" "$BACKEND_ADMIN_URL"
replace_var "INTERNAL_API_KEY" "$INTERNAL_API_KEY"
replace_var "GOOGLE_SHEET_ID" "$GOOGLE_SHEET_ID"
replace_var "GOOGLE_SERVICE_ACCOUNT_EMAIL" "$GOOGLE_SERVICE_ACCOUNT_EMAIL"
replace_var "GOOGLE_PRIVATE_KEY" "$GOOGLE_PRIVATE_KEY"

echo "✅ Task definition file created successfully!"

# Validate JSON
if jq . "$OUTPUT_FILE" > /dev/null 2>&1; then
  echo "✅ JSON is valid"
else
  echo "❌ Invalid JSON in task definition"
  exit 1
fi

# Get AWS infrastructure IDs
echo "🔍 Retrieving AWS infrastructure identifiers..."
SUBNET_A=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=mexp-public-subnet-1a" --query "Subnets[0].SubnetId" --output text --region $REGION)
SUBNET_B=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=mexp-public-subnet-1b" --query "Subnets[0].SubnetId" --output text --region $REGION)
SECURITY_GROUP=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=mexp-ecs-containers-sg" --query "SecurityGroups[0].GroupId" --output text --region $REGION)
TARGET_GROUP_ARN=$(aws elbv2 describe-target-groups --names "mexp-myxperiences-back-tg" --query "TargetGroups[0].TargetGroupArn" --output text --region $REGION)

# Validate infrastructure
if [ "$SUBNET_A" == "None" ] || [ "$SECURITY_GROUP" == "None" ] || [ -z "$TARGET_GROUP_ARN" ]; then
  echo "❌ Failed to retrieve infrastructure resources"
  exit 1
fi

echo "📍 Resources found:"
echo "   - Subnet A: $SUBNET_A"
echo "   - Subnet B: $SUBNET_B"
echo "   - Security Group: $SECURITY_GROUP"
echo "   - Target Group: $TARGET_GROUP_ARN"

# Register task definition
echo "📝 Registering task definition..."
aws ecs register-task-definition \
  --cli-input-json file://"$OUTPUT_FILE" \
  --region $REGION

if [ $? -ne 0 ]; then
  echo "❌ Failed to register task definition"
  exit 1
fi

# Create ECS service
echo "🏗️ Creating ECS service..."
aws ecs create-service \
  --cluster $CLUSTER_NAME \
  --service-name $SERVICE_NAME \
  --task-definition $TASK_FAMILY \
  --desired-count 1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_A,$SUBNET_B],securityGroups=[$SECURITY_GROUP],assignPublicIp=ENABLED}" \
  --load-balancers "targetGroupArn=$TARGET_GROUP_ARN,containerName=myxperiences-api,containerPort=4000" \
  --region $REGION

if [ $? -ne 0 ]; then
  echo "❌ Failed to create ECS service"
  exit 1
fi

echo "✅ myxperiences backend service created successfully!"
echo "⏳ ECS is starting the container..."
echo "🌐 Backend will be available at: https://api.myxperiences.org"
