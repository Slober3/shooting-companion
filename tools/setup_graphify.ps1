[CmdletBinding()]
param(
  [switch]$InstallCli
)

$ErrorActionPreference = 'Stop'
$requiredVersion = '0.9.40'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

Push-Location $repoRoot
try {
  $command = Get-Command graphify -ErrorAction SilentlyContinue
  if ($null -eq $command) {
    if (-not $InstallCli) {
      throw "Graphify $requiredVersion is missing. Rerun with -InstallCli."
    }
    if ($null -eq (Get-Command uv -ErrorAction SilentlyContinue)) {
      throw 'uv is required to install the pinned Graphify CLI.'
    }
    uv tool install --force "graphifyy==$requiredVersion"
  } elseif ($InstallCli) {
    uv tool install --force "graphifyy==$requiredVersion"
  }

  $reported = (& graphify --version).Trim()
  if ($LASTEXITCODE -ne 0) { throw 'graphify --version failed.' }
  if ($reported -ne "graphify $requiredVersion") {
    throw "Expected graphify $requiredVersion, found '$reported'."
  }

  graphify install --platform codex
  if ($LASTEXITCODE -ne 0) { throw 'Graphify Codex skill installation failed.' }
  graphify codex install
  if ($LASTEXITCODE -ne 0) { throw 'Graphify repository instruction installation failed.' }
  $generatedCodexHook = Join-Path $repoRoot '.codex/hooks.json'
  if (Test-Path $generatedCodexHook) {
    Remove-Item -LiteralPath $generatedCodexHook -Force
  }
  graphify hook install
  if ($LASTEXITCODE -ne 0) { throw 'Graphify hook installation failed.' }
  graphify extract . --code-only
  if ($LASTEXITCODE -ne 0) { throw 'Graphify code-only extraction failed.' }
  graphify update .
  if ($LASTEXITCODE -ne 0) { throw 'Graphify AST update failed.' }
  python tools/normalize_graphify_output.py
  if ($LASTEXITCODE -ne 0) { throw 'Graphify normalization failed.' }
  python tools/verify_graphify.py
  if ($LASTEXITCODE -ne 0) { throw 'Graphify verification failed.' }

  $hooksDir = git rev-parse --git-path hooks
  $normalizerMarker = '# shooting-companion-graphify-normalizer'
  $normalizerLines = @(
    $normalizerMarker,
    'repo_root="$(git rev-parse --show-toplevel)"',
    'python "$repo_root/tools/normalize_graphify_output.py" --root "$repo_root"'
  ) -join "`n"
  foreach ($hookName in @('post-commit', 'post-checkout')) {
    $hookPath = Join-Path $hooksDir $hookName
    if ((Test-Path $hookPath) -and
        -not (Select-String -Path $hookPath -SimpleMatch $normalizerMarker -Quiet)) {
      Add-Content -Path $hookPath -Value "`n$normalizerLines`n"
    }
  }

  graphify hook status
  if ($LASTEXITCODE -ne 0) { throw 'Graphify hooks or merge driver are incomplete.' }
} finally {
  Pop-Location
}
