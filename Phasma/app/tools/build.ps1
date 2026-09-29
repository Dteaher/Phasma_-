param([switch]$SkipTests)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$flutterCommand = Get-Command flutter -ErrorAction SilentlyContinue
$flutterPath = if ($flutterCommand) { $flutterCommand.Source } else { Join-Path $env:USERPROFILE '.cache\tailtown-tools\flutter\bin\flutter.bat' }
if (!(Test-Path -LiteralPath $flutterPath)) { throw 'Установите Flutter stable и добавьте flutter в PATH.' }
$shortPath = Join-Path $env:USERPROFILE '.cache\tailtown-project'
if (!(Test-Path -LiteralPath $shortPath)) { New-Item -ItemType Junction -Path $shortPath -Target $root | Out-Null }
Push-Location $shortPath
try {
  & $flutterPath pub get
  if ($LASTEXITCODE) { throw 'Не удалось получить зависимости.' }
  if (!$SkipTests) {
    & $flutterPath analyze --no-pub
    if ($LASTEXITCODE) { throw 'Анализ кода обнаружил проблемы.' }
    & $flutterPath test --no-pub
    if ($LASTEXITCODE) { throw 'Проверки не прошли.' }
  }
  & $flutterPath build apk --release --no-pub
  if ($LASTEXITCODE) { throw 'APK не собран.' }
  New-Item -ItemType Directory -Force output\android | Out-Null
  Copy-Item -LiteralPath build\app\outputs\flutter-apk\app-release.apk -Destination output\android\Город-Хвостиков-0.16.apk
  Get-FileHash -LiteralPath output\android\Город-Хвостиков-0.16.apk -Algorithm SHA256
} finally { Pop-Location }
