#!/bin/bash
# =================================================================
# Update myxperiences frontend service in ECS
# Compatible with Git Bash on Windows
# =================================================================

set -e

# Configuration
REGION="us-east-1"
CLUSTER_NAME="mexp-apps-shared-cluster"
SERVICE_NAME="mexp-myxperiences-front-service"
TASK_FAMILY="mexp-myxperiences-front"
TEMPLATE_FILE="myxperiences-front-task-definition.json"
OUTPUT_FILE="myxperiences-front-task-definition-var.json"

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

echo "🔄 Starting myxperiences frontend update..."

# Copy template to output file
cp "$TEMPLATE_FILE" "$OUTPUT_FILE"

# Load environment variables
if [ -f .env_myxperiences_frontend ]; then
  set -a
  source .env_myxperiences_frontend
  set +a
else
  echo "❌ .env_myxperiences_frontend file not found"
  exit 1
fi

# Replace all environment variables
echo "📝 Replacing environment variables in task definition..."
replace_var "IMAGE_TAG" "$IMAGE_TAG"
replace_var "PORT" "$PORT"
replace_var "NODE_ENV" "$NODE_ENV"
replace_var "HOSTNAME" "$HOSTNAME"
replace_var "VITE_API_SERVICE" "$VITE_API_SERVICE"

echo "✅ Task definition file created successfully!"

# Validate JSON
if jq . "$OUTPUT_FILE" > /dev/null 2>&1; then
  echo "✅ JSON is valid"
else
  echo "❌ Invalid JSON in task definition"
  exit 1
fi

# Register new task definition
echo "📝 Registering new task definition..."
aws ecs register-task-definition \
  --cli-input-json file://"$OUTPUT_FILE" \
  --region $REGION

if [ $? -ne 0 ]; then
  echo "❌ Failed to register task definition"
  exit 1
fi

# Update service with new task definition
echo "🔄 Updating ECS service..."
aws ecs update-service \
  --cluster $CLUSTER_NAME \
  --service $SERVICE_NAME \
  --task-definition $TASK_FAMILY \
  --force-new-deployment \
  --region $REGION

if [ $? -ne 0 ]; then
  echo "❌ Failed to update ECS service"
  exit 1
fi

echo "✅ myxperiences frontend service updated successfully!"
echo "⏳ ECS is deploying the new version..."
