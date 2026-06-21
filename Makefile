# =================================================================
# MAKEFILE - Automatización de Build, Push y Deployment ECS
# =================================================================
# Soporta: Admin Frontend, Admin Backend, MyXperiences Frontend, Backend
# Uso:
#   make build-admin-back         # Build imagen Backend Admin
#   make deploy-admin-back        # Deploy Backend Admin (build + push + update)
#   make deploy-all-admin         # Deploy Admin (frontend + backend)
#   make deploy-all               # Deploy todos los servicios
# =================================================================

# ============ CONFIGURACIÓN BASE ============
AWS_ACCOUNT_ID ?= 991795763909
AWS_REGION ?= us-east-1
ECR_REGISTRY ?= $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com

# ============ RUTAS ============
ROOT_DIR := $(shell pwd)
ADMIN_BACK_DIR := ../Backend-Admin
ADMIN_FRONT_DIR := ../Frontend-Admin
MYXP_BACK_DIR := ../../Prueba/backend
MYXP_FRONT_DIR := ../../Prueba/frontend

# ============ NOMBRES DE IMAGENES ============
ADMIN_BACK_REPO := mexp-admin-back
ADMIN_FRONT_REPO := mexp-admin-front
MYXP_BACK_REPO := mexp-lanapp-back
MYXP_FRONT_REPO := mexp-lanapp-front

# ============ CONFIGURACIONES POR SERVICIO ============
# Admin Backend
ADMIN_BACK_IMAGE := $(ECR_REGISTRY)/$(ADMIN_BACK_REPO)
ADMIN_BACK_ENV_FILE := ecs-admin/.env_admin_backend.template
ADMIN_BACK_TASK_TEMPLATE := ecs-admin/admin-back-task-definition.json

# Admin Frontend
ADMIN_FRONT_IMAGE := $(ECR_REGISTRY)/$(ADMIN_FRONT_REPO)
ADMIN_FRONT_ENV_FILE := ecs-admin/.env_admin_frontend.template
ADMIN_FRONT_TASK_TEMPLATE := ecs-admin/admin-front-task-definition.json

# MyXperiences Backend
MYXP_BACK_IMAGE := $(ECR_REGISTRY)/$(MYXP_BACK_REPO)
MYXP_BACK_ENV_FILE := ecs-myxperiences/.env_myxperiences_backend
MYXP_BACK_TASK_TEMPLATE := ecs-myxperiences/myxperiences-back-task-definition.json

# MyXperiences Frontend
MYXP_FRONT_IMAGE := $(ECR_REGISTRY)/$(MYXP_FRONT_REPO)
MYXP_FRONT_ENV_FILE := ecs-myxperiences/.env_myxperiences_frontend
MYXP_FRONT_TASK_TEMPLATE := ecs-myxperiences/myxperiences-front-task-definition.json

# ============ FUNCIONES ÚTILES ============
define get_image_tag
	@git -C $(1) rev-parse --short HEAD 2>/dev/null || echo "manual"
endef

define print_section
	@echo ""
	@echo "════════════════════════════════════════════════════════════"
	@echo "   $(1)"
	@echo "════════════════════════════════════════════════════════════"
	@echo ""
endef

# ============ TARGETS PRINCIPALES ============
.PHONY: help
help:
	@echo "🔧 MAKEFILE - Automatización ECS Deploy"
	@echo ""
	@echo "📌 BUILD TARGETS:"
	@echo "  make build-admin-back          - Build imagen Backend Admin"
	@echo "  make build-admin-front         - Build imagen Frontend Admin"
	@echo "  make build-myxp-back           - Build imagen Backend MyXperiences"
	@echo "  make build-myxp-front          - Build imagen Frontend MyXperiences"
	@echo "  make build-all                 - Build todas las imágenes"
	@echo ""
	@echo "🚀 DEPLOY TARGETS (Build + Push + Update):"
	@echo "  make deploy-admin-back         - Deploy Backend Admin (completo)"
	@echo "  make deploy-admin-front        - Deploy Frontend Admin (completo)"
	@echo "  make deploy-myxp-back          - Deploy Backend MyXperiences (completo)"
	@echo "  make deploy-myxp-front         - Deploy Frontend MyXperiences (completo)"
	@echo "  make deploy-all-admin          - Deploy todos los servicios Admin"
	@echo "  make deploy-all-myxp           - Deploy todos los servicios MyXperiences"
	@echo "  make deploy-all                - Deploy TODOS los servicios"
	@echo ""
	@echo "🔄 UPDATE TARGETS (Solo Update sin Build):"
	@echo "  make update-admin-back         - Update servicio Backend Admin"
	@echo "  make update-admin-front        - Update servicio Frontend Admin"
	@echo "  make update-myxp-back          - Update servicio Backend MyXperiences"
	@echo "  make update-myxp-front         - Update servicio Frontend MyXperiences"
	@echo ""
	@echo "🔐 AWS TARGETS:"
	@echo "  make ecr-login                 - Login a ECR"
	@echo "  make ecr-logout                - Logout de ECR"
	@echo ""

