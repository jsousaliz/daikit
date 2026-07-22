unit Daikit.Adaptadores.Gemini.Adaptador;

interface

uses
  Daikit.Dominio.Interfaces,
  Daikit.Aplicacao.Interfaces,
  Daikit.Adaptadores.Interfaces,
  Daikit.Infraestrutura.HTTP.Interfaces,
  Daikit.Adaptadores.Gemini.Interfaces;

type
  TAdaptadorGemini = class(TInterfacedObject, IAdaptadorIA)
  private
    FTransporteHTTP: ITransporteHTTP;
    FFonteChaveAPI: IFonteChaveAPI;
    FConfiguracaoGemini: IConfiguracaoGemini;
    FMapeadorGemini: IMapeadorGemini;
    FCapacidadesAdaptador: ICapacidadesAdaptadorIA;
  public
    constructor Create(const ATransporte: ITransporteHTTP;
      const AFonteChaveAPI: IFonteChaveAPI;
      const AConfiguracao: IConfiguracaoGemini;
      const AMapeador: IMapeadorGemini);
    function ObterCapacidades: ICapacidadesAdaptadorIA;
    function Concluir(const ARequisicao: IRequisicaoChatIA;
      const ACancelamento: ITokenCancelamentoIA = nil): IRespostaChatIA;
    function ListarModelos(
      const ACancelamento: ITokenCancelamentoIA = nil): TArray<IModeloIA>;
  end;

implementation

uses
  System.SysUtils,
  System.JSON,
  System.Generics.Collections,
  Daikit.Dominio.Excecoes,
  Daikit.Aplicacao.CapacidadesAdaptador,
  Daikit.Infraestrutura.HTTP.Modelos,
  Daikit.Infraestrutura.HTTP.Sanitizador,
  Daikit.Infraestrutura.JSON.Constantes,
  Daikit.Infraestrutura.JSON.Excecoes,
  Daikit.Infraestrutura.JSON.Serializador,
  Daikit.Adaptadores.Gemini.Constantes,
  Daikit.Adaptadores.Gemini.Contratos,
  Daikit.Adaptadores.Gemini.Excecoes;

function NormalizarEnvelopeErro(const ACorpo: string): string;
var
  LValorJSON: TJSONValue;
  LListaJSON: TJSONArray;
begin
  Result := '';
  LValorJSON := nil;
  try
    try
      LValorJSON := TJSONObject.ParseJSONValue(ACorpo);
      if LValorJSON is TJSONObject then
        Result := LValorJSON.ToJSON
      else if LValorJSON is TJSONArray then
      begin
        LListaJSON := TJSONArray(LValorJSON);
        if (LListaJSON.Count > 0) and
          (LListaJSON.Items[0] is TJSONObject) then
          Result := LListaJSON.Items[0].ToJSON;
      end;
    except
      Result := '';
    end;
  finally
    LValorJSON.Free;
  end;
end;

procedure LancarErroResposta(const AResposta: IRespostaHTTP;
  const AChaveAPI: string);
var
  LEnvelopeErroGemini: TEnvelopeErroGemini;
  LJSONErro: string;
  LCodigoErro: Integer;
  LTipoErro: string;
  LIdRequisicao: string;
  LMensagemAPI: string;
begin
  LCodigoErro := 0;
  LTipoErro := '';
  LMensagemAPI := '';
  LIdRequisicao := TCabecalhoHTTP.ObterValor(AResposta.Cabecalhos,
    CCabecalhoIdRequisicaoGemini);
  LEnvelopeErroGemini := nil;
  try
    try
      LJSONErro := NormalizarEnvelopeErro(AResposta.Corpo);
      if LJSONErro <> '' then
        LEnvelopeErroGemini := TSerializadorJSON.Desserializar<TEnvelopeErroGemini>(
          LJSONErro);
      if (LEnvelopeErroGemini <> nil) and (LEnvelopeErroGemini.Erro <> nil) then
      begin
        LCodigoErro := LEnvelopeErroGemini.Erro.Codigo;
        LTipoErro := LEnvelopeErroGemini.Erro.Status;
        LMensagemAPI := LEnvelopeErroGemini.Erro.Mensagem;
      end;
    except
      on E: ESerializacaoJSON do
      begin
        LCodigoErro := 0;
        LTipoErro := '';
        LMensagemAPI := '';
      end;
    end;
  finally
    LEnvelopeErroGemini.Free;
  end;
  raise ERespostaGemini.Create(AResposta.Status, LCodigoErro, LTipoErro,
    LIdRequisicao, TSanitizadorHTTP.SanitizarMensagemErro(LMensagemAPI,
      [AChaveAPI]));
