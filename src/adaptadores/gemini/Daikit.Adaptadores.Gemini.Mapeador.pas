unit Daikit.Adaptadores.Gemini.Mapeador;

interface

uses
  Daikit.Dominio.Interfaces,
  Daikit.Adaptadores.Gemini.Contratos,
  Daikit.Adaptadores.Gemini.Interfaces;

type
  TMapeadorGemini = class(TInterfacedObject, IMapeadorGemini)
  private
    FArmazenamentoContextoGemini: IArmazenamentoContextoGemini;
  public
    constructor Create(
      const AArmazenamentoContexto: IArmazenamentoContextoGemini);
    function CriarContratoRequisicao(const ARequisicao: IRequisicaoChatIA;
      const AModeloPadrao: string;
      AMaximoTokens: Integer): TRequisicaoInteracaoGemini;
    function MapearResposta(
      AResposta: TRespostaInteracaoGemini): IRespostaChatIA;
    function MapearModelos(
      AResposta: TRespostaModelosGemini): TArray<IModeloIA>;
  end;

implementation

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  Daikit.Dominio.Mensagem,
  Daikit.Dominio.Modelo,
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
  LContextoInteracaoGemini: TContextoInteracaoGemini;
  LPassosGemini: TArray<TPassoGemini>;
  I: Integer;
begin
  LContextoInteracaoGemini := TContextoInteracaoGemini.Create;
  try
    SetLength(LPassosGemini, Length(APassos));
    try
      for I := Low(APassos) to High(APassos) do
        LPassosGemini[I] := ClonarPasso(APassos[I]);
    except
      for I := Low(LPassosGemini) to High(LPassosGemini) do
        LPassosGemini[I].Free;
      raise;
    end;
    LContextoInteracaoGemini.Passos := LPassosGemini;
    Result := TSerializadorJSON.Serializar(LContextoInteracaoGemini, COpcoesJSONSemVazios);
  finally
    LContextoInteracaoGemini.Free;
  end;
end;

function EhCorrelacaoGemini(const AIdCorrelacao: string): Boolean;
begin
  Result := SameText(Copy(AIdCorrelacao, 1, Length(CPrefixoContextoGemini)),
    CPrefixoContextoGemini);
end;

function SuportaGeracaoConteudo(AModelo: TModeloGemini): Boolean;
var
  LMetodo: string;
begin
  Result := False;
  for LMetodo in AModelo.MetodosGeracaoSuportados do
    if SameText(LMetodo, CMetodoGeracaoConteudoGemini) then
      Exit(True);
end;

function TMapeadorGemini.MapearModelos(
  AResposta: TRespostaModelosGemini): TArray<IModeloIA>;
var
  LModeloGemini: TModeloGemini;
  LModelos: TList<IModeloIA>;
  LIdModelo: string;
begin
  if AResposta = nil then
    raise EContratoGemini.Create(
      'A resposta de modelos Gemini deve ser informada.');
  LModelos := TList<IModeloIA>.Create;
  try
    for LModeloGemini in AResposta.Modelos do
      if (LModeloGemini <> nil) and SuportaGeracaoConteudo(LModeloGemini) then
      begin
        LIdModelo := Trim(LModeloGemini.IdModeloBase);
        if LIdModelo = '' then
        begin
          LIdModelo := Trim(LModeloGemini.NomeRecurso);
          if Copy(LIdModelo, 1, Length(CPrefixoNomeModeloGemini)) =
            CPrefixoNomeModeloGemini then
            Delete(LIdModelo, 1, Length(CPrefixoNomeModeloGemini));
        end;
        if LIdModelo <> '' then
          LModelos.Add(TModeloIA.Create(LIdModelo,
            LModeloGemini.NomeExibicao));
      end;
    Result := LModelos.ToArray;
  finally
    LModelos.Free;
  end;
end;

procedure ValidarPassosResposta(
  const APassos: TArray<TPassoGemini>);
var
  LPassoGemini: TPassoGemini;
