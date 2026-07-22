unit Daikit.Componentes.Provedores;

interface

uses
  System.Classes,
  Daikit.Aplicacao.Interfaces,
  Daikit.Componentes.Constantes,
  Daikit.Componentes.Provedor,
  Daikit.Infraestrutura.HTTP.Interfaces,
  Daikit.Adaptadores.Gemini.Interfaces;

type
  TProvedorOpenAI = class(TProvedorIA)
  protected
    function ObterEndpointPadrao: string; override;
    function ObterModeloPadraoDoAdaptador: string; override;
    function ObterVariavelAmbienteChaveAPIPadrao: string; override;
    function ObterNomeProvedorLog: string; override;
    function CriarAdaptadorComTransporte(
      const ATransporte: ITransporteHTTP): IAdaptadorIA; override;
  end;

  TProvedorAnthropic = class(TProvedorIA)
  private
    FVersaoAPI: string;
    FMaximoTokens: Integer;
    function ObterVersaoAPI: string;
    function ArmazenarVersaoAPI: Boolean;
  protected
    function ObterEndpointPadrao: string; override;
    function ObterModeloPadraoDoAdaptador: string; override;
    function ObterVariavelAmbienteChaveAPIPadrao: string; override;
    function ObterNomeProvedorLog: string; override;
    function CriarAdaptadorComTransporte(
      const ATransporte: ITransporteHTTP): IAdaptadorIA; override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property VersaoAPI: string read ObterVersaoAPI write FVersaoAPI
      stored ArmazenarVersaoAPI;
    property MaximoTokens: Integer read FMaximoTokens write FMaximoTokens
      default CMaximoTokensComponentePadrao;
  end;

  TProvedorGemini = class(TProvedorIA)
  private
    FMaximoTokens: Integer;
    FModoContexto: TModoContextoGemini;
    FArmazenamentoContexto: IArmazenamentoContextoGemini;
  protected
    function ObterEndpointPadrao: string; override;
    function ObterModeloPadraoDoAdaptador: string; override;
    function ObterVariavelAmbienteChaveAPIPadrao: string; override;
    function ObterNomeProvedorLog: string; override;
    function CriarAdaptadorComTransporte(
      const ATransporte: ITransporteHTTP): IAdaptadorIA; override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure LimparContextoLocal;
  published
    property MaximoTokens: Integer read FMaximoTokens write FMaximoTokens
      default CMaximoTokensComponentePadrao;
    property ModoContexto: TModoContextoGemini read FModoContexto
      write FModoContexto default TModoContextoGemini.Local;
  end;

implementation

uses
  Daikit.Adaptadores.Interfaces,
  Daikit.Adaptadores.ChaveAPI,
  Daikit.Adaptadores.OpenAI.Constantes,
  Daikit.Adaptadores.OpenAI.Interfaces,
  Daikit.Adaptadores.OpenAI.Configuracao,
  Daikit.Adaptadores.OpenAI.Mapeador,
  Daikit.Adaptadores.OpenAI.Adaptador,
  Daikit.Adaptadores.Anthropic.Constantes,
  Daikit.Adaptadores.Anthropic.Interfaces,
  Daikit.Adaptadores.Anthropic.Configuracao,
  Daikit.Adaptadores.Anthropic.Mapeador,
  Daikit.Adaptadores.Anthropic.Adaptador,
  Daikit.Adaptadores.Gemini.Constantes,
  Daikit.Adaptadores.Gemini.Configuracao,
  Daikit.Adaptadores.Gemini.Armazenamento,
  Daikit.Adaptadores.Gemini.Mapeador,
  Daikit.Adaptadores.Gemini.Adaptador;

{ TProvedorOpenAI }

function TProvedorOpenAI.CriarAdaptadorComTransporte(
  const ATransporte: ITransporteHTTP): IAdaptadorIA;
var
  LFonte: IFonteChaveAPI;
begin
  if TemChaveAPIEmMemoria then
    LFonte := TFonteChaveAPIMemoria.Create(ObterChaveAPIEmMemoria)
  else
    LFonte := TFonteChaveAPIAmbiente.Create(VariavelAmbienteChaveAPI);
  
  Result := TAdaptadorOpenAI.Create(
    ATransporte, LFonte,
    TConfiguracaoOpenAI.Create(Endpoint, ModeloPadrao,
      TimeoutConexaoMS, TimeoutRespostaMS, LimiteRespostaBytes),
    TMapeadorOpenAI.Create);
end;

