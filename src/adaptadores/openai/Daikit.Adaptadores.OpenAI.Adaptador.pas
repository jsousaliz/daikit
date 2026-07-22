unit Daikit.Adaptadores.OpenAI.Adaptador;

interface

uses
  Daikit.Dominio.Interfaces,
  Daikit.Aplicacao.Interfaces,
  Daikit.Adaptadores.Interfaces,
  Daikit.Infraestrutura.HTTP.Interfaces,
  Daikit.Adaptadores.OpenAI.Interfaces;

type
  TAdaptadorOpenAI = class(TInterfacedObject, IAdaptadorIA)
  private
    FTransporte: ITransporteHTTP;
    FFonteChaveAPI: IFonteChaveAPI;
    FConfiguracao: IConfiguracaoOpenAI;
    FMapeador: IMapeadorOpenAI;
    FCapacidades: ICapacidadesAdaptadorIA;
  public
    constructor Create(const ATransporte: ITransporteHTTP;
      const AFonteChaveAPI: IFonteChaveAPI;
      const AConfiguracao: IConfiguracaoOpenAI;
      const AMapeador: IMapeadorOpenAI);
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
  Daikit.Infraestrutura.JSON.Excecoes,
  Daikit.Infraestrutura.JSON.Serializador,
  Daikit.Adaptadores.OpenAI.Constantes,
  Daikit.Adaptadores.OpenAI.Contratos,
  Daikit.Adaptadores.OpenAI.Excecoes;

procedure LancarErroResposta(const AResposta: IRespostaHTTP);
var
  LEnvelope: TEnvelopeErroOpenAI;
  LTipo: string;
  LCodigo: string;
begin
  LTipo := '';
  LCodigo := '';
  LEnvelope := nil;
  try
    try
      LEnvelope := TSerializadorJSON.Desserializar<TEnvelopeErroOpenAI>(
        AResposta.Corpo);
      if LEnvelope.Erro <> nil then
      begin
        LTipo := LEnvelope.Erro.Tipo;
        LCodigo := LEnvelope.Erro.Codigo;
      end;
    except
      on E: ESerializacaoJSON do
      begin
        LTipo := '';
        LCodigo := '';
      end;
    end;
  finally
    LEnvelope.Free;
  end;
  raise ERespostaOpenAI.Create(AResposta.Status, LTipo, LCodigo,
    TCabecalhoHTTP.ObterValor(AResposta.Cabecalhos,
      CCabecalhoIdRequisicaoOpenAI));
end;

constructor TAdaptadorOpenAI.Create(const ATransporte: ITransporteHTTP;
  const AFonteChaveAPI: IFonteChaveAPI;
  const AConfiguracao: IConfiguracaoOpenAI;
  const AMapeador: IMapeadorOpenAI);
begin
  inherited Create;
  if ATransporte = nil then
    raise EConfiguracaoOpenAI.Create('O transporte HTTP deve ser informado.');
  if AFonteChaveAPI = nil then
    raise EConfiguracaoOpenAI.Create('A fonte da chave OpenAI deve ser informada.');
  if AConfiguracao = nil then
    raise EConfiguracaoOpenAI.Create('A configuracao OpenAI deve ser informada.');
  if AMapeador = nil then
    raise EConfiguracaoOpenAI.Create('O mapeador OpenAI deve ser informado.');
  FTransporte := ATransporte;
  FFonteChaveAPI := AFonteChaveAPI;
  FConfiguracao := AConfiguracao;
  FMapeador := AMapeador;
  FCapacidades := TCapacidadesAdaptadorIA.SomenteTextoSincrono;
end;

function TAdaptadorOpenAI.ObterCapacidades: ICapacidadesAdaptadorIA;
begin
  Result := FCapacidades;
end;

function TAdaptadorOpenAI.Concluir(const ARequisicao: IRequisicaoChatIA;
  const ACancelamento: ITokenCancelamentoIA): IRespostaChatIA;
var
  LChaveAPI: string;
  LContratoRequisicao: TRequisicaoRespostasOpenAI;
  LContratoResposta: TRespostaOpenAI;
  LCorpo: string;
  LCabecalhos: TArray<TCabecalhoHTTP>;
  LRequisicaoHTTP: IRequisicaoHTTP;
  LRespostaHTTP: IRespostaHTTP;
begin
  if ARequisicao = nil then
    raise EContratoOpenAI.Create('A requisicao canonica deve ser informada.');
  if (ACancelamento <> nil) and ACancelamento.FoiCancelado then
    raise EOperacaoCanceladaIA.Create('A operacao OpenAI foi cancelada.');

  LChaveAPI := Trim(FFonteChaveAPI.ObterChaveAPI);
  if LChaveAPI = '' then
    raise EConfiguracaoOpenAI.Create(
      'A chave da API OpenAI nao foi fornecida pela fonte configurada.');

  LContratoRequisicao := FMapeador.CriarContratoRequisicao(ARequisicao,
    FConfiguracao.ModeloPadrao);
  try
    LCorpo := TSerializadorJSON.Serializar(LContratoRequisicao);
  finally
    LContratoRequisicao.Free;
  end;

  SetLength(LCabecalhos, CQuantidadeCabecalhosRequisicaoOpenAI);
  LCabecalhos[CIndiceCabecalhoAutorizacaoOpenAI] :=
    TCabecalhoHTTP.Criar(CCabecalhoAutorizacao,
    CPrefixoBearer + LChaveAPI);
  LCabecalhos[CIndiceCabecalhoTipoConteudoOpenAI] :=
    TCabecalhoHTTP.Criar(CCabecalhoTipoConteudo,
    CTipoConteudoJSON);
  LCabecalhos[CIndiceCabecalhoAceiteOpenAI] :=
    TCabecalhoHTTP.Criar(CCabecalhoAceite,
    CTipoConteudoJSON);
  LRequisicaoHTTP := TRequisicaoHTTP.Create(TMetodoHTTP.Post,
    FConfiguracao.Endpoint, LCabecalhos, LCorpo,
    FConfiguracao.TimeoutConexaoMS, FConfiguracao.TimeoutRespostaMS,
    FConfiguracao.LimiteRespostaBytes);
  LRespostaHTTP := FTransporte.Enviar(LRequisicaoHTTP, ACancelamento);
  if LRespostaHTTP = nil then
    raise EContratoOpenAI.Create(
      'O transporte HTTP nao retornou uma resposta para a OpenAI.');
  if not LRespostaHTTP.FoiSucesso then
    LancarErroResposta(LRespostaHTTP);

  LContratoResposta := nil;
  try
    try
      LContratoResposta := TSerializadorJSON.Desserializar<TRespostaOpenAI>(
        LRespostaHTTP.Corpo);
    except
      on E: ESerializacaoJSON do
        raise EContratoOpenAI.Create(
          'A API OpenAI retornou um JSON de sucesso invalido.');
    end;
    if LContratoResposta.Erro <> nil then
      raise ERespostaOpenAI.Create(LRespostaHTTP.Status, '',
        LContratoResposta.Erro.Codigo,
        TCabecalhoHTTP.ObterValor(LRespostaHTTP.Cabecalhos,
          CCabecalhoIdRequisicaoOpenAI));
    Result := FMapeador.MapearResposta(LContratoResposta);
  finally
    LContratoResposta.Free;
  end;
end;

end.
