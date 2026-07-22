unit Daikit.Infraestrutura.HTTP.Modelos;

interface

uses
  Daikit.Infraestrutura.HTTP.Constantes,
  Daikit.Infraestrutura.HTTP.Interfaces;

type
  TOpcoesRequisicaoHTTP = record
    Metodo: TMetodoHTTP;
    URL: string;
    Cabecalhos: TArray<TCabecalhoHTTP>;
    Corpo: string;
    TimeoutConexaoMS: Integer;
    TimeoutRespostaMS: Integer;
    LimiteRespostaBytes: Int64;
    class function Padrao: TOpcoesRequisicaoHTTP; static;
  end;

  TRequisicaoHTTP = class(TInterfacedObject, IRequisicaoHTTP)
  private
    FMetodoHTTP: TMetodoHTTP;
    FURL: string;
    FCabecalhosHTTP: TArray<TCabecalhoHTTP>;
    FCorpoHTTP: string;
    FTimeoutConexaoMS: Integer;
    FTimeoutRespostaMS: Integer;
    FLimiteRespostaBytes: Int64;
    function ObterMetodo: TMetodoHTTP;
    function ObterURL: string;
    function ObterCabecalhos: TArray<TCabecalhoHTTP>;
    function ObterCorpo: string;
    function ObterTimeoutConexaoMS: Integer;
    function ObterTimeoutRespostaMS: Integer;
    function ObterLimiteRespostaBytes: Int64;
  public
    constructor Create(const AOpcoes: TOpcoesRequisicaoHTTP);
  end;

  TRespostaHTTP = class(TInterfacedObject, IRespostaHTTP)
  private
    FStatusHTTP: Integer;
    FMotivoHTTP: string;
    FCabecalhosHTTP: TArray<TCabecalhoHTTP>;
    FCorpoHTTP: string;
    function ObterStatus: Integer;
    function ObterMotivo: string;
    function ObterCabecalhos: TArray<TCabecalhoHTTP>;
    function ObterCorpo: string;
    function ObterFoiSucesso: Boolean;
  public
    constructor Create(AStatus: Integer; const AMotivo: string;
      const ACabecalhos: TArray<TCabecalhoHTTP>; const ACorpo: string);
  end;

implementation

uses
  System.SysUtils,
  System.Net.URLClient,
  Daikit.Infraestrutura.HTTP.Excecoes;

procedure ValidarURL(const AURL: string);
var
  LURI: TURI;
begin
  try
    LURI := TURI.Create(AURL);
  except
    on E: Exception do
      raise EValidacaoHTTP.Create('A URL da requisicao possui formato invalido.');
  end;

  if not SameText(LURI.Scheme, 'http') and
    not SameText(LURI.Scheme, 'https') then
    raise EValidacaoHTTP.Create('A URL deve utilizar HTTP ou HTTPS.');
  if Trim(LURI.Host) = '' then
    raise EValidacaoHTTP.Create('A URL da requisicao deve possuir um host.');
end;

procedure CopiarEValidarCabecalhos(const AOrigem: TArray<TCabecalhoHTTP>;
  out ADestino: TArray<TCabecalhoHTTP>);
var
  I: Integer;
begin
  SetLength(ADestino, Length(AOrigem));
  for I := Low(AOrigem) to High(AOrigem) do
  begin
    if Trim(AOrigem[I].Nome) = '' then
      raise EValidacaoHTTP.CreateFmt(
        'O cabecalho no indice %d deve possuir um nome.', [I]);
    if AOrigem[I].Nome.IndexOfAny([CCaractereRetornoCarro,
      CCaractereNovaLinha]) >= 0 then
      raise EValidacaoHTTP.CreateFmt(
        'O nome do cabecalho no indice %d possui caractere invalido.', [I]);
    if AOrigem[I].Valor.IndexOfAny([CCaractereRetornoCarro,
      CCaractereNovaLinha]) >= 0 then
      raise EValidacaoHTTP.CreateFmt(
        'O valor do cabecalho no indice %d possui caractere invalido.', [I]);
    ADestino[I] := AOrigem[I];
  end;
end;

{ TRequisicaoHTTP }

