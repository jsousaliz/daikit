unit Daikit.Adaptadores.Gemini.Configuracao;

interface

uses
  Daikit.Infraestrutura.HTTP.Constantes,
  Daikit.Adaptadores.Configuracao,
  Daikit.Adaptadores.Gemini.Constantes,
  Daikit.Adaptadores.Gemini.Interfaces;

type
  TConfiguracaoGemini = class(TConfiguracaoAdaptadorIA,
    IConfiguracaoGemini)
  private
    FMaximoTokens: Integer;
    FModoContexto: TModoContextoGemini;
    function ObterMaximoTokens: Integer;
    function ObterModoContexto: TModoContextoGemini;
  public
    constructor Create(const AEndpoint: string = CEndpointInteracoesGemini;
      const AModeloPadrao: string = CModeloGeminiPadrao;
      AMaximoTokens: Integer = CMaximoTokensSaidaPadraoGemini;
      ATimeoutConexaoMS: Integer = CTimeoutConexaoPadraoMS;
      ATimeoutRespostaMS: Integer = CTimeoutRespostaPadraoMS;
      ALimiteRespostaBytes: Int64 = CLimiteRespostaPadraoBytes;
      AModoContexto: TModoContextoGemini = TModoContextoGemini.Local);
  end;

implementation

uses
  Daikit.Adaptadores.Gemini.Excecoes;

constructor TConfiguracaoGemini.Create(const AEndpoint, AModeloPadrao: string;
  AMaximoTokens, ATimeoutConexaoMS, ATimeoutRespostaMS: Integer;
  ALimiteRespostaBytes: Int64; AModoContexto: TModoContextoGemini);
begin
  inherited Create('Gemini', AEndpoint, AModeloPadrao,
    ATimeoutConexaoMS, ATimeoutRespostaMS, ALimiteRespostaBytes,
    EConfiguracaoGemini);
  if AMaximoTokens <= 0 then
    raise EConfiguracaoGemini.Create(
      'O maximo de tokens Gemini deve ser maior que zero.');
  if AModoContexto <> TModoContextoGemini.Local then
    raise EConfiguracaoGemini.Create(
      'O contexto remoto Gemini ainda nao foi implementado. Use o modo Local.');
  FMaximoTokens := AMaximoTokens;
  FModoContexto := AModoContexto;
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
