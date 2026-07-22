unit Daikit.Adaptadores.Anthropic.Interfaces;

interface

uses
  Daikit.Dominio.Interfaces,
  Daikit.Adaptadores.Interfaces,
  Daikit.Adaptadores.Anthropic.Contratos;

type
  IConfiguracaoAnthropic = interface(IConfiguracaoAdaptadorIA)
    ['{E3D62495-2E5D-4A9E-9158-4F130A201C49}']
    function ObterVersaoAPI: string;
    function ObterMaximoTokens: Integer;
    property VersaoAPI: string read ObterVersaoAPI;
    property MaximoTokens: Integer read ObterMaximoTokens;
  end;

  IMapeadorAnthropic = interface
    ['{4775E3A2-FEBA-4151-B887-39510F3056E1}']
    function CriarContratoRequisicao(const ARequisicao: IRequisicaoChatIA;
      const AModeloPadrao: string;
      AMaximoTokens: Integer): TRequisicaoMensagensAnthropic;
    function MapearResposta(AResposta: TRespostaAnthropic): IRespostaChatIA;
  end;

implementation

end.