end;

constructor TAdaptadorGemini.Create(const ATransporte: ITransporteHTTP;
  const AFonteChaveAPI: IFonteChaveAPI;
  const AConfiguracao: IConfiguracaoGemini;
  const AMapeador: IMapeadorGemini);
begin
  inherited Create;
  if (ATransporte = nil) or (AFonteChaveAPI = nil) or
    (AConfiguracao = nil) or (AMapeador = nil) then
    raise EConfiguracaoGemini.Create(
      'Todas as dependencias do provedor Gemini devem ser informadas.');
  if AConfiguracao.ModoContexto <> TModoContextoGemini.Local then
    raise EConfiguracaoGemini.Create(
      'O provedor Gemini suporta apenas contexto local nesta versao.');
  FTransporteHTTP := ATransporte;
  FFonteChaveAPI := AFonteChaveAPI;
  FConfiguracaoGemini := AConfiguracao;
  FMapeadorGemini := AMapeador;
  FCapacidadesAdaptador := TCapacidadesAdaptadorIA.SomenteTextoSincrono;
end;

function TAdaptadorGemini.ObterCapacidades: ICapacidadesAdaptadorIA;
begin
  Result := FCapacidadesAdaptador;
end;

function TAdaptadorGemini.ListarModelos(
  const ACancelamento: ITokenCancelamentoIA): TArray<IModeloIA>;
var
  LChaveAPI: string;
  LCabecalhosHTTP: TArray<TCabecalhoHTTP>;
  LOpcoesRequisicaoHTTP: TOpcoesRequisicaoHTTP;
  LRequisicaoHTTP: IRequisicaoHTTP;
  LRespostaHTTP: IRespostaHTTP;
  LRespostaModelosGemini: TRespostaModelosGemini;
begin
  if (ACancelamento <> nil) and ACancelamento.FoiCancelado then
    raise EOperacaoCanceladaIA.Create(
      'A listagem de modelos Gemini foi cancelada.');
  LChaveAPI := Trim(FFonteChaveAPI.ObterChaveAPI);
  if LChaveAPI = '' then
    raise EConfiguracaoGemini.Create(
      'A chave da API Gemini nao foi fornecida pela fonte configurada.');
  SetLength(LCabecalhosHTTP, CQuantidadeCabecalhosGemini);
  LCabecalhosHTTP[CIndiceChaveGemini] := TCabecalhoHTTP.Criar(
    CCabecalhoChaveGemini, LChaveAPI);
  LCabecalhosHTTP[CIndiceTipoConteudoGemini] := TCabecalhoHTTP.Criar(
    CCabecalhoTipoConteudoGemini, CTipoConteudoJSONGemini);
  LCabecalhosHTTP[CIndiceAceiteGemini] := TCabecalhoHTTP.Criar(
    CCabecalhoAceiteGemini, CTipoConteudoJSONGemini);
  LOpcoesRequisicaoHTTP := TOpcoesRequisicaoHTTP.Padrao;
  LOpcoesRequisicaoHTTP.Metodo := TMetodoHTTP.Get;
  LOpcoesRequisicaoHTTP.URL := FConfiguracaoGemini.EndpointModelos;
  LOpcoesRequisicaoHTTP.Cabecalhos := LCabecalhosHTTP;
  LOpcoesRequisicaoHTTP.TimeoutConexaoMS :=
    FConfiguracaoGemini.TimeoutConexaoMS;
  LOpcoesRequisicaoHTTP.TimeoutRespostaMS :=
    FConfiguracaoGemini.TimeoutRespostaMS;
  LOpcoesRequisicaoHTTP.LimiteRespostaBytes :=
    FConfiguracaoGemini.LimiteRespostaBytes;
  LRequisicaoHTTP := TRequisicaoHTTP.Create(LOpcoesRequisicaoHTTP);
  LRespostaHTTP := FTransporteHTTP.Enviar(LRequisicaoHTTP, ACancelamento);
  if LRespostaHTTP = nil then
    raise EContratoGemini.Create(
      'O transporte HTTP nao retornou a lista de modelos Gemini.');
  if not LRespostaHTTP.FoiSucesso then
    LancarErroResposta(LRespostaHTTP, LChaveAPI);
  LRespostaModelosGemini := nil;
  try
    try
      LRespostaModelosGemini := TSerializadorJSON.Desserializar<
        TRespostaModelosGemini>(LRespostaHTTP.Corpo);
    except
      on E: ESerializacaoJSON do
        raise EContratoGemini.Create(
          'A API Gemini retornou uma lista de modelos invalida.');
    end;
    Result := FMapeadorGemini.MapearModelos(LRespostaModelosGemini);
  finally
    LRespostaModelosGemini.Free;
  end;
