unit Daikit.Dominio.Interfaces;

interface

type
  IModeloIA = interface
    ['{ED6473D7-A797-423D-A430-1628C351CFE3}']
    function ObterId: string;
    function ObterNome: string;
    property Id: string read ObterId;
    property Nome: string read ObterNome;
  end;

  TTipoParteConteudoIA = (Texto);
  TPapelMensagemIA = (Sistema, Usuario, Assistente, Ferramenta);
  TModoConversaIA = (ManterHistorico, MensagemIsolada);

  IParteConteudoIA = interface
    ['{0432EA5A-6BBF-42F1-B6C9-11B3AE684CF6}']
    function ObterTipo: TTipoParteConteudoIA;
    function ObterTexto: string;
    property Tipo: TTipoParteConteudoIA read ObterTipo;
    property Texto: string read ObterTexto;
  end;

  IMensagemIA = interface
    ['{E02C41E9-C30D-4B79-BA11-4890B00B7F06}']
    function ObterPapel: TPapelMensagemIA;
    function ObterPartes: TArray<IParteConteudoIA>;
    function ObterTexto: string;
    function ObterNome: string;
    function ObterIdCorrelacao: string;
    property Papel: TPapelMensagemIA read ObterPapel;
    property Partes: TArray<IParteConteudoIA> read ObterPartes;
    property Texto: string read ObterTexto;
    property Nome: string read ObterNome;
    property IdCorrelacao: string read ObterIdCorrelacao;
  end;

  IArmazenamentoContextoIA = interface
    ['{F9EF4185-F6AB-441B-B123-000DC88D6045}']
    procedure Adicionar(const AMensagem: IMensagemIA);
    function ObterInstantaneo: TArray<IMensagemIA>;
    function ObterQuantidade: Integer;
    procedure Limpar;
    property Quantidade: Integer read ObterQuantidade;
  end;

  IContextoIA = interface
    ['{59B74A2F-7E79-4A4D-91AE-13819F17132C}']
    procedure Adicionar(const AMensagem: IMensagemIA);
    function AdicionarMensagemSistema(const ATexto: string): IMensagemIA;
    function AdicionarMensagemUsuario(const ATexto: string): IMensagemIA;
    function AdicionarMensagemAssistente(const ATexto: string): IMensagemIA;
    function ObterMensagens: TArray<IMensagemIA>;
    function ObterQuantidade: Integer;
    procedure Limpar;
    property Quantidade: Integer read ObterQuantidade;
  end;

  IUsoIA = interface
    ['{374B536E-0705-489E-8A7B-E1CE9670BDE5}']
    function ObterUnidadesEntrada: Int64;
    function ObterUnidadesSaida: Int64;
    function ObterUnidadesTotal: Int64;
    property UnidadesEntrada: Int64 read ObterUnidadesEntrada;
    property UnidadesSaida: Int64 read ObterUnidadesSaida;
    property UnidadesTotal: Int64 read ObterUnidadesTotal;
  end;

  IRequisicaoChatIA = interface
    ['{DC09CA67-BB5E-4F8D-B955-397E7294EFFA}']
    function ObterModelo: string;
    function ObterMensagens: TArray<IMensagemIA>;
    property Modelo: string read ObterModelo;
    property Mensagens: TArray<IMensagemIA> read ObterMensagens;
  end;

  IRespostaChatIA = interface
    ['{B1656FA0-B86B-4777-92DA-019A6071FCAD}']
    function ObterId: string;
    function ObterMensagem: IMensagemIA;
    function ObterUso: IUsoIA;
    property Id: string read ObterId;
    property Mensagem: IMensagemIA read ObterMensagem;
    property Uso: IUsoIA read ObterUso;
  end;

implementation

end.
