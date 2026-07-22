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
    function ObterEndpointModelosPadrao: string; override;
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
    function ObterEndpointModelosPadrao: string; override;
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
    FModoContextoGemini: TModoContextoGemini;
    FArmazenamentoContextoGemini: IArmazenamentoContextoGemini;
  protected
    function ObterEndpointPadrao: string; override;
    function ObterEndpointModelosPadrao: string; override;
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
    property ModoContexto: TModoContextoGemini read FModoContextoGemini
      write FModoContextoGemini default TModoContextoGemini.Local;
  end;

implementation

uses
  Daikit.Adaptadores.Interfaces,
  Daikit.Adaptadores.ChaveAPI,
  Daikit.Adaptadores.Configuracao,
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
  LFonteChaveAPI: IFonteChaveAPI;
  LOpcoesConfiguracaoOpenAI: TOpcoesConfiguracaoAdaptadorIA;
  LConfiguracaoOpenAI: IConfiguracaoOpenAI;
  LMapeadorOpenAI: IMapeadorOpenAI;
begin
  if TemChaveAPIEmMemoria then
    LFonteChaveAPI := TFonteChaveAPIMemoria.Create(ObterChaveAPIEmMemoria)
  else
    LFonteChaveAPI := TFonteChaveAPIAmbiente.Create(VariavelAmbienteChaveAPI);
  
  LOpcoesConfiguracaoOpenAI := TOpcoesConfiguracaoAdaptadorIA.Padrao(
    Endpoint, EndpointModelos, ModeloPadrao);
  LOpcoesConfiguracaoOpenAI.TimeoutConexaoMS := TimeoutConexaoMS;
  LOpcoesConfiguracaoOpenAI.TimeoutRespostaMS := TimeoutRespostaMS;
  LOpcoesConfiguracaoOpenAI.LimiteRespostaBytes := LimiteRespostaBytes;
  LConfiguracaoOpenAI := TConfiguracaoOpenAI.Create(
    LOpcoesConfiguracaoOpenAI);
  LMapeadorOpenAI := TMapeadorOpenAI.Create;
  Result := TAdaptadorOpenAI.Create(ATransporte, LFonteChaveAPI,
    LConfiguracaoOpenAI, LMapeadorOpenAI);
end;

function TProvedorOpenAI.ObterNomeProvedorLog: string;
begin
  Result := CNomeProvedorLogOpenAI;
end;

function TProvedorOpenAI.ObterEndpointPadrao: string;
begin
  Result := CEndpointRespostasOpenAI;
end;

function TProvedorOpenAI.ObterEndpointModelosPadrao: string;
begin
  Result := CEndpointModelosOpenAI;
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
  LFonteChaveAPI: IFonteChaveAPI;
  LOpcoesConfiguracaoAnthropic: TOpcoesConfiguracaoAnthropic;
  LConfiguracaoAnthropic: IConfiguracaoAnthropic;
  LMapeadorAnthropic: IMapeadorAnthropic;
begin
  if TemChaveAPIEmMemoria then
    LFonteChaveAPI := TFonteChaveAPIMemoria.Create(ObterChaveAPIEmMemoria)
  else
    LFonteChaveAPI := TFonteChaveAPIAmbiente.Create(VariavelAmbienteChaveAPI);

  LOpcoesConfiguracaoAnthropic := TOpcoesConfiguracaoAnthropic.Padrao;
  LOpcoesConfiguracaoAnthropic.Comum.Endpoint := Endpoint;
  LOpcoesConfiguracaoAnthropic.Comum.EndpointModelos := EndpointModelos;
  LOpcoesConfiguracaoAnthropic.Comum.ModeloPadrao := ModeloPadrao;
  LOpcoesConfiguracaoAnthropic.VersaoAPI := ObterVersaoAPI;
  LOpcoesConfiguracaoAnthropic.MaximoTokens := FMaximoTokens;
  LOpcoesConfiguracaoAnthropic.Comum.TimeoutConexaoMS := TimeoutConexaoMS;
  LOpcoesConfiguracaoAnthropic.Comum.TimeoutRespostaMS := TimeoutRespostaMS;
  LOpcoesConfiguracaoAnthropic.Comum.LimiteRespostaBytes :=
    LimiteRespostaBytes;
  LConfiguracaoAnthropic := TConfiguracaoAnthropic.Create(
    LOpcoesConfiguracaoAnthropic);
  LMapeadorAnthropic := TMapeadorAnthropic.Create;
  Result := TAdaptadorAnthropic.Create(ATransporte, LFonteChaveAPI,
    LConfiguracaoAnthropic, LMapeadorAnthropic);
