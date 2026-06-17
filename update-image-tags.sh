#!/bin/bash
# =================================================================
# update-image-tags.sh - Script para actualizar IMAGE_TAG en .env files
# =================================================================
# Uso:
#   ./update-image-tags.sh                    # Actualiza todos los tags
#   ./update-image-tags.sh admin              # Solo Admin (backend + frontend)
#   ./update-image-tags.sh admin-backend      # Solo Admin Backend
#   ./update-image-tags.sh myxp               # Solo MyXperiences
# =================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Rutas
ADMIN_BACK_DIR="../Backend-Admin"
ADMIN_FRONT_DIR="../Frontend-Admin"
MYXP_BACK_DIR="../Prueba/backend"
MYXP_FRONT_DIR="../Prueba/frontend"

echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  📋 UPDATE IMAGE TAGS${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""

# Función para obtener git short hash
get_git_hash() {
    local repo_dir="$1"
    local default="$2"
    
    if [ -d "$repo_dir/.git" ]; then
        git -C "$repo_dir" rev-parse --short HEAD 2>/dev/null || echo "$default"
    else
        echo "$default"
    fi
}

# Función para actualizar IMAGE_TAG en archivo .env
update_image_tag() {
    local env_file="$1"
    local new_tag="$2"
    local service_name="$3"
    
    if [ ! -f "$env_file" ]; then
        echo -e "${RED}❌ File not found: $env_file${NC}"
        return 1
    fi
    
    # Obtener tag anterior
    local old_tag=$(grep "^IMAGE_TAG=" "$env_file" | cut -d'=' -f2 || echo "N/A")
    
    # Actualizar
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s/^IMAGE_TAG=.*/IMAGE_TAG=$new_tag/" "$env_file"
    else
        # Linux
        sed -i "s/^IMAGE_TAG=.*/IMAGE_TAG=$new_tag/" "$env_file"
    fi
    
    echo -e "${GREEN}✅ $service_name${NC}"
    echo "   📍 File: $env_file"
    echo "   Old Tag: ${YELLOW}$old_tag${NC}"
    echo "   New Tag: ${GREEN}$new_tag${NC}"
    echo ""
}

# Determinar qué servicios actualizar
UPDATE_ADMIN_BACK=false
UPDATE_ADMIN_FRONT=false
UPDATE_MYXP_BACK=false
UPDATE_MYXP_FRONT=false

case "${1:-all}" in
    "all")
        UPDATE_ADMIN_BACK=true
        UPDATE_ADMIN_FRONT=true
        UPDATE_MYXP_BACK=true
        UPDATE_MYXP_FRONT=true
        ;;
    "admin")
        UPDATE_ADMIN_BACK=true
        UPDATE_ADMIN_FRONT=true
        ;;
    "admin-backend" | "admin-back")
        UPDATE_ADMIN_BACK=true
        ;;
    "admin-frontend" | "admin-front")
        UPDATE_ADMIN_FRONT=true
        ;;
    "myxp" | "myxperiences")
        UPDATE_MYXP_BACK=true
        UPDATE_MYXP_FRONT=true
        ;;
    "myxp-backend" | "myxp-back")
        UPDATE_MYXP_BACK=true
        ;;
    "myxp-frontend" | "myxp-front")
        UPDATE_MYXP_FRONT=true
        ;;
    *)
        echo -e "${RED}❌ Uso desconocido: $1${NC}"
        echo ""
        echo "Uso:"
        echo "  $0                    # Actualizar todos"
        echo "  $0 admin              # Solo Admin"
        echo "  $0 admin-back         # Solo Admin Backend"
        echo "  $0 admin-front        # Solo Admin Frontend"
        echo "  $0 myxp               # Solo MyXperiences"
        echo "  $0 myxp-back          # Solo MyXp Backend"
        echo "  $0 myxp-front         # Solo MyXp Frontend"
        exit 1
        ;;
esac

echo -e "${YELLOW}🔍 Obteniendo tags de git...${NC}"
echo ""

# Admin Backend
if [ "$UPDATE_ADMIN_BACK" = true ]; then
    ADMIN_BACK_TAG=$(get_git_hash "$ADMIN_BACK_DIR" "manual")
    update_image_tag "ecs-admin/.env_admin_backend.template" "$ADMIN_BACK_TAG" "Admin Backend"
fi

# Admin Frontend
if [ "$UPDATE_ADMIN_FRONT" = true ]; then
    ADMIN_FRONT_TAG=$(get_git_hash "$ADMIN_FRONT_DIR" "manual")
    update_image_tag "ecs-admin/.env_admin_frontend.template" "$ADMIN_FRONT_TAG" "Admin Frontend"
fi

# MyXperiences Backend
if [ "$UPDATE_MYXP_BACK" = true ]; then
    MYXP_BACK_TAG=$(get_git_hash "$MYXP_BACK_DIR" "manual")
    update_image_tag "ecs/.env_backend" "$MYXP_BACK_TAG" "MyXperiences Backend"
fi

# MyXperiences Frontend
if [ "$UPDATE_MYXP_FRONT" = true ]; then
    MYXP_FRONT_TAG=$(get_git_hash "$MYXP_FRONT_DIR" "manual")
    update_image_tag "ecs/.env_frontend" "$MYXP_FRONT_TAG" "MyXperiences Frontend"
fi

echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅ IMAGE TAGS UPDATED${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo ""
echo "Ahora puedes ejecutar:"
echo -e "  ${BLUE}make deploy-all${NC}  # Para deployar todo"
echo ""