# ============ BUILD TARGETS ============
.PHONY: build-admin-back
build-admin-back:
	$(call print_section,🔨 BUILDING ADMIN BACKEND)
	@IMAGE_TAG=$$(git -C $(ADMIN_BACK_DIR) rev-parse --short HEAD 2>/dev/null || echo "manual"); \
	echo "📦 Building: $(ADMIN_BACK_IMAGE):$$IMAGE_TAG"; \
	docker build \
		--build-arg NODE_ENV=production \
		-t $(ADMIN_BACK_IMAGE):$$IMAGE_TAG \
		-t $(ADMIN_BACK_IMAGE):latest \
		-f $(ADMIN_BACK_DIR)/Dockerfile \
		$(ADMIN_BACK_DIR) || exit 1; \
	echo "✅ Build completado: $$IMAGE_TAG"

.PHONY: build-admin-front
build-admin-front:
	$(call print_section,🔨 BUILDING ADMIN FRONTEND)
	@IMAGE_TAG=$$(git -C $(ADMIN_FRONT_DIR) rev-parse --short HEAD 2>/dev/null || echo "manual"); \
	echo "📦 Building: $(ADMIN_FRONT_IMAGE):$$IMAGE_TAG"; \
	docker build \
		--build-arg NODE_ENV=production \
		-t $(ADMIN_FRONT_IMAGE):$$IMAGE_TAG \
		-t $(ADMIN_FRONT_IMAGE):latest \
		-f $(ADMIN_FRONT_DIR)/Dockerfile \
		$(ADMIN_FRONT_DIR) || exit 1; \
	echo "✅ Build completado: $$IMAGE_TAG"

.PHONY: build-myxp-back
build-myxp-back:
	$(call print_section,🔨 BUILDING MYXPERIENCES BACKEND)
	@IMAGE_TAG=$$(git -C $(MYXP_BACK_DIR) rev-parse --short HEAD 2>/dev/null || echo "manual"); \
	echo "📦 Building: $(MYXP_BACK_IMAGE):$$IMAGE_TAG"; \
	docker build \
		--build-arg NODE_ENV=production \
		-t $(MYXP_BACK_IMAGE):$$IMAGE_TAG \
		-t $(MYXP_BACK_IMAGE):latest \
		-f $(MYXP_BACK_DIR)/Dockerfile \
		$(MYXP_BACK_DIR) || exit 1; \
	echo "✅ Build completado: $$IMAGE_TAG"

.PHONY: build-myxp-front
build-myxp-front:
	$(call print_section,🔨 BUILDING MYXPERIENCES FRONTEND)
	@IMAGE_TAG=$$(git -C $(MYXP_FRONT_DIR) rev-parse --short HEAD 2>/dev/null || echo "manual"); \
	echo "📦 Building: $(MYXP_FRONT_IMAGE):$$IMAGE_TAG"; \
	docker build \
		--build-arg NODE_ENV=production \
		-t $(MYXP_FRONT_IMAGE):$$IMAGE_TAG \
		-t $(MYXP_FRONT_IMAGE):latest \
		-f $(MYXP_FRONT_DIR)/Dockerfile \
		$(MYXP_FRONT_DIR) || exit 1; \
	echo "✅ Build completado: $$IMAGE_TAG"

.PHONY: build-all
build-all: build-admin-back build-admin-front build-myxp-back build-myxp-front
	$(call print_section,✅ TODOS LOS BUILDS COMPLETADOS)

