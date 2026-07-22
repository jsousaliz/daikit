unit Daikit.Adaptadores.Anthropic.Adaptador;

interface

uses
  Daikit.Dominio.Interfaces,
  Daikit.Aplicacao.Interfaces,
  Daikit.Adaptadores.Interfaces,
  Daikit.Infraestrutura.HTTP.Interfaces,
  Daikit.Adaptadores.Anthropic.Interfaces;

type
  TAdaptadorAnthropic = class(TInterfacedObject, IAdaptadorIA)
  private
    FTransporteHTTP: ITransporteHTTP;
    FFonteChaveAPI: IFonteChaveAPI;
    FConfiguracaoAnthropic: IConfiguracaoAnthropic;
    FMapeadorAnthropic: IMapeadorAnthropic;
    FCapacidadesAdaptador: ICapacidadesAdaptadorIA;
  public
    constructor Create(const ATransporte: ITransporteHTTP;
      const AFonteChaveAPI: IFonteChaveAPI;
      const AConfiguracao: IConfiguracaoAnthropic;
      const AMapeador: IMapeadorAnthropic);
    function ObterCapacidades: ICapacidadesAdaptadorIA;
    function Concluir(const ARequisicao: IRequisicaoChatIA;
      const ACancelamento: ITokenCancelamentoIA = nil): IRespostaChatIA;
  end;

implementation

uses
  System.SysUtils,
  Daikit.Dominio.Excecoes,
  Daikit.Aplicacao.CapacidadesAdaptador,
  Daikit.Infraestrutura.HTTP.Modelos,
  Daikit.Infraestrutura.JSON.Constantes,
  Daikit.Infraestrutura.JSON.Excecoes,
  Daikit.Infraestrutura.JSON.Serializador,
  Daikit.Adaptadores.Anthropic.Constantes,
  Daikit.Adaptadores.Anthropic.Contratos,
  Daikit.Adaptadores.Anthropic.Excecoes;

procedure LancarErroResposta(const AResposta: IRespostaHTTP);
var
  LEnvelopeErroAnthropic: TEnvelopeErroAnthropic;
  LTipoErro: string;
  LIdRequisicao: string;
begin
  LTipoErro := '';
  LIdRequisicao := TCabecalhoHTTP.ObterValor(AResposta.Cabecalhos,
    CCabecalhoIdRequisicaoAnthropic);
  LEnvelopeErroAnthropic := nil;
  try
    try
      LEnvelopeErroAnthropic := TSerializadorJSON.Desserializar<TEnvelopeErroAnthropic>(
        AResposta.Corpo);
      if LEnvelopeErroAnthropic.Erro <> nil then
        LTipoErro := LEnvelopeErroAnthropic.Erro.Tipo;
      if (LIdRequisicao = '') and (LEnvelopeErroAnthropic.IdRequisicao <> '') then
        LIdRequisicao := LEnvelopeErroAnthropic.IdRequisicao;
    except
      on E: ESerializacaoJSON do
        LTipoErro := '';
    end;
  finally
    LEnvelopeErroAnthropic.Free;
  end;
  raise ERespostaAnthropic.Create(AResposta.Status, LTipoErro,
    LIdRequisicao);
end;

constructor TAdaptadorAnthropic.Create(const ATransporte: ITransporteHTTP;
  const AFonteChaveAPI: IFonteChaveAPI;
  const AConfiguracao: IConfiguracaoAnthropic;
  const AMapeador: IMapeadorAnthropic);
begin
  inherited Create;
  if (ATransporte = nil) or (AFonteChaveAPI = nil) or
    (AConfiguracao = nil) or (AMapeador = nil) then
    raise EConfiguracaoAnthropic.Create(
      'Todas as dependencias do provedor Anthropic devem ser informadas.');
  FTransporteHTTP := ATransporte;
  FFonteChaveAPI := AFonteChaveAPI;
  FConfiguracaoAnthropic := AConfiguracao;
  FMapeadorAnthropic := AMapeador;
  FCapacidadesAdaptador := TCapacidadesAdaptadorIA.SomenteTextoSincrono;
end;

function TAdaptadorAnthropic.ObterCapacidades: ICapacidadesAdaptadorIA;
begin
  Result := FCapacidadesAdaptador;
end;

function TAdaptadorAnthropic.Concluir(const ARequisicao: IRequisicaoChatIA;
  const ACancelamento: ITokenCancelamentoIA): IRespostaChatIA;
