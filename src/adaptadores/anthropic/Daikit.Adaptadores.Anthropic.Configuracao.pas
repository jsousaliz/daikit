unit Daikit.Adaptadores.Anthropic.Configuracao;

interface

uses
  Daikit.Adaptadores.Configuracao,
  Daikit.Adaptadores.Anthropic.Constantes,
  Daikit.Adaptadores.Anthropic.Interfaces;

type
  TOpcoesConfiguracaoAnthropic = record
    Comum: TOpcoesConfiguracaoAdaptadorIA;
    VersaoAPI: string;
    MaximoTokens: Integer;
    class function Padrao: TOpcoesConfiguracaoAnthropic; static;
  end;

  TConfiguracaoAnthropic = class(TConfiguracaoAdaptadorIA,
    IConfiguracaoAnthropic)
  private
    FVersaoAPI: string;
    FMaximoTokens: Integer;
    function ObterVersaoAPI: string;
    function ObterMaximoTokens: Integer;
  public
    constructor Create; overload;
    constructor Create(const AOpcoes: TOpcoesConfiguracaoAnthropic); overload;
  end;

implementation

uses
  System.SysUtils,
  Daikit.Adaptadores.Anthropic.Excecoes;

class function TOpcoesConfiguracaoAnthropic.Padrao:
  TOpcoesConfiguracaoAnthropic;
begin
  Result.Comum := TOpcoesConfiguracaoAdaptadorIA.Padrao(
    CEndpointMensagensAnthropic, CModeloAnthropicPadrao);
  Result.VersaoAPI := CVersaoAPIAnthropic;
  Result.MaximoTokens := CMaximoTokensSaidaPadraoAnthropic;
end;

constructor TConfiguracaoAnthropic.Create;
begin
  Create(TOpcoesConfiguracaoAnthropic.Padrao);
end;

constructor TConfiguracaoAnthropic.Create(
  const AOpcoes: TOpcoesConfiguracaoAnthropic);
begin
  inherited Create('Anthropic', AOpcoes.Comum, EConfiguracaoAnthropic);
  if Trim(AOpcoes.VersaoAPI) = '' then
    raise EConfiguracaoAnthropic.Create(
      'A versao da API Anthropic deve ser informada.');
  if AOpcoes.MaximoTokens <= 0 then
    raise EConfiguracaoAnthropic.Create(
      'O maximo de tokens Anthropic deve ser maior que zero.');
  FVersaoAPI := AOpcoes.VersaoAPI;
  FMaximoTokens := AOpcoes.MaximoTokens;
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
