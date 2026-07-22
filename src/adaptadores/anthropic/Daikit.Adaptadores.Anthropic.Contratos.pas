unit Daikit.Adaptadores.Anthropic.Contratos;

interface

uses
  REST.Json.Types;

type
  TMensagemEntradaAnthropic = class
  private
    [JSONName('role')] FPapel: string;
    [JSONName('content')] FConteudo: string;
  public
    property Papel: string read FPapel write FPapel;
    property Conteudo: string read FConteudo write FConteudo;
  end;

  TRequisicaoMensagensAnthropic = class
  private
    [JSONName('model')] FModelo: string;
    [JSONName('max_tokens')] FMaximoTokens: Integer;
    [JSONName('system')] FSistema: string;
    [JSONName('messages')] FMensagens: TArray<TMensagemEntradaAnthropic>;
  public
    destructor Destroy; override;
    property Modelo: string read FModelo write FModelo;
    property MaximoTokens: Integer read FMaximoTokens write FMaximoTokens;
    property Sistema: string read FSistema write FSistema;
    property Mensagens: TArray<TMensagemEntradaAnthropic> read FMensagens
      write FMensagens;
  end;

  TConteudoSaidaAnthropic = class
  private
    [JSONName('type')] FTipo: string;
    [JSONName('text')] FTexto: string;
  public
    property Tipo: string read FTipo write FTipo;
    property Texto: string read FTexto write FTexto;
  end;

  TUsoAnthropic = class
  private
    [JSONName('input_tokens')] FTokensEntrada: Int64;
    [JSONName('output_tokens')] FTokensSaida: Int64;
  public
    property TokensEntrada: Int64 read FTokensEntrada write FTokensEntrada;
    property TokensSaida: Int64 read FTokensSaida write FTokensSaida;
  end;

  TRespostaAnthropic = class
  private
    [JSONName('id')] FId: string;
    [JSONName('type')] FTipo: string;
    [JSONName('role')] FPapel: string;
    [JSONName('model')] FModelo: string;
    [JSONName('content')] FConteudo: TArray<TConteudoSaidaAnthropic>;
    [JSONName('stop_reason')] FMotivoTermino: string;
    [JSONName('usage')] FUso: TUsoAnthropic;
  public
    destructor Destroy; override;
    property Id: string read FId write FId;
    property Tipo: string read FTipo write FTipo;
    property Papel: string read FPapel write FPapel;
    property Modelo: string read FModelo write FModelo;
    property Conteudo: TArray<TConteudoSaidaAnthropic> read FConteudo
      write FConteudo;
    property MotivoTermino: string read FMotivoTermino write FMotivoTermino;
    property Uso: TUsoAnthropic read FUso write FUso;
  end;

  TDetalheErroAnthropic = class
  private
    [JSONName('type')] FTipo: string;
    [JSONName('message')] FMensagem: string;
  public
    property Tipo: string read FTipo write FTipo;
    property Mensagem: string read FMensagem write FMensagem;
  end;

  TEnvelopeErroAnthropic = class
  private
    [JSONName('type')] FTipo: string;
    [JSONName('error')] FErro: TDetalheErroAnthropic;
    [JSONName('request_id')] FIdRequisicao: string;
  public
    destructor Destroy; override;
    property Tipo: string read FTipo write FTipo;
    property Erro: TDetalheErroAnthropic read FErro write FErro;
    property IdRequisicao: string read FIdRequisicao write FIdRequisicao;
  end;

implementation

destructor TRequisicaoMensagensAnthropic.Destroy;
var
  LMensagemEntradaAnthropic: TMensagemEntradaAnthropic;
begin
  for LMensagemEntradaAnthropic in FMensagens do
    LMensagemEntradaAnthropic.Free;
  FMensagens := nil;
  inherited;
end;

destructor TRespostaAnthropic.Destroy;
var
  LConteudoSaidaAnthropic: TConteudoSaidaAnthropic;
begin
  for LConteudoSaidaAnthropic in FConteudo do
    LConteudoSaidaAnthropic.Free;
  FConteudo := nil;
  FUso.Free;
  inherited;
end;

destructor TEnvelopeErroAnthropic.Destroy;
begin
  FErro.Free;
  inherited;
end;

end.