end;

function TProvedorAnthropic.ObterNomeProvedorLog: string;
begin
  Result := CNomeProvedorLogAnthropic;
end;

function TProvedorAnthropic.ObterEndpointPadrao: string;
begin
  Result := CEndpointMensagensAnthropic;
end;

function TProvedorAnthropic.ObterEndpointModelosPadrao: string;
begin
  Result := CEndpointModelosAnthropic;
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
  FModoContextoGemini := TModoContextoGemini.Local;
  FArmazenamentoContextoGemini := TArmazenamentoContextoGemini.Create;
end;

function TProvedorGemini.CriarAdaptadorComTransporte(
  const ATransporte: ITransporteHTTP): IAdaptadorIA;
var
  LFonteChaveAPI: IFonteChaveAPI;
  LOpcoesConfiguracaoGemini: TOpcoesConfiguracaoGemini;
  LConfiguracaoGemini: IConfiguracaoGemini;
  LMapeadorGemini: IMapeadorGemini;
begin
  if TemChaveAPIEmMemoria then
    LFonteChaveAPI := TFonteChaveAPIMemoria.Create(ObterChaveAPIEmMemoria)
  else
    LFonteChaveAPI := TFonteChaveAPIAmbiente.Create(VariavelAmbienteChaveAPI);

  LOpcoesConfiguracaoGemini := TOpcoesConfiguracaoGemini.Padrao;
  LOpcoesConfiguracaoGemini.Comum.Endpoint := Endpoint;
  LOpcoesConfiguracaoGemini.Comum.EndpointModelos := EndpointModelos;
  LOpcoesConfiguracaoGemini.Comum.ModeloPadrao := ModeloPadrao;
  LOpcoesConfiguracaoGemini.MaximoTokens := FMaximoTokens;
  LOpcoesConfiguracaoGemini.Comum.TimeoutConexaoMS := TimeoutConexaoMS;
  LOpcoesConfiguracaoGemini.Comum.TimeoutRespostaMS := TimeoutRespostaMS;
  LOpcoesConfiguracaoGemini.Comum.LimiteRespostaBytes :=
    LimiteRespostaBytes;
  LOpcoesConfiguracaoGemini.ModoContexto := FModoContextoGemini;
  LConfiguracaoGemini := TConfiguracaoGemini.Create(
    LOpcoesConfiguracaoGemini);
  LMapeadorGemini := TMapeadorGemini.Create(FArmazenamentoContextoGemini);
  Result := TAdaptadorGemini.Create(ATransporte, LFonteChaveAPI,
    LConfiguracaoGemini, LMapeadorGemini);
end;

function TProvedorGemini.ObterNomeProvedorLog: string;
begin
  Result := CNomeProvedorLogGemini;
end;

procedure TProvedorGemini.LimparContextoLocal;
begin
  FArmazenamentoContextoGemini.Limpar;
end;

function TProvedorGemini.ObterEndpointPadrao: string;
begin
  Result := CEndpointInteracoesGemini;
end;

function TProvedorGemini.ObterEndpointModelosPadrao: string;
begin
  Result := CEndpointModelosGemini;
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
