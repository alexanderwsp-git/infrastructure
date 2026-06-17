#!/bin/bash
# =================================================================
# update-env-tag.sh - Actualiza IMAGE_TAG en archivos .env
# =================================================================
# Uso:
#   ./update-env-tag.sh ecs-admin/.env_admin_backend.template ../Backend-Admin
#   ./update-env-tag.sh ecs/.env_backend ../../Prueba/backend
# =================================================================

ENV_FILE="$1"
REPO_DIR="$2"

if [ -z "$ENV_FILE" ] || [ -z "$REPO_DIR" ]; then
    echo "❌ Uso: $0 <env_file> <repo_dir>"
    exit 1
fi

if [ ! -f "$ENV_FILE" ]; then
    echo "❌ Archivo no encontrado: $ENV_FILE"
    exit 1
fi

if [ ! -d "$REPO_DIR" ]; then
    echo "❌ Directorio no encontrado: $REPO_DIR"
    exit 1
fi

# Obtener el hash de git
IMAGE_TAG=$(git -C "$REPO_DIR" rev-parse --short HEAD 2>/dev/null || echo "manual")

if [ -z "$IMAGE_TAG" ]; then
    IMAGE_TAG="manual"
fi

echo "📝 Actualizando $ENV_FILE → IMAGE_TAG=$IMAGE_TAG"

# Crear archivo temporal
TEMP_FILE="${ENV_FILE}.tmp"

# Leer archivo línea por línea y reemplazar IMAGE_TAG
while IFS= read -r line; do
    if [[ "$line" =~ ^IMAGE_TAG= ]]; then
        echo "IMAGE_TAG=$IMAGE_TAG" >> "$TEMP_FILE"
    else
        echo "$line" >> "$TEMP_FILE"
    fi
done < "$ENV_FILE"

# Reemplazar archivo original
mv "$TEMP_FILE" "$ENV_FILE"

echo "✅ Actualizado: IMAGE_TAG=$IMAGE_TAG"
