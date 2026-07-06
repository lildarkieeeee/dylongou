# install_and_push.ps1
# Intenta instalar Git (winget o choco) y luego inicializa el repo y hace push.

param(
  [string]$Remote = 'https://github.com/lildarkieeeee/dylongou.git'
)

function Write-Err($m){ Write-Host $m -ForegroundColor Red }
function Write-Ok($m){ Write-Host $m -ForegroundColor Green }

function Test-IsAdmin {
  $wi = [Security.Principal.WindowsIdentity]::GetCurrent()
  $wp = New-Object Security.Principal.WindowsPrincipal($wi)
  return $wp.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

Push-Location (Split-Path -Path $MyInvocation.MyCommand.Definition -Parent)

Write-Host "Verificando entorno para Git..."

if (Get-Command git -ErrorAction SilentlyContinue) {
  Write-Ok "Git ya está instalado: $(git --version)"
} elseif (Get-Command winget -ErrorAction SilentlyContinue) {
  Write-Host "Instalando Git con winget...";
  winget install --id Git.Git -e --accept-package-agreements --accept-source-agreements
} elseif (Get-Command choco -ErrorAction SilentlyContinue) {
  Write-Host "Instalando Git con Chocolatey...";
  choco install git -y
} else {
  Write-Host "No se detectó 'git', 'winget' ni 'choco'. Intentaré descargar el instalador oficial de Git para Windows y ejecutarlo."

  if (-not (Test-IsAdmin)) {
    Write-Host "Necesito privilegios de administrador para instalar Git. Reiniciando el script elevado..."
    Start-Process -FilePath powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Pop-Location
    exit 0
  }

  # Intentar obtener el instalador desde GitHub Releases
  try {
    $api = 'https://api.github.com/repos/git-for-windows/git/releases/latest'
    $rel = Invoke-RestMethod -UseBasicParsing -Uri $api -Headers @{ 'User-Agent' = 'PowerShell' }
    $asset = $rel.assets | Where-Object { $_.name -match '64-bit.exe$' } | Select-Object -First 1
    if (-not $asset) {
      $asset = $rel.assets | Where-Object { $_.name -match 'Git-.*64-bit.*\.exe' } | Select-Object -First 1
    }
    if ($asset -and $asset.browser_download_url) {
      $url = $asset.browser_download_url
    } else {
      # fallback to generic redirect (GitHub provides this pattern)
      $url = 'https://github.com/git-for-windows/git/releases/latest/download/Git-64-bit.exe'
    }

    $tmp = Join-Path $env:TEMP 'Git-Installer.exe'
    Write-Host "Descargando instalador desde: $url"
    Invoke-WebRequest -Uri $url -OutFile $tmp -UseBasicParsing
    Write-Host "Ejecutando instalador (silencioso)..."
    $args = '/VERYSILENT','/NORESTART'
    $p = Start-Process -FilePath $tmp -ArgumentList $args -Wait -PassThru
    if ($p.ExitCode -ne 0) {
      Write-Err "El instalador devolvió código $($p.ExitCode). Revisa la instalación manualmente."
    } else {
      Write-Ok "Instalación completada."
    }
    Remove-Item -Path $tmp -ErrorAction SilentlyContinue
  } catch {
    Write-Err "Error descargando o ejecutando el instalador: $_"
    Write-Err "Por favor instala Git manualmente desde: https://git-scm.com/download/win"
    Pop-Location
    exit 4
  }
}

# Asegurar que 'git' está disponible ahora
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  # buscar rutas comunes
  $candidates = @(
    'C:\Program Files\Git\cmd\git.exe',
    'C:\Program Files (x86)\Git\cmd\git.exe'
  )
  $found = $null
  foreach ($c in $candidates) {
    if (Test-Path $c) { $found = $c; break }
  }
  if ($found) {
    $gitDir = Split-Path -Parent $found
    $env:Path = "$env:Path;$gitDir"
    Write-Ok "Git encontrado en: $found"
  } else {
    Write-Err "No se encontró 'git' en PATH ni en ubicaciones comunes. Reinicia la terminal y verifica la instalación."
    Pop-Location
    exit 5
  }
}

Write-Ok "Git listo: $(git --version)"

# Inicializar y preparar el repo
Write-Host "Inicializando repo en $(Get-Location)..."
if (-not (Test-Path .git)) {
  git init
}
git add .
git commit -m "Initial commit: sitio estático" --allow-empty
if ($LASTEXITCODE -ne 0) {
  Write-Host "Commit posiblemente falló (sin cambios)"
}

if (-not (git remote) -match 'origin') {
  git remote add origin $Remote
} else {
  Write-Host "Remote 'origin' ya existe."
}

git branch -M main

Write-Host "Intentando push a $Remote (se te pedirá credenciales si es necesario)..."
git push -u origin main

Pop-Location
