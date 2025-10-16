# ═══════════════════════════════════════════════════════════════════════
# Script para quitar LoadOnDemand de Ascension_NamePlates
# ═══════════════════════════════════════════════════════════════════════
# Este script modifica el archivo .toc para que el addon se cargue
# automáticamente al iniciar el juego.
#
# INSTRUCCIONES:
# 1. CIERRA el juego completamente antes de ejecutar este script
# 2. Click derecho en este archivo → "Ejecutar con PowerShell"
# 3. Inicia el juego - el addon se cargará automáticamente
# ═══════════════════════════════════════════════════════════════════════

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Fix Ascension NamePlates LoadOnDemand" -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Ruta al archivo .toc
$tocPath = "d:\Games\Ascension Launcher\resources\client\Interface\AddOns\Ascension_NamePlates\Ascension_NamePlates.toc"
$backupPath = "d:\Games\Ascension Launcher\resources\client\Interface\AddOns\Ascension_NamePlates\Ascension_NamePlates.toc.backup"

# Verificar si el archivo existe
if (-Not (Test-Path $tocPath)) {
    Write-Host "[ERROR] No se encontró el archivo:" -ForegroundColor Red
    Write-Host "  $tocPath" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Asegúrate de que Ascension_NamePlates esté instalado en:" -ForegroundColor Yellow
    Write-Host "  Interface\AddOns\Ascension_NamePlates\" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Presiona cualquier tecla para salir..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

Write-Host "[1/4] Archivo encontrado" -ForegroundColor Green
Write-Host "      $tocPath" -ForegroundColor Gray
Write-Host ""

# Crear backup
Write-Host "[2/4] Creando backup..." -ForegroundColor Yellow
try {
    Copy-Item -Path $tocPath -Destination $backupPath -Force
    Write-Host "      Backup creado: Ascension_NamePlates.toc.backup" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] No se pudo crear el backup: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Presiona cualquier tecla para salir..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}
Write-Host ""

# Leer el contenido del archivo
Write-Host "[3/4] Modificando archivo .toc..." -ForegroundColor Yellow
try {
    $content = Get-Content -Path $tocPath -Raw
    
    # Verificar si tiene LoadOnDemand
    if ($content -match '## LoadOnDemand: 1') {
        # Comentar la línea LoadOnDemand
        $newContent = $content -replace '## LoadOnDemand: 1', '## LoadOnDemand: 0  ## Disabled by YATP Fix Script'
        
        # Guardar el archivo modificado
        Set-Content -Path $tocPath -Value $newContent -NoNewline
        
        Write-Host "      LoadOnDemand ha sido desactivado" -ForegroundColor Green
    } elseif ($content -match '## LoadOnDemand: 0') {
        Write-Host "      LoadOnDemand ya estaba desactivado" -ForegroundColor Yellow
    } else {
        Write-Host "      No se encontró la línea LoadOnDemand en el archivo" -ForegroundColor Yellow
    }
} catch {
    Write-Host "[ERROR] No se pudo modificar el archivo: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Restaurando backup..." -ForegroundColor Yellow
    Copy-Item -Path $backupPath -Destination $tocPath -Force
    Write-Host ""
    Write-Host "Presiona cualquier tecla para salir..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}
Write-Host ""

Write-Host "[4/4] ¡Completado!" -ForegroundColor Green
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  ÉXITO - Ascension NamePlates se cargará automáticamente" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "QUÉ SE HA HECHO:" -ForegroundColor Yellow
Write-Host "  • Se creó un backup: Ascension_NamePlates.toc.backup" -ForegroundColor Gray
Write-Host "  • Se desactivó LoadOnDemand en el archivo .toc" -ForegroundColor Gray
Write-Host "  • El addon se cargará automáticamente al iniciar el juego" -ForegroundColor Gray
Write-Host ""
Write-Host "PRÓXIMOS PASOS:" -ForegroundColor Yellow
Write-Host "  1. Inicia el juego" -ForegroundColor Gray
Write-Host "  2. El addon Ascension_NamePlates se cargará automáticamente" -ForegroundColor Gray
Write-Host "  3. Abre /yatp → NamePlates para configurarlo" -ForegroundColor Gray
Write-Host ""
Write-Host "PARA REVERTIR LOS CAMBIOS:" -ForegroundColor Yellow
Write-Host "  Renombra 'Ascension_NamePlates.toc.backup' a 'Ascension_NamePlates.toc'" -ForegroundColor Gray
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Presiona cualquier tecla para cerrar..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
