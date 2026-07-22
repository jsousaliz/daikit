unit Daikit.Instalador.Servico;

interface

uses
  System.SysUtils;

type
  EInstaladorDaikit = class(Exception);

  TEstadoInstalacaoDaikit = record
    DelphiInstalado: Boolean;
    IDEEmExecucao: Boolean;
    ArtefatosDisponiveis: Boolean;
    PacoteRegistrado: Boolean;
    DiretorioBPL: string;
    Descricao: string;
  end;

  TServicoInstalacaoDaikit = class
  strict private
    class function AjustarCaminho(const AAtual, ACaminho: string;
      AAdicionar: Boolean): string; static;
    function ChaveBDSExiste: Boolean;
    procedure CopiarDiretorio(const AOrigem, ADestino: string);
    function DiretorioBPL: string;
    function DiretorioComum: string;
    function DiretorioDCP(const APlataforma: string): string;
    procedure ExcluirInstalacao;
    procedure ExigirIDEFechada;
    procedure ExtrairPayload(const ADestino: string);
    function LerSearchPath(const APlataforma: string): string;
    function PacoteRegistrado: Boolean;
    function PayloadDisponivel: Boolean;
    procedure RegistrarPacote(const ACaminho: string);
    procedure RemoverRegistroPacote;
    procedure AtualizarSearchPath(const APlataforma: string;
      AAdicionar: Boolean);
    procedure EscreverSearchPath(const APlataforma, AValor: string);
    procedure ValidarPayload(const ADiretorio: string);
  public
    constructor Create;
    class function AdicionarCaminhoPesquisa(const AAtual,
      ACaminho: string): string; static;
    class function RemoverCaminhoPesquisa(const AAtual,
      ACaminho: string): string; static;
    class function IDEEmExecucao: Boolean; static;
    function ObterEstado: TEstadoInstalacaoDaikit;
    procedure Instalar;
    procedure Desinstalar;
  end;

implementation

uses
  System.Classes,
  System.IOUtils,
  System.Win.Registry,
  System.Zip,
  Winapi.ShlObj,
  Winapi.TlHelp32,
  Winapi.Windows;

const
  VERSAO_BDS = '23.0';
  CHAVE_BDS = '\Software\Embarcadero\BDS\' + VERSAO_BDS;
  CHAVE_PACOTES = CHAVE_BDS + '\Known Packages';
  PACOTE_RUNTIME = 'DaikitRuntimeD12.bpl';
  PACOTE_DESIGN = 'DaikitDesignD12.bpl';
  PACOTE_DCP = 'DaikitRuntimeD12.dcp';
  DCU_VALIDACAO = 'Daikit.Componentes.Chat.dcu';
  DESCRICAO_PACOTE = 'Daikit - Componentes';
  RECURSO_PAYLOAD = 'DAIKIT_DELPHI12_PAYLOAD';
  WIN32 = 'Win32';
  WIN64 = 'Win64';
  SEARCH_PATH_WIN32 = '$(BDSCOMMONDIR)\Dcp\Daikit\Win32';
  SEARCH_PATH_WIN64 = '$(BDSCOMMONDIR)\Dcp\Daikit\Win64';

function DocumentosPublicos: string;
var
  LBufferCaminho: array[0..MAX_PATH] of Char;
begin
  if SHGetFolderPath(0, CSIDL_COMMON_DOCUMENTS, 0, SHGFP_TYPE_CURRENT,
    LBufferCaminho) <> S_OK then
    raise EInstaladorDaikit.Create(
      'Nao foi possivel localizar os documentos publicos do Windows.');
  Result := LBufferCaminho;
end;

procedure ExcluirArquivo(const AArquivo: string);
begin
  if TFile.Exists(AArquivo) then
    TFile.Delete(AArquivo);
end;

procedure ExcluirDiretorio(const ADiretorio: string);
begin
  if not TDirectory.Exists(ADiretorio) then
    Exit;
  try
    TDirectory.Delete(ADiretorio, True);
  except
    on E: EDirectoryNotFoundException do
      Exit;
  end;
end;

{ TServicoInstalacaoDaikit }

constructor TServicoInstalacaoDaikit.Create;
begin
  inherited Create;
end;

class function TServicoInstalacaoDaikit.AdicionarCaminhoPesquisa(
  const AAtual, ACaminho: string): string;
begin
  Result := AjustarCaminho(AAtual, ACaminho, True);
end;

class function TServicoInstalacaoDaikit.AjustarCaminho(
  const AAtual, ACaminho: string; AAdicionar: Boolean): string;
var
  LItem: string;
  LItens: TStringList;
  LResultado: TStringList;