function TProvedorOpenAI.ObterNomeProvedorLog: string;
begin
  Result := CNomeProvedorLogOpenAI;
end;

function TProvedorOpenAI.ObterEndpointPadrao: string;
begin
  Result := CEndpointRespostasOpenAI;
end;

function TProvedorOpenAI.ObterModeloPadraoDoAdaptador: string;
begin
  Result := CModeloOpenAIRecomendado;
end;

function TProvedorOpenAI.ObterVariavelAmbienteChaveAPIPadrao: string;
begin
  Result := CVariavelAmbienteChaveOpenAI;
end;

{ TProvedorAnthropic }

constructor TProvedorAnthropic.Create(AOwner: TComponent);
begin
  inherited;
  FMaximoTokens := CMaximoTokensComponentePadrao;
end;

function TProvedorAnthropic.ArmazenarVersaoAPI: Boolean;
begin
  Result := FVersaoAPI <> '';
end;

function TProvedorAnthropic.ObterVersaoAPI: string;
begin
  if FVersaoAPI = '' then Result := CVersaoAPIAnthropic
  else Result := FVersaoAPI;
end;

function TProvedorAnthropic.CriarAdaptadorComTransporte(
  const ATransporte: ITransporteHTTP): IAdaptadorIA;
var
  LFonte: IFonteChaveAPI;
begin
  if TemChaveAPIEmMemoria then
    LFonte := TFonteChaveAPIMemoria.Create(ObterChaveAPIEmMemoria)
  else
    LFonte := TFonteChaveAPIAmbiente.Create(VariavelAmbienteChaveAPI);

  Result := TAdaptadorAnthropic.Create(
    ATransporte, LFonte,
    TConfiguracaoAnthropic.Create(Endpoint, ModeloPadrao,
      ObterVersaoAPI, FMaximoTokens, TimeoutConexaoMS,
      TimeoutRespostaMS, LimiteRespostaBytes),
    TMapeadorAnthropic.Create);
end;

function TProvedorAnthropic.ObterNomeProvedorLog: string;
begin
  Result := CNomeProvedorLogAnthropic;
end;

function TProvedorAnthropic.ObterEndpointPadrao: string;
begin
  Result := CEndpointMensagensAnthropic;
end;

function TProvedorAnthropic.ObterModeloPadraoDoAdaptador: string;
begin
  Result := CModeloAnthropicPadrao;
end;

function TProvedorAnthropic.ObterVariavelAmbienteChaveAPIPadrao: string;
begin
  Result := CVariavelAmbienteChaveAnthropic;
end;

{ TProvedorGemini }

constructor TProvedorGemini.Create(AOwner: TComponent);
begin
  inherited;
  FMaximoTokens := CMaximoTokensComponentePadrao;
  FModoContexto := TModoContextoGemini.Local;
  FArmazenamentoContexto := TArmazenamentoContextoGemini.Create;
end;

function TProvedorGemini.CriarAdaptadorComTransporte(
  const ATransporte: ITransporteHTTP): IAdaptadorIA;
var
  LFonte: IFonteChaveAPI;
begin
  if TemChaveAPIEmMemoria then
    LFonte := TFonteChaveAPIMemoria.Create(ObterChaveAPIEmMemoria)
  else
    LFonte := TFonteChaveAPIAmbiente.Create(VariavelAmbienteChaveAPI);

  Result := TAdaptadorGemini.Create(
    ATransporte, LFonte,
    TConfiguracaoGemini.Create(Endpoint, ModeloPadrao,
      FMaximoTokens, TimeoutConexaoMS, TimeoutRespostaMS,
      LimiteRespostaBytes, FModoContexto),
    TMapeadorGemini.Create(FArmazenamentoContexto));
end;

function TProvedorGemini.ObterNomeProvedorLog: string;
begin
  Result := CNomeProvedorLogGemini;
end;

procedure TProvedorGemini.LimparContextoLocal;
begin
  FArmazenamentoContexto.Limpar;
end;

function TProvedorGemini.ObterEndpointPadrao: string;
begin
  Result := CEndpointInteracoesGemini;
end;

function TProvedorGemini.ObterModeloPadraoDoAdaptador: string;
begin
  Result := CModeloGeminiPadrao;
end;

function TProvedorGemini.ObterVariavelAmbienteChaveAPIPadrao: string;
begin
  Result := CVariavelAmbienteChaveGemini;
end;

initialization
  RegisterClasses([TProvedorOpenAI, TProvedorAnthropic, TProvedorGemini]);

end.
