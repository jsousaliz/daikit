unit Daikit.Dominio.Contexto;

interface

uses
  Daikit.Dominio.Interfaces;

type
  TContextoIA = class(TInterfacedObject, IContextoIA)
  private
    FArmazenamento: IArmazenamentoContextoIA;
    function ObterQuantidade: Integer;
  public
    constructor Create(const AArmazenamento: IArmazenamentoContextoIA);
    procedure Adicionar(const AMensagem: IMensagemIA);
    function AdicionarSistema(const ATexto: string): IMensagemIA;
    function AdicionarUsuario(const ATexto: string): IMensagemIA;
    function AdicionarAssistente(const ATexto: string): IMensagemIA;
    function ObterMensagens: TArray<IMensagemIA>;
    procedure Limpar;
  end;

implementation

uses
  Daikit.Dominio.Excecoes,
  Daikit.Dominio.Mensagem;

constructor TContextoIA.Create(
  const AArmazenamento: IArmazenamentoContextoIA);
begin
  inherited Create;
  if AArmazenamento = nil then
    raise EValidacaoDominioIA.Create('O armazenamento do contexto de IA deve ser informado.');
  FArmazenamento := AArmazenamento;
end;

procedure TContextoIA.Adicionar(const AMensagem: IMensagemIA);
begin
  FArmazenamento.Adicionar(AMensagem);
end;

function TContextoIA.AdicionarAssistente(const ATexto: string): IMensagemIA;
begin
  Result := TMensagemIA.CriarTexto(TPapelMensagemIA.Assistente, ATexto);
  Adicionar(Result);
end;

function TContextoIA.AdicionarSistema(const ATexto: string): IMensagemIA;
begin
  Result := TMensagemIA.CriarTexto(TPapelMensagemIA.Sistema, ATexto);
  Adicionar(Result);
end;

function TContextoIA.AdicionarUsuario(const ATexto: string): IMensagemIA;
begin
  Result := TMensagemIA.CriarTexto(TPapelMensagemIA.Usuario, ATexto);
  Adicionar(Result);
end;

procedure TContextoIA.Limpar;
begin
  FArmazenamento.Limpar;
end;

function TContextoIA.ObterMensagens: TArray<IMensagemIA>;
begin
  Result := FArmazenamento.ObterInstantaneo;
end;

function TContextoIA.ObterQuantidade: Integer;
begin
  Result := FArmazenamento.Quantidade;
end;

end.
