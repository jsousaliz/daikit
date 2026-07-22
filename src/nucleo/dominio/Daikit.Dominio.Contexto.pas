unit Daikit.Dominio.Contexto;

interface

uses
  Daikit.Dominio.Interfaces;

type
  TContextoIA = class(TInterfacedObject, IContextoIA)
  private
    FArmazenamentoContexto: IArmazenamentoContextoIA;
    function ObterQuantidade: Integer;
  public
    constructor Create(const AArmazenamento: IArmazenamentoContextoIA);
    procedure Adicionar(const AMensagem: IMensagemIA);
    function AdicionarMensagemSistema(const ATexto: string): IMensagemIA;
    function AdicionarMensagemUsuario(const ATexto: string): IMensagemIA;
    function AdicionarMensagemAssistente(const ATexto: string): IMensagemIA;
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
  FArmazenamentoContexto := AArmazenamento;
end;

procedure TContextoIA.Adicionar(const AMensagem: IMensagemIA);
begin
  FArmazenamentoContexto.Adicionar(AMensagem);
end;

function TContextoIA.AdicionarMensagemAssistente(
  const ATexto: string): IMensagemIA;
begin
  Result := TMensagemIA.CriarTexto(TPapelMensagemIA.Assistente, ATexto);
  Adicionar(Result);
end;

function TContextoIA.AdicionarMensagemSistema(
  const ATexto: string): IMensagemIA;
begin
  Result := TMensagemIA.CriarTexto(TPapelMensagemIA.Sistema, ATexto);
  Adicionar(Result);
end;

function TContextoIA.AdicionarMensagemUsuario(
  const ATexto: string): IMensagemIA;
begin
  Result := TMensagemIA.CriarTexto(TPapelMensagemIA.Usuario, ATexto);
  Adicionar(Result);
end;

procedure TContextoIA.Limpar;
begin
  FArmazenamentoContexto.Limpar;
end;

function TContextoIA.ObterMensagens: TArray<IMensagemIA>;
begin
  Result := FArmazenamentoContexto.ObterInstantaneo;
end;

function TContextoIA.ObterQuantidade: Integer;
begin
  Result := FArmazenamentoContexto.Quantidade;
end;

end.
