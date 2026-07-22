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
    FTransporte: ITransporteHTTP;
    FFonteChaveAPI: IFonteChaveAPI;
    FConfiguracao: IConfiguracaoGemini;
    FMapeador: IMapeadorGemini;
    FCapacidades: ICapacidadesAdaptadorIA;
  public
    constructor Create(const ATransporte: ITransporteHTTP;
      const AFonteChaveAPI: IFonteChaveAPI;
      const AConfiguracao: IConfiguracaoGemini;
      const AMapeador: IMapeadorGemini);
    function ObterCapacidades: ICapacidadesAdaptadorIA;
    function Concluir(const ARequisicao: IRequisicaoChatIA;
      const ACancelamento: ITokenCancelamentoIA = nil): IRespostaChatIA;
  end;

implementation

uses
  System.SysUtils,
  System.JSON,
  System.Generics.Collections,
  Daikit.Dominio.Excecoes,
  Daikit.Aplicacao.CapacidadesAdaptador,
  Daikit.Infraestrutura.HTTP.Modelos,
  Daikit.Infraestrutura.JSON.Constantes,
  Daikit.Infraestrutura.JSON.Excecoes,
  Daikit.Infraestrutura.JSON.Serializador,
  Daikit.Adaptadores.Gemini.Constantes,
  Daikit.Adaptadores.Gemini.Contratos,
  Daikit.Adaptadores.Gemini.Excecoes;

function NormalizarEnvelopeErro(const ACorpo: string): string;
var
  LJSON: TJSONValue;
  LLista: TJSONArray;
begin
  Result := '';
  LJSON := nil;
  try
    try
      LJSON := TJSONObject.ParseJSONValue(ACorpo);
      if LJSON is TJSONObject then
        Result := LJSON.ToJSON
      else if LJSON is TJSONArray then
      begin
        LLista := TJSONArray(LJSON);
        if (LLista.Count > 0) and
          (LLista.Items[0] is TJSONObject) then
          Result := LLista.Items[0].ToJSON;
      end;
    except
      Result := '';
    end;
  finally
    LJSON.Free;
  end;
end;

procedure LancarErroResposta(const AResposta: IRespostaHTTP);
var
  LEnvelope: TEnvelopeErroGemini;
  LCorpoErro: string;
  LCodigo: Integer;
  LTipoErro: string;
  LIdRequisicao: string;
begin
  LCodigo := 0;
  LTipoErro := '';
  LIdRequisicao := TCabecalhoHTTP.ObterValor(AResposta.Cabecalhos,
    CCabecalhoIdRequisicaoGemini);
  LEnvelope := nil;
  try
    try
      LCorpoErro := NormalizarEnvelopeErro(AResposta.Corpo);
      if LCorpoErro <> '' then
        LEnvelope := TSerializadorJSON.Desserializar<TEnvelopeErroGemini>(
          LCorpoErro);
      if (LEnvelope <> nil) and (LEnvelope.Erro <> nil) then
      begin
        LCodigo := LEnvelope.Erro.Codigo;
        LTipoErro := LEnvelope.Erro.Status;
      end;
    except
      on E: ESerializacaoJSON do
      begin
        LCodigo := 0;
        LTipoErro := '';
      end;
    end;
  finally
    LEnvelope.Free;
  end;
  raise ERespostaGemini.Create(AResposta.Status, LCodigo, LTipoErro,
    LIdRequisicao);
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
  FTransporte := ATransporte;
  FFonteChaveAPI := AFonteChaveAPI;
  FConfiguracao := AConfiguracao;
  FMapeador := AMapeador;
  FCapacidades := TCapacidadesAdaptadorIA.SomenteTextoSincrono;
end;

function TAdaptadorGemini.ObterCapacidades: ICapacidadesAdaptadorIA;
begin
  Result := FCapacidades;
end;

function TAdaptadorGemini.Concluir(const ARequisicao: IRequisicaoChatIA;
  const ACancelamento: ITokenCancelamentoIA): IRespostaChatIA;
var
  LChave: string;
  LContratoRequisicao: TRequisicaoInteracaoGemini;
  LContratoResposta: TRespostaInteracaoGemini;
  LCabecalhos: TArray<TCabecalhoHTTP>;
  LRequisicaoHTTP: IRequisicaoHTTP;
  LRespostaHTTP: IRespostaHTTP;
  LCorpo: string;
begin
  if ARequisicao = nil then
    raise EContratoGemini.Create('A requisicao canonica deve ser informada.');
  if (ACancelamento <> nil) and ACancelamento.FoiCancelado then
    raise EOperacaoCanceladaIA.Create('A operacao Gemini foi cancelada.');
  LChave := Trim(FFonteChaveAPI.ObterChaveAPI);
  if LChave = '' then
    raise EConfiguracaoGemini.Create(
      'A chave da API Gemini nao foi fornecida pela fonte configurada.');
  LContratoRequisicao := FMapeador.CriarContratoRequisicao(ARequisicao,
    FConfiguracao.ModeloPadrao, FConfiguracao.MaximoTokens);
  try
    LCorpo := TSerializadorJSON.Serializar(LContratoRequisicao,
      COpcoesJSONSemVazios);
  finally
    LContratoRequisicao.Free;
  end;
  SetLength(LCabecalhos, CQuantidadeCabecalhosGemini);
  LCabecalhos[CIndiceChaveGemini] := TCabecalhoHTTP.Criar(
    CCabecalhoChaveGemini, LChave);
  LCabecalhos[CIndiceTipoConteudoGemini] := TCabecalhoHTTP.Criar(
    CCabecalhoTipoConteudoGemini, CTipoConteudoJSONGemini);
  LCabecalhos[CIndiceAceiteGemini] := TCabecalhoHTTP.Criar(
    CCabecalhoAceiteGemini, CTipoConteudoJSONGemini);
  LRequisicaoHTTP := TRequisicaoHTTP.Create(TMetodoHTTP.Post,
    FConfiguracao.Endpoint, LCabecalhos, LCorpo,
    FConfiguracao.TimeoutConexaoMS, FConfiguracao.TimeoutRespostaMS,
    FConfiguracao.LimiteRespostaBytes);
  LRespostaHTTP := FTransporte.Enviar(LRequisicaoHTTP, ACancelamento);
  if LRespostaHTTP = nil then
    raise EContratoGemini.Create(
      'O transporte HTTP nao retornou uma resposta para a Gemini.');
  if not LRespostaHTTP.FoiSucesso then
    LancarErroResposta(LRespostaHTTP);
  LContratoResposta := nil;
  try
    try
      LContratoResposta :=
        TSerializadorJSON.Desserializar<TRespostaInteracaoGemini>(
          LRespostaHTTP.Corpo);
    except
      on E: ESerializacaoJSON do
        raise EContratoGemini.Create(
          'A API Gemini retornou um JSON de sucesso invalido.');
    end;
    Result := FMapeador.MapearResposta(LContratoResposta);
  finally
    LContratoResposta.Free;
  end;
end;

end.
