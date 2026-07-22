unit Daikit.Adaptadores.OpenAI.Interfaces;

interface

uses
  Daikit.Dominio.Interfaces,
  Daikit.Adaptadores.Interfaces,
  Daikit.Adaptadores.OpenAI.Contratos;

type
  IConfiguracaoOpenAI = interface(IConfiguracaoAdaptadorIA)
    ['{A8EF134F-369B-46F5-8D52-FCB04AF8B4A0}']
  end;

  IMapeadorOpenAI = interface
    ['{D20EF4F4-B035-4333-9B23-165BCFA25BE6}']
    function CriarContratoRequisicao(const ARequisicao: IRequisicaoChatIA;
      const AModeloPadrao: string): TRequisicaoRespostasOpenAI;
    function MapearResposta(AResposta: TRespostaOpenAI): IRespostaChatIA;
    function MapearModelos(
      AResposta: TRespostaModelosOpenAI): TArray<IModeloIA>;
  end;

implementation

end.
