# Infraestructura MyXperiences

Esta guía resume la infraestructura declarada y los procedimientos de despliegue que aparecen en esta carpeta. Se basa únicamente en los archivos versionados o presentes bajo `infrastructure`. No se consultó el estado real de AWS y no se ejecutaron comandos de Terraform ni de despliegue.

> **Advertencia sobre credenciales:** los archivos locales de variables, entorno y definiciones de tareas pueden contener credenciales. No los copies a tickets, chats o repositorios. Si algún secreto se expuso fuera de su canal autorizado, rótalo. El estado de Terraform también puede contener valores sensibles aunque una variable o salida esté marcada como `sensitive`.

## Arquitectura general

La infraestructura combina recursos compartidos con despliegues separados para MyXperiences, Admin y Lanapp:

```text
Usuarios
   |
Route 53 (dominio raíz y subdominios)
   |
ALB compartido (HTTP redirige a HTTPS; certificado ACM)
   |                         |
   +-- host de frontend -----+--> target group frontend --> ECS/Fargate
   +-- host de API ----------+--> target group backend  --> ECS/Fargate
                                                             |       |
                                                             |       +--> S3
                                                             +----------> PostgreSQL RDS

ECR almacena imágenes de contenedor
CloudWatch Logs recibe los logs de las tareas
IAM define roles y permisos para tareas y servicios
SES y Route 53 configuran correo y DNS del dominio
```

El ALB, VPC, subredes, security groups, target groups, ECR, buckets, clúster ECS, IAM, grupos de logs, RDS, Cognito, DNS y certificados se declaran en Terraform. Los scripts de `ecs-myxperiences/` registran task definitions y crean o actualizan los servicios MyXperiences en ECS; no encontré definiciones Terraform de esos servicios ECS.

## Componentes de MyXperiences

### Frontend

- La imagen del frontend se construye desde el proyecto frontend y se publica en ECR.
- El contenedor sirve la aplicación en el puerto `3000`; el target group del ALB también escucha en ese puerto.
- El task definition incluye `VITE_API_SERVICE`. El script de build del frontend recibe ese valor como argumento de Docker, de modo que la URL de API se incorpora al bundle durante el build. Cambiar únicamente la variable de entorno de una tarea en ejecución no recompone el bundle.
- El target group comprueba la ruta raíz `/`.

### Backend

- La imagen del backend se construye desde el proyecto backend y se publica en ECR.
- El contenedor y su target group usan el puerto `4000`.
- El target group configura un health check en `/api/healthCheck/health`.
- El task role declarado en Terraform da a la tarea del backend permisos sobre el bucket S3 de MyXperiences.
- El task definition suministra configuración al contenedor, incluyendo base de datos, JWT, correo, AWS, Google Sheets, Stripe, integraciones internas y webhook. Los nombres de esas variables aparecen en la sección de configuración.

### Red y acceso

- Terraform declara una VPC con dos subredes públicas y un internet gateway.
- El ALB permite HTTP/HTTPS desde Internet; HTTP se redirige a HTTPS.
- Los security groups de contenedores permiten el tráfico de los puertos de aplicación desde el security group del ALB.
- El security group de base de datos permite PostgreSQL desde ECS y desde direcciones IPv4 específicas declaradas en Terraform. No se detallan aquí esas direcciones.
- Los scripts de creación de servicios ECS configuran Fargate, una tarea deseada y `assignPublicIp=ENABLED`.

Revisa cuidadosamente cambios de red y exposición pública antes de proponerlos: las subredes, security groups, ALB y acceso a RDS son compartidos o afectan a más de una aplicación.

## Base de datos y respaldos

`iac/src/v1/4_databases.tf` declara un subnet group y tres instancias RDS PostgreSQL asociadas a las aplicaciones del entorno. Los recursos declaran `skip_final_snapshot = true`. El archivo no establece `backup_retention_period` ni declara snapshots manuales.

**Lo que se puede confirmar desde el repositorio:**

- Terraform administra instancias RDS, no solamente la configuración de conexión.
- No encontré una política explícita de retención de backups automáticos para RDS.
- No encontré scripts o comandos que creen un snapshot antes de desplegar, ni instrucciones de restauración.
- Al destruir una instancia declarada con `skip_final_snapshot = true`, Terraform no solicitaría crear un snapshot final.
- El backend S3 del estado Terraform tiene versionado y cifrado. Esto protege versiones del estado, no los datos de RDS.
- CloudWatch Logs tiene retención configurada de siete días en los grupos declarados. Esto es retención de logs, no respaldo de la base de datos.

