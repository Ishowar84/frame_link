# scrcpy Binary Downloader Script
# This script downloads and extracts scrcpy binaries for the GUI app

param(
    [string]$Version = "3.3.4"
)

Write-Host "===============================================" -ForegroundColor Cyan
Write-Host " scrcpy GUI - Binary Setup Script" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host ""

$DOWNLOAD_URL = "https://github.com/Genymobile/scrcpy/releases/download/v$Version/scrcpy-win64-v$Version.zip"
$TEMP_ZIP = "$env:TEMP\scrcpy.zip"
$TEMP_EXTRACT = "$env:TEMP\scrcpy_extract"
$RESOURCES_DIR = "windows\runner\resources"

Write-Host "[1/5] Checking resources directory..." -ForegroundColor Yellow
if (!(Test-Path $RESOURCES_DIR)) {
    New-Item -ItemType Directory -Force -Path $RESOURCES_DIR | Out-Null
    Write-Host "  Created resources directory" -ForegroundColor Green
}
else {
    Write-Host "  Resources directory exists" -ForegroundColor Green
}

Write-Host ""
Write-Host "[2/5] Downloading scrcpy v$Version..." -ForegroundColor Yellow
Write-Host "  URL: $DOWNLOAD_URL" -ForegroundColor Gray

try {
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $DOWNLOAD_URL -OutFile $TEMP_ZIP -UseBasicParsing
    Write-Host "  Download complete" -ForegroundColor Green
}
catch {
    Write-Host "  Download failed: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Manual download:" -ForegroundColor Yellow
    Write-Host "1. Go to: https://github.com/Genymobile/scrcpy/releases/latest"
    Write-Host "2. Download: scrcpy-win64-v$Version.zip"
    Write-Host "3. Extract all files to: $RESOURCES_DIR"
    exit 1
}

Write-Host ""
Write-Host "[3/5] Extracting archive..." -ForegroundColor Yellow
if (Test-Path $TEMP_EXTRACT) {
    Remove-Item -Recurse -Force $TEMP_EXTRACT
}
New-Item -ItemType Directory -Force -Path $TEMP_EXTRACT | Out-Null

try {
    Expand-Archive -Path $TEMP_ZIP -DestinationPath $TEMP_EXTRACT -Force
    Write-Host "  Extraction complete" -ForegroundColor Green
}
catch {
    Write-Host "  Extraction failed: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[4/5] Copying binaries..." -ForegroundColor Yellow
$ExtractedFolder = Get-ChildItem -Path $TEMP_EXTRACT -Directory | Select-Object -First 1
$SourceFolder = $ExtractedFolder.FullName

$FilesCopied = 0
Get-ChildItem -Path $SourceFolder -File | ForEach-Object {
    Copy-Item $_.FullName -Destination $RESOURCES_DIR -Force
    $FilesCopied++
}
Write-Host "  Copied $FilesCopied files" -ForegroundColor Green

Write-Host ""
Write-Host "[5/5] Verifying installation..." -ForegroundColor Yellow
$RequiredFiles = @("scrcpy.exe", "scrcpy-server", "adb.exe", "SDL2.dll")
$MissingFiles = @()

foreach ($file in $RequiredFiles) {
    $FilePath = Join-Path $RESOURCES_DIR $file
    if (!(Test-Path $FilePath)) {
        $MissingFiles += $file
    }
}

if ($MissingFiles.Count -eq 0) {
    Write-Host "  All required files present!" -ForegroundColor Green
}
else {
    Write-Host "  Missing files:" -ForegroundColor Red
    $MissingFiles | ForEach-Object { Write-Host "    - $_" -ForegroundColor Red }
    exit 1
}

Remove-Item -Force $TEMP_ZIP -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force $TEMP_EXTRACT -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "===============================================" -ForegroundColor Green
Write-Host " Setup Complete!" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Files: $RESOURCES_DIR" -ForegroundColor Gray
Write-Host "Count: $FilesCopied files" -ForegroundColor Gray
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. flutter pub get"
Write-Host "  2. flutter run -d windows"
Write-Host ""
