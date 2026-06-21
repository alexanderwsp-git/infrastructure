# Lanapp ECS deployment

Automates build, ECR push, and ECS rollout for **lanapp** (API + UI).

## Prerequisites

- Docker with `buildx`
- AWS CLI authenticated (`aws configure` or env vars)
- `jq` installed
- Monorepo [`webapp`](../../webapp) checked out at `../../webapp` (override with `WEBAPP_DIR=...`)

## First-time setup

```bash
cd webapp-infra/ecs-lanapp
cp .env_backend.example .env_backend
cp .env_frontend.example .env_frontend
```

Fill in real values (Terraform outputs for Cognito, RDS URL for backend).  
`IMAGE_TAG` is updated automatically by `make`; the initial value is ignored.

## Deploy

```bash
make deploy          # backend, then frontend (build + push + ECS)
make deploy-back     # API only
make deploy-front    # UI only
```

Image tag defaults to the first **7 characters** of `git rev-parse HEAD` in the webapp repo (same as `webapp/scripts/build-lanapp-*.sh`).

Override tag explicitly:

```bash
make deploy-front IMAGE_TAG=abc1234
```

## ECS-only update (image already in ECR)

```bash
make update-back
make update-front
make update-all
```

These run `set-image-tag.sh` to sync `IMAGE_TAG` in `.env_*`, then `update-*.sh`.

## Build without ECS rollout

```bash
make build-all
make build-back
make build-front
```

## Bootstrap (new ECS services)

```bash
make create-back
make create-front
```

## Utilities

```bash
make help
make show-tags
make info
```

## Files

| File | Purpose |
|------|---------|
| `Makefile` | Orchestrates build, tag sync, ECS update |
| `set-image-tag.sh` | Writes `IMAGE_TAG=` in `.env_backend` / `.env_frontend` |
| `.env_backend` | Runtime env for API task (local, gitignored) |
| `.env_frontend` | Runtime env for UI task (local, gitignored) |
| `lanapp-*-task-definition.json` | ECS task templates |
| `deploy-flags.sh` | Rolling deploy: 2 tasks, circuit breaker, grace period |
| `update-*.sh` / `create-*.sh` | Register task definition + create/update service |

See also [`webapp/lanapp-ui/docs/DEPLOY_ECS.md`](../../webapp/lanapp-ui/docs/DEPLOY_ECS.md) for infrastructure details and verification.
