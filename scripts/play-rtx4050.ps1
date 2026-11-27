# ScarlettVictory-RTX4050 launcher tuned for NVIDIA RTX 4050 Laptop (6 GB VRAM) + 16 GB RAM.
# Combines VIctory-Belobug-AMD Renderer Ports (#1, #2, #5, #6, #7) + Residency with
# ScarlettPort's FastBoot, SkipCutscenes, LoadUnpaced, PressFile, and RayTracing=0.
param(
    [string]$Exe = 'c:\CHANCHALE\GAMERUN\game_scarlett_master.exe',
    [ValidateSet('series-s', 'series-x')][string]$Console = 'series-s',
    [ValidateSet('diag', 'release')][string]$Build = 'diag',
    [switch]$FastBoot,
    [switch]$RayTracing,
    [switch]$NoDlss,
    [switch]$NoFrameGen,
    [switch]$Safe,
    [string]$Output = '1920x1080',
    [string]$FrameIntervalMs = '33.333',
    [hashtable]$More = @{}
)

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$victory = Join-Path $root "target\$Build\victory.exe"
if (-not (Test-Path $victory)) { throw "Missing $victory. Build it first." }
if (-not (Test-Path $Exe)) { throw "Missing $Exe." }

$settings = [ordered]@{
    VICTORY_D3D12_ADAPTER      = 'NVIDIA'
    VICTORY_RENDER_SCALE       = '0.5'
    VICTORY_NO_ROVS            = '1'
    VICTORY_SHADER_OPT         = '127'
    VICTORY_DYNAMIC_SLOTS      = '524288'
    VICTORY_TEXTURE_NO_WAIT    = '1'
    VICTORY_RELAY              = '2'
    VICTORY_WIDE_BACK          = '1'
    VICTORY_CARD_REHASH_RUNS   = '1'
    VICTORY_JOIN_COPIES        = '1'
    VICTORY_INDIRECT_WINDOW    = '1'
    VICTORY_RELAY_COPY         = '1'
    VICTORY_CARD_STEPS         = '2'
    VICTORY_INDIRECT_BATCH     = '2'
    VICTORY_MAP_THREADS        = '1'
    VICTORY_TITLE_PRIORITIES   = '0'
    VICTORY_CARD_AWAKE         = '1'
    VICTORY_SHOW_AFTER         = '1'
    VICTORY_AMBIENT            = 'constant:0.15'
    VICTORY_AMBIENT_AIR        = '0.8'
    VICTORY_LEVELS_ON_DEMAND   = '0'
    VICTORY_WINDOW_KB          = '256'
    VICTORY_WINDOW_TAILS       = '1'
    VICTORY_WINDOW_BUDGET_MB   = '512'
    VICTORY_SNAPSHOT_POOL      = '16'
    VICTORY_CARD_BUFFERS_MIN_MB = '1'
    VICTORY_CARD_BUFFERS_MB    = '1024'
    VICTORY_WINDOWS_BAR_MB     = '1024'
    VICTORY_E5_TARGETS         = 'r11g11b10'
    VICTORY_RT_MISS            = '1'
    VICTORY_CARD_ROOM_FOR_TARGETS_MB = '1536'
    VICTORY_TEXTURE_ROOM_PERCENT = '65'
    VICTORY_TEXTURE_BACK       = '0'
    VICTORY_RESIDENCY          = '1'
    VICTORY_RESIDENCY_LIMITED  = '1'
    VICTORY_WAIT_RESIDENT      = '0'
    VICTORY_METER_THREAD       = '0'
    VICTORY_PIPELINE_WAIT_MS   = '0'
    VICTORY_KBM_GTA            = '1'
    VICTORY_FRAME_INTERVAL_MS  = $FrameIntervalMs
    VICTORY_PRESS_FILE         = (Join-Path $root 'press.txt')
}

if (-not (Test-Path $settings.VICTORY_PRESS_FILE)) {
    Set-Content -Path $settings.VICTORY_PRESS_FILE -Value '' -NoNewline
}

if ($Safe) {
    $settings.VICTORY_UNDER_WIDE = '0'
    $settings.VICTORY_LAND_ECHO = '0'
} else {
    $settings.VICTORY_THIN = '0'
    $settings.VICTORY_JOIN_PARTS = '4'
    $settings.VICTORY_UPLOAD_AHEAD = '1'
    $settings.VICTORY_PORT_CONSTANTS = '1'
    $settings.VICTORY_PORT_DESCRIPTORS = '1'
    $settings.VICTORY_PORT_CBV = '0'
    $settings.VICTORY_PORT_GUARD = '1'
    $settings.VICTORY_PORT_JOURNAL = '1'
}

if ($RayTracing) {
    $settings.VICTORY_BVH_BUILDER = '1'
    $settings.VICTORY_RAY_TRACING = '1'
} else {
    $settings.VICTORY_RAY_TRACING = '0'
    $settings.VICTORY_SKIP_PIPELINES = 'none'
}

if ($FastBoot) {
    $settings.VICTORY_FAST_BOOT = '1'
    $settings.VICTORY_SKIP_CUTSCENES = '1'
}

if ($Output) {
    $settings.VICTORY_OUTPUT = $Output
}

$dlssDir = Join-Path $root 'nvidia-sdk\DLSS\lib\Windows_x86_64\rel'
$slDir = Join-Path $root 'nvidia-sdk\Streamline\bin\x64'
if (-not $NoDlss -and (Test-Path (Join-Path $dlssDir 'nvngx_dlss.dll'))) {
    $settings.VICTORY_UPSCALE = 'dlss'
    $settings.VICTORY_DLSS_DIR = $dlssDir
    $settings.VICTORY_DLSS_BEFORE_SL = '1'
} else {
    $settings.VICTORY_UPSCALER = '6'
}
if (-not $NoFrameGen -and -not $RayTracing -and (Test-Path (Join-Path $slDir 'sl.interposer.dll'))) {
    $settings.VICTORY_STREAMLINE_DIR = $slDir
    $settings.VICTORY_FRAME_GEN = '2'
    $settings.VICTORY_FG_ANY_UPSCALE = '1'
}

foreach ($k in $More.Keys) {
    $settings[$k] = $More[$k]
}

foreach ($k in $settings.Keys) {
    Set-Item "Env:$k" $settings[$k]
}

$logs = Join-Path $root 'logs'
New-Item -ItemType Directory -Force $logs | Out-Null
$log = Join-Path $logs ("rtx4050-{0:yyyyMMdd-HHmmss}.log" -f (Get-Date))

$Exe = (Resolve-Path $Exe).Path
Push-Location $root
$ErrorActionPreference = 'Continue'
try {
    & $victory run $Exe --console $Console --execute 2>&1 | Tee-Object -FilePath $log
} finally {
    $ErrorActionPreference = 'Stop'
    Pop-Location
}
