unit Daikit.Testes.AdaptadorFalso;

interface

uses
  Daikit.Dominio.Interfaces,
  Daikit.Aplicacao.Interfaces;

type
  TAdaptadorIAFalso = class(TInterfacedObject, IAdaptadorIA)
  private
    FPrefixoResposta: string;
    FUltimaRequisicao: IRequisicaoChatIA;
    FQuantidadeChamadas: Integer;
    FRetornarNulo: Boolean;
  public
    constructor Create(const APrefixoResposta: string = 'Resposta: ');
    function ObterCapacidades: ICapacidadesAdaptadorIA;
    function Concluir(const ARequisicao: IRequisicaoChatIA;
      const ACancelamento: ITokenCancelamentoIA = nil): IRespostaChatIA;
    property UltimaRequisicao: IRequisicaoChatIA read FUltimaRequisicao;
    property QuantidadeChamadas: Integer read FQuantidadeChamadas;
    property RetornarNulo: Boolean read FRetornarNulo write FRetornarNulo;
  end;

implementation

uses
  Daikit.Aplicacao.CapacidadesAdaptador,
  Daikit.Testes.Constantes,
  Daikit.Dominio.Excecoes,
  Daikit.Dominio.Mensagem,
  Daikit.Dominio.RequisicaoResposta;

constructor TAdaptadorIAFalso.Create(const APrefixoResposta: string);
begin
  inherited Create;
  FPrefixoResposta := APrefixoResposta;
end;

function TAdaptadorIAFalso.ObterCapacidades: ICapacidadesAdaptadorIA;
begin
  Result := TCapacidadesAdaptadorIA.SomenteTextoSincrono;
end;

function TAdaptadorIAFalso.Concluir(const ARequisicao: IRequisicaoChatIA;
  const ACancelamento: ITokenCancelamentoIA): IRespostaChatIA;
var
  LMensagens: TArray<IMensagemIA>;
  LMensagem: IMensagemIA;
  LUso: IUsoIA;
begin
  if ARequisicao = nil then
    raise EValidacaoDominioIA.Create('A requisicao do provedor falso deve ser informada.');
  if (ACancelamento <> nil) and ACancelamento.FoiCancelado then
    raise EOperacaoCanceladaIA.Create('A operacao foi cancelada no provedor falso.');

  Inc(FQuantidadeChamadas);
  FUltimaRequisicao := ARequisicao;
  if FRetornarNulo then
    Exit(nil);

  LMensagens := ARequisicao.Mensagens;
  LMensagem := TMensagemIA.CriarTexto(TPapelMensagemIA.Assistente,
    FPrefixoResposta + LMensagens[High(LMensagens)].Texto);
  LUso := TUsoIA.Create(Length(LMensagens),
    CQuantidadeUnidadesSaidaProvedorFalso);
  Result := TRespostaChatIA.Create('resposta-falsa', LMensagem, LUso);
end;

end.