# ============ PUSH TARGETS ============
.PHONY: push-admin-back
push-admin-back: ecr-login
	$(call print_section,📤 PUSHING ADMIN BACKEND)
	@IMAGE_TAG=$$(git -C $(ADMIN_BACK_DIR) rev-parse --short HEAD 2>/dev/null || echo "manual"); \
	echo "📤 Pushing: $(ADMIN_BACK_IMAGE):$$IMAGE_TAG"; \
	docker push $(ADMIN_BACK_IMAGE):$$IMAGE_TAG || exit 1; \
	docker push $(ADMIN_BACK_IMAGE):latest || exit 1; \
	echo "✅ Push completado: $$IMAGE_TAG"

.PHONY: push-admin-front
push-admin-front: ecr-login
	$(call print_section,📤 PUSHING ADMIN FRONTEND)
	@IMAGE_TAG=$$(git -C $(ADMIN_FRONT_DIR) rev-parse --short HEAD 2>/dev/null || echo "manual"); \
	echo "📤 Pushing: $(ADMIN_FRONT_IMAGE):$$IMAGE_TAG"; \
	docker push $(ADMIN_FRONT_IMAGE):$$IMAGE_TAG || exit 1; \
	docker push $(ADMIN_FRONT_IMAGE):latest || exit 1; \
	echo "✅ Push completado: $$IMAGE_TAG"

.PHONY: push-myxp-back
push-myxp-back: ecr-login
	$(call print_section,📤 PUSHING MYXPERIENCES BACKEND)
	@IMAGE_TAG=$$(git -C $(MYXP_BACK_DIR) rev-parse --short HEAD 2>/dev/null || echo "manual"); \
	echo "📤 Pushing: $(MYXP_BACK_IMAGE):$$IMAGE_TAG"; \
	docker push $(MYXP_BACK_IMAGE):$$IMAGE_TAG || exit 1; \
	docker push $(MYXP_BACK_IMAGE):latest || exit 1; \
	echo "✅ Push completado: $$IMAGE_TAG"

.PHONY: push-myxp-front
push-myxp-front: ecr-login
	$(call print_section,📤 PUSHING MYXPERIENCES FRONTEND)
	@IMAGE_TAG=$$(git -C $(MYXP_FRONT_DIR) rev-parse --short HEAD 2>/dev/null || echo "manual"); \
	echo "📤 Pushing: $(MYXP_FRONT_IMAGE):$$IMAGE_TAG"; \
	docker push $(MYXP_FRONT_IMAGE):$$IMAGE_TAG || exit 1; \
	docker push $(MYXP_FRONT_IMAGE):latest || exit 1; \
	echo "✅ Push completado: $$IMAGE_TAG"

# ============ UPDATE TARGETS (Solo actualizar servicios ECS) ============
.PHONY: update-admin-back
update-admin-back:
	$(call print_section,🚀 UPDATING ADMIN BACKEND SERVICE)
	@cd ecs-admin && bash update-admin-backend.sh || exit 1

.PHONY: update-admin-front
update-admin-front:
	$(call print_section,🚀 UPDATING ADMIN FRONTEND SERVICE)
	@cd ecs-admin && bash update-admin-frontend.sh || exit 1

.PHONY: update-myxp-back
update-myxp-back:
	$(call print_section,🚀 UPDATING MYXPERIENCES BACKEND SERVICE)
	@bash update-env-tag.sh ecs-myxperiences/.env_myxperiences_backend $(MYXP_BACK_DIR) || exit 1
	@cd ecs-myxperiences && bash update-myxperiences-backend.sh || exit 1

.PHONY: update-myxp-front
update-myxp-front:
	$(call print_section,🚀 UPDATING MYXPERIENCES FRONTEND SERVICE)
	@bash update-env-tag.sh ecs-myxperiences/.env_myxperiences_frontend $(MYXP_FRONT_DIR) || exit 1
	@cd ecs-myxperiences && bash update-myxperiences-frontend.sh || exit 1

# ============ DEPLOY TARGETS (Build + Push + Update) ============
.PHONY: deploy-admin-back
deploy-admin-back: build-admin-back push-admin-back update-admin-back
	$(call print_section,✅ ADMIN BACKEND DEPLOYMENT COMPLETE)
	@echo "🌐 Service: mexp-admin-back-service"
	@echo "🔗 URL: https://admin-api.myxperiences.org"

