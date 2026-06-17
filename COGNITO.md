# Shared Myxperiences Cognito — Terraform + ECS env

## Architecture

- **One User Pool** (`mexp-myxperiences-users`) for the whole suite
- **Three app clients**: `lanapp`, `admin`, `myxperiences` (each product uses its own client ID + secret)
- **Groups** per app: `lanapp_admin`, `lanapp_veterinario`, `lanapp_operario`, `admin_admin`, `myxperiences_user`, etc.
- **Lanapp auth BFF** runs inside `lanapp-ui` (Next.js `/api/auth/*`), not a separate service

## 1. Apply Terraform

```bash
cd webapp-infra/infra
terraform plan
terraform apply
```

Outputs:

```bash
terraform output cognito_user_pool_id
terraform output cognito_client_ids
terraform output -json cognito_client_secrets  # sensitive
```

## 2. Bootstrap first admin

```bash
POOL_ID=$(terraform output -raw cognito_user_pool_id)
aws cognito-idp admin-create-user \
  --user-pool-id "$POOL_ID" \
  --username "you@yourfarm.com" \
  --user-attributes Name=email,Value=you@yourfarm.com Name=email_verified,Value=true \
  --desired-delivery-mediums EMAIL

aws cognito-idp admin-add-user-to-group \
  --user-pool-id "$POOL_ID" \
  --username "you@yourfarm.com" \
  --group-name lanapp_admin
```

## 3. ECS env — lanapp front (`ecs/.env_frontend`)

```
IMAGE_TAG=...
PORT=3000
NODE_ENV=production
HOSTNAME=0.0.0.0
AWS_REGION=us-east-1
COGNITO_USER_POOL_ID=<from terraform>
COGNITO_CLIENT_ID=<cognito_client_ids.lanapp>
COGNITO_CLIENT_SECRET=<cognito_client_secrets.lanapp>
```

## 4. ECS env — lanapp API (`ecs/.env_backend`)

When auth is live in production:

```
SKIP_AUTH=false
COGNITO_USER_POOL_ID=<same pool>
COGNITO_CLIENT_ID=<lanapp client id>
```

## 5. Deploy

```bash
cd webapp && ./scripts/build-lanapp-ui-image.sh
cd webapp-infra/ecs && ./update-frontend.sh

cd webapp && ./scripts/build-lanapp-image.sh
cd webapp-infra/ecs && ./update-backend.sh
```

## Local dev

Keep `SKIP_AUTH=true` in `lanapp/.env` and `NEXT_PUBLIC_SKIP_AUTH=true` in `lanapp-ui/.env`.

## Cost

Under 10,000 MAU/month on Cognito Lite: **$0**.
