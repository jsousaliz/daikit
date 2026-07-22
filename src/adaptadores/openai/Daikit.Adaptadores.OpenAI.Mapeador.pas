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
  LEntrada: TArray<TMensagemEntradaOpenAI>;
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
    SetLength(LEntrada, Length(LMensagens));
    Result.Entrada := LEntrada;
    for I := Low(LMensagens) to High(LMensagens) do
    begin
      LEntrada[I] := TMensagemEntradaOpenAI.Create;
      LEntrada[I].Papel := PapelParaOpenAI(LMensagens[I].Papel);
      LEntrada[I].Conteudo := LMensagens[I].Texto;
    end;
  except
    Result.Free;
    raise;
  end;
end;

function TMapeadorOpenAI.MapearResposta(
  AResposta: TRespostaOpenAI): IRespostaChatIA;
var
  LItem: TItemSaidaOpenAI;
  LConteudo: TConteudoSaidaOpenAI;
  LPartesLista: TList<IParteConteudoIA>;
  LPartes: TArray<IParteConteudoIA>;
  LMensagem: IMensagemIA;
  LUso: IUsoIA;
begin
  if AResposta = nil then
    raise EContratoOpenAI.Create('A resposta OpenAI deve ser informada.');
  if not SameText(AResposta.Status, CStatusConcluidoOpenAI) then
    raise EContratoOpenAI.CreateFmt(
      'A resposta OpenAI nao foi concluida (status "%s").', [AResposta.Status]);

  LPartesLista := TList<IParteConteudoIA>.Create;
  try
    for LItem in AResposta.Saida do
      if SameText(LItem.Tipo, CTipoMensagemOpenAI) and
        SameText(LItem.Papel, CPapelAssistenteOpenAI) then
        for LConteudo in LItem.Conteudo do
          if SameText(LConteudo.Tipo, CTipoTextoSaidaOpenAI) and
            (Trim(LConteudo.Texto) <> '') then
            LPartesLista.Add(TParteConteudoTextoIA.Create(LConteudo.Texto));
    if LPartesLista.Count = 0 then
      raise EContratoOpenAI.Create(
        'A resposta OpenAI concluida nao possui conteudo textual.');
    LPartes := LPartesLista.ToArray;
  finally
    LPartesLista.Free;
  end;

  LMensagem := TMensagemIA.Create(TPapelMensagemIA.Assistente, LPartes);
  LUso := nil;
  if AResposta.Uso <> nil then
    LUso := TUsoIA.Create(AResposta.Uso.TokensEntrada,
      AResposta.Uso.TokensSaida);
  Result := TRespostaChatIA.Create(AResposta.Id, LMensagem, LUso);
end;

end.
