# Place this script beside index.html. Requires Python 3.
[CmdletBinding()]
param(
    [ValidateRange(1024, 65535)]
    [int]$Port = 8080
)

$ErrorActionPreference = 'Stop'
$siteRoot = $PSScriptRoot
if (-not (Test-Path -LiteralPath (Join-Path $siteRoot 'index.html') -PathType Leaf)) {
    Write-Host 'index.html must be in the same folder as serve.ps1.' -ForegroundColor Red
    exit 1
}

$pythonCommand = $null
$pythonPrefix = @()
foreach ($candidate in @('py', 'python', 'python3')) {
    if (-not (Get-Command $candidate -ErrorAction SilentlyContinue)) { continue }
    $prefix = @()
    if ($candidate -eq 'py') { $prefix = @('-3') }
    try {
        & $candidate @prefix -c 'import sys; sys.exit(0 if sys.version_info.major == 3 else 1)' 2>$null
        if ($LASTEXITCODE -eq 0) {
            $pythonCommand = $candidate
            $pythonPrefix = $prefix
            break
        }
    } catch { }
}
if (-not $pythonCommand) {
    Write-Host 'Python 3 is required. Install it from https://www.python.org/downloads/' -ForegroundColor Red
    exit 1
}

# Bind only to this computer; reject an occupied port before opening a browser.
$probe = $null
try {
    $probe = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $Port)
    $probe.Start()
} catch {
    Write-Host "Port $Port is unavailable. Try: .\serve.ps1 -Port 8081" -ForegroundColor Red
    exit 1
} finally {
    if ($null -ne $probe) { $probe.Stop() }
}

$url = "http://127.0.0.1:$Port/"
Write-Host "Serving: $siteRoot" -ForegroundColor Cyan
Write-Host "Open: $url" -ForegroundColor Green
Write-Host 'Stop the server with Ctrl+C. This is a local static server, not an API proxy.'
Start-Process $url
& $pythonCommand @pythonPrefix -m http.server $Port --bind 127.0.0.1 --directory $siteRoot
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
