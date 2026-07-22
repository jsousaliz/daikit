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
    FTransporte: ITransporteHTTP;
    FFonteChaveAPI: IFonteChaveAPI;
    FConfiguracao: IConfiguracaoAnthropic;
    FMapeador: IMapeadorAnthropic;
    FCapacidades: ICapacidadesAdaptadorIA;
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
  LEnvelope: TEnvelopeErroAnthropic;
  LTipoErro: string;
  LIdRequisicao: string;
begin
  LTipoErro := '';
  LIdRequisicao := TCabecalhoHTTP.ObterValor(AResposta.Cabecalhos,
    CCabecalhoIdRequisicaoAnthropic);
  LEnvelope := nil;
  try
    try
      LEnvelope := TSerializadorJSON.Desserializar<TEnvelopeErroAnthropic>(
        AResposta.Corpo);
      if LEnvelope.Erro <> nil then
        LTipoErro := LEnvelope.Erro.Tipo;
      if (LIdRequisicao = '') and (LEnvelope.IdRequisicao <> '') then
        LIdRequisicao := LEnvelope.IdRequisicao;
    except
      on E: ESerializacaoJSON do
        LTipoErro := '';
    end;
  finally
    LEnvelope.Free;
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
  FTransporte := ATransporte;
  FFonteChaveAPI := AFonteChaveAPI;
  FConfiguracao := AConfiguracao;
  FMapeador := AMapeador;
  FCapacidades := TCapacidadesAdaptadorIA.SomenteTextoSincrono;
end;

function TAdaptadorAnthropic.ObterCapacidades: ICapacidadesAdaptadorIA;
begin
  Result := FCapacidades;
end;

function TAdaptadorAnthropic.Concluir(const ARequisicao: IRequisicaoChatIA;
  const ACancelamento: ITokenCancelamentoIA): IRespostaChatIA;
var
  LChave: string;
  LContratoRequisicao: TRequisicaoMensagensAnthropic;
  LContratoResposta: TRespostaAnthropic;
  LCabecalhos: TArray<TCabecalhoHTTP>;
  LRequisicaoHTTP: IRequisicaoHTTP;
  LRespostaHTTP: IRespostaHTTP;
  LCorpo: string;
begin
  if ARequisicao = nil then
    raise EContratoAnthropic.Create('A requisicao canonica deve ser informada.');
  if (ACancelamento <> nil) and ACancelamento.FoiCancelado then
    raise EOperacaoCanceladaIA.Create('A operacao Anthropic foi cancelada.');
  LChave := Trim(FFonteChaveAPI.ObterChaveAPI);
  if LChave = '' then
    raise EConfiguracaoAnthropic.Create(
      'A chave da API Anthropic nao foi fornecida pela fonte configurada.');
  LContratoRequisicao := FMapeador.CriarContratoRequisicao(ARequisicao,
    FConfiguracao.ModeloPadrao, FConfiguracao.MaximoTokens);
  try
    LCorpo := TSerializadorJSON.Serializar(LContratoRequisicao,
      COpcoesJSONSemVazios);
  finally
    LContratoRequisicao.Free;
  end;
  SetLength(LCabecalhos, CQuantidadeCabecalhosAnthropic);
  LCabecalhos[CIndiceChaveAnthropic] := TCabecalhoHTTP.Criar(
    CCabecalhoChaveAnthropic, LChave);
  LCabecalhos[CIndiceVersaoAnthropic] := TCabecalhoHTTP.Criar(
    CCabecalhoVersaoAnthropic, FConfiguracao.VersaoAPI);
  LCabecalhos[CIndiceTipoConteudoAnthropic] := TCabecalhoHTTP.Criar(
    CCabecalhoTipoConteudoAnthropic, CTipoConteudoJSONAnthropic);
  LCabecalhos[CIndiceAceiteAnthropic] := TCabecalhoHTTP.Criar(
    CCabecalhoAceiteAnthropic, CTipoConteudoJSONAnthropic);
  LRequisicaoHTTP := TRequisicaoHTTP.Create(TMetodoHTTP.Post,
    FConfiguracao.Endpoint, LCabecalhos, LCorpo,
    FConfiguracao.TimeoutConexaoMS, FConfiguracao.TimeoutRespostaMS,
    FConfiguracao.LimiteRespostaBytes);
  LRespostaHTTP := FTransporte.Enviar(LRequisicaoHTTP, ACancelamento);
  if LRespostaHTTP = nil then
    raise EContratoAnthropic.Create(
      'O transporte HTTP nao retornou uma resposta para a Anthropic.');
  if not LRespostaHTTP.FoiSucesso then
    LancarErroResposta(LRespostaHTTP);
  LContratoResposta := nil;
  try
    try
      LContratoResposta := TSerializadorJSON.Desserializar<TRespostaAnthropic>(
        LRespostaHTTP.Corpo);
    except
      on E: ESerializacaoJSON do
        raise EContratoAnthropic.Create(
          'A API Anthropic retornou um JSON de sucesso invalido.');
    end;
    Result := FMapeador.MapearResposta(LContratoResposta);
  finally
    LContratoResposta.Free;
  end;
end;

end.
