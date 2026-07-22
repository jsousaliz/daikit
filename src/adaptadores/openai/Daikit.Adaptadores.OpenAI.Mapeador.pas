unit Daikit.Adaptadores.OpenAI.Mapeador;

interface

uses
  Daikit.Dominio.Interfaces,
  Daikit.Adaptadores.OpenAI.Contratos,
  Daikit.Adaptadores.OpenAI.Interfaces;

type
  TMapeadorOpenAI = class(TInterfacedObject, IMapeadorOpenAI)
  public
    function CriarContratoRequisicao(const ARequisicao: IRequisicaoChatIA;
      const AModeloPadrao: string): TRequisicaoRespostasOpenAI;
    function MapearResposta(AResposta: TRespostaOpenAI): IRespostaChatIA;
  end;

implementation

uses
  System.SysUtils,
  System.Generics.Collections,
  Daikit.Dominio.Mensagem,
  Daikit.Dominio.RequisicaoResposta,
  Daikit.Adaptadores.OpenAI.Constantes,
  Daikit.Adaptadores.OpenAI.Excecoes;

function PapelParaOpenAI(APapel: TPapelMensagemIA): string;
begin
  case APapel of
    TPapelMensagemIA.Sistema:
      Result := CPapelSistemaOpenAI;
    TPapelMensagemIA.Usuario:
      Result := CPapelUsuarioOpenAI;
    TPapelMensagemIA.Assistente:
      Result := CPapelAssistenteOpenAI;
  else
    raise EContratoOpenAI.Create(
      'Mensagens de ferramenta ainda nao sao suportadas pelo provedor OpenAI textual.');
  end;
end;

function TMapeadorOpenAI.CriarContratoRequisicao(
  const ARequisicao: IRequisicaoChatIA;
  const AModeloPadrao: string): TRequisicaoRespostasOpenAI;
var
  I: Integer;
  LMensagens: TArray<IMensagemIA>;
  LMensagensEntradaOpenAI: TArray<TMensagemEntradaOpenAI>;
begin
  if ARequisicao = nil then
    raise EContratoOpenAI.Create('A requisicao canonica deve ser informada.');
  Result := TRequisicaoRespostasOpenAI.Create;
  try
    Result.Modelo := Trim(ARequisicao.Modelo);
    if Result.Modelo = '' then
      Result.Modelo := AModeloPadrao;
    Result.Armazenar := False;
    LMensagens := ARequisicao.Mensagens;
    SetLength(LMensagensEntradaOpenAI, Length(LMensagens));
    Result.Entrada := LMensagensEntradaOpenAI;
    for I := Low(LMensagens) to High(LMensagens) do
    begin
      LMensagensEntradaOpenAI[I] := TMensagemEntradaOpenAI.Create;
      LMensagensEntradaOpenAI[I].Papel := PapelParaOpenAI(LMensagens[I].Papel);
      LMensagensEntradaOpenAI[I].Conteudo := LMensagens[I].Texto;
    end;
  except
    Result.Free;
    raise;
  end;
end;

function TMapeadorOpenAI.MapearResposta(
  AResposta: TRespostaOpenAI): IRespostaChatIA;
var
  LItemSaidaOpenAI: TItemSaidaOpenAI;
  LConteudoSaidaOpenAI: TConteudoSaidaOpenAI;
  LListaPartesConteudo: TList<IParteConteudoIA>;
  LPartesConteudo: TArray<IParteConteudoIA>;
  LMensagem: IMensagemIA;
  LUso: IUsoIA;
begin
  if AResposta = nil then
    raise EContratoOpenAI.Create('A resposta OpenAI deve ser informada.');
  if not SameText(AResposta.Status, CStatusConcluidoOpenAI) then
    raise EContratoOpenAI.CreateFmt(
      'A resposta OpenAI nao foi concluida (status "%s").', [AResposta.Status]);

  LListaPartesConteudo := TList<IParteConteudoIA>.Create;
  try
    for LItemSaidaOpenAI in AResposta.Saida do
      if SameText(LItemSaidaOpenAI.Tipo, CTipoMensagemOpenAI) and
        SameText(LItemSaidaOpenAI.Papel, CPapelAssistenteOpenAI) then
        for LConteudoSaidaOpenAI in LItemSaidaOpenAI.Conteudo do
          if SameText(LConteudoSaidaOpenAI.Tipo, CTipoTextoSaidaOpenAI) and
            (Trim(LConteudoSaidaOpenAI.Texto) <> '') then
            LListaPartesConteudo.Add(TParteConteudoTextoIA.Create(LConteudoSaidaOpenAI.Texto));
    if LListaPartesConteudo.Count = 0 then
      raise EContratoOpenAI.Create(
        'A resposta OpenAI concluida nao possui conteudo textual.');
    LPartesConteudo := LListaPartesConteudo.ToArray;
  finally
    LListaPartesConteudo.Free;
  end;

  LMensagem := TMensagemIA.Create(TPapelMensagemIA.Assistente, LPartesConteudo);
  LUso := nil;
  if AResposta.Uso <> nil then
    LUso := TUsoIA.Create(AResposta.Uso.TokensEntrada,
      AResposta.Uso.TokensSaida);
  Result := TRespostaChatIA.Create(AResposta.Id, LMensagem, LUso);
end;

end.
