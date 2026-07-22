unit Daikit.Adaptadores.Gemini.Mapeador;

interface

uses
  Daikit.Dominio.Interfaces,
  Daikit.Adaptadores.Gemini.Contratos,
  Daikit.Adaptadores.Gemini.Interfaces;

type
  TMapeadorGemini = class(TInterfacedObject, IMapeadorGemini)
  private
    FArmazenamentoContexto: IArmazenamentoContextoGemini;
  public
    constructor Create(
      const AArmazenamentoContexto: IArmazenamentoContextoGemini);
    function CriarContratoRequisicao(const ARequisicao: IRequisicaoChatIA;
      const AModeloPadrao: string;
      AMaximoTokens: Integer): TRequisicaoInteracaoGemini;
    function MapearResposta(
      AResposta: TRespostaInteracaoGemini): IRespostaChatIA;
  end;

implementation

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  Daikit.Dominio.Mensagem,
  Daikit.Dominio.RequisicaoResposta,
  Daikit.Infraestrutura.JSON.Constantes,
  Daikit.Infraestrutura.JSON.Excecoes,
  Daikit.Infraestrutura.JSON.Serializador,
  Daikit.Adaptadores.Gemini.Constantes,
  Daikit.Adaptadores.Gemini.Excecoes;

function ClonarConteudos(
  const AConteudos: TArray<TConteudoGemini>): TArray<TConteudoGemini>;
var
  I: Integer;
begin
  SetLength(Result, Length(AConteudos));
  try
    for I := Low(AConteudos) to High(AConteudos) do
    begin
      Result[I] := TConteudoGemini.Create;
      Result[I].Tipo := AConteudos[I].Tipo;
      Result[I].Texto := AConteudos[I].Texto;
    end;
  except
    for I := Low(Result) to High(Result) do
      Result[I].Free;
    raise;
  end;
end;

function ClonarPasso(APasso: TPassoGemini): TPassoGemini;
begin
  Result := TPassoGemini.Create;
  try
    Result.Tipo := APasso.Tipo;
    Result.Assinatura := APasso.Assinatura;
    Result.Conteudo := ClonarConteudos(APasso.Conteudo);
    Result.Resumo := ClonarConteudos(APasso.Resumo);
  except
    Result.Free;
    raise;
  end;
end;

function CriarContextoJSON(
  const APassos: TArray<TPassoGemini>): string;
var
  LContexto: TContextoInteracaoGemini;
  LPassos: TArray<TPassoGemini>;
  I: Integer;
begin
  LContexto := TContextoInteracaoGemini.Create;
  try
    SetLength(LPassos, Length(APassos));
    try
      for I := Low(APassos) to High(APassos) do
        LPassos[I] := ClonarPasso(APassos[I]);
    except
      for I := Low(LPassos) to High(LPassos) do
        LPassos[I].Free;
      raise;
    end;
    LContexto.Passos := LPassos;
    Result := TSerializadorJSON.Serializar(LContexto, COpcoesJSONSemVazios);
  finally
    LContexto.Free;
  end;
end;

function EhCorrelacaoGemini(const AIdCorrelacao: string): Boolean;
begin
  Result := SameText(Copy(AIdCorrelacao, 1, Length(CPrefixoContextoGemini)),
    CPrefixoContextoGemini);
end;

procedure ValidarPassosResposta(
  const APassos: TArray<TPassoGemini>);
var
  LPasso: TPassoGemini;
begin
  for LPasso in APassos do
    if SameText(LPasso.Tipo, CTipoPensamentoGemini) then
    begin
      if Trim(LPasso.Assinatura) = '' then
        raise EContratoGemini.Create(
          'A resposta Gemini possui um pensamento sem assinatura.');
    end
    else if not SameText(LPasso.Tipo, CTipoSaidaModeloGemini) then
      raise EContratoGemini.CreateFmt(
        'A resposta Gemini possui o step nao suportado "%s".',
        [LPasso.Tipo]);
end;

function CriarIdCorrelacao(const AIdInteracao: string): string;
var
  LGUID: TGUID;
  LIdentificador: string;
begin
  LIdentificador := Trim(AIdInteracao);
  if LIdentificador = '' then
  begin
    if CreateGUID(LGUID) <> CResultadoSucessoCriacaoGUIDGemini then
      raise EContratoGemini.Create(
        'Nao foi possivel criar a correlacao local da resposta Gemini.');
    LIdentificador := GUIDToString(LGUID);
  end;
  Result := CPrefixoContextoGemini + LIdentificador;
end;

constructor TMapeadorGemini.Create(
  const AArmazenamentoContexto: IArmazenamentoContextoGemini);
begin
  inherited Create;
  if AArmazenamentoContexto = nil then
    raise EConfiguracaoGemini.Create(
      'O armazenamento de contexto Gemini deve ser informado.');
  FArmazenamentoContexto := AArmazenamentoContexto;
end;

function TMapeadorGemini.CriarContratoRequisicao(
  const ARequisicao: IRequisicaoChatIA; const AModeloPadrao: string;
  AMaximoTokens: Integer): TRequisicaoInteracaoGemini;
var
  LMensagem: IMensagemIA;
  LPassos: TObjectList<TPassoGemini>;
  LSistema: TStringBuilder;
  LPasso: TPassoGemini;
  LConteudo: TConteudoGemini;
  LConteudos: TArray<TConteudoGemini>;
  LContextoJSON: string;
  LContexto: TContextoInteracaoGemini;
  LPassoContexto: TPassoGemini;
