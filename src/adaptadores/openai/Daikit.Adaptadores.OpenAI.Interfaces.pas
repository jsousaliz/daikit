unit Daikit.Adaptadores.OpenAI.Interfaces;

interface

uses
  Daikit.Dominio.Interfaces,
  Daikit.Adaptadores.Interfaces,
  Daikit.Adaptadores.OpenAI.Contratos;

type
  IConfiguracaoOpenAI = interface(IConfiguracaoAdaptadorIA)
    ['{F8799BC6-8D9C-4B8B-9A51-21CD97F89A20}']
  end;

  IMapeadorOpenAI = interface
    ['{415B4563-D314-438A-8B53-D5E114B6F627}']
    function CriarContratoRequisicao(const ARequisicao: IRequisicaoChatIA;
      const AModeloPadrao: string): TRequisicaoRespostasOpenAI;
    function MapearResposta(AResposta: TRespostaOpenAI): IRespostaChatIA;
  end;

implementation

end.
