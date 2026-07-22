unit Daikit.Adaptadores.OpenAI.Configuracao;

interface

uses
  Daikit.Infraestrutura.HTTP.Constantes,
  Daikit.Adaptadores.Configuracao,
  Daikit.Adaptadores.OpenAI.Constantes,
  Daikit.Adaptadores.OpenAI.Interfaces;

type
  TConfiguracaoOpenAI = class(TConfiguracaoAdaptadorIA,
    IConfiguracaoOpenAI)
  public
    constructor Create(const AEndpoint: string = CEndpointRespostasOpenAI;
      const AModeloPadrao: string = CModeloOpenAIRecomendado;
      ATimeoutConexaoMS: Integer = CTimeoutConexaoPadraoMS;
      ATimeoutRespostaMS: Integer = CTimeoutRespostaPadraoMS;
      ALimiteRespostaBytes: Int64 = CLimiteRespostaPadraoBytes);
  end;

implementation

uses
  Daikit.Adaptadores.OpenAI.Excecoes;

constructor TConfiguracaoOpenAI.Create(const AEndpoint, AModeloPadrao: string;
  ATimeoutConexaoMS, ATimeoutRespostaMS: Integer;
  ALimiteRespostaBytes: Int64);
begin
  inherited Create('OpenAI', AEndpoint, AModeloPadrao,
    ATimeoutConexaoMS, ATimeoutRespostaMS, ALimiteRespostaBytes,
    EConfiguracaoOpenAI);
end;

end.
