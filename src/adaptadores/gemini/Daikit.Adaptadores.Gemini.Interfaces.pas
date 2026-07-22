unit Daikit.Adaptadores.Gemini.Interfaces;

interface

uses
  Daikit.Dominio.Interfaces,
  Daikit.Adaptadores.Interfaces,
  Daikit.Adaptadores.Gemini.Contratos;

type
  TModoContextoGemini = (Local, RemotoGoogle);

  IArmazenamentoContextoGemini = interface
    ['{043F06CC-BA4A-4AB8-89C4-BE0154E57532}']
    procedure Guardar(const AIdCorrelacao, AContextoJSON: string);
    function TentarObter(const AIdCorrelacao: string;
      out AContextoJSON: string): Boolean;
    procedure Remover(const AIdCorrelacao: string);
    procedure Limpar;
    function ObterQuantidade: Integer;
    property Quantidade: Integer read ObterQuantidade;
  end;

  IConfiguracaoGemini = interface(IConfiguracaoAdaptadorIA)
    ['{0EBDBC1D-3767-4AF7-8915-C93A681EA384}']
    function ObterMaximoTokens: Integer;
    function ObterModoContexto: TModoContextoGemini;
    property MaximoTokens: Integer read ObterMaximoTokens;
    property ModoContexto: TModoContextoGemini read ObterModoContexto;
  end;

  IMapeadorGemini = interface
    ['{B4B4C317-E8D9-4839-90CC-1C91D5A1A9CC}']
    function CriarContratoRequisicao(const ARequisicao: IRequisicaoChatIA;
      const AModeloPadrao: string;
      AMaximoTokens: Integer): TRequisicaoInteracaoGemini;
    function MapearResposta(
      AResposta: TRespostaInteracaoGemini): IRespostaChatIA;
    function MapearModelos(
      AResposta: TRespostaModelosGemini): TArray<IModeloIA>;
  end;

implementation

end.
