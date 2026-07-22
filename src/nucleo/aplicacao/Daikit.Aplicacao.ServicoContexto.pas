unit Daikit.Aplicacao.ServicoContexto;

interface

uses
  Daikit.Dominio.Interfaces,
  Daikit.Aplicacao.Interfaces;

type
  TServicoContextoIA = class
  private
    FAdaptador: IAdaptadorIA;
    FContexto: IContextoIA;
    class procedure VerificarCancelamento(
      const ACancelamento: ITokenCancelamentoIA); static;
    class function AcrescentarMensagem(
      const AMensagens: TArray<IMensagemIA>;
      const AMensagem: IMensagemIA): TArray<IMensagemIA>; static;
  public
    constructor Create(const AAdaptador: IAdaptadorIA;
      const AContexto: IContextoIA);
    function Enviar(const AModelo, ATexto: string; AModo: TModoConversaIA;
      const ACancelamento: ITokenCancelamentoIA = nil): IRespostaChatIA;
  end;

implementation

uses
  Daikit.Aplicacao.Constantes,
  Daikit.Dominio.Excecoes,
  Daikit.Dominio.Mensagem,
  Daikit.Dominio.RequisicaoResposta;

constructor TServicoContextoIA.Create(const AAdaptador: IAdaptadorIA;
  const AContexto: IContextoIA);
begin
  inherited Create;
  if AAdaptador = nil then
    raise EValidacaoDominioIA.Create('O adaptador de IA deve ser informado.');
  if AContexto = nil then
    raise EValidacaoDominioIA.Create('O contexto de IA deve ser informado.');
  FAdaptador := AAdaptador;
  FContexto := AContexto;
end;

class function TServicoContextoIA.AcrescentarMensagem(
  const AMensagens: TArray<IMensagemIA>;
  const AMensagem: IMensagemIA): TArray<IMensagemIA>;
var
  I: Integer;
begin
  SetLength(Result, Length(AMensagens) + CQuantidadeMensagensAcrescentadas);
  for I := Low(AMensagens) to High(AMensagens) do
    Result[I] := AMensagens[I];
  Result[High(Result)] := AMensagem;
end;

function TServicoContextoIA.Enviar(const AModelo, ATexto: string;
  AModo: TModoConversaIA;
  const ACancelamento: ITokenCancelamentoIA): IRespostaChatIA;
var
  LUsuario: IMensagemIA;
  LMensagens: TArray<IMensagemIA>;
  LRequisicao: IRequisicaoChatIA;
begin
  VerificarCancelamento(ACancelamento);
  LUsuario := TMensagemIA.CriarTexto(TPapelMensagemIA.Usuario, ATexto);

  if AModo = TModoConversaIA.ManterHistorico then
    LMensagens := AcrescentarMensagem(FContexto.ObterMensagens, LUsuario)
  else
    LMensagens := AcrescentarMensagem(nil, LUsuario);

  LRequisicao := TRequisicaoChatIA.Create(AModelo, LMensagens);
  Result := FAdaptador.Concluir(LRequisicao, ACancelamento);
  VerificarCancelamento(ACancelamento);

  if Result = nil then
    raise EValidacaoDominioIA.Create('O adaptador retornou uma resposta nula.');

  if AModo = TModoConversaIA.ManterHistorico then
  begin
    FContexto.Adicionar(LUsuario);
    FContexto.Adicionar(Result.Mensagem);
  end;
end;

class procedure TServicoContextoIA.VerificarCancelamento(
  const ACancelamento: ITokenCancelamentoIA);
begin
  if (ACancelamento <> nil) and ACancelamento.FoiCancelado then
    raise EOperacaoCanceladaIA.Create('A operacao foi cancelada.');
end;

end.
