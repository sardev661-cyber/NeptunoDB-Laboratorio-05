$ErrorActionPreference = 'Stop'
$base = $PSScriptRoot
$framework = Join-Path $env:WINDIR 'Microsoft.NET/Framework64/v4.0.30319'
$csc = Join-Path $framework 'csc.exe'
$out = Join-Path $base 'Aplicacion'
New-Item -ItemType Directory -Force -Path $out | Out-Null
$refs = @('System.dll','System.Core.dll','System.Data.dll','System.Configuration.dll','System.Xml.dll','System.Xaml.dll') | ForEach-Object { '/reference:' + (Join-Path $framework $_) }
$refs += @('WindowsBase.dll','PresentationCore.dll','PresentationFramework.dll') | ForEach-Object { '/reference:' + (Join-Path $framework "WPF/$_") }
$sources = Get-ChildItem -LiteralPath (Join-Path $base 'Neptuno.Wpf') -Filter '*.cs' | ForEach-Object { $_.FullName }
& $csc /nologo /target:winexe /utf8output "/out:$out/Neptuno.Wpf.exe" $refs $sources
if ($LASTEXITCODE -ne 0) { throw 'La compilación ha fallado.' }
Copy-Item -LiteralPath "$base/Neptuno.Wpf/MainWindow.xaml" -Destination $out -Force
Copy-Item -LiteralPath "$base/Neptuno.Wpf/App.config" -Destination "$out/Neptuno.Wpf.exe.config" -Force
Write-Output "Compilación correcta: $out/Neptuno.Wpf.exe"
