unit Daikit.Adaptadores.Gemini.Contratos;

interface

uses
  REST.Json.Types;

type
  TConteudoGemini = class
  private
    [JSONName('type')] FTipo: string;
    [JSONName('text')] FTexto: string;
  public
    property Tipo: string read FTipo write FTipo;
    property Texto: string read FTexto write FTexto;
  end;

  TPassoGemini = class
  private
    [JSONName('type')] FTipo: string;
    [JSONName('content')] FConteudo: TArray<TConteudoGemini>;
    [JSONName('signature')] FAssinatura: string;
    [JSONName('summary')] FResumo: TArray<TConteudoGemini>;
  public
    destructor Destroy; override;
    property Tipo: string read FTipo write FTipo;
    property Conteudo: TArray<TConteudoGemini> read FConteudo write FConteudo;
    property Assinatura: string read FAssinatura write FAssinatura;
    property Resumo: TArray<TConteudoGemini> read FResumo write FResumo;
  end;

  TContextoInteracaoGemini = class
  private
    [JSONName('steps')] FPassos: TArray<TPassoGemini>;
  public
    destructor Destroy; override;
    property Passos: TArray<TPassoGemini> read FPassos write FPassos;
  end;

  TConfiguracaoGeracaoGemini = class
  private
    [JSONName('max_output_tokens')] FMaximoTokensSaida: Integer;
  public
    property MaximoTokensSaida: Integer read FMaximoTokensSaida
      write FMaximoTokensSaida;
  end;

  TRequisicaoInteracaoGemini = class
  private
    [JSONName('model')] FModelo: string;
    [JSONName('input')] FEntrada: TArray<TPassoGemini>;
    [JSONName('system_instruction')] FInstrucaoSistema: string;
    [JSONName('store')] FArmazenar: Boolean;
    [JSONName('generation_config')]
    FConfiguracaoGeracao: TConfiguracaoGeracaoGemini;
  public
    destructor Destroy; override;
    property Modelo: string read FModelo write FModelo;
    property Entrada: TArray<TPassoGemini> read FEntrada write FEntrada;
    property InstrucaoSistema: string read FInstrucaoSistema
      write FInstrucaoSistema;
    property Armazenar: Boolean read FArmazenar write FArmazenar;
    property ConfiguracaoGeracao: TConfiguracaoGeracaoGemini
      read FConfiguracaoGeracao write FConfiguracaoGeracao;
  end;

  TUsoGemini = class
  private
    [JSONName('total_input_tokens')] FTotalTokensEntrada: Int64;
    [JSONName('input_tokens')] FTokensEntrada: Int64;
    [JSONName('total_output_tokens')] FTotalTokensSaida: Int64;
    [JSONName('output_tokens')] FTokensSaida: Int64;
    [JSONName('total_tokens')] FTotalTokens: Int64;
  public
    property TotalTokensEntrada: Int64 read FTotalTokensEntrada
      write FTotalTokensEntrada;
    property TokensEntrada: Int64 read FTokensEntrada write FTokensEntrada;
    property TotalTokensSaida: Int64 read FTotalTokensSaida
      write FTotalTokensSaida;
    property TokensSaida: Int64 read FTokensSaida write FTokensSaida;
    property TotalTokens: Int64 read FTotalTokens write FTotalTokens;
  end;

  TRespostaInteracaoGemini = class
  private
    [JSONName('id')] FId: string;
    [JSONName('model')] FModelo: string;
    [JSONName('status')] FStatus: string;
    [JSONName('steps')] FPassos: TArray<TPassoGemini>;
    [JSONName('usage')] FUso: TUsoGemini;
  public
    destructor Destroy; override;
    property Id: string read FId write FId;
    property Modelo: string read FModelo write FModelo;
    property Status: string read FStatus write FStatus;
    property Passos: TArray<TPassoGemini> read FPassos write FPassos;
    property Uso: TUsoGemini read FUso write FUso;
  end;

  TDetalheErroGemini = class
  private
    [JSONName('code')] FCodigo: Integer;
    [JSONName('message')] FMensagem: string;
    [JSONName('status')] FStatus: string;
  public
    property Codigo: Integer read FCodigo write FCodigo;
    property Mensagem: string read FMensagem write FMensagem;
    property Status: string read FStatus write FStatus;
  end;

  TEnvelopeErroGemini = class
  private
    [JSONName('error')] FErro: TDetalheErroGemini;
  public
    destructor Destroy; override;
    property Erro: TDetalheErroGemini read FErro write FErro;
  end;

implementation

destructor TPassoGemini.Destroy;
var
  LConteudoGemini: TConteudoGemini;
begin
  for LConteudoGemini in FConteudo do
    LConteudoGemini.Free;
  FConteudo := nil;
  for LConteudoGemini in FResumo do
    LConteudoGemini.Free;
  FResumo := nil;
  inherited;
end;

destructor TContextoInteracaoGemini.Destroy;
var
  LPassoGemini: TPassoGemini;
begin
  for LPassoGemini in FPassos do
    LPassoGemini.Free;
  FPassos := nil;
  inherited;
end;

destructor TRequisicaoInteracaoGemini.Destroy;
var
  LPassoGemini: TPassoGemini;
begin
  for LPassoGemini in FEntrada do
    LPassoGemini.Free;
  FEntrada := nil;
  FConfiguracaoGeracao.Free;
  inherited;
end;

destructor TRespostaInteracaoGemini.Destroy;
var
  LPassoGemini: TPassoGemini;
begin
  for LPassoGemini in FPassos do
    LPassoGemini.Free;
  FPassos := nil;
  FUso.Free;
  inherited;
end;

destructor TEnvelopeErroGemini.Destroy;
begin
  FErro.Free;
  inherited;
end;

end.
