[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$RaizProjeto = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$Instalador = Join-Path $RaizProjeto 'tools\instalador\bin\Win32\Daikit.Instalador.exe'

if (-not (Test-Path -LiteralPath $Instalador -PathType Leaf)) {
  throw 'Instalador nao encontrado. Execute tools\instalador\Construir.ps1 primeiro.'
}

Start-Process -FilePath $Instalador -Wait