No se puede inferir desde estos archivos cuál es la política de backup actualmente activa en AWS. Compruébala en AWS antes de cualquier operación sobre RDS y establece un procedimiento de respaldo/restauración aprobado.

Hay una discrepancia documental: `ecs-myxperiences/README.md` describe MyXperiences como compartiendo RDS con Admin, mientras que el Terraform actual declara recursos de base de datos separados para esas aplicaciones. Este repositorio no permite confirmar cuál describe el estado desplegado.

`ecs-myxperiences/init-schema.sql` crea el esquema de MyXperiences y concede permisos; no es un respaldo ni un procedimiento de restauración.

## Despliegue actual de MyXperiences

El flujo manual disponible es:

```text
build de imagen -> Docker/buildx -> push a ECR -> nueva revisión de task definition -> actualización ECS
```

### Construir y publicar imágenes

Desde la raíz de `infrastructure`, el `Makefile` ofrece:

| Target | Función declarada |
|---|---|
| `make build-myxp-back` | Construye la imagen local del backend MyXperiences. |
| `make build-myxp-front` | Construye la imagen local del frontend MyXperiences. |
| `make push-myxp-back` | Inicia sesión en ECR y publica la imagen del backend. |
| `make push-myxp-front` | Inicia sesión en ECR y publica la imagen del frontend. |
| `make build-all` | Construye las imágenes de Admin y MyXperiences. |

También existen scripts dedicados:

- `scripts/myxperiences/build-myxperiences-backend-image.sh`
- `scripts/myxperiences/build-myxperiences-frontend-image.sh`

Estos scripts usan Docker Buildx para la plataforma `linux/amd64`, se autentican en ECR con AWS CLI, construyen y publican la imagen. Aceptan un tag opcional; si no se proporciona, usan el hash corto del commit actual. El script de frontend exige `VITE_API_SERVICE` y lo pasa al build.

Los scripts incluyen rutas absolutas locales para encontrar los proyectos de aplicación, por lo que no son portables a otra máquina sin ajustes. No se deben tratar como comandos genéricos de Terraform.

### Actualizar servicios existentes

El `Makefile` ofrece:

| Target | Función declarada |
|---|---|
| `make update-myxp-back` | Actualiza el tag de imagen de backend y llama al script de actualización ECS correspondiente. |
| `make update-myxp-front` | Actualiza el tag de imagen de frontend y llama al script de actualización ECS correspondiente. |
| `make deploy-myxp-back` | Encadena build, push y actualización de backend. |
| `make deploy-myxp-front` | Encadena build, push y actualización de frontend. |
| `make deploy-all-myxp` | Ejecuta el despliegue de backend y frontend. |

Los scripts `ecs-myxperiences/update-myxperiences-backend.sh` y `update-myxperiences-frontend.sh`:

1. Copian la task definition plantilla a un archivo de salida renderizado.
2. Cargan el archivo local de entorno correspondiente y sustituyen marcadores de variables.
3. Validan el JSON generado.
4. Registran una nueva revisión de task definition en ECS.
5. Llaman a `aws ecs update-service` con `--force-new-deployment`.

La actualización fuerza el redespliegue del servicio; no modifica por sí misma el código fuente. El script de frontend también incluye variables de runtime, pero `VITE_API_SERVICE` debe tener el valor correcto durante el build para cambiar la API incluida en el bundle.

### Crear servicios por primera vez

`ecs-myxperiences/create-myxperiences-backend.sh` y `create-myxperiences-frontend.sh` son scripts de creación inicial. Consultan identificadores de red/target group en AWS, registran la task definition y crean el servicio ECS. No son los scripts de actualización normal y no deben repetirse sobre un servicio existente sin verificar el estado y el efecto esperado.

### Otros targets

El `Makefile` también define `help`, `info`, `show-tags`, targets de Admin, `ecr-login`, `ecr-logout`, `clean` y `prune`.

- `clean` elimina imágenes Docker locales relacionadas con los nombres definidos por el Makefile.
- `prune` depende de `clean` y ejecuta `docker system prune`; esto puede borrar otros recursos Docker locales que Docker considere no utilizados. No afecta AWS por sí mismo, pero sí puede eliminar datos/cachés locales; inspecciona el comando antes de usarlo.
- `deploy-all` incluye los despliegues declarados para Admin y MyXperiences. No lo uses si tu intención es actualizar solo MyXperiences.

