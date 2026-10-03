param(
    [ValidateSet('Debug', 'Release')]
    [string]$Configuration = 'Release'
)

$ErrorActionPreference = 'Stop'
$projectRoot = $PSScriptRoot
$propsPath = Join-Path $projectRoot 'local.props'
if (-not (Test-Path -LiteralPath $propsPath)) {
    throw 'Copy local.props.template to local.props and set your game and Godot paths first.'
}
$props = [xml](Get-Content -LiteralPath $propsPath -Raw)
$godotExe = [string]$props.Project.PropertyGroup.GodotExe
if (-not (Test-Path -LiteralPath $godotExe -PathType Leaf)) {
    throw 'GodotExe in local.props must point to Godot 4.5.1 .NET.'
}

Push-Location -LiteralPath $projectRoot
try {
    & $godotExe --headless --path $projectRoot --editor --quit
    if ($LASTEXITCODE -ne 0) { throw 'Godot resource import failed.' }
    dotnet build ReactiveCompanionUI.csproj -c $Configuration --nologo
    if ($LASTEXITCODE -ne 0) { throw 'C# build failed.' }

    $packageDir = Join-Path $projectRoot 'dist/ReactiveCompanionUI'
    New-Item -ItemType Directory -Path $packageDir -Force | Out-Null
    $pckPath = Join-Path $packageDir 'ReactiveCompanionUI.pck'
    & $godotExe --headless --path $projectRoot --export-pack 'Windows Desktop' $pckPath
    if ($LASTEXITCODE -ne 0) { throw 'Godot PCK export failed.' }

    $dllPath = Join-Path $projectRoot ".godot/mono/temp/bin/$Configuration/ReactiveCompanionUI.dll"
    Copy-Item -LiteralPath $dllPath -Destination (Join-Path $packageDir 'ReactiveCompanionUI.dll') -Force
    Copy-Item -LiteralPath (Join-Path $projectRoot 'ReactiveCompanionUI.json') -Destination (Join-Path $packageDir 'ReactiveCompanionUI.json') -Force
    Write-Output "Build complete: $packageDir"
} finally {
    Pop-Location
}
