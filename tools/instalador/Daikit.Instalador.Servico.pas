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
  LBuffer: array[0..MAX_PATH] of Char;
begin
  if SHGetFolderPath(0, CSIDL_COMMON_DOCUMENTS, 0, SHGFP_TYPE_CURRENT,
    LBuffer) <> S_OK then
    raise EInstaladorDaikit.Create(
      'Nao foi possivel localizar os documentos publicos do Windows.');
  Result := LBuffer;
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
  LRegistro: TRegistry;
begin
  LRegistro := TRegistry.Create(KEY_READ or KEY_WOW64_32KEY);
  try
    LRegistro.RootKey := HKEY_CURRENT_USER;
    Result := LRegistro.KeyExists(CHAVE_BDS);
    if Result then
      Exit;
    LRegistro.RootKey := HKEY_LOCAL_MACHINE;
    Result := LRegistro.KeyExists(CHAVE_BDS);
  finally
    LRegistro.Free;
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
  LRegistro: TRegistry;
begin
  LRegistro := TRegistry.Create(KEY_READ or KEY_WRITE or KEY_WOW64_32KEY);
  try
    LRegistro.RootKey := HKEY_CURRENT_USER;
    if not LRegistro.OpenKey(CHAVE_BDS + '\Library\' + APlataforma,
      True) then
      raise EInstaladorDaikit.Create(
        'Nao foi possivel atualizar o Search Path do Delphi.');
    LRegistro.WriteString('Search Path', AValor);
  finally
    LRegistro.Free;
  end;
end;

procedure TServicoInstalacaoDaikit.ExcluirInstalacao;
var
  LBPL: string;