begin
  for LPassoGemini in APassos do
    if SameText(LPassoGemini.Tipo, CTipoPensamentoGemini) then
    begin
      if Trim(LPassoGemini.Assinatura) = '' then
        raise EContratoGemini.Create(
          'A resposta Gemini possui um pensamento sem assinatura.');
    end
    else if not SameText(LPassoGemini.Tipo, CTipoSaidaModeloGemini) then
      raise EContratoGemini.CreateFmt(
        'A resposta Gemini possui o step nao suportado "%s".',
        [LPassoGemini.Tipo]);
end;

function CriarIdCorrelacao(const AIdInteracao: string): string;
var
  LGUID: TGUID;
  LIdentificadorCorrelacao: string;
begin
  LIdentificadorCorrelacao := Trim(AIdInteracao);
  if LIdentificadorCorrelacao = '' then
  begin
    if CreateGUID(LGUID) <> CResultadoSucessoCriacaoGUIDGemini then
      raise EContratoGemini.Create(
        'Nao foi possivel criar a correlacao local da resposta Gemini.');
    LIdentificadorCorrelacao := GUIDToString(LGUID);
  end;
  Result := CPrefixoContextoGemini + LIdentificadorCorrelacao;
end;

constructor TMapeadorGemini.Create(
  const AArmazenamentoContexto: IArmazenamentoContextoGemini);
begin
  inherited Create;
  if AArmazenamentoContexto = nil then
    raise EConfiguracaoGemini.Create(
      'O armazenamento de contexto Gemini deve ser informado.');
  FArmazenamentoContextoGemini := AArmazenamentoContexto;
end;

function TMapeadorGemini.CriarContratoRequisicao(
  const ARequisicao: IRequisicaoChatIA; const AModeloPadrao: string;
  AMaximoTokens: Integer): TRequisicaoInteracaoGemini;
var
  LMensagem: IMensagemIA;
  LPassosGemini: TObjectList<TPassoGemini>;
  LInstrucaoSistema: TStringBuilder;
  LPassoGemini: TPassoGemini;
  LConteudoGemini: TConteudoGemini;
  LConteudosGemini: TArray<TConteudoGemini>;
  LContextoJSON: string;
  LContextoInteracaoGemini: TContextoInteracaoGemini;
  LPassoContextoGemini: TPassoGemini;
begin
  if ARequisicao = nil then
    raise EContratoGemini.Create('A requisicao canonica deve ser informada.');
  Result := TRequisicaoInteracaoGemini.Create;
  LPassosGemini := TObjectList<TPassoGemini>.Create(True);
  LInstrucaoSistema := TStringBuilder.Create;
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
              if LInstrucaoSistema.Length > 0 then
                LInstrucaoSistema.Append(CSeparadorMensagensSistemaGemini);
              LInstrucaoSistema.Append(LMensagem.Texto);
            end;
          TPapelMensagemIA.Usuario, TPapelMensagemIA.Assistente:
            begin
              if (LMensagem.Papel = TPapelMensagemIA.Assistente) and
                EhCorrelacaoGemini(LMensagem.IdCorrelacao) then
              begin
                if not FArmazenamentoContextoGemini.TentarObter(
                  LMensagem.IdCorrelacao, LContextoJSON) then
                  raise EContratoGemini.Create(
                    'O contexto local da mensagem Gemini nao esta disponivel.');
                LContextoInteracaoGemini := nil;
                try
                  try
                    LContextoInteracaoGemini := TSerializadorJSON.Desserializar<
                      TContextoInteracaoGemini>(LContextoJSON);
                  except
                    on E: ESerializacaoJSON do
                      raise EContratoGemini.Create(
                        'O contexto local da mensagem Gemini e invalido.');
                  end;
                  ValidarPassosResposta(LContextoInteracaoGemini.Passos);
                  for LPassoContextoGemini in LContextoInteracaoGemini.Passos do
                    LPassosGemini.Add(ClonarPasso(LPassoContextoGemini));
                finally
                  LContextoInteracaoGemini.Free;
                end;
              end
              else
              begin
                LPassoGemini := TPassoGemini.Create;
                if LMensagem.Papel = TPapelMensagemIA.Usuario then
                  LPassoGemini.Tipo := CTipoEntradaUsuarioGemini
                else
                  LPassoGemini.Tipo := CTipoSaidaModeloGemini;
                LConteudoGemini := TConteudoGemini.Create;
                LConteudoGemini.Tipo := CTipoTextoGemini;
                LConteudoGemini.Texto := LMensagem.Texto;
                SetLength(LConteudosGemini, 1);
                LConteudosGemini[0] := LConteudoGemini;
                LPassoGemini.Conteudo := LConteudosGemini;
                LPassosGemini.Add(LPassoGemini);
              end;
            end;
        else
          raise EContratoGemini.Create(
            'Mensagens de ferramenta ainda nao sao suportadas pelo provedor Gemini textual.');
        end;
      if LPassosGemini.Count = 0 then
        raise EContratoGemini.Create(
          'A Gemini exige ao menos uma mensagem de usuario ou assistente.');
      Result.InstrucaoSistema := LInstrucaoSistema.ToString;
      Result.Entrada := LPassosGemini.ToArray;
      LPassosGemini.OwnsObjects := False;
    except
      Result.Free;
      raise;
    end;
  finally
    LInstrucaoSistema.Free;
    LPassosGemini.Free;
  end;
