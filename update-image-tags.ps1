# =================================================================
# update-image-tags.ps1 - Script para actualizar IMAGE_TAG en .env files (PowerShell)
# =================================================================
# Uso (PowerShell):
#   .\update-image-tags.ps1                    # Actualiza todos
#   .\update-image-tags.ps1 -Type admin        # Solo Admin
#   .\update-image-tags.ps1 -Type admin-back   # Solo Admin Backend
# =================================================================

param(
    [Parameter(Position = 0)]
    [ValidateSet("all", "admin", "admin-back", "admin-front", "myxp", "myxp-back", "myxp-front", IgnoreCase = $true)]
    [string]$Type = "all"
)

# Colores
function Write-Green { Write-Host $args -ForegroundColor Green }
function Write-Red { Write-Host $args -ForegroundColor Red }
function Write-Yellow { Write-Host $args -ForegroundColor Yellow }
function Write-Blue { Write-Host $args -ForegroundColor Blue }

# Rutas
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$ADMIN_BACK_DIR = Join-Path $SCRIPT_DIR "..\Backend-Admin"
$ADMIN_FRONT_DIR = Join-Path $SCRIPT_DIR "..\Frontend-Admin"
$MYXP_BACK_DIR = Join-Path $SCRIPT_DIR "..\Prueba\backend"
$MYXP_FRONT_DIR = Join-Path $SCRIPT_DIR "..\Prueba\frontend"

Write-Blue "════════════════════════════════════════════════════════════"
Write-Blue "  📋 UPDATE IMAGE TAGS (PowerShell)"
Write-Blue "════════════════════════════════════════════════════════════"
Write-Host ""

# Función para obtener git short hash
function Get-GitHash {
    param([string]$RepoDir, [string]$Default = "manual")
    
    if (Test-Path "$RepoDir\.git") {
        $hash = & git -C $RepoDir rev-parse --short HEAD 2>$null
        if ($LASTEXITCODE -eq 0) {
            return $hash
        }
    }
    return $Default
}

# Función para actualizar IMAGE_TAG en archivo .env
function Update-ImageTag {
    param(
        [string]$EnvFile,
        [string]$NewTag,
        [string]$ServiceName
    )
    
    if (-not (Test-Path $EnvFile)) {
        Write-Red "❌ Archivo no encontrado: $EnvFile"
        return $false
    }
    
    # Obtener tag anterior
    $content = Get-Content $EnvFile
    $oldTag = ($content | Where-Object { $_ -match "^IMAGE_TAG=" } | 
        ForEach-Object { $_ -replace "^IMAGE_TAG=", "" }).Trim()
    
    if (-not $oldTag) {
        $oldTag = "N/A"
    }
    
    # Actualizar
    $content = $content -replace "^IMAGE_TAG=.*", "IMAGE_TAG=$NewTag"
    Set-Content -Path $EnvFile -Value $content -Encoding UTF8
    
    Write-Green "✅ $ServiceName"
    Write-Host "   📍 Archivo: $EnvFile"
    Write-Yellow "   Old Tag: $oldTag"
    Write-Green "   New Tag: $NewTag"
    Write-Host ""
    
    return $true
}

# Determinar qué servicios actualizar
$updateAdminBack = $false
$updateAdminFront = $false
$updateMyxpBack = $false
$updateMyxpFront = $false

switch ($Type.ToLower()) {
    "all" {
        $updateAdminBack = $true
        $updateAdminFront = $true
        $updateMyxpBack = $true
        $updateMyxpFront = $true
    }
    "admin" {
        $updateAdminBack = $true
        $updateAdminFront = $true
    }
    { $_ -in "admin-back", "admin-backend" } {
        $updateAdminBack = $true
    }
    { $_ -in "admin-front", "admin-frontend" } {
        $updateAdminFront = $true
    }
    { $_ -in "myxp", "myxperiences" } {
        $updateMyxpBack = $true
        $updateMyxpFront = $true
    }
    { $_ -in "myxp-back", "myxp-backend" } {
        $updateMyxpBack = $true
    }
    { $_ -in "myxp-front", "myxp-frontend" } {
        $updateMyxpFront = $true
    }
}

Write-Yellow "🔍 Obteniendo tags de git..."
Write-Host ""

# Admin Backend
if ($updateAdminBack) {
    $adminBackTag = Get-GitHash $ADMIN_BACK_DIR
    Update-ImageTag "$SCRIPT_DIR\ecs-admin\.env_admin_backend.template" $adminBackTag "Admin Backend"
}

# Admin Frontend
if ($updateAdminFront) {
    $adminFrontTag = Get-GitHash $ADMIN_FRONT_DIR
    Update-ImageTag "$SCRIPT_DIR\ecs-admin\.env_admin_frontend.template" $adminFrontTag "Admin Frontend"
}

# MyXperiences Backend
if ($updateMyxpBack) {
    $myxpBackTag = Get-GitHash $MYXP_BACK_DIR
    Update-ImageTag "$SCRIPT_DIR\ecs\.env_backend" $myxpBackTag "MyXperiences Backend"
}

# MyXperiences Frontend
if ($updateMyxpFront) {
    $myxpFrontTag = Get-GitHash $MYXP_FRONT_DIR
    Update-ImageTag "$SCRIPT_DIR\ecs\.env_frontend" $myxpFrontTag "MyXperiences Frontend"
}

Write-Blue "════════════════════════════════════════════════════════════"
Write-Green "  ✅ IMAGE TAGS UPDATED"
Write-Blue "════════════════════════════════════════════════════════════"
Write-Host ""
Write-Host "Ahora puedes ejecutar:"
Write-Blue "  make deploy-all  # Para deployar todo"
Write-Host ""