begin
  LBPL := DiretorioBPL;
  ExcluirArquivo(TPath.Combine(LBPL, PACOTE_DESIGN));
  ExcluirArquivo(TPath.Combine(LBPL, PACOTE_RUNTIME));
  ExcluirArquivo(TPath.Combine(TPath.Combine(LBPL, WIN64),
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
  LRecurso: TResourceStream;
  LZip: string;
begin
  if not PayloadDisponivel then
    raise EInstaladorDaikit.Create(
      'Payload ausente. Reconstrua o instalador com Construir.ps1.');
  ForceDirectories(ADestino);
  LZip := TPath.Combine(ADestino, 'Daikit.Delphi12.zip');
  LRecurso := TResourceStream.Create(HInstance, RECURSO_PAYLOAD, RT_RCDATA);
  try
    LRecurso.SaveToFile(LZip);
  finally
    LRecurso.Free;
  end;
  TZipFile.ExtractZipFile(LZip, ADestino);
  ExcluirArquivo(LZip);
end;

class function TServicoInstalacaoDaikit.IDEEmExecucao: Boolean;
var
  LEntrada: TProcessEntry32;
  LSnapshot: THandle;
begin
  Result := False;
  LSnapshot := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if LSnapshot = INVALID_HANDLE_VALUE then
    Exit;
  try
    ZeroMemory(@LEntrada, SizeOf(LEntrada));
    LEntrada.dwSize := SizeOf(LEntrada);
    if Process32First(LSnapshot, LEntrada) then
      repeat
        if SameText(ExtractFileName(LEntrada.szExeFile), 'bds.exe') then
          Exit(True);
      until not Process32Next(LSnapshot, LEntrada);
  finally
    CloseHandle(LSnapshot);
  end;
end;

procedure TServicoInstalacaoDaikit.Instalar;
var
  LBPL: string;
  LTemporario: string;
begin
  ExigirIDEFechada;
  if not ChaveBDSExiste then
    raise EInstaladorDaikit.Create(
      'Delphi 12 (BDS 23.0) nao foi localizado.');
  LTemporario := TPath.Combine(TPath.GetTempPath,
    'Daikit-' + TGUID.NewGuid.ToString.Replace('{', '').Replace('}', ''));
  try
    try
      ExtrairPayload(LTemporario);
      ValidarPayload(LTemporario);
      LBPL := DiretorioBPL;
      CopiarDiretorio(TPath.Combine(LTemporario, 'Win32\Bpl'), LBPL);
      CopiarDiretorio(TPath.Combine(LTemporario, 'Win64\Bpl'),
        TPath.Combine(LBPL, WIN64));
      CopiarDiretorio(TPath.Combine(LTemporario, 'Win32\Dcp'),
        DiretorioDCP(WIN32));
      CopiarDiretorio(TPath.Combine(LTemporario, 'Win64\Dcp'),
        DiretorioDCP(WIN64));
      AtualizarSearchPath(WIN32, True);
      AtualizarSearchPath(WIN64, True);
      RegistrarPacote(TPath.Combine(LBPL, PACOTE_DESIGN));
    except
      RemoverRegistroPacote;
      AtualizarSearchPath(WIN32, False);
      AtualizarSearchPath(WIN64, False);
      ExcluirInstalacao;
      raise;
    end;
  finally
    ExcluirDiretorio(LTemporario);
  end;
end;

function TServicoInstalacaoDaikit.LerSearchPath(
  const APlataforma: string): string;
var
  LChave: string;
  LRegistro: TRegistry;
begin
  Result := '';
  LChave := CHAVE_BDS + '\Library\' + APlataforma;
  LRegistro := TRegistry.Create(KEY_READ or KEY_WOW64_32KEY);
  try
    LRegistro.RootKey := HKEY_CURRENT_USER;
    if LRegistro.OpenKeyReadOnly(LChave) and
      LRegistro.ValueExists('Search Path') then
      Exit(LRegistro.ReadString('Search Path'));
    LRegistro.CloseKey;
    LRegistro.RootKey := HKEY_LOCAL_MACHINE;
    if LRegistro.OpenKeyReadOnly(LChave) and
      LRegistro.ValueExists('Search Path') then
      Result := LRegistro.ReadString('Search Path');
  finally
    LRegistro.Free;
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
  LRegistro: TRegistry;
begin
  LCaminho := TPath.Combine(DiretorioBPL, PACOTE_DESIGN);
  LRegistro := TRegistry.Create(KEY_READ or KEY_WOW64_32KEY);
  try
    LRegistro.RootKey := HKEY_CURRENT_USER;
    Result := LRegistro.OpenKeyReadOnly(CHAVE_PACOTES) and
      LRegistro.ValueExists(LCaminho) and TFile.Exists(LCaminho);
  finally
    LRegistro.Free;
  end;
end;

function TServicoInstalacaoDaikit.PayloadDisponivel: Boolean;
begin
  Result := FindResource(HInstance, RECURSO_PAYLOAD, RT_RCDATA) <> 0;
end;

procedure TServicoInstalacaoDaikit.RegistrarPacote(
  const ACaminho: string);
var
  LRegistro: TRegistry;
begin
  LRegistro := TRegistry.Create(KEY_READ or KEY_WRITE or KEY_WOW64_32KEY);
  try
    LRegistro.RootKey := HKEY_CURRENT_USER;
    if not LRegistro.OpenKey(CHAVE_PACOTES, True) then
      raise EInstaladorDaikit.Create(
        'Nao foi possivel registrar o pacote no Delphi.');
    LRegistro.WriteString(ACaminho, DESCRICAO_PACOTE);
  finally
    LRegistro.Free;
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
  LRegistro: TRegistry;
begin
  LCaminho := TPath.Combine(DiretorioBPL, PACOTE_DESIGN);
  LRegistro := TRegistry.Create(KEY_READ or KEY_WRITE or KEY_WOW64_32KEY);
  try
    LRegistro.RootKey := HKEY_CURRENT_USER;
    if LRegistro.OpenKey(CHAVE_PACOTES, False) and
      LRegistro.ValueExists(LCaminho) then
      LRegistro.DeleteValue(LCaminho);
  finally
    LRegistro.Free;
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
