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
    FAtrasoMS: Integer;
  public
    constructor Create(const APrefixoResposta: string = 'Resposta: ');
    function ObterCapacidades: ICapacidadesAdaptadorIA;
    function Concluir(const ARequisicao: IRequisicaoChatIA;
      const ACancelamento: ITokenCancelamentoIA = nil): IRespostaChatIA;
    function ListarModelos(
      const ACancelamento: ITokenCancelamentoIA = nil): TArray<IModeloIA>;
    property UltimaRequisicao: IRequisicaoChatIA read FUltimaRequisicao;
    property QuantidadeChamadas: Integer read FQuantidadeChamadas;
    property RetornarNulo: Boolean read FRetornarNulo write FRetornarNulo;
    property AtrasoMS: Integer read FAtrasoMS write FAtrasoMS;
  end;

implementation

uses
  System.Classes,
  Daikit.Aplicacao.CapacidadesAdaptador,
  Daikit.Testes.Constantes,
  Daikit.Dominio.Excecoes,
  Daikit.Dominio.Mensagem,
  Daikit.Dominio.Modelo,
  Daikit.Dominio.RequisicaoResposta;

constructor TAdaptadorIAFalso.Create(const APrefixoResposta: string);
begin
  inherited Create;
  FPrefixoResposta := APrefixoResposta;
end;

function TAdaptadorIAFalso.ListarModelos(
  const ACancelamento: ITokenCancelamentoIA): TArray<IModeloIA>;
begin
  if (ACancelamento <> nil) and ACancelamento.FoiCancelado then
    raise EOperacaoCanceladaIA.Create(
      'A listagem de modelos foi cancelada no provedor falso.');
  SetLength(Result, 2);
  Result[0] := TModeloIA.Create('modelo-falso-1', 'Modelo falso 1');
  Result[1] := TModeloIA.Create('modelo-falso-2', 'Modelo falso 2');
end;

function TAdaptadorIAFalso.ObterCapacidades: ICapacidadesAdaptadorIA;
begin
  Result := TCapacidadesAdaptadorIA.SomenteTextoSincrono;
end;

function TAdaptadorIAFalso.Concluir(const ARequisicao: IRequisicaoChatIA;
  const ACancelamento: ITokenCancelamentoIA): IRespostaChatIA;
var
  LDecorridoMS: Integer;
  LMensagens: TArray<IMensagemIA>;
  LMensagem: IMensagemIA;
  LUso: IUsoIA;
begin
  if ARequisicao = nil then
    raise EValidacaoDominioIA.Create('A requisicao do provedor falso deve ser informada.');
  if (ACancelamento <> nil) and ACancelamento.FoiCancelado then
    raise EOperacaoCanceladaIA.Create('A operacao foi cancelada no provedor falso.');

  LDecorridoMS := 0;
  while LDecorridoMS < FAtrasoMS do
  begin
    TThread.Sleep(10);
    Inc(LDecorridoMS, 10);
    if (ACancelamento <> nil) and ACancelamento.FoiCancelado then
      raise EOperacaoCanceladaIA.Create(
        'A operacao foi cancelada no provedor falso.');
  end;

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
