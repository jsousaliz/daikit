unit Daikit.Adaptadores.Gemini.Configuracao;

interface

uses
  Daikit.Adaptadores.Configuracao,
  Daikit.Adaptadores.Gemini.Constantes,
  Daikit.Adaptadores.Gemini.Interfaces;

type
  TOpcoesConfiguracaoGemini = record
    Comum: TOpcoesConfiguracaoAdaptadorIA;
    MaximoTokens: Integer;
    ModoContexto: TModoContextoGemini;
    class function Padrao: TOpcoesConfiguracaoGemini; static;
  end;

  TConfiguracaoGemini = class(TConfiguracaoAdaptadorIA,
    IConfiguracaoGemini)
  private
    FMaximoTokens: Integer;
    FModoContexto: TModoContextoGemini;
    function ObterMaximoTokens: Integer;
    function ObterModoContexto: TModoContextoGemini;
  public
    constructor Create; overload;
    constructor Create(const AOpcoes: TOpcoesConfiguracaoGemini); overload;
  end;

implementation

uses
  Daikit.Adaptadores.Gemini.Excecoes;

class function TOpcoesConfiguracaoGemini.Padrao: TOpcoesConfiguracaoGemini;
begin
  Result.Comum := TOpcoesConfiguracaoAdaptadorIA.Padrao(
    CEndpointInteracoesGemini, CModeloGeminiPadrao);
  Result.MaximoTokens := CMaximoTokensSaidaPadraoGemini;
  Result.ModoContexto := TModoContextoGemini.Local;
end;

constructor TConfiguracaoGemini.Create;
begin
  Create(TOpcoesConfiguracaoGemini.Padrao);
end;

constructor TConfiguracaoGemini.Create(
  const AOpcoes: TOpcoesConfiguracaoGemini);
begin
  inherited Create('Gemini', AOpcoes.Comum, EConfiguracaoGemini);
  if AOpcoes.MaximoTokens <= 0 then
    raise EConfiguracaoGemini.Create(
      'O maximo de tokens Gemini deve ser maior que zero.');
  if AOpcoes.ModoContexto <> TModoContextoGemini.Local then
    raise EConfiguracaoGemini.Create(
      'O contexto remoto Gemini ainda nao foi implementado. Use o modo Local.');
  FMaximoTokens := AOpcoes.MaximoTokens;
  FModoContexto := AOpcoes.ModoContexto;
end;

function TConfiguracaoGemini.ObterMaximoTokens: Integer;
begin
  Result := FMaximoTokens;
end;

function TConfiguracaoGemini.ObterModoContexto: TModoContextoGemini;
begin
  Result := FModoContexto;
end;

end.
