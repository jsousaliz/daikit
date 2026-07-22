unit Daikit.Adaptadores.OpenAI.Contratos;

interface

uses
  REST.Json.Types;

type
  TMensagemEntradaOpenAI = class
  private
    [JSONName('role')]
    FPapel: string;
    [JSONName('content')]
    FConteudo: string;
  public
    property Papel: string read FPapel write FPapel;
    property Conteudo: string read FConteudo write FConteudo;
  end;

  TRequisicaoRespostasOpenAI = class
  private
    [JSONName('model')]
    FModelo: string;
    [JSONName('input')]
    FEntrada: TArray<TMensagemEntradaOpenAI>;
    [JSONName('store')]
    FArmazenar: Boolean;
  public
    destructor Destroy; override;
    property Modelo: string read FModelo write FModelo;
    property Entrada: TArray<TMensagemEntradaOpenAI> read FEntrada write FEntrada;
    property Armazenar: Boolean read FArmazenar write FArmazenar;
  end;

  TConteudoSaidaOpenAI = class
  private
    [JSONName('type')]
    FTipo: string;
    [JSONName('text')]
    FTexto: string;
  public
    property Tipo: string read FTipo write FTipo;
    property Texto: string read FTexto write FTexto;
  end;

  TItemSaidaOpenAI = class
  private
    [JSONName('type')]
    FTipo: string;
    [JSONName('role')]
    FPapel: string;
    [JSONName('status')]
    FStatus: string;
    [JSONName('content')]
    FConteudo: TArray<TConteudoSaidaOpenAI>;
  public
    destructor Destroy; override;
    property Tipo: string read FTipo write FTipo;
    property Papel: string read FPapel write FPapel;
    property Status: string read FStatus write FStatus;
    property Conteudo: TArray<TConteudoSaidaOpenAI> read FConteudo write FConteudo;
  end;

  TUsoOpenAI = class
  private
    [JSONName('input_tokens')]
    FTokensEntrada: Int64;
    [JSONName('output_tokens')]
    FTokensSaida: Int64;
    [JSONName('total_tokens')]
    FTokensTotal: Int64;
  public
    property TokensEntrada: Int64 read FTokensEntrada write FTokensEntrada;
    property TokensSaida: Int64 read FTokensSaida write FTokensSaida;
    property TokensTotal: Int64 read FTokensTotal write FTokensTotal;
  end;

  TDetalheErroOpenAI = class
  private
    [JSONName('message')]
    FMensagem: string;
    [JSONName('type')]
    FTipo: string;
    [JSONName('param')]
    FParametro: string;
    [JSONName('code')]
    FCodigo: string;
  public
    property Mensagem: string read FMensagem write FMensagem;
    property Tipo: string read FTipo write FTipo;
    property Parametro: string read FParametro write FParametro;
    property Codigo: string read FCodigo write FCodigo;
  end;

  TRespostaOpenAI = class
  private
    [JSONName('id')]
    FId: string;
    [JSONName('status')]
    FStatus: string;
    [JSONName('model')]
    FModelo: string;
    [JSONName('output')]
    FSaida: TArray<TItemSaidaOpenAI>;
    [JSONName('usage')]
    FUso: TUsoOpenAI;
    [JSONName('error')]
    FErro: TDetalheErroOpenAI;
  public
    destructor Destroy; override;
    property Id: string read FId write FId;
    property Status: string read FStatus write FStatus;
    property Modelo: string read FModelo write FModelo;
    property Saida: TArray<TItemSaidaOpenAI> read FSaida write FSaida;
    property Uso: TUsoOpenAI read FUso write FUso;
    property Erro: TDetalheErroOpenAI read FErro write FErro;
  end;

  TEnvelopeErroOpenAI = class
  private
    [JSONName('error')]
    FErro: TDetalheErroOpenAI;
  public
    destructor Destroy; override;
    property Erro: TDetalheErroOpenAI read FErro write FErro;
  end;

implementation

destructor TRequisicaoRespostasOpenAI.Destroy;
var
  LMensagemEntradaOpenAI: TMensagemEntradaOpenAI;
begin
  for LMensagemEntradaOpenAI in FEntrada do
    LMensagemEntradaOpenAI.Free;
  FEntrada := nil;
  inherited;
end;

destructor TItemSaidaOpenAI.Destroy;
var
  LConteudoSaidaOpenAI: TConteudoSaidaOpenAI;
begin
  for LConteudoSaidaOpenAI in FConteudo do
    LConteudoSaidaOpenAI.Free;
  FConteudo := nil;
  inherited;
end;

destructor TRespostaOpenAI.Destroy;
var
  LItemSaidaOpenAI: TItemSaidaOpenAI;
begin
  for LItemSaidaOpenAI in FSaida do
    LItemSaidaOpenAI.Free;
  FSaida := nil;
  FUso.Free;
  FErro.Free;
  inherited;
end;

destructor TEnvelopeErroOpenAI.Destroy;
begin
  FErro.Free;
  inherited;
end;

end.