begin
  LItens := TStringList.Create;
  LResultado := TStringList.Create;
  try
    LItens.StrictDelimiter := True;
    LItens.Delimiter := ';';
    LItens.DelimitedText := AAtual;
    for LItem in LItens do
      if not LItem.Trim.IsEmpty and
        not SameText(ExcludeTrailingPathDelimiter(LItem.Trim),
          ExcludeTrailingPathDelimiter(ACaminho.Trim)) then
        LResultado.Add(LItem.Trim);
    if AAdicionar and not ACaminho.Trim.IsEmpty then
      LResultado.Add(ACaminho.Trim);
    Result := '';
    for LItem in LResultado do
      if Result.IsEmpty then
        Result := LItem
      else
        Result := Result + ';' + LItem;
  finally
    LResultado.Free;
    LItens.Free;
  end;
end;

procedure TServicoInstalacaoDaikit.AtualizarSearchPath(
  const APlataforma: string; AAdicionar: Boolean);
var
  LCaminho: string;
  LValor: string;
begin
  if SameText(APlataforma, WIN64) then
    LCaminho := SEARCH_PATH_WIN64
  else
    LCaminho := SEARCH_PATH_WIN32;
  LValor := LerSearchPath(APlataforma);
  if AAdicionar then
    LValor := AdicionarCaminhoPesquisa(LValor, LCaminho)
  else
    LValor := RemoverCaminhoPesquisa(LValor, LCaminho);
  EscreverSearchPath(APlataforma, LValor);
end;

function TServicoInstalacaoDaikit.ChaveBDSExiste: Boolean;
var
  LRegistroWindows: TRegistry;
begin
  LRegistroWindows := TRegistry.Create(KEY_READ or KEY_WOW64_32KEY);
  try
    LRegistroWindows.RootKey := HKEY_CURRENT_USER;
    Result := LRegistroWindows.KeyExists(CHAVE_BDS);
    if Result then
      Exit;
    LRegistroWindows.RootKey := HKEY_LOCAL_MACHINE;
    Result := LRegistroWindows.KeyExists(CHAVE_BDS);
  finally
    LRegistroWindows.Free;
  end;
end;

procedure TServicoInstalacaoDaikit.CopiarDiretorio(
  const AOrigem, ADestino: string);
var
  LArquivo: string;
begin
  ForceDirectories(ADestino);
  for LArquivo in TDirectory.GetFiles(AOrigem, '*',
    TSearchOption.soTopDirectoryOnly) do
    TFile.Copy(LArquivo, TPath.Combine(ADestino,
      TPath.GetFileName(LArquivo)), True);
end;

procedure TServicoInstalacaoDaikit.Desinstalar;
begin
  ExigirIDEFechada;
  RemoverRegistroPacote;
  AtualizarSearchPath(WIN32, False);
  AtualizarSearchPath(WIN64, False);
  ExcluirInstalacao;
end;

function TServicoInstalacaoDaikit.DiretorioBPL: string;
begin
  Result := TPath.Combine(DiretorioComum, 'Bpl');
end;

