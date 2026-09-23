$ErrorActionPreference = 'Stop'
$base = $PSScriptRoot
$framework = Join-Path $env:WINDIR 'Microsoft.NET/Framework64/v4.0.30319'
$csc = Join-Path $framework 'csc.exe'
$out = Join-Path $base 'Aplicacion'
New-Item -ItemType Directory -Force -Path $out | Out-Null

$dataRefs = @('System.dll','System.Core.dll','System.Data.dll') | ForEach-Object { '/reference:' + (Join-Path $framework $_) }
$dataSources = Get-ChildItem -LiteralPath (Join-Path $base 'Neptuno.Data') -Filter '*.cs' -Recurse | ForEach-Object { $_.FullName }
& $csc /nologo /target:library /utf8output "/out:$out/Neptuno.Data.dll" $dataRefs $dataSources
if ($LASTEXITCODE -ne 0) { throw 'La compilación de Neptuno.Data ha fallado.' }

$wpfRefs = @('System.dll','System.Core.dll','System.Data.dll','System.Configuration.dll','System.Xml.dll','System.Xaml.dll') | ForEach-Object { '/reference:' + (Join-Path $framework $_) }
$wpfRefs += @('WindowsBase.dll','PresentationCore.dll','PresentationFramework.dll') | ForEach-Object { '/reference:' + (Join-Path $framework "WPF/$_") }
$wpfRefs += '/reference:' + (Join-Path $out 'Neptuno.Data.dll')
$wpfSources = Get-ChildItem -LiteralPath (Join-Path $base 'Neptuno.Wpf') -Filter '*.cs' | ForEach-Object { $_.FullName }
& $csc /nologo /target:winexe /utf8output "/out:$out/Neptuno.Wpf.exe" $wpfRefs $wpfSources
if ($LASTEXITCODE -ne 0) { throw 'La compilación de Neptuno.Wpf ha fallado.' }
Copy-Item -LiteralPath "$base/Neptuno.Wpf/MainWindow.xaml" -Destination $out -Force
Copy-Item -LiteralPath "$base/Neptuno.Wpf/App.config" -Destination "$out/Neptuno.Wpf.exe.config" -Force
Write-Output "Compilación correcta: $out/Neptuno.Data.dll"
Write-Output "Compilación correcta: $out/Neptuno.Wpf.exe"