begin
  if ARequisicao = nil then
    raise EContratoGemini.Create('A requisicao canonica deve ser informada.');
  Result := TRequisicaoInteracaoGemini.Create;
  LPassos := TObjectList<TPassoGemini>.Create(True);
  LSistema := TStringBuilder.Create;
  try
    try
      Result.Modelo := Trim(ARequisicao.Modelo);
      if Result.Modelo = '' then
        Result.Modelo := AModeloPadrao;
      Result.Armazenar := False;
      Result.ConfiguracaoGeracao := TConfiguracaoGeracaoGemini.Create;
      Result.ConfiguracaoGeracao.MaximoTokensSaida := AMaximoTokens;
      for LMensagem in ARequisicao.Mensagens do
        case LMensagem.Papel of
          TPapelMensagemIA.Sistema:
            begin
              if LSistema.Length > 0 then
                LSistema.Append(CSeparadorMensagensSistemaGemini);
              LSistema.Append(LMensagem.Texto);
            end;
          TPapelMensagemIA.Usuario, TPapelMensagemIA.Assistente:
            begin
              if (LMensagem.Papel = TPapelMensagemIA.Assistente) and
                EhCorrelacaoGemini(LMensagem.IdCorrelacao) then
              begin
                if not FArmazenamentoContexto.TentarObter(
                  LMensagem.IdCorrelacao, LContextoJSON) then
                  raise EContratoGemini.Create(
                    'O contexto local da mensagem Gemini nao esta disponivel.');
                LContexto := nil;
                try
                  try
                    LContexto := TSerializadorJSON.Desserializar<
                      TContextoInteracaoGemini>(LContextoJSON);
                  except
                    on E: ESerializacaoJSON do
                      raise EContratoGemini.Create(
                        'O contexto local da mensagem Gemini e invalido.');
                  end;
                  ValidarPassosResposta(LContexto.Passos);
                  for LPassoContexto in LContexto.Passos do
                    LPassos.Add(ClonarPasso(LPassoContexto));
                finally
                  LContexto.Free;
                end;
              end
              else
              begin
                LPasso := TPassoGemini.Create;
                if LMensagem.Papel = TPapelMensagemIA.Usuario then
                  LPasso.Tipo := CTipoEntradaUsuarioGemini
                else
                  LPasso.Tipo := CTipoSaidaModeloGemini;
                LConteudo := TConteudoGemini.Create;
                LConteudo.Tipo := CTipoTextoGemini;
                LConteudo.Texto := LMensagem.Texto;
                SetLength(LConteudos, 1);
                LConteudos[0] := LConteudo;
                LPasso.Conteudo := LConteudos;
                LPassos.Add(LPasso);
              end;
            end;
        else
          raise EContratoGemini.Create(
            'Mensagens de ferramenta ainda nao sao suportadas pelo provedor Gemini textual.');
        end;
      if LPassos.Count = 0 then
        raise EContratoGemini.Create(
          'A Gemini exige ao menos uma mensagem de usuario ou assistente.');
      Result.InstrucaoSistema := LSistema.ToString;
      Result.Entrada := LPassos.ToArray;
      LPassos.OwnsObjects := False;
    except
      Result.Free;
      raise;
    end;
  finally
    LSistema.Free;
    LPassos.Free;
  end;
end;

function TMapeadorGemini.MapearResposta(
  AResposta: TRespostaInteracaoGemini): IRespostaChatIA;
var
  LPasso: TPassoGemini;
  LConteudo: TConteudoGemini;
  LPartesLista: TList<IParteConteudoIA>;
  LPartes: TArray<IParteConteudoIA>;
  LMensagem: IMensagemIA;
  LUso: IUsoIA;
  LEntrada: Int64;
  LSaida: Int64;
  LIdCorrelacao: string;
begin
  if AResposta = nil then
    raise EContratoGemini.Create('A resposta Gemini deve ser informada.');
  if not SameText(AResposta.Status, CStatusConcluidoGemini) and
    not SameText(AResposta.Status, CStatusIncompletoGemini) then
    raise EContratoGemini.Create('A resposta Gemini possui status invalido.');
  ValidarPassosResposta(AResposta.Passos);
  LPartesLista := TList<IParteConteudoIA>.Create;
  try
    for LPasso in AResposta.Passos do
      if SameText(LPasso.Tipo, CTipoSaidaModeloGemini) then
        for LConteudo in LPasso.Conteudo do
          if SameText(LConteudo.Tipo, CTipoTextoGemini) and
            (Trim(LConteudo.Texto) <> '') then
            LPartesLista.Add(TParteConteudoTextoIA.Create(LConteudo.Texto));
    if LPartesLista.Count = 0 then
      raise EContratoGemini.Create(
        'A resposta Gemini nao possui conteudo textual do modelo.');
    LPartes := LPartesLista.ToArray;
  finally
    LPartesLista.Free;
  end;
  LIdCorrelacao := CriarIdCorrelacao(AResposta.Id);
  FArmazenamentoContexto.Guardar(LIdCorrelacao,
    CriarContextoJSON(AResposta.Passos));
  LMensagem := TMensagemIA.Create(TPapelMensagemIA.Assistente, LPartes, '',
    LIdCorrelacao);
  LUso := nil;
  if AResposta.Uso <> nil then
  begin
    LEntrada := AResposta.Uso.TotalTokensEntrada;
    if LEntrada = 0 then
      LEntrada := AResposta.Uso.TokensEntrada;
    LSaida := AResposta.Uso.TotalTokensSaida;
    if LSaida = 0 then
      LSaida := AResposta.Uso.TokensSaida;
    LUso := TUsoIA.Create(LEntrada, LSaida);
  end;
  Result := TRespostaChatIA.Create(AResposta.Id, LMensagem, LUso);
end;

end.