No ejecuté ninguno de estos targets o scripts.

## Terraform

### Organización

| Ruta | Alcance |
|---|---|
| `iac/bootstrap/` | Declara bucket S3 para estado remoto, versionado, cifrado, bloqueo de acceso público y tabla DynamoDB para locks. |
| `iac/src/v1/` | Stack compartido de red, routing/TLS, compute/storage, bases de datos y Cognito; contiene variables y outputs. |
| `iac/domain/v1/` | Recursos DNS/correo SES y certificado ACM en una configuración separada. |
| `iac/terraform.tfvars` | Archivo local de valores Terraform; está excluido de Git por el `.gitignore`. No compartas ni imprimas su contenido. |

El backend remoto del stack principal está configurado en `iac/src/v1/providers.tf` con S3, cifrado y una tabla DynamoDB para locks. Bootstrap declara el bucket con versionado y cifrado. Terraform debe tener acceso autorizado a esos recursos y al provider AWS.

Los archivos principales de `iac/src/v1/` son:

- `1_network.tf`: VPC, subredes, gateway, rutas y security groups.
- `2_routing_ssl.tf`: certificado, ALB, listeners, reglas por host y DNS.
- `3_compute_storage.tf`: target groups, ECR, buckets S3, clúster ECS, logs e IAM.
- `4_databases.tf`: subnet group e instancias RDS.
- `5_cognito.tf`: user pool, cliente, grupos y permisos asociados.
- `providers.tf`, `variables.tf`, `outputs.tf`: backend/proveedores, entradas y salidas.

`iac/domain/v1/main.tf` declara DNS/SES, usuario SMTP IAM y certificado ACM. No se verificó que todas las variables declaradas en `iac/domain/v1/variables.tf` se usen en los recursos actuales.

### Versiones de Terraform providers

- Las configuraciones Terraform declaran Terraform `>= 1.0.0`.
- El stack principal requiere AWS provider `>= 5.83.0` y PostgreSQL provider `~> 1.22.0`.
- Bootstrap requiere AWS provider `~> 5.0`.

No se encontró una versión exacta de Terraform fijada para todo el repositorio.

### Cambios de impacto elevado

Un cambio aplicado en Terraform puede afectar directamente recursos existentes. Revisa el plan y el estado antes de cualquier aplicación, en especial si el cambio toca:

- VPC, subredes, tablas de rutas, security groups o conexiones ECS/RDS.
- ALB, listeners, reglas host-based, target groups, certificados o DNS.
- Instancias RDS, su subnet group, nombre de base de datos o credenciales.
- Repositorios ECR, buckets S3, clúster ECS, IAM o Cognito.
- SES, registros de verificación de dominio o credenciales SMTP.

Las tres declaraciones de buckets de aplicaciones tienen `force_destroy = true`: una destrucción de esos recursos puede borrar objetos del bucket. Las instancias RDS tienen `skip_final_snapshot = true`: no hay snapshot final solicitado en una destrucción. En los certificados hay `create_before_destroy`, pero esto no elimina el riesgo de afectar certificados, DNS o tráfico durante cambios.

No hay en este repositorio un procedimiento de aprobación de planes, política de cambios, ni comando documentado que garantice preservar datos. No ejecutes `terraform apply` o `terraform destroy` sin revisión explícita del plan, confirmación de backups y autorización operativa.

## Variables y secretos

Esta sección enumera nombres vistos en variables Terraform, task definitions y scripts; no contiene valores. Distingue entradas declaradas de variables que los scripts realmente sustituyen.

### Terraform: stack principal `iac/src/v1`

Variables declaradas:

- Configuración: `aws_region`, `domain_name`, `hosted_zone_id`, `tags_base`.
- Usuarios y passwords de DB: `db_user_myxperiences`, `db_user_lanapp`, `db_user_admin`, `db_password_myxperiences`, `db_password_lanapp`, `db_password_admin`.
- Conexión declarada para Lanapp: `lanapp_db_url`.

### Terraform: configuración de dominio `iac/domain/v1`

Variables declaradas:

- `db_nonprod_host`, `username_nonprod`, `password_nonprod`, `username_prod`, `password_prod`.
- `backend_image`, `backend_port`, `posgret_db`, `secret_jwt_seed`.
- `cloud_name`, `api_key`, `api_secret`.
- `mailer_host`, `mailer_port`, `mailer_user`, `mailer_pass`.

