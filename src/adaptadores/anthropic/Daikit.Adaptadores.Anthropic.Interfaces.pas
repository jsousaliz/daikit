unit Daikit.Adaptadores.Anthropic.Interfaces;

interface

uses
  Daikit.Dominio.Interfaces,
  Daikit.Adaptadores.Interfaces,
  Daikit.Adaptadores.Anthropic.Contratos;

type
  IConfiguracaoAnthropic = interface(IConfiguracaoAdaptadorIA)
    ['{AD2A97E6-9A24-4AD8-AD18-C22AAB95C8E0}']
    function ObterVersaoAPI: string;
    function ObterMaximoTokens: Integer;
    property VersaoAPI: string read ObterVersaoAPI;
    property MaximoTokens: Integer read ObterMaximoTokens;
  end;

  IMapeadorAnthropic = interface
    ['{F25EA0D7-8094-4D5C-A4C3-9DFF2D853C4E}']
    function CriarContratoRequisicao(const ARequisicao: IRequisicaoChatIA;
      const AModeloPadrao: string;
      AMaximoTokens: Integer): TRequisicaoMensagensAnthropic;
    function MapearResposta(AResposta: TRespostaAnthropic): IRespostaChatIA;
    function MapearModelos(
      AResposta: TRespostaModelosAnthropic): TArray<IModeloIA>;
  end;

implementation

end.
