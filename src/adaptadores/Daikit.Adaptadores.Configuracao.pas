unit Daikit.Adaptadores.Configuracao;

interface

uses
  System.SysUtils,
  Daikit.Infraestrutura.HTTP.Constantes,
  Daikit.Adaptadores.Interfaces;

type
  TClasseExcecaoConfiguracaoAdaptadorIA = class of Exception;

  TOpcoesConfiguracaoAdaptadorIA = record
    Endpoint: string;
    EndpointModelos: string;
    ModeloPadrao: string;
    TimeoutConexaoMS: Integer;
    TimeoutRespostaMS: Integer;
    LimiteRespostaBytes: Int64;
    class function Padrao(const AEndpoint, AEndpointModelos,
      AModeloPadrao: string): TOpcoesConfiguracaoAdaptadorIA; static;
  end;

  TConfiguracaoAdaptadorIA = class abstract(TInterfacedObject,
    IConfiguracaoAdaptadorIA)
  private
    FEndpoint: string;
    FEndpointModelos: string;
    FModeloPadrao: string;
    FTimeoutConexaoMS: Integer;
    FTimeoutRespostaMS: Integer;
    FLimiteRespostaBytes: Int64;
  protected
    constructor Create(const ANomeAdaptador: string;
      const AOpcoes: TOpcoesConfiguracaoAdaptadorIA;
      AClasseExcecao: TClasseExcecaoConfiguracaoAdaptadorIA);
  public
    function ObterEndpoint: string;
    function ObterEndpointModelos: string;
    function ObterModeloPadrao: string;
    function ObterTimeoutConexaoMS: Integer;
    function ObterTimeoutRespostaMS: Integer;
    function ObterLimiteRespostaBytes: Int64;
  end;

implementation

uses
  System.Net.URLClient;

class function TOpcoesConfiguracaoAdaptadorIA.Padrao(const AEndpoint,
  AEndpointModelos, AModeloPadrao: string): TOpcoesConfiguracaoAdaptadorIA;
begin
  Result.Endpoint := AEndpoint;
  Result.EndpointModelos := AEndpointModelos;
  Result.ModeloPadrao := AModeloPadrao;
  Result.TimeoutConexaoMS := CTimeoutConexaoPadraoMS;
  Result.TimeoutRespostaMS := CTimeoutRespostaPadraoMS;
  Result.LimiteRespostaBytes := CLimiteRespostaPadraoBytes;
end;

constructor TConfiguracaoAdaptadorIA.Create(const ANomeAdaptador: string;
  const AOpcoes: TOpcoesConfiguracaoAdaptadorIA;
  AClasseExcecao: TClasseExcecaoConfiguracaoAdaptadorIA);
var
  LURI: TURI;
begin
  inherited Create;
  if Trim(AOpcoes.Endpoint) = '' then
    raise AClasseExcecao.CreateFmt(
      'O endpoint %s deve ser informado.', [ANomeAdaptador]);
  try
    LURI := TURI.Create(AOpcoes.Endpoint);
  except
    on E: Exception do
      raise AClasseExcecao.CreateFmt(
        'O endpoint %s possui formato invalido.', [ANomeAdaptador]);
  end;
  if not SameText(LURI.Scheme, 'https') or (Trim(LURI.Host) = '') then
    raise AClasseExcecao.CreateFmt(
      'O endpoint %s deve possuir host e utilizar HTTPS.', [ANomeAdaptador]);
  if Trim(AOpcoes.ModeloPadrao) = '' then
    raise AClasseExcecao.CreateFmt(
      'O modelo padrao %s deve ser informado.', [ANomeAdaptador]);
  if Trim(AOpcoes.EndpointModelos) = '' then
    raise AClasseExcecao.CreateFmt(
      'O endpoint de modelos %s deve ser informado.', [ANomeAdaptador]);
  try
    LURI := TURI.Create(AOpcoes.EndpointModelos);
  except
    on E: Exception do
      raise AClasseExcecao.CreateFmt(
        'O endpoint de modelos %s possui formato invalido.', [ANomeAdaptador]);
  end;
  if not SameText(LURI.Scheme, 'https') or (Trim(LURI.Host) = '') then
    raise AClasseExcecao.CreateFmt(
      'O endpoint de modelos %s deve possuir host e utilizar HTTPS.',
      [ANomeAdaptador]);
  if AOpcoes.TimeoutConexaoMS <= 0 then
    raise AClasseExcecao.Create(
      'O timeout de conexao deve ser maior que zero.');
  if AOpcoes.TimeoutRespostaMS <= 0 then
    raise AClasseExcecao.Create(
      'O timeout de resposta deve ser maior que zero.');
  if AOpcoes.LimiteRespostaBytes <= 0 then
    raise AClasseExcecao.Create(
      'O limite da resposta deve ser maior que zero.');
  FEndpoint := AOpcoes.Endpoint;
  FEndpointModelos := AOpcoes.EndpointModelos;
  FModeloPadrao := AOpcoes.ModeloPadrao;
  FTimeoutConexaoMS := AOpcoes.TimeoutConexaoMS;
  FTimeoutRespostaMS := AOpcoes.TimeoutRespostaMS;
  FLimiteRespostaBytes := AOpcoes.LimiteRespostaBytes;
end;

function TConfiguracaoAdaptadorIA.ObterEndpoint: string;
begin
  Result := FEndpoint;
end;

function TConfiguracaoAdaptadorIA.ObterEndpointModelos: string;
begin
  Result := FEndpointModelos;
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