Estas son variables declaradas; no se afirma que todas se usen en el despliegue Terraform actual.

### Task definition del backend MyXperiences

Variables que el script de actualización sustituye:

`IMAGE_TAG`, `PORT`, `NODE_ENV`, `POSTGRES_PORT`, `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_HOST`, `POSTGRES_SCHEMA`, `SECRET_JWT_SEED`, `MAILER_HOST`, `MAILER_PORT`, `MAILER_USER`, `MAILER_PASS`, `MAILER_FRONT`, `MAIL_PAYMENT_INSCRIPTION`, `MAIL_PAYMENT_DESTINATION`, `MAIL_PAYMENT_GENERAL`, `DOMINIO_EXPERIENCES`, `AWS_BUCKET_NAME`, `AWS_BUCKET_REGION`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `PROD`, `SYNCALTER`, `BACKEND_ADMIN_URL`, `INTERNAL_API_KEY`, `GOOGLE_SHEET_ID`, `GOOGLE_SERVICE_ACCOUNT_EMAIL`, `GOOGLE_PRIVATE_KEY`, `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, `GOOGLE_DESTINATIONS_SHEET_ID`, `DESTINATIONS_SYNC_API_KEY` y `WEBHOOK_URL`.

Los passwords, tokens, claves, credenciales de servicio y URLs internas deben tratarse como secretos o datos sensibles. Los archivos de entorno viven localmente junto a los scripts ECS y están ignorados por Git. El script los carga y sustituye en una task definition renderizada; por ello el archivo generado también debe protegerse y no compartirse.

### Task definition del frontend MyXperiences

`IMAGE_TAG`, `PORT`, `NODE_ENV`, `HOSTNAME` y `VITE_API_SERVICE`. `VITE_API_SERVICE` no es un secreto, pero queda incluido en el bundle al construir el frontend.

El Makefile define además configuración local de publicación y nombres de repositorios/imágenes para las distintas aplicaciones; los scripts de build MyXperiences admiten `AWS_REGION` y `AWS_ACCOUNT_ID`. Se omiten aquí los valores configurados.

## CI/CD, rollback y recuperación

### CI/CD

No encontré workflows de GitHub Actions en `infrastructure`. El procedimiento MyXperiences identificado es manual, mediante Makefile y scripts Bash/AWS CLI. No se confirmó otro sistema externo de CI/CD.

### Rollback

No encontré un mecanismo de rollback documentado ni un script que seleccione una task definition o imagen anterior. Los scripts de actualización registran revisiones nuevas de task definition y actualizan el servicio; los tags de imagen se conservan en la configuración local de despliegue, pero el repositorio no documenta retención ECR ni una operación de rollback verificada.

Por eso, esta guía no prescribe un comando de reversión. Antes de desplegar, el equipo responsable debe confirmar en AWS qué imagen y revisión están activas y acordar un procedimiento de rollback compatible con sus políticas.

### Recuperación de RDS

No hay respaldo manual ni restauración documentados en estos archivos. No se puede dar por hecho que un backup automático esté habilitado ni que exista snapshot utilizable. Verifica la configuración real de RDS y prueba el procedimiento de recuperación por un canal operativo autorizado antes de cambios que puedan afectar datos.

## Discrepancias y límites de este documento

- El README de ECS describe una base MyXperiences compartida con Admin; `iac/src/v1/4_databases.tf` declara instancias separadas. No se consultó AWS para establecer cuál refleja el despliegue vigente.
- El README de ECS menciona plantillas de entorno; no se encontraron archivos `.template` correspondientes dentro de `ecs-myxperiences`.
- Los scripts de build usan rutas absolutas locales y requieren adaptarse para otras máquinas.
- No se verificaron estado, backups, DNS, reglas de red, servicios activos, tags/imágenes presentes ni parámetros efectivos en AWS.
- Los scripts, task definitions y archivos `.tfvars` pueden variar localmente y estar ignorados por Git. Este documento no valida su contenido local.

## Archivos de referencia

- Terraform: `iac/bootstrap/`, `iac/src/v1/`, `iac/domain/v1/`.
- Comandos Make: `Makefile`.
- Guía ECS existente: `ecs-myxperiences/README.md`.
- Build de imágenes: `scripts/myxperiences/`.
- Creación y actualización de servicios: `ecs-myxperiences/`.
- Inicialización de esquema: `ecs-myxperiences/init-schema.sql`.