function TServicoInstalacaoDaikit.DiretorioComum: string;
begin
  Result := GetEnvironmentVariable('BDSCOMMONDIR');
  if Result.IsEmpty then
    Result := TPath.Combine(DocumentosPublicos,
      'Embarcadero\Studio\' + VERSAO_BDS);
end;

function TServicoInstalacaoDaikit.DiretorioDCP(
  const APlataforma: string): string;
begin
  Result := TPath.Combine(TPath.Combine(DiretorioComum,
    'Dcp\Daikit'), APlataforma);
end;

procedure TServicoInstalacaoDaikit.EscreverSearchPath(
  const APlataforma, AValor: string);
var
  LRegistroWindows: TRegistry;
begin
  LRegistroWindows := TRegistry.Create(KEY_READ or KEY_WRITE or KEY_WOW64_32KEY);
  try
    LRegistroWindows.RootKey := HKEY_CURRENT_USER;
    if not LRegistroWindows.OpenKey(CHAVE_BDS + '\Library\' + APlataforma,
      True) then
      raise EInstaladorDaikit.Create(
        'Nao foi possivel atualizar o Search Path do Delphi.');
    LRegistroWindows.WriteString('Search Path', AValor);
  finally
    LRegistroWindows.Free;
  end;
end;

procedure TServicoInstalacaoDaikit.ExcluirInstalacao;
var
  LCaminhoBPL: string;
begin
  LCaminhoBPL := DiretorioBPL;
  ExcluirArquivo(TPath.Combine(LCaminhoBPL, PACOTE_DESIGN));
  ExcluirArquivo(TPath.Combine(LCaminhoBPL, PACOTE_RUNTIME));
  ExcluirArquivo(TPath.Combine(TPath.Combine(LCaminhoBPL, WIN64),
    PACOTE_RUNTIME));
  ExcluirDiretorio(TPath.Combine(TPath.Combine(DiretorioComum,
    'Dcp'), 'Daikit'));
end;

procedure TServicoInstalacaoDaikit.ExigirIDEFechada;
begin
  if IDEEmExecucao then
    raise EInstaladorDaikit.Create(
      'Feche todas as instancias do Delphi antes de continuar.');
end;

procedure TServicoInstalacaoDaikit.ExtrairPayload(
  const ADestino: string);
var
  LStreamRecurso: TResourceStream;
  LCaminhoArquivoZIP: string;
begin
  if not PayloadDisponivel then
    raise EInstaladorDaikit.Create(
      'Payload ausente. Reconstrua o instalador com Construir.ps1.');
  ForceDirectories(ADestino);
  LCaminhoArquivoZIP := TPath.Combine(ADestino, 'Daikit.Delphi12.zip');
  LStreamRecurso := TResourceStream.Create(HInstance, RECURSO_PAYLOAD, RT_RCDATA);
  try
    LStreamRecurso.SaveToFile(LCaminhoArquivoZIP);
  finally
    LStreamRecurso.Free;
  end;
  TZipFile.ExtractZipFile(LCaminhoArquivoZIP, ADestino);
  ExcluirArquivo(LCaminhoArquivoZIP);
end;

class function TServicoInstalacaoDaikit.IDEEmExecucao: Boolean;
var
  LEntradaProcesso: TProcessEntry32;
  LSnapshotProcessos: THandle;
begin
  Result := False;
  LSnapshotProcessos := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if LSnapshotProcessos = INVALID_HANDLE_VALUE then
    Exit;
  try
    ZeroMemory(@LEntradaProcesso, SizeOf(LEntradaProcesso));
    LEntradaProcesso.dwSize := SizeOf(LEntradaProcesso);
    if Process32First(LSnapshotProcessos, LEntradaProcesso) then
      repeat
        if SameText(ExtractFileName(LEntradaProcesso.szExeFile), 'bds.exe') then
          Exit(True);
      until not Process32Next(LSnapshotProcessos, LEntradaProcesso);
  finally
    CloseHandle(LSnapshotProcessos);
  end;
end;

procedure TServicoInstalacaoDaikit.Instalar;
var
  LCaminhoBPL: string;
  LCaminhoTemporario: string;
begin
  ExigirIDEFechada;
  if not ChaveBDSExiste then
    raise EInstaladorDaikit.Create(
      'Delphi 12 (BDS 23.0) nao foi localizado.');
  LCaminhoTemporario := TPath.Combine(TPath.GetTempPath,
    'Daikit-' + TGUID.NewGuid.ToString.Replace('{', '').Replace('}', ''));
  try
    try
      ExtrairPayload(LCaminhoTemporario);
      ValidarPayload(LCaminhoTemporario);
      LCaminhoBPL := DiretorioBPL;
      CopiarDiretorio(TPath.Combine(LCaminhoTemporario, 'Win32\Bpl'), LCaminhoBPL);
      CopiarDiretorio(TPath.Combine(LCaminhoTemporario, 'Win64\Bpl'),
        TPath.Combine(LCaminhoBPL, WIN64));
      CopiarDiretorio(TPath.Combine(LCaminhoTemporario, 'Win32\Dcp'),
        DiretorioDCP(WIN32));
      CopiarDiretorio(TPath.Combine(LCaminhoTemporario, 'Win64\Dcp'),
        DiretorioDCP(WIN64));
      AtualizarSearchPath(WIN32, True);
      AtualizarSearchPath(WIN64, True);
      RegistrarPacote(TPath.Combine(LCaminhoBPL, PACOTE_DESIGN));
    except
      RemoverRegistroPacote;
      AtualizarSearchPath(WIN32, False);
      AtualizarSearchPath(WIN64, False);
      ExcluirInstalacao;
      raise;
    end;
  finally
    ExcluirDiretorio(LCaminhoTemporario);
  end;
end;

function TServicoInstalacaoDaikit.LerSearchPath(
  const APlataforma: string): string;
var
  LChaveRegistro: string;
  LRegistroWindows: TRegistry;
begin
  Result := '';
  LChaveRegistro := CHAVE_BDS + '\Library\' + APlataforma;
  LRegistroWindows := TRegistry.Create(KEY_READ or KEY_WOW64_32KEY);
  try
    LRegistroWindows.RootKey := HKEY_CURRENT_USER;
    if LRegistroWindows.OpenKeyReadOnly(LChaveRegistro) and
      LRegistroWindows.ValueExists('Search Path') then
      Exit(LRegistroWindows.ReadString('Search Path'));
    LRegistroWindows.CloseKey;
    LRegistroWindows.RootKey := HKEY_LOCAL_MACHINE;
    if LRegistroWindows.OpenKeyReadOnly(LChaveRegistro) and
      LRegistroWindows.ValueExists('Search Path') then
      Result := LRegistroWindows.ReadString('Search Path');
  finally
    LRegistroWindows.Free;
  end;
end;

function TServicoInstalacaoDaikit.ObterEstado: TEstadoInstalacaoDaikit;
begin
  Result.DelphiInstalado := ChaveBDSExiste;
  Result.IDEEmExecucao := IDEEmExecucao;
  Result.ArtefatosDisponiveis := PayloadDisponivel;
  Result.PacoteRegistrado := PacoteRegistrado;
  Result.DiretorioBPL := DiretorioBPL;
  if not Result.DelphiInstalado then
    Result.Descricao := 'Delphi 12 nao localizado'
  else if Result.IDEEmExecucao then
    Result.Descricao := 'Feche o Delphi para alterar a instalacao'
  else if not Result.ArtefatosDisponiveis then
    Result.Descricao := 'Payload ausente: execute Construir.ps1'
  else if Result.PacoteRegistrado then
    Result.Descricao := 'Daikit instalado no Delphi 12'
  else
    Result.Descricao := 'Pronto para instalar';
end;

function TServicoInstalacaoDaikit.PacoteRegistrado: Boolean;
var
  LCaminho: string;
  LRegistroWindows: TRegistry;
begin
  LCaminho := TPath.Combine(DiretorioBPL, PACOTE_DESIGN);
  LRegistroWindows := TRegistry.Create(KEY_READ or KEY_WOW64_32KEY);
  try
    LRegistroWindows.RootKey := HKEY_CURRENT_USER;
    Result := LRegistroWindows.OpenKeyReadOnly(CHAVE_PACOTES) and
      LRegistroWindows.ValueExists(LCaminho) and TFile.Exists(LCaminho);
  finally
    LRegistroWindows.Free;
  end;
end;

function TServicoInstalacaoDaikit.PayloadDisponivel: Boolean;
begin
  Result := FindResource(HInstance, RECURSO_PAYLOAD, RT_RCDATA) <> 0;
end;

procedure TServicoInstalacaoDaikit.RegistrarPacote(
  const ACaminho: string);
var
  LRegistroWindows: TRegistry;
begin
  LRegistroWindows := TRegistry.Create(KEY_READ or KEY_WRITE or KEY_WOW64_32KEY);
  try
    LRegistroWindows.RootKey := HKEY_CURRENT_USER;
    if not LRegistroWindows.OpenKey(CHAVE_PACOTES, True) then
      raise EInstaladorDaikit.Create(
        'Nao foi possivel registrar o pacote no Delphi.');
    LRegistroWindows.WriteString(ACaminho, DESCRICAO_PACOTE);
  finally
    LRegistroWindows.Free;
  end;
end;

class function TServicoInstalacaoDaikit.RemoverCaminhoPesquisa(
  const AAtual, ACaminho: string): string;
begin
  Result := AjustarCaminho(AAtual, ACaminho, False);
end;

procedure TServicoInstalacaoDaikit.RemoverRegistroPacote;
var
  LCaminho: string;
  LRegistroWindows: TRegistry;
begin
  LCaminho := TPath.Combine(DiretorioBPL, PACOTE_DESIGN);
  LRegistroWindows := TRegistry.Create(KEY_READ or KEY_WRITE or KEY_WOW64_32KEY);
  try
    LRegistroWindows.RootKey := HKEY_CURRENT_USER;
    if LRegistroWindows.OpenKey(CHAVE_PACOTES, False) and
      LRegistroWindows.ValueExists(LCaminho) then
      LRegistroWindows.DeleteValue(LCaminho);
  finally
    LRegistroWindows.Free;
  end;
end;

procedure TServicoInstalacaoDaikit.ValidarPayload(
  const ADiretorio: string);

  procedure Exigir(const ACaminho: string);
  begin
    if not TFile.Exists(TPath.Combine(ADiretorio, ACaminho)) then
      raise EInstaladorDaikit.CreateFmt(
        'Payload incompleto: "%s" nao foi encontrado.', [ACaminho]);
  end;

begin
  Exigir('Win32\Bpl\' + PACOTE_RUNTIME);
  Exigir('Win32\Bpl\' + PACOTE_DESIGN);
  Exigir('Win32\Dcp\' + PACOTE_DCP);
  Exigir('Win32\Dcp\' + DCU_VALIDACAO);
  Exigir('Win64\Bpl\' + PACOTE_RUNTIME);
  Exigir('Win64\Dcp\' + PACOTE_DCP);
  Exigir('Win64\Dcp\' + DCU_VALIDACAO);
end;

end.
