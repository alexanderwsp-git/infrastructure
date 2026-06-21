# =================================================================
# Lanapp ECS — build, push, and deploy
# =================================================================
# Usage (from this directory):
#   make deploy          # backend + frontend (build + push + ECS update)
#   make deploy-front    # UI only
#   make update-back     # ECS only (image already in ECR)
#   make deploy-front IMAGE_TAG=abc1234
# =================================================================

AWS_ACCOUNT_ID ?= 991795763909
AWS_REGION ?= us-east-1
ECR_REGISTRY ?= $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com

WEBAPP_DIR ?= ../../webapp
LANAPP_SERVICE_URL ?= https://lanapp-api.myxperiences.org

FRONT_REPO := mexp-lanapp-front
BACK_REPO := mexp-lanapp-back
FRONT_IMAGE := $(ECR_REGISTRY)/$(FRONT_REPO)
BACK_IMAGE := $(ECR_REGISTRY)/$(BACK_REPO)

CLUSTER := mexp-apps-shared-cluster
FRONT_SERVICE := mexp-lanapp-front-service
BACK_SERVICE := mexp-lanapp-back-service

IMAGE_TAG ?=

define print_section
	@echo ""
	@echo "==================================================================="
	@echo "  $(1)"
	@echo "==================================================================="
endef

.PHONY: help info show-tags \
	build-front build-back build-all \
	set-tag-front set-tag-back \
	update-front update-back update-all \
	deploy-front deploy-back deploy deploy-all \
	create-front create-back

.DEFAULT_GOAL := help

help:
	@echo "Lanapp ECS deployment"
	@echo ""
	@echo "Deploy (build + push + ECS):"
	@echo "  make deploy          Backend then frontend"
	@echo "  make deploy-back     API only"
	@echo "  make deploy-front    UI only"
	@echo ""
	@echo "Build + push (ECR):"
	@echo "  make build-all       Both images"
	@echo "  make build-back      API image"
	@echo "  make build-front     UI image"
	@echo ""
	@echo "ECS update (image already in ECR):"
	@echo "  make update-all      Both services"
	@echo "  make update-back     API service"
	@echo "  make update-front    UI service"
	@echo "  make set-tag-back    Sync IMAGE_TAG in .env_backend from git"
	@echo "  make set-tag-front   Sync IMAGE_TAG in .env_frontend from git"
	@echo ""
	@echo "Bootstrap (first-time service creation):"
	@echo "  make create-back"
	@echo "  make create-front"
	@echo ""
	@echo "Utilities:"
	@echo "  make show-tags       Git short tag (7 chars) for webapp repo"
	@echo "  make info            ECR repos, cluster, services"
	@echo ""
	@echo "Variables:"
	@echo "  WEBAPP_DIR=$(WEBAPP_DIR)"
	@echo "  IMAGE_TAG=$(if $(IMAGE_TAG),$(IMAGE_TAG),(from git rev-parse --short=7))"
	@echo "  LANAPP_SERVICE_URL=$(LANAPP_SERVICE_URL)"

info:
	$(call print_section,CONFIG)
	@echo "AWS Account:  $(AWS_ACCOUNT_ID)"
	@echo "AWS Region:   $(AWS_REGION)"
	@echo "ECR Registry: $(ECR_REGISTRY)"
	@echo "Webapp dir:   $(WEBAPP_DIR)"
	@echo ""
	@echo "Front image:  $(FRONT_IMAGE)"
	@echo "Back image:   $(BACK_IMAGE)"
	@echo "Cluster:      $(CLUSTER)"
	@echo "Front svc:    $(FRONT_SERVICE)"
	@echo "Back svc:     $(BACK_SERVICE)"

show-tags:
	$(call print_section,GIT IMAGE TAG)
	@echo "Webapp: $$(git -C $(WEBAPP_DIR) rev-parse --short=7 HEAD 2>/dev/null || echo N/A)"

# ============ BUILD (buildx + push to ECR) ============

build-front:
	$(call print_section,BUILD FRONTEND)
	@set -a && . ./.env_frontend && set +a; \
	if [ -n "$(IMAGE_TAG)" ]; then \
	  bash "$(WEBAPP_DIR)/scripts/build-lanapp-ui-image.sh" "$(IMAGE_TAG)"; \
	else \
	  bash "$(WEBAPP_DIR)/scripts/build-lanapp-ui-image.sh"; \
	fi

build-back:
	$(call print_section,BUILD BACKEND)
	@if [ -n "$(IMAGE_TAG)" ]; then \
	  bash "$(WEBAPP_DIR)/scripts/build-lanapp-image.sh" "$(IMAGE_TAG)"; \
	else \
	  bash "$(WEBAPP_DIR)/scripts/build-lanapp-image.sh"; \
	fi

build-all: build-back build-front
	$(call print_section,BUILD COMPLETE)

# ============ IMAGE TAG IN .env ============

set-tag-front:
	@bash set-image-tag.sh .env_frontend "$(WEBAPP_DIR)" "$(IMAGE_TAG)"

set-tag-back:
	@bash set-image-tag.sh .env_backend "$(WEBAPP_DIR)" "$(IMAGE_TAG)"

# ============ ECS UPDATE ============

update-front: set-tag-front
	$(call print_section,UPDATE FRONTEND SERVICE)
	@bash update-frontend.sh

update-back: set-tag-back
	$(call print_section,UPDATE BACKEND SERVICE)
	@bash update-backend.sh

update-all: update-back update-front
	$(call print_section,ECS UPDATE COMPLETE)

# ============ DEPLOY (build + push + ECS) ============

deploy-front: build-front update-front
	$(call print_section,FRONTEND DEPLOYMENT COMPLETE)
	@echo "Service: $(FRONT_SERVICE)"
	@echo "URL:     https://lanapp.myxperiences.org"

deploy-back: build-back update-back
	$(call print_section,BACKEND DEPLOYMENT COMPLETE)
	@echo "Service: $(BACK_SERVICE)"
	@echo "URL:     https://lanapp-api.myxperiences.org"

deploy deploy-all: deploy-back deploy-front
	$(call print_section,LANAPP DEPLOYMENT COMPLETE)
	@echo "Backend:  https://lanapp-api.myxperiences.org"
	@echo "Frontend: https://lanapp.myxperiences.org"

# ============ BOOTSTRAP ============

create-front: set-tag-front
	$(call print_section,CREATE FRONTEND SERVICE)
	@bash create-frontend.sh

create-back: set-tag-back
	$(call print_section,CREATE BACKEND SERVICE)
	@bash create-backend.sh
