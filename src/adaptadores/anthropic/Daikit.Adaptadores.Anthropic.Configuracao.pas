unit Daikit.Adaptadores.Anthropic.Configuracao;

interface

uses
  Daikit.Infraestrutura.HTTP.Constantes,
  Daikit.Adaptadores.Configuracao,
  Daikit.Adaptadores.Anthropic.Constantes,
  Daikit.Adaptadores.Anthropic.Interfaces;

type
  TConfiguracaoAnthropic = class(TConfiguracaoAdaptadorIA,
    IConfiguracaoAnthropic)
  private
    FVersaoAPI: string;
    FMaximoTokens: Integer;
    function ObterVersaoAPI: string;
    function ObterMaximoTokens: Integer;
  public
    constructor Create(const AEndpoint: string = CEndpointMensagensAnthropic;
      const AModeloPadrao: string = CModeloAnthropicPadrao;
      const AVersaoAPI: string = CVersaoAPIAnthropic;
      AMaximoTokens: Integer = CMaximoTokensSaidaPadraoAnthropic;
      ATimeoutConexaoMS: Integer = CTimeoutConexaoPadraoMS;
      ATimeoutRespostaMS: Integer = CTimeoutRespostaPadraoMS;
      ALimiteRespostaBytes: Int64 = CLimiteRespostaPadraoBytes);
  end;

implementation

uses
  System.SysUtils,
  Daikit.Adaptadores.Anthropic.Excecoes;

constructor TConfiguracaoAnthropic.Create(const AEndpoint, AModeloPadrao,
  AVersaoAPI: string; AMaximoTokens, ATimeoutConexaoMS,
  ATimeoutRespostaMS: Integer; ALimiteRespostaBytes: Int64);
begin
  inherited Create('Anthropic', AEndpoint, AModeloPadrao,
    ATimeoutConexaoMS, ATimeoutRespostaMS, ALimiteRespostaBytes,
    EConfiguracaoAnthropic);
  if Trim(AVersaoAPI) = '' then
    raise EConfiguracaoAnthropic.Create(
      'A versao da API Anthropic deve ser informada.');
  if AMaximoTokens <= 0 then
    raise EConfiguracaoAnthropic.Create(
      'O maximo de tokens Anthropic deve ser maior que zero.');
  FVersaoAPI := AVersaoAPI;
  FMaximoTokens := AMaximoTokens;
end;

function TConfiguracaoAnthropic.ObterMaximoTokens: Integer;
begin
  Result := FMaximoTokens;
end;

function TConfiguracaoAnthropic.ObterVersaoAPI: string;
begin
  Result := FVersaoAPI;
end;

end.
