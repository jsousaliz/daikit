[CmdletBinding()]
param(
  [ValidatePattern('^\d+\.\d+\.\d+$')]
  [string]$Versao = '0.0.0'
)

$ErrorActionPreference = 'Stop'

$DiretorioScript = Split-Path -Parent $MyInvocation.MyCommand.Path
$RaizProjeto = [IO.Path]::GetFullPath((Join-Path $DiretorioScript '..\..'))
$DiretorioPacotes = Join-Path $RaizProjeto 'packages\Delphi12'
$DiretorioPayload = Join-Path $DiretorioScript 'payload'
$DiretorioEstagio = Join-Path $DiretorioPayload 'estagio'
$ArquivoZip = Join-Path $DiretorioPayload 'Daikit.Delphi12.zip'
$ArquivoRecurso = Join-Path $DiretorioScript 'Daikit.Instalador.Payload.res'
$ArquivoRecursoManifesto = Join-Path $DiretorioScript 'Daikit.Instalador.Manifesto.res'
$BDS = 'C:\Program Files (x86)\Embarcadero\Studio\23.0'
$MSBuild = 'C:\Windows\Microsoft.NET\Framework\v4.0.30319\MSBuild.exe'
$BRCC32 = Join-Path $BDS 'bin\brcc32.exe'

function Confirmar-DentroDoProjeto([string]$Caminho) {
  $Resolvido = [IO.Path]::GetFullPath($Caminho)
  if (-not $Resolvido.StartsWith($RaizProjeto, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Caminho fora do projeto: $Resolvido"
  }
}

function Compilar-Projeto([string]$Projeto, [string]$Plataforma, [string]$Configuracao) {
  & $MSBuild $Projeto '/t:Build' "/p:Platform=$Plataforma" "/p:Config=$Configuracao" '/nologo' '/verbosity:minimal'
  if ($LASTEXITCODE -ne 0) {
    throw "Falha ao compilar $Projeto para $Plataforma."
  }
}

function Compilar-Instalador([string]$Projeto, [string]$VersaoInstalador) {
  $PartesVersao = $VersaoInstalador.Split('.')
  $ParametrosVersao = @(
    "/p:VerInfo_MajorVer=$($PartesVersao[0])",
    "/p:VerInfo_MinorVer=$($PartesVersao[1])",
    "/p:VerInfo_Release=$($PartesVersao[2])",
    '/p:VerInfo_Build=0'
  )

  & $MSBuild $Projeto '/t:Build' '/p:Platform=Win32' '/p:Config=Release' `
    @ParametrosVersao '/nologo' '/verbosity:minimal'
  if ($LASTEXITCODE -ne 0) {
    throw "Falha ao compilar o instalador Daikit $VersaoInstalador."
  }
}

if (-not (Test-Path -LiteralPath $MSBuild -PathType Leaf)) {
  throw 'MSBuild do Delphi 12 nao encontrado.'
}

$env:BDS = $BDS
$env:BDSINCLUDE = Join-Path $BDS 'include'
$env:BDSCOMMONDIR = 'C:\Users\Public\Documents\Embarcadero\Studio\23.0'

Compilar-Projeto (Join-Path $DiretorioPacotes 'DaikitRuntimeD12.dproj') 'Win32' 'Release'
Compilar-Projeto (Join-Path $DiretorioPacotes 'DaikitRuntimeD12.dproj') 'Win64' 'Release'

$DiretorioDesign = Join-Path $RaizProjeto 'src\design'
Push-Location $DiretorioDesign
try {
  & $BRCC32 '-foDaikit.Design.Registro.dcr' 'Daikit.Design.Registro.rc'
  if ($LASTEXITCODE -ne 0) {
    throw 'Falha ao compilar os icones dos componentes.'
  }
}
finally {
  Pop-Location
}

Compilar-Projeto (Join-Path $DiretorioPacotes 'DaikitDesignD12.dproj') 'Win32' 'Release'

Confirmar-DentroDoProjeto $DiretorioPayload
if (Test-Path -LiteralPath $DiretorioPayload) {
  Remove-Item -LiteralPath $DiretorioPayload -Recurse -Force
}

$Pastas = @(
  'Win32\Bpl',
  'Win32\Dcp',
  'Win64\Bpl',
  'Win64\Dcp'
)
foreach ($Pasta in $Pastas) {
  New-Item -ItemType Directory -Path (Join-Path $DiretorioEstagio $Pasta) -Force | Out-Null
}

Copy-Item -LiteralPath (Join-Path $DiretorioPacotes 'bin\Win32\DaikitRuntimeD12.bpl') -Destination (Join-Path $DiretorioEstagio 'Win32\Bpl')
Copy-Item -LiteralPath (Join-Path $DiretorioPacotes 'bin\Win32\DaikitDesignD12.bpl') -Destination (Join-Path $DiretorioEstagio 'Win32\Bpl')
Copy-Item -LiteralPath (Join-Path $DiretorioPacotes 'bin\Win64\DaikitRuntimeD12.bpl') -Destination (Join-Path $DiretorioEstagio 'Win64\Bpl')
Copy-Item -LiteralPath (Join-Path $DiretorioPacotes 'bin\Win32\DaikitRuntimeD12.dcp') -Destination (Join-Path $DiretorioEstagio 'Win32\Dcp')
Copy-Item -LiteralPath (Join-Path $DiretorioPacotes 'bin\Win64\DaikitRuntimeD12.dcp') -Destination (Join-Path $DiretorioEstagio 'Win64\Dcp')
Copy-Item -Path (Join-Path $DiretorioPacotes 'bin\Win32\dcu\runtime\*.dcu') -Destination (Join-Path $DiretorioEstagio 'Win32\Dcp')
Copy-Item -Path (Join-Path $DiretorioPacotes 'bin\Win64\dcu\runtime\*.dcu') -Destination (Join-Path $DiretorioEstagio 'Win64\Dcp')

Compress-Archive -Path (Join-Path $DiretorioEstagio '*') -DestinationPath $ArquivoZip -CompressionLevel Optimal
Remove-Item -LiteralPath $DiretorioEstagio -Recurse -Force

Push-Location $DiretorioScript
try {
  & $BRCC32 '-foDaikit.Instalador.Manifesto.res' 'Daikit.Instalador.Manifesto.rc'
  if ($LASTEXITCODE -ne 0) {
    throw 'Falha ao compilar o manifesto do instalador.'
  }
  & $BRCC32 '-foDaikit.Instalador.Payload.res' 'Daikit.Instalador.Payload.rc'
  if ($LASTEXITCODE -ne 0) {
    throw 'Falha ao incorporar o payload do instalador.'
  }
  Compilar-Instalador (Join-Path $DiretorioScript 'Daikit.Instalador.dproj') $Versao
}
finally {
  Pop-Location
}

Write-Host 'Instalador autocontido criado em:'
Write-Host (Join-Path $DiretorioScript 'bin\Win32\Daikit.Instalador.exe')
Write-Host "Versao: $Versao"
