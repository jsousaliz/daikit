unit Daikit.Adaptadores.OpenAI.Configuracao;

interface

uses
  Daikit.Adaptadores.Configuracao,
  Daikit.Adaptadores.OpenAI.Constantes,
  Daikit.Adaptadores.OpenAI.Interfaces;

type
  TConfiguracaoOpenAI = class(TConfiguracaoAdaptadorIA,
    IConfiguracaoOpenAI)
  public
    constructor Create; overload;
    constructor Create(
      const AOpcoes: TOpcoesConfiguracaoAdaptadorIA); overload;
  end;

implementation

uses
  Daikit.Adaptadores.OpenAI.Excecoes;

constructor TConfiguracaoOpenAI.Create;
begin
  Create(TOpcoesConfiguracaoAdaptadorIA.Padrao(
    CEndpointRespostasOpenAI, CEndpointModelosOpenAI,
    CModeloOpenAIRecomendado));
end;

constructor TConfiguracaoOpenAI.Create(
  const AOpcoes: TOpcoesConfiguracaoAdaptadorIA);
begin
  inherited Create('OpenAI', AOpcoes, EConfiguracaoOpenAI);
end;

end.
