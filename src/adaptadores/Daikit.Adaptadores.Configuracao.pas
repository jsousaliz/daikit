unit Daikit.Adaptadores.Configuracao;

interface

uses
  System.SysUtils,
  Daikit.Adaptadores.Interfaces;

type
  TClasseExcecaoConfiguracaoAdaptadorIA = class of Exception;

  TConfiguracaoAdaptadorIA = class abstract(TInterfacedObject,
    IConfiguracaoAdaptadorIA)
  private
    FEndpoint: string;
    FModeloPadrao: string;
    FTimeoutConexaoMS: Integer;
    FTimeoutRespostaMS: Integer;
    FLimiteRespostaBytes: Int64;
  protected
    constructor Create(const ANomeAdaptador, AEndpoint,
      AModeloPadrao: string; ATimeoutConexaoMS, ATimeoutRespostaMS: Integer;
      ALimiteRespostaBytes: Int64;
      AClasseExcecao: TClasseExcecaoConfiguracaoAdaptadorIA);
  public
    function ObterEndpoint: string;
    function ObterModeloPadrao: string;
    function ObterTimeoutConexaoMS: Integer;
    function ObterTimeoutRespostaMS: Integer;
    function ObterLimiteRespostaBytes: Int64;
  end;

implementation

uses
  System.Net.URLClient;

constructor TConfiguracaoAdaptadorIA.Create(const ANomeAdaptador, AEndpoint,
  AModeloPadrao: string; ATimeoutConexaoMS, ATimeoutRespostaMS: Integer;
  ALimiteRespostaBytes: Int64;
  AClasseExcecao: TClasseExcecaoConfiguracaoAdaptadorIA);
var
  LURI: TURI;
begin
  inherited Create;
  if Trim(AEndpoint) = '' then
    raise AClasseExcecao.CreateFmt(
      'O endpoint %s deve ser informado.', [ANomeAdaptador]);
  try
    LURI := TURI.Create(AEndpoint);
  except
    on E: Exception do
      raise AClasseExcecao.CreateFmt(
        'O endpoint %s possui formato invalido.', [ANomeAdaptador]);
  end;
  if not SameText(LURI.Scheme, 'https') or (Trim(LURI.Host) = '') then
    raise AClasseExcecao.CreateFmt(
      'O endpoint %s deve possuir host e utilizar HTTPS.', [ANomeAdaptador]);
  if Trim(AModeloPadrao) = '' then
    raise AClasseExcecao.CreateFmt(
      'O modelo padrao %s deve ser informado.', [ANomeAdaptador]);
  if ATimeoutConexaoMS <= 0 then
    raise AClasseExcecao.Create(
      'O timeout de conexao deve ser maior que zero.');
  if ATimeoutRespostaMS <= 0 then
    raise AClasseExcecao.Create(
      'O timeout de resposta deve ser maior que zero.');
  if ALimiteRespostaBytes <= 0 then
    raise AClasseExcecao.Create(
      'O limite da resposta deve ser maior que zero.');
  FEndpoint := AEndpoint;
  FModeloPadrao := AModeloPadrao;
  FTimeoutConexaoMS := ATimeoutConexaoMS;
  FTimeoutRespostaMS := ATimeoutRespostaMS;
  FLimiteRespostaBytes := ALimiteRespostaBytes;
end;

function TConfiguracaoAdaptadorIA.ObterEndpoint: string;
begin
  Result := FEndpoint;
end;

function TConfiguracaoAdaptadorIA.ObterLimiteRespostaBytes: Int64;
begin
  Result := FLimiteRespostaBytes;
end;

function TConfiguracaoAdaptadorIA.ObterModeloPadrao: string;
begin
  Result := FModeloPadrao;
end;

function TConfiguracaoAdaptadorIA.ObterTimeoutConexaoMS: Integer;
begin
  Result := FTimeoutConexaoMS;
end;

function TConfiguracaoAdaptadorIA.ObterTimeoutRespostaMS: Integer;
begin
  Result := FTimeoutRespostaMS;
end;

end.