end;

function TAdaptadorGemini.Concluir(const ARequisicao: IRequisicaoChatIA;
  const ACancelamento: ITokenCancelamentoIA): IRespostaChatIA;
var
  LChaveAPI: string;
  LContratoRequisicaoGemini: TRequisicaoInteracaoGemini;
  LContratoRespostaGemini: TRespostaInteracaoGemini;
  LCabecalhosHTTP: TArray<TCabecalhoHTTP>;
  LOpcoesRequisicaoHTTP: TOpcoesRequisicaoHTTP;
  LRequisicaoHTTP: IRequisicaoHTTP;
  LRespostaHTTP: IRespostaHTTP;
  LJSONRequisicao: string;
begin
  if ARequisicao = nil then
    raise EContratoGemini.Create('A requisicao canonica deve ser informada.');
  if (ACancelamento <> nil) and ACancelamento.FoiCancelado then
    raise EOperacaoCanceladaIA.Create('A operacao Gemini foi cancelada.');
  LChaveAPI := Trim(FFonteChaveAPI.ObterChaveAPI);
  if LChaveAPI = '' then
    raise EConfiguracaoGemini.Create(
      'A chave da API Gemini nao foi fornecida pela fonte configurada.');
  LContratoRequisicaoGemini := FMapeadorGemini.CriarContratoRequisicao(ARequisicao,
    FConfiguracaoGemini.ModeloPadrao, FConfiguracaoGemini.MaximoTokens);
  try
    LJSONRequisicao := TSerializadorJSON.Serializar(LContratoRequisicaoGemini,
      COpcoesJSONSemVazios);
  finally
    LContratoRequisicaoGemini.Free;
  end;
  SetLength(LCabecalhosHTTP, CQuantidadeCabecalhosGemini);
  LCabecalhosHTTP[CIndiceChaveGemini] := TCabecalhoHTTP.Criar(
    CCabecalhoChaveGemini, LChaveAPI);
  LCabecalhosHTTP[CIndiceTipoConteudoGemini] := TCabecalhoHTTP.Criar(
    CCabecalhoTipoConteudoGemini, CTipoConteudoJSONGemini);
  LCabecalhosHTTP[CIndiceAceiteGemini] := TCabecalhoHTTP.Criar(
    CCabecalhoAceiteGemini, CTipoConteudoJSONGemini);
  LOpcoesRequisicaoHTTP := TOpcoesRequisicaoHTTP.Padrao;
  LOpcoesRequisicaoHTTP.Metodo := TMetodoHTTP.Post;
  LOpcoesRequisicaoHTTP.URL := FConfiguracaoGemini.Endpoint;
  LOpcoesRequisicaoHTTP.Cabecalhos := LCabecalhosHTTP;
  LOpcoesRequisicaoHTTP.Corpo := LJSONRequisicao;
  LOpcoesRequisicaoHTTP.TimeoutConexaoMS :=
    FConfiguracaoGemini.TimeoutConexaoMS;
  LOpcoesRequisicaoHTTP.TimeoutRespostaMS :=
    FConfiguracaoGemini.TimeoutRespostaMS;
  LOpcoesRequisicaoHTTP.LimiteRespostaBytes :=
    FConfiguracaoGemini.LimiteRespostaBytes;
  LRequisicaoHTTP := TRequisicaoHTTP.Create(LOpcoesRequisicaoHTTP);
  LRespostaHTTP := FTransporteHTTP.Enviar(LRequisicaoHTTP, ACancelamento);
  if LRespostaHTTP = nil then
    raise EContratoGemini.Create(
      'O transporte HTTP nao retornou uma resposta para a Gemini.');
  if not LRespostaHTTP.FoiSucesso then
    LancarErroResposta(LRespostaHTTP, LChaveAPI);
  LContratoRespostaGemini := nil;
  try
    try
      LContratoRespostaGemini :=
        TSerializadorJSON.Desserializar<TRespostaInteracaoGemini>(
          LRespostaHTTP.Corpo);
    except
      on E: ESerializacaoJSON do
        raise EContratoGemini.Create(
          'A API Gemini retornou um JSON de sucesso invalido.');
    end;
    Result := FMapeadorGemini.MapearResposta(LContratoRespostaGemini);
  finally
    LContratoRespostaGemini.Free;
  end;
end;

end.
