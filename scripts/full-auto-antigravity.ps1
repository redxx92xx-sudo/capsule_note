param()
$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$RequirementFile = Join-Path $ProjectRoot "新需求說明.md"
$ReportDir = Join-Path $ProjectRoot "automation-reports"
New-Item -ItemType Directory -Force -Path $ReportDir | Out-Null
if (-not (Test-Path $RequirementFile)) { throw "找不到需求檔：$RequirementFile" }
$Requirement = Get-Content -Raw -Encoding UTF8 $RequirementFile
if ([string]::IsNullOrWhiteSpace($Requirement)) { throw "需求內容是空白的。" }
$Prompt = @"
你正在維護專案：$ProjectRoot
派送器辨識類型：Flutter
已辨識組成：Flutter（根目錄）
先讀取專案現況與 AGENTS.md（若存在），自行確認實際框架與可用腳本。修改前列出預計修改的檔案與原因，然後直接執行；只有危險、破壞性或無法判斷時才詢問。
必須實際修改程式。保留既有未提交修改，禁止 git reset --hard、git clean -fd 或 checkout 覆蓋使用者檔案。完成後依實際框架執行格式化、靜態檢查與測試；失敗須繼續修正。不要把非 Flutter 專案轉成 Flutter。
本次需求：
$Requirement
"@
Push-Location $ProjectRoot
try {
  & agy -p $Prompt --output-format stream-json --print-timeout 60m --dangerously-skip-permissions
  if ($LASTEXITCODE -ne 0) { throw "Antigravity 執行失敗，代碼 $LASTEXITCODE" }
  & (Join-Path $PSScriptRoot "verify-build-install.ps1")
  if ($LASTEXITCODE -ne 0) { throw "驗收、建置或安裝失敗，代碼 $LASTEXITCODE" }
} finally { Pop-Location }
