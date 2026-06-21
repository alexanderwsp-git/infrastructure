# Shared ECS deployment settings for lanapp front/back services.
# Override via env: ECS_DESIRED_COUNT, ECS_HEALTH_CHECK_GRACE_PERIOD

ECS_DESIRED_COUNT="${ECS_DESIRED_COUNT:-2}"
ECS_HEALTH_CHECK_GRACE_PERIOD="${ECS_HEALTH_CHECK_GRACE_PERIOD:-120}"
ECS_DEPLOYMENT_CONFIGURATION="minimumHealthyPercent=100,maximumPercent=200,deploymentCircuitBreaker={enable=true,rollback=true}"
