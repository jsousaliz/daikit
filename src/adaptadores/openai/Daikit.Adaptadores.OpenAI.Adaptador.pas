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
    FTransporteHTTP: ITransporteHTTP;
    FFonteChaveAPI: IFonteChaveAPI;
    FConfiguracaoOpenAI: IConfiguracaoOpenAI;
    FMapeadorOpenAI: IMapeadorOpenAI;
    FCapacidadesAdaptador: ICapacidadesAdaptadorIA;
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
  LEnvelopeErroOpenAI: TEnvelopeErroOpenAI;
  LTipoErro: string;
  LCodigoErro: string;
begin
  LTipoErro := '';
  LCodigoErro := '';
  LEnvelopeErroOpenAI := nil;
  try
    try
      LEnvelopeErroOpenAI := TSerializadorJSON.Desserializar<TEnvelopeErroOpenAI>(
        AResposta.Corpo);
      if LEnvelopeErroOpenAI.Erro <> nil then
      begin
        LTipoErro := LEnvelopeErroOpenAI.Erro.Tipo;
        LCodigoErro := LEnvelopeErroOpenAI.Erro.Codigo;
      end;
    except
      on E: ESerializacaoJSON do
      begin
        LTipoErro := '';
        LCodigoErro := '';
      end;
    end;
  finally
    LEnvelopeErroOpenAI.Free;
  end;
  raise ERespostaOpenAI.Create(AResposta.Status, LTipoErro, LCodigoErro,
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
  FTransporteHTTP := ATransporte;
  FFonteChaveAPI := AFonteChaveAPI;
  FConfiguracaoOpenAI := AConfiguracao;
  FMapeadorOpenAI := AMapeador;
  FCapacidadesAdaptador := TCapacidadesAdaptadorIA.SomenteTextoSincrono;
end;

function TAdaptadorOpenAI.ObterCapacidades: ICapacidadesAdaptadorIA;
begin
  Result := FCapacidadesAdaptador;
end;

function TAdaptadorOpenAI.Concluir(const ARequisicao: IRequisicaoChatIA;
  const ACancelamento: ITokenCancelamentoIA): IRespostaChatIA;
var
  LChaveAPI: string;
  LContratoRequisicaoOpenAI: TRequisicaoRespostasOpenAI;
  LContratoRespostaOpenAI: TRespostaOpenAI;
  LJSONRequisicao: string;
  LCabecalhosHTTP: TArray<TCabecalhoHTTP>;
  LOpcoesRequisicaoHTTP: TOpcoesRequisicaoHTTP;
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

  LContratoRequisicaoOpenAI := FMapeadorOpenAI.CriarContratoRequisicao(ARequisicao,
    FConfiguracaoOpenAI.ModeloPadrao);
  try
    LJSONRequisicao := TSerializadorJSON.Serializar(LContratoRequisicaoOpenAI);
  finally
    LContratoRequisicaoOpenAI.Free;
  end;

  SetLength(LCabecalhosHTTP, CQuantidadeCabecalhosRequisicaoOpenAI);
  LCabecalhosHTTP[CIndiceCabecalhoAutorizacaoOpenAI] :=
    TCabecalhoHTTP.Criar(CCabecalhoAutorizacao,
    CPrefixoBearer + LChaveAPI);
  LCabecalhosHTTP[CIndiceCabecalhoTipoConteudoOpenAI] :=
    TCabecalhoHTTP.Criar(CCabecalhoTipoConteudo,
    CTipoConteudoJSON);
  LCabecalhosHTTP[CIndiceCabecalhoAceiteOpenAI] :=
    TCabecalhoHTTP.Criar(CCabecalhoAceite,
    CTipoConteudoJSON);
  LOpcoesRequisicaoHTTP := TOpcoesRequisicaoHTTP.Padrao;
  LOpcoesRequisicaoHTTP.Metodo := TMetodoHTTP.Post;
  LOpcoesRequisicaoHTTP.URL := FConfiguracaoOpenAI.Endpoint;
  LOpcoesRequisicaoHTTP.Cabecalhos := LCabecalhosHTTP;
  LOpcoesRequisicaoHTTP.Corpo := LJSONRequisicao;
  LOpcoesRequisicaoHTTP.TimeoutConexaoMS :=
    FConfiguracaoOpenAI.TimeoutConexaoMS;
  LOpcoesRequisicaoHTTP.TimeoutRespostaMS :=
    FConfiguracaoOpenAI.TimeoutRespostaMS;
  LOpcoesRequisicaoHTTP.LimiteRespostaBytes :=
    FConfiguracaoOpenAI.LimiteRespostaBytes;
  LRequisicaoHTTP := TRequisicaoHTTP.Create(LOpcoesRequisicaoHTTP);
  LRespostaHTTP := FTransporteHTTP.Enviar(LRequisicaoHTTP, ACancelamento);
  if LRespostaHTTP = nil then
    raise EContratoOpenAI.Create(
      'O transporte HTTP nao retornou uma resposta para a OpenAI.');
  if not LRespostaHTTP.FoiSucesso then
    LancarErroResposta(LRespostaHTTP);

  LContratoRespostaOpenAI := nil;
  try
    try
      LContratoRespostaOpenAI := TSerializadorJSON.Desserializar<TRespostaOpenAI>(
        LRespostaHTTP.Corpo);
    except
      on E: ESerializacaoJSON do
        raise EContratoOpenAI.Create(
          'A API OpenAI retornou um JSON de sucesso invalido.');
    end;
    if LContratoRespostaOpenAI.Erro <> nil then
      raise ERespostaOpenAI.Create(LRespostaHTTP.Status, '',
        LContratoRespostaOpenAI.Erro.Codigo,
        TCabecalhoHTTP.ObterValor(LRespostaHTTP.Cabecalhos,
          CCabecalhoIdRequisicaoOpenAI));
    Result := FMapeadorOpenAI.MapearResposta(LContratoRespostaOpenAI);
  finally
    LContratoRespostaOpenAI.Free;
  end;
end;

end.