.PHONY: deploy-admin-front
deploy-admin-front: build-admin-front push-admin-front update-admin-front
	$(call print_section,✅ ADMIN FRONTEND DEPLOYMENT COMPLETE)
	@echo "🌐 Service: mexp-admin-front-service"
	@echo "🔗 URL: https://admin.myxperiences.org"

.PHONY: deploy-myxp-back
deploy-myxp-back: build-myxp-back push-myxp-back update-myxp-back
	$(call print_section,✅ MYXPERIENCES BACKEND DEPLOYMENT COMPLETE)
	@echo "🌐 Service: mexp-lanapp-back-service"

.PHONY: deploy-myxp-front
deploy-myxp-front: build-myxp-front push-myxp-front update-myxp-front
	$(call print_section,✅ MYXPERIENCES FRONTEND DEPLOYMENT COMPLETE)
	@echo "🌐 Service: mexp-lanapp-front-service"
	@echo "🔗 URL: https://lanapp.myxperiences.org"

.PHONY: deploy-all-admin
deploy-all-admin: deploy-admin-back deploy-admin-front
	$(call print_section,✅ TODOS LOS SERVICIOS ADMIN DESPLEGADOS)

.PHONY: deploy-all-myxp
deploy-all-myxp: deploy-myxp-back deploy-myxp-front
	$(call print_section,✅ TODOS LOS SERVICIOS MYXPERIENCES DESPLEGADOS)

.PHONY: deploy-all
deploy-all: deploy-all-admin deploy-all-myxp
	$(call print_section,✅✅ DESPLIEGUE COMPLETO EXITOSO)
	@echo "🎉 Todos los servicios han sido actualizados en AWS ECS"

# ============ AWS TARGETS ============
.PHONY: ecr-login
ecr-login:
	@echo "🔐 Autenticando con AWS ECR..."
	@aws ecr get-login-password --region $(AWS_REGION) | \
	  docker login --username AWS --password-stdin $(ECR_REGISTRY) || exit 1
	@echo "✅ Autenticación exitosa en ECR"

.PHONY: ecr-logout
ecr-logout:
	@docker logout $(ECR_REGISTRY)
	@echo "✅ Desconexión de ECR completada"

# ============ UTILITY TARGETS ============
.PHONY: show-tags
show-tags:
	$(call print_section,📋 TAGS DE LAS IMÁGENES)
	@echo "Admin Backend:        $$(git -C $(ADMIN_BACK_DIR) rev-parse --short HEAD 2>/dev/null || echo 'N/A')"
	@echo "Admin Frontend:       $$(git -C $(ADMIN_FRONT_DIR) rev-parse --short HEAD 2>/dev/null || echo 'N/A')"
	@echo "MyXperiences Backend: $$(git -C $(MYXP_BACK_DIR) rev-parse --short HEAD 2>/dev/null || echo 'N/A')"
	@echo "MyXperiences Frontend:$$(git -C $(MYXP_FRONT_DIR) rev-parse --short HEAD 2>/dev/null || echo 'N/A')"

.PHONY: clean
clean:
	$(call print_section,🧹 LIMPIANDO IMÁGENES DOCKER)
	@docker rmi $(ADMIN_BACK_IMAGE):latest || true
	@docker rmi $(ADMIN_FRONT_IMAGE):latest || true
	@docker rmi $(MYXP_BACK_IMAGE):latest || true
	@docker rmi $(MYXP_FRONT_IMAGE):latest || true
	@echo "✅ Limpieza completada"

.PHONY: prune
prune: clean
	@docker system prune -f
	@echo "✅ Docker prune completado"

# ============ INFO ============
.PHONY: info
info:
	$(call print_section,ℹ️ INFORMACIÓN DE CONFIGURACIÓN)
	@echo "AWS Account:     $(AWS_ACCOUNT_ID)"
	@echo "AWS Region:      $(AWS_REGION)"
	@echo "ECR Registry:    $(ECR_REGISTRY)"
	@echo ""
	@echo "Admin Backend Image:     $(ADMIN_BACK_IMAGE)"
	@echo "Admin Frontend Image:    $(ADMIN_FRONT_IMAGE)"
	@echo "MyXp Backend Image:      $(MYXP_BACK_IMAGE)"
	@echo "MyXp Frontend Image:     $(MYXP_FRONT_IMAGE)"

.DEFAULT_GOAL := help
