# OZONE release check (docs/spec/F3-03 §3). Run before every APK given to the owner:
#   powershell -ExecutionPolicy Bypass -File tool\release_check.ps1
# Stops at the first failed check. On success, copies the APK to ..\dist\.

$ErrorActionPreference = 'Stop'
$app = Split-Path -Parent $PSScriptRoot
$repo = Split-Path -Parent $app
Set-Location $app

$env:Path = 'C:\dev\flutter\bin;' + [Environment]::GetEnvironmentVariable('Path', 'User') + ';' + [Environment]::GetEnvironmentVariable('Path', 'Machine')
$env:JAVA_HOME = 'C:\Program Files\Android\Android Studio\jbr'
$buildTools = Join-Path $env:LOCALAPPDATA 'Android\Sdk\build-tools\36.0.0'

function Step($name) { Write-Host "`n== $name" -ForegroundColor Cyan }
function Fail($msg) { Write-Host "FAILED: $msg" -ForegroundColor Red; exit 1 }
function Run($exe, [string[]]$argList) {
    & $exe @argList
    if ($LASTEXITCODE -ne 0) { Fail "$exe $($argList -join ' ')" }
}

Step '1/8 Packages match the lockfile'
Run flutter @('pub', 'get', '--enforce-lockfile')

Step '2/8 Analyzer (zero issues)'
Run flutter @('analyze', '--fatal-infos')

Step '3/8 Tests'
Run flutter @('test')

Step '4/8 Vulnerability scan (osv-scanner)'
Run osv-scanner @('scan', 'source', '--lockfile=pubspec.lock')

Step '5/8 Secret scan'
$skip = '\\(build|\.dart_tool|\.git|\.gradle|node_modules)\\'
$bad = Get-ChildItem $repo -Recurse -File -Force -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notmatch $skip } |
    Where-Object { $_.Name -match '\.(jks|keystore|p12|pem)$|^key\.properties$|^\.env' }
if ($bad) { Fail ("key or secret files inside the repository: " + ($bad.FullName -join ', ')) }
$hits = Get-ChildItem $repo -Recurse -File -Include *.dart, *.kts, *.gradle, *.xml, *.yaml, *.json, *.properties, *.ps1, *.md -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notmatch $skip -and $_.Name -ne 'release_check.ps1' } |
    Select-String -CaseSensitive -List -Pattern 'BEGIN [A-Z ]*PRIVATE KEY', '(?<![A-Za-z])(storePassword|keyPassword)\s*=(?!>)\s*(?!keyProps)\S', 'AIza[0-9A-Za-z_\-]{30,}', 'ghp_[0-9A-Za-z]{30,}'
if ($hits) { Fail ("possible secrets: " + ($hits | ForEach-Object { "$($_.Path):$($_.LineNumber)" }) -join ', ') }
Write-Host 'No secrets found.'

Step '6/8 Release builds (universal + per-CPU for size)'
Run flutter @('build', 'apk', '--release')
Run flutter @('build', 'apk', '--release', '--split-per-abi')
$out = Join-Path $app 'build\app\outputs\flutter-apk'
$apk = Join-Path $out 'app-release.apk'

Step '7/8 Permissions, signature and size'
$allowed = @(
    'android.permission.USE_BIOMETRIC',
    'android.permission.USE_FINGERPRINT',
    'android.permission.POST_NOTIFICATIONS',
    'android.permission.RECEIVE_BOOT_COMPLETED',
    'ph.ozone.ozone.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION'
)
$perms = & (Join-Path $buildTools 'aapt2.exe') dump permissions $apk |
    Select-String "uses-permission: name='([^']+)'" | ForEach-Object { $_.Matches[0].Groups[1].Value }
Write-Host ("Permissions: " + ($perms -join ', '))
if ($perms -contains 'android.permission.INTERNET') { Fail 'INTERNET permission found (F2-03 §1)' }
$extra = $perms | Where-Object { $_ -notin $allowed }
if ($extra) { Fail ("permissions not in the F2-03 list: " + ($extra -join ', ')) }

$cert = & (Join-Path $buildTools 'apksigner.bat') verify --print-certs $apk
if ($LASTEXITCODE -ne 0) { Fail 'APK signature does not verify' }
if ($cert -match 'CN=Android Debug') { Fail 'APK is signed with the debug key' }
($cert | Select-String 'certificate SHA-256') | ForEach-Object { Write-Host $_ }

$arm64 = Get-Item (Join-Path $out 'app-arm64-v8a-release.apk')
$mb = [math]::Round($arm64.Length / 1MB, 1)
Write-Host "arm64 APK: $mb MB (budget 25 MB); universal: $([math]::Round((Get-Item $apk).Length / 1MB, 1)) MB"
if ($mb -gt 25) { Fail 'arm64 APK is over the 25 MB budget (F2-03 §8)' }

Step '8/8 Copy for the owner'
$version = (Select-String -Path (Join-Path $app 'pubspec.yaml') -Pattern '^version:\s*(\S+)').Matches[0].Groups[1].Value
$dist = Join-Path $repo 'dist'
New-Item -ItemType Directory -Force $dist | Out-Null
$name = "OZONE-$($version.Replace('+', '-build'))-$(Get-Date -Format 'yyyy-MM-dd').apk"
Copy-Item $apk (Join-Path $dist $name) -Force
Write-Host "`nALL CHECKS PASSED. Install file: dist\$name" -ForegroundColor Green
Write-Host 'Performance budgets (F2-03 §8) are measured on the phone from M1 onward.'
