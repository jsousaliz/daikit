unit Daikit.Infraestrutura.HTTP.Modelos;

interface

uses
  Daikit.Infraestrutura.HTTP.Constantes,
  Daikit.Infraestrutura.HTTP.Interfaces;

type
  TRequisicaoHTTP = class(TInterfacedObject, IRequisicaoHTTP)
  private
    FMetodo: TMetodoHTTP;
    FURL: string;
    FCabecalhos: TArray<TCabecalhoHTTP>;
    FCorpo: string;
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
    constructor Create(AMetodo: TMetodoHTTP; const AURL: string;
      const ACabecalhos: TArray<TCabecalhoHTTP>; const ACorpo: string = '';
      ATimeoutConexaoMS: Integer = CTimeoutConexaoPadraoMS;
      ATimeoutRespostaMS: Integer = CTimeoutRespostaPadraoMS;
      ALimiteRespostaBytes: Int64 = CLimiteRespostaPadraoBytes);
  end;

  TRespostaHTTP = class(TInterfacedObject, IRespostaHTTP)
  private
    FStatus: Integer;
    FMotivo: string;
    FCabecalhos: TArray<TCabecalhoHTTP>;
    FCorpo: string;
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

constructor TRequisicaoHTTP.Create(AMetodo: TMetodoHTTP; const AURL: string;
  const ACabecalhos: TArray<TCabecalhoHTTP>; const ACorpo: string;
  ATimeoutConexaoMS, ATimeoutRespostaMS: Integer;
  ALimiteRespostaBytes: Int64);
begin
  inherited Create;
  if Trim(AURL) = '' then
    raise EValidacaoHTTP.Create('A URL da requisicao deve ser informada.');
  if Length(AURL) > CLimiteURLCaracteres then
    raise EValidacaoHTTP.Create('A URL da requisicao excede o limite permitido.');
  ValidarURL(AURL);
  if TEncoding.UTF8.GetByteCount(ACorpo) > CLimiteCorpoRequisicaoBytes then
    raise EValidacaoHTTP.Create('O corpo da requisicao excede o limite permitido.');
  if ATimeoutConexaoMS <= 0 then
    raise EValidacaoHTTP.Create('O timeout de conexao deve ser maior que zero.');
  if ATimeoutRespostaMS <= 0 then
    raise EValidacaoHTTP.Create('O timeout de resposta deve ser maior que zero.');
  if ALimiteRespostaBytes <= 0 then
    raise EValidacaoHTTP.Create('O limite da resposta deve ser maior que zero.');

  FMetodo := AMetodo;
  FURL := AURL;
  CopiarEValidarCabecalhos(ACabecalhos, FCabecalhos);
  FCorpo := ACorpo;
  FTimeoutConexaoMS := ATimeoutConexaoMS;
  FTimeoutRespostaMS := ATimeoutRespostaMS;
  FLimiteRespostaBytes := ALimiteRespostaBytes;
end;

function TRequisicaoHTTP.ObterCabecalhos: TArray<TCabecalhoHTTP>;
begin
  Result := Copy(FCabecalhos);
end;

function TRequisicaoHTTP.ObterCorpo: string;
begin
  Result := FCorpo;
end;

function TRequisicaoHTTP.ObterLimiteRespostaBytes: Int64;
begin
  Result := FLimiteRespostaBytes;
end;

function TRequisicaoHTTP.ObterMetodo: TMetodoHTTP;
begin
  Result := FMetodo;
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
  FStatus := AStatus;
  FMotivo := AMotivo;
  CopiarEValidarCabecalhos(ACabecalhos, FCabecalhos);
  FCorpo := ACorpo;
end;

function TRespostaHTTP.ObterCabecalhos: TArray<TCabecalhoHTTP>;
begin
  Result := Copy(FCabecalhos);
end;

function TRespostaHTTP.ObterCorpo: string;
begin
  Result := FCorpo;
end;

function TRespostaHTTP.ObterFoiSucesso: Boolean;
begin
  Result := (FStatus >= CStatusHTTPSucessoMinimo) and
    (FStatus <= CStatusHTTPSucessoMaximo);
end;

function TRespostaHTTP.ObterMotivo: string;
begin
  Result := FMotivo;
end;

function TRespostaHTTP.ObterStatus: Integer;
begin
  Result := FStatus;
end;

end.