class function TOpcoesRequisicaoHTTP.Padrao: TOpcoesRequisicaoHTTP;
begin
  Result.Metodo := TMetodoHTTP.Get;
  Result.URL := '';
  Result.Cabecalhos := nil;
  Result.Corpo := '';
  Result.TimeoutConexaoMS := CTimeoutConexaoPadraoMS;
  Result.TimeoutRespostaMS := CTimeoutRespostaPadraoMS;
  Result.LimiteRespostaBytes := CLimiteRespostaPadraoBytes;
end;

constructor TRequisicaoHTTP.Create(const AOpcoes: TOpcoesRequisicaoHTTP);
begin
  inherited Create;
  if Trim(AOpcoes.URL) = '' then
    raise EValidacaoHTTP.Create('A URL da requisicao deve ser informada.');
  if Length(AOpcoes.URL) > CLimiteURLCaracteres then
    raise EValidacaoHTTP.Create('A URL da requisicao excede o limite permitido.');
  ValidarURL(AOpcoes.URL);
  if TEncoding.UTF8.GetByteCount(AOpcoes.Corpo) >
    CLimiteCorpoRequisicaoBytes then
    raise EValidacaoHTTP.Create('O corpo da requisicao excede o limite permitido.');
  if AOpcoes.TimeoutConexaoMS <= 0 then
    raise EValidacaoHTTP.Create('O timeout de conexao deve ser maior que zero.');
  if AOpcoes.TimeoutRespostaMS <= 0 then
    raise EValidacaoHTTP.Create('O timeout de resposta deve ser maior que zero.');
  if AOpcoes.LimiteRespostaBytes <= 0 then
    raise EValidacaoHTTP.Create('O limite da resposta deve ser maior que zero.');

  FMetodoHTTP := AOpcoes.Metodo;
  FURL := AOpcoes.URL;
  CopiarEValidarCabecalhos(AOpcoes.Cabecalhos, FCabecalhosHTTP);
  FCorpoHTTP := AOpcoes.Corpo;
  FTimeoutConexaoMS := AOpcoes.TimeoutConexaoMS;
  FTimeoutRespostaMS := AOpcoes.TimeoutRespostaMS;
  FLimiteRespostaBytes := AOpcoes.LimiteRespostaBytes;
end;

function TRequisicaoHTTP.ObterCabecalhos: TArray<TCabecalhoHTTP>;
begin
  Result := Copy(FCabecalhosHTTP);
end;

function TRequisicaoHTTP.ObterCorpo: string;
begin
  Result := FCorpoHTTP;
end;

function TRequisicaoHTTP.ObterLimiteRespostaBytes: Int64;
begin
  Result := FLimiteRespostaBytes;
end;

function TRequisicaoHTTP.ObterMetodo: TMetodoHTTP;
begin
  Result := FMetodoHTTP;
end;

function TRequisicaoHTTP.ObterTimeoutConexaoMS: Integer;
begin
  Result := FTimeoutConexaoMS;
end;

function TRequisicaoHTTP.ObterTimeoutRespostaMS: Integer;
begin
  Result := FTimeoutRespostaMS;
end;

function TRequisicaoHTTP.ObterURL: string;
begin
  Result := FURL;
end;

{ TRespostaHTTP }

constructor TRespostaHTTP.Create(AStatus: Integer; const AMotivo: string;
  const ACabecalhos: TArray<TCabecalhoHTTP>; const ACorpo: string);
begin
  inherited Create;
  if (AStatus < CStatusHTTPMinimo) or (AStatus > CStatusHTTPMaximo) then
    raise EValidacaoHTTP.Create('O status HTTP informado e invalido.');
  FStatusHTTP := AStatus;
  FMotivoHTTP := AMotivo;
  CopiarEValidarCabecalhos(ACabecalhos, FCabecalhosHTTP);
  FCorpoHTTP := ACorpo;
end;

function TRespostaHTTP.ObterCabecalhos: TArray<TCabecalhoHTTP>;
begin
  Result := Copy(FCabecalhosHTTP);
end;

function TRespostaHTTP.ObterCorpo: string;
begin
  Result := FCorpoHTTP;
end;

function TRespostaHTTP.ObterFoiSucesso: Boolean;
begin
  Result := (FStatusHTTP >= CStatusHTTPSucessoMinimo) and
    (FStatusHTTP <= CStatusHTTPSucessoMaximo);
end;

function TRespostaHTTP.ObterMotivo: string;
begin
  Result := FMotivoHTTP;
end;

function TRespostaHTTP.ObterStatus: Integer;
begin
  Result := FStatusHTTP;
end;

end.
