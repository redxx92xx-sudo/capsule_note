param()
$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$ProjectType = "flutter"
$MobileRelative = ""
$ReportDir = Join-Path $ProjectRoot "automation-reports"
New-Item -ItemType Directory -Force -Path $ReportDir | Out-Null
$LogFile = Join-Path $ReportDir ("verify-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".log")
function Run-Step([string]$Name, [scriptblock]$Action) {
  "`n=== $Name ===" | Tee-Object -FilePath $LogFile -Append
  & $Action 2>&1 | Tee-Object -FilePath $LogFile -Append
  if ($LASTEXITCODE -ne 0) { throw "$Name 失敗，代碼 $LASTEXITCODE" }
}
function Install-Js([string]$Dir) {
  Push-Location $Dir
  try {
    if (Test-Path "pnpm-lock.yaml") { Run-Step "pnpm install" { pnpm install --frozen-lockfile } }
    elseif (Test-Path "yarn.lock") { Run-Step "yarn install" { yarn install --immutable } }
    elseif (Test-Path "package-lock.json") { Run-Step "npm ci" { npm.cmd ci } }
    else { Run-Step "npm install" { npm.cmd install } }
  } finally { Pop-Location }
}
function Run-Script([string]$Dir, [string]$Name) {
  $P = Get-Content -Raw -Encoding UTF8 (Join-Path $Dir "package.json") | ConvertFrom-Json
  if ($P.scripts -and $P.scripts.PSObject.Properties.Name -contains $Name) {
    Push-Location $Dir
    try { Run-Step "npm run $Name" { npm.cmd run $Name } } finally { Pop-Location }
  }
}
function Find-Adb {
  $C = Get-Command adb -ErrorAction SilentlyContinue
  if ($C) { return $C.Source }
  $D = Join-Path $env:LOCALAPPDATA "Android\Sdk\platform-tools\adb.exe"
  if (Test-Path $D) { return $D }
  return $null
}
function Install-Apk([string]$Dir) {
  $Apk = Get-ChildItem $Dir -Recurse -Filter "*.apk" -ErrorAction SilentlyContinue | Where-Object FullName -match "release" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if (-not $Apk) { "未產生 APK；已完成可用的專案檢查與建置。" | Tee-Object -FilePath $LogFile -Append; return }
  $Adb = Find-Adb
  if (-not $Adb) { "APK 已完成但找不到 adb.exe：$($Apk.FullName)" | Tee-Object -FilePath $LogFile -Append; return }
  if (@((& $Adb devices) | Select-String "\sdevice$").Count -eq 0) { "APK 已完成但未連接 Android 手機。" | Tee-Object -FilePath $LogFile -Append; return }
  Run-Step "安裝手機" { & $Adb install -r $Apk.FullName }
}
function Verify-Flutter([string]$Dir) {
  Push-Location $Dir
  try {
    Run-Step "flutter pub get" { flutter pub get }; Run-Step "dart format" { dart format . }
    Run-Step "flutter analyze" { flutter analyze }; Run-Step "flutter test" { flutter test }
    Run-Step "Flutter Release APK" { flutter build apk --release }; Install-Apk $Dir
  } finally { Pop-Location }
}
function Verify-Js([string]$Dir, [bool]$Mobile) {
  Install-Js $Dir
  foreach ($N in @("format", "lint", "typecheck", "test", "build")) { Run-Script $Dir $N }
  if ($Mobile) {
    $Gradle = Join-Path $Dir "android\gradlew.bat"
    if (Test-Path $Gradle) {
      Push-Location (Join-Path $Dir "android"); try { Run-Step "Android Release APK" { & $Gradle assembleRelease } } finally { Pop-Location }; Install-Apk $Dir
    } else { "Expo Managed 專案沒有 android 目錄；跳過本機 APK，保留 EAS 建置方式。" | Tee-Object -FilePath $LogFile -Append }
  }
}
Push-Location $ProjectRoot
try {
  if ($ProjectType -eq "flutter") { Verify-Flutter $ProjectRoot }
  elseif ($ProjectType -in @("expo", "react_native")) { Verify-Js $ProjectRoot $true }
  elseif ($ProjectType -in @("nextjs", "nodejs")) { Verify-Js $ProjectRoot $false }
  elseif ($ProjectType -eq "monorepo") {
    if (Test-Path (Join-Path $ProjectRoot "package.json")) { Verify-Js $ProjectRoot $false }
    if ($MobileRelative) {
      $M = Join-Path $ProjectRoot $MobileRelative
      if (Test-Path (Join-Path $M "pubspec.yaml")) { Verify-Flutter $M }
      elseif (Test-Path (Join-Path $M "package.json")) { Verify-Js $M $true }
    }
  } else { throw "不支援的專案類型：$ProjectType" }
  "`nSUCCESS`nTYPE=$ProjectType" | Tee-Object -FilePath $LogFile -Append
} finally { Pop-Location }
