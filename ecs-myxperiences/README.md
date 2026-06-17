# myxperiences ECS Deployment Configuration

## Domain Configuration

- **Frontend**: https://myxperiences.org
- **Backend API**: https://api.myxperiences.org

## Important Notes

### Database Configuration

- **Database Type**: PostgreSQL
- **Port**: 5432 (default PostgreSQL port)
- **Dialect**: `postgres` in Sequelize configuration
- **Shared Database**: Uses the same RDS instance as admin (`admindb`)
- **Schema**: `myxperiences` (isolated schema for data separation)
- The code uses `POSTGRES_*` environment variable names

### Application Ports

- **Backend**: Port 4000
- **Frontend**: Port 3000

### Health Checks

- **Backend**: `/api/healthCheck/health` on port 4000
- **Frontend**: `/` on port 3000

### DNS Migration

The current Route53 shows `myxperiences.org` pointing to an old ALB (`xperiences-alb-1000147957`). After applying Terraform, the DNS records will automatically update to point to the new shared ALB (`mexp-shared-apps-alb`).

**No manual DNS changes needed** - Terraform will handle the migration.

## Environment Files

### Backend (.env_myxperiences_backend)

Copy the template and fill with production values:

```bash
cp .env_myxperiences_backend.template .env_myxperiences_backend
```

Required variables:

- Database: `POSTGRES_HOST`, `POSGRET_DB`, `POSGRET_USER`, `POSTGRES_PASSWORD`, `POSTGRES_PORT` (5432), `POSTGRES_SCHEMA` (myxperiences)
- **Important**: Uses same RDS as admin but with schema `myxperiences` for data isolation
- JWT: `SECRET_JWT_SEED`
- Email: `MAILER_*`
- AWS S3: `AWS_BUCKET_NAME`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`
- Domain: `DOMINIO_EXPERIENCES=https://myxperiences.org`
- **Backend Admin Integration**: `BACKEND_ADMIN_URL=https://admin.myxperiences.org/api`, `INTERNAL_API_KEY` (for syncing seasons, clients, payments, userDestinations)
- Production flags: `PROD=true`, `SYNCALTER=true`, `SYNCFORCE=false`

### Frontend (.env_myxperiences_frontend)

Copy the template and fill with production values:

```bash
cp .env_myxperiences_frontend.template .env_myxperiences_frontend
```

Required variables:

- `VITE_API_SERVICE=https://api.myxperiences.org` (backend API URL)

## Deployment Steps

### 1. Build and push Docker images

The build scripts automatically tag images with the git commit hash (first 7 characters).

#### Backend

```bash
cd ../scripts/myxperiences
./build-myxperiences-backend-image.sh
# Optional: specify a custom tag
./build-myxperiences-backend-image.sh v1.0.0
```

The script will output the IMAGE_TAG (e.g., `a1b2c3d`). **Update this tag** in your `.env_myxperiences_backend` file:

```bash
IMAGE_TAG=a1b2c3d  # Use the tag from the build output
```

#### Frontend

```bash
cd ../scripts/myxperiences
./build-myxperiences-frontend-image.sh
# Optional: specify a custom tag
./build-myxperiences-frontend-image.sh v1.0.0
```

The script will output the IMAGE_TAG. **Update this tag** in your `.env_myxperiences_frontend` file:

```bash
IMAGE_TAG=a1b2c3d  # Use the tag from the build output
```

### 2. Deploy to ECS (first time)

```bash
cd ../../ecs-myxperiences
./create-myxperiences-backend.sh
./create-myxperiences-frontend.sh
```

### 3. Update existing services

```bash
cd ../../ecs-myxperiences
./update-myxperiences-backend.sh
./update-myxperiences-frontend.sh
```

## Verification

After deployment, verify:

```bash
# Check service status
aws ecs describe-services \
  --cluster mexp-apps-shared-cluster \
  --services mexp-myxperiences-back-service mexp-myxperiences-front-service \
  --region us-east-1

# Check target health
aws elbv2 describe-target-health \
  --target-group-arn $(aws elbv2 describe-target-groups --names mexp-myxperiences-back-tg --query 'TargetGroups[0].TargetGroupArn' --output text) \
  --region us-east-1

# View logs
aws logs tail /ecs/mexp-myxperiences-back --follow --region us-east-1
aws logs tail /ecs/mexp-myxperiences-front --follow --region us-east-1
```

## Architecture

```
Internet
   ↓
Route53 DNS
   ├─→ myxperiences.org → ALB (shared)
   └─→ api.myxperiences.org → ALB (shared)
         ↓
Application Load Balancer (mexp-shared-apps-alb)
   ├─→ Target Group (mexp-myxperiences-front-tg:3000) → ECS Frontend
   └─→ Target Group (mexp-myxperiences-back-tg:4000) → ECS Backend
                                                           ↓
                                                      PostgreSQL RDS
                                                      S3 Bucket
```

## Troubleshooting

### Database Connection Issues

- Verify RDS endpoint is correct in `.env_myxperiences_backend`
- Ensure `POSTGRES_PORT=5432` (PostgreSQL port)
- Check `PROD=true` to enable SSL connection
- Verify security groups allow traffic from ECS to RDS

### VITE Variables Not Applied

- VITE variables must be set **at build time**, not runtime
- Rebuild the Docker image with updated variables
- Push new image and redeploy

### Health Check Failures

- Backend: Verify `/api/healthCheck/health` returns 200
- Frontend: Verify root path `/` returns 2xx/3xx status
- Check container logs for startup errors

### DNS Not Resolving

- Wait 5-10 minutes for DNS propagation after Terraform apply
- Clear local DNS cache: `ipconfig /flushdns` (Windows) or `sudo systemd-resolve --flush-caches` (Linux)
- Verify Route53 records point to correct ALB
