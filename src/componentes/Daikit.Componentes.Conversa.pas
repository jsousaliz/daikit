unit Daikit.Componentes.Conversa;

interface

uses
  System.Classes,
  Daikit.Dominio.Interfaces;

type
  TEventoConversaIA = procedure(Sender: TObject) of object;
  TEventoMensagemConversaIA = procedure(Sender: TObject;
    const AMensagem: IMensagemIA) of object;

  TConversaIA = class(TComponent)
  private
    FArmazenamento: IArmazenamentoContextoIA;
    FContexto: IContextoIA;
    FAoAdicionar: TEventoMensagemConversaIA;
    FAoLimpar: TEventoConversaIA;
    FAoAlterar: TEventoConversaIA;
    function ObterQuantidade: Integer;
    procedure NotificarMensagemAdicionada(const AMensagem: IMensagemIA);
    procedure NotificarAlteracao;
  public
    constructor Create(AOwner: TComponent); override;
    procedure DefinirArmazenamentoContexto(
      const AArmazenamentoContexto: IArmazenamentoContextoIA);
    function ObterContexto: IContextoIA;
    procedure AdicionarSistema(const ATexto: string);
    procedure AdicionarUsuario(const ATexto: string);
    procedure AdicionarAssistente(const ATexto: string);
    function ObterMensagens: TArray<IMensagemIA>;
    procedure Limpar;
    property Quantidade: Integer read ObterQuantidade;
  published
    property AoAdicionar: TEventoMensagemConversaIA
      read FAoAdicionar write FAoAdicionar;
    property AoLimpar: TEventoConversaIA read FAoLimpar write FAoLimpar;
    property AoAlterar: TEventoConversaIA read FAoAlterar write FAoAlterar;
  end;

implementation

uses
  Daikit.Dominio.ArmazenamentoContexto,
  Daikit.Dominio.Contexto;

constructor TConversaIA.Create(AOwner: TComponent);
begin
  inherited;
  DefinirArmazenamentoContexto(TArmazenamentoContextoIA.Create);
end;

procedure TConversaIA.AdicionarAssistente(const ATexto: string);
var
  LMensagem: IMensagemIA;
begin
  LMensagem := FContexto.AdicionarAssistente(ATexto);
  NotificarMensagemAdicionada(LMensagem);
end;

procedure TConversaIA.AdicionarSistema(const ATexto: string);
var
  LMensagem: IMensagemIA;
begin
  LMensagem := FContexto.AdicionarSistema(ATexto);
  NotificarMensagemAdicionada(LMensagem);
end;

procedure TConversaIA.AdicionarUsuario(const ATexto: string);
var
  LMensagem: IMensagemIA;
begin
  LMensagem := FContexto.AdicionarUsuario(ATexto);
  NotificarMensagemAdicionada(LMensagem);
end;

procedure TConversaIA.DefinirArmazenamentoContexto(
  const AArmazenamentoContexto: IArmazenamentoContextoIA);
var
  LContexto: IContextoIA;
  LTinhaContexto: Boolean;
begin
  LContexto := TContextoIA.Create(AArmazenamentoContexto);
  LTinhaContexto := FContexto <> nil;
  FArmazenamento := AArmazenamentoContexto;
  FContexto := LContexto;
  if LTinhaContexto then
    NotificarAlteracao;
end;

procedure TConversaIA.Limpar;
var
  LTinhaMensagens: Boolean;
begin
  LTinhaMensagens := FContexto.Quantidade > 0;
  FContexto.Limpar;
  if not LTinhaMensagens then
    Exit;
  if Assigned(FAoLimpar) then
    FAoLimpar(Self);
  NotificarAlteracao;
end;

procedure TConversaIA.NotificarAlteracao;
begin
  if Assigned(FAoAlterar) then
    FAoAlterar(Self);
end;

procedure TConversaIA.NotificarMensagemAdicionada(
  const AMensagem: IMensagemIA);
begin
  if Assigned(FAoAdicionar) then
    FAoAdicionar(Self, AMensagem);
  NotificarAlteracao;
end;

function TConversaIA.ObterContexto: IContextoIA;
begin
  Result := FContexto;
end;

function TConversaIA.ObterMensagens: TArray<IMensagemIA>;
begin
  Result := FContexto.ObterMensagens;
end;

function TConversaIA.ObterQuantidade: Integer;
begin
  Result := FContexto.Quantidade;
end;

initialization
  RegisterClass(TConversaIA);

end.