var
  LChaveAPI: string;
  LContratoRequisicaoAnthropic: TRequisicaoMensagensAnthropic;
  LContratoRespostaAnthropic: TRespostaAnthropic;
  LCabecalhosHTTP: TArray<TCabecalhoHTTP>;
  LOpcoesRequisicaoHTTP: TOpcoesRequisicaoHTTP;
  LRequisicaoHTTP: IRequisicaoHTTP;
  LRespostaHTTP: IRespostaHTTP;
  LJSONRequisicao: string;
begin
  if ARequisicao = nil then
    raise EContratoAnthropic.Create('A requisicao canonica deve ser informada.');
  if (ACancelamento <> nil) and ACancelamento.FoiCancelado then
    raise EOperacaoCanceladaIA.Create('A operacao Anthropic foi cancelada.');
  LChaveAPI := Trim(FFonteChaveAPI.ObterChaveAPI);
  if LChaveAPI = '' then
    raise EConfiguracaoAnthropic.Create(
      'A chave da API Anthropic nao foi fornecida pela fonte configurada.');
  LContratoRequisicaoAnthropic := FMapeadorAnthropic.CriarContratoRequisicao(ARequisicao,
    FConfiguracaoAnthropic.ModeloPadrao, FConfiguracaoAnthropic.MaximoTokens);
  try
    LJSONRequisicao := TSerializadorJSON.Serializar(LContratoRequisicaoAnthropic,
      COpcoesJSONSemVazios);
  finally
    LContratoRequisicaoAnthropic.Free;
  end;
  SetLength(LCabecalhosHTTP, CQuantidadeCabecalhosAnthropic);
  LCabecalhosHTTP[CIndiceChaveAnthropic] := TCabecalhoHTTP.Criar(
    CCabecalhoChaveAnthropic, LChaveAPI);
  LCabecalhosHTTP[CIndiceVersaoAnthropic] := TCabecalhoHTTP.Criar(
    CCabecalhoVersaoAnthropic, FConfiguracaoAnthropic.VersaoAPI);
  LCabecalhosHTTP[CIndiceTipoConteudoAnthropic] := TCabecalhoHTTP.Criar(
    CCabecalhoTipoConteudoAnthropic, CTipoConteudoJSONAnthropic);
  LCabecalhosHTTP[CIndiceAceiteAnthropic] := TCabecalhoHTTP.Criar(
    CCabecalhoAceiteAnthropic, CTipoConteudoJSONAnthropic);
  LOpcoesRequisicaoHTTP := TOpcoesRequisicaoHTTP.Padrao;
  LOpcoesRequisicaoHTTP.Metodo := TMetodoHTTP.Post;
  LOpcoesRequisicaoHTTP.URL := FConfiguracaoAnthropic.Endpoint;
  LOpcoesRequisicaoHTTP.Cabecalhos := LCabecalhosHTTP;
  LOpcoesRequisicaoHTTP.Corpo := LJSONRequisicao;
  LOpcoesRequisicaoHTTP.TimeoutConexaoMS :=
    FConfiguracaoAnthropic.TimeoutConexaoMS;
  LOpcoesRequisicaoHTTP.TimeoutRespostaMS :=
    FConfiguracaoAnthropic.TimeoutRespostaMS;
  LOpcoesRequisicaoHTTP.LimiteRespostaBytes :=
    FConfiguracaoAnthropic.LimiteRespostaBytes;
  LRequisicaoHTTP := TRequisicaoHTTP.Create(LOpcoesRequisicaoHTTP);
  LRespostaHTTP := FTransporteHTTP.Enviar(LRequisicaoHTTP, ACancelamento);
  if LRespostaHTTP = nil then
    raise EContratoAnthropic.Create(
      'O transporte HTTP nao retornou uma resposta para a Anthropic.');
  if not LRespostaHTTP.FoiSucesso then
    LancarErroResposta(LRespostaHTTP);
  LContratoRespostaAnthropic := nil;
  try
    try
      LContratoRespostaAnthropic := TSerializadorJSON.Desserializar<TRespostaAnthropic>(
        LRespostaHTTP.Corpo);
    except
      on E: ESerializacaoJSON do
        raise EContratoAnthropic.Create(
          'A API Anthropic retornou um JSON de sucesso invalido.');
    end;
    Result := FMapeadorAnthropic.MapearResposta(LContratoRespostaAnthropic);
  finally
    LContratoRespostaAnthropic.Free;
  end;
end;

end.