end;

function TMapeadorGemini.MapearResposta(
  AResposta: TRespostaInteracaoGemini): IRespostaChatIA;
var
  LPassoGemini: TPassoGemini;
  LConteudoGemini: TConteudoGemini;
  LListaPartesConteudo: TList<IParteConteudoIA>;
  LPartesConteudo: TArray<IParteConteudoIA>;
  LMensagem: IMensagemIA;
  LUso: IUsoIA;
  LUnidadesEntrada: Int64;
  LUnidadesSaida: Int64;
  LIdCorrelacao: string;
begin
  if AResposta = nil then
    raise EContratoGemini.Create('A resposta Gemini deve ser informada.');
  if not SameText(AResposta.Status, CStatusConcluidoGemini) and
    not SameText(AResposta.Status, CStatusIncompletoGemini) then
    raise EContratoGemini.Create('A resposta Gemini possui status invalido.');
  ValidarPassosResposta(AResposta.Passos);
  LListaPartesConteudo := TList<IParteConteudoIA>.Create;
  try
    for LPassoGemini in AResposta.Passos do
      if SameText(LPassoGemini.Tipo, CTipoSaidaModeloGemini) then
        for LConteudoGemini in LPassoGemini.Conteudo do
          if SameText(LConteudoGemini.Tipo, CTipoTextoGemini) and
            (Trim(LConteudoGemini.Texto) <> '') then
            LListaPartesConteudo.Add(TParteConteudoTextoIA.Create(LConteudoGemini.Texto));
    if LListaPartesConteudo.Count = 0 then
      raise EContratoGemini.Create(
        'A resposta Gemini nao possui conteudo textual do modelo.');
    LPartesConteudo := LListaPartesConteudo.ToArray;
  finally
    LListaPartesConteudo.Free;
  end;
  LIdCorrelacao := CriarIdCorrelacao(AResposta.Id);
  FArmazenamentoContextoGemini.Guardar(LIdCorrelacao,
    CriarContextoJSON(AResposta.Passos));
  LMensagem := TMensagemIA.Create(TPapelMensagemIA.Assistente, LPartesConteudo, '',
    LIdCorrelacao);
  LUso := nil;
  if AResposta.Uso <> nil then
  begin
    LUnidadesEntrada := AResposta.Uso.TotalTokensEntrada;
    if LUnidadesEntrada = 0 then
      LUnidadesEntrada := AResposta.Uso.TokensEntrada;
    LUnidadesSaida := AResposta.Uso.TotalTokensSaida;
    if LUnidadesSaida = 0 then
      LUnidadesSaida := AResposta.Uso.TokensSaida;
    LUso := TUsoIA.Create(LUnidadesEntrada, LUnidadesSaida);
  end;
  Result := TRespostaChatIA.Create(AResposta.Id, LMensagem, LUso);
end;

end.
