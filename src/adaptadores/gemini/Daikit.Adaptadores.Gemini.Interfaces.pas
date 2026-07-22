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
    ['{201CA7F1-F910-42B9-9CA7-6BAFE73D129A}']
    function ObterMaximoTokens: Integer;
    function ObterModoContexto: TModoContextoGemini;
    property MaximoTokens: Integer read ObterMaximoTokens;
    property ModoContexto: TModoContextoGemini read ObterModoContexto;
  end;

  IMapeadorGemini = interface
    ['{4878F2A1-B397-48E1-BF69-840E78E327B7}']
    function CriarContratoRequisicao(const ARequisicao: IRequisicaoChatIA;
      const AModeloPadrao: string;
      AMaximoTokens: Integer): TRequisicaoInteracaoGemini;
    function MapearResposta(
      AResposta: TRespostaInteracaoGemini): IRespostaChatIA;
  end;

implementation

end.
