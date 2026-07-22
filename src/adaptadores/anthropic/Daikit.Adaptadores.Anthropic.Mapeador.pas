unit Daikit.Adaptadores.Anthropic.Mapeador;

interface

uses
  Daikit.Dominio.Interfaces,
  Daikit.Adaptadores.Anthropic.Contratos,
  Daikit.Adaptadores.Anthropic.Interfaces;

type
  TMapeadorAnthropic = class(TInterfacedObject, IMapeadorAnthropic)
  public
    function CriarContratoRequisicao(const ARequisicao: IRequisicaoChatIA;
      const AModeloPadrao: string;
      AMaximoTokens: Integer): TRequisicaoMensagensAnthropic;
    function MapearResposta(AResposta: TRespostaAnthropic): IRespostaChatIA;
  end;

implementation

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  Daikit.Dominio.Mensagem,
  Daikit.Dominio.RequisicaoResposta,
  Daikit.Adaptadores.Anthropic.Constantes,
  Daikit.Adaptadores.Anthropic.Excecoes;

function TMapeadorAnthropic.CriarContratoRequisicao(
  const ARequisicao: IRequisicaoChatIA; const AModeloPadrao: string;
  AMaximoTokens: Integer): TRequisicaoMensagensAnthropic;
var
  LMensagem: IMensagemIA;
  LMensagens: TObjectList<TMensagemEntradaAnthropic>;
  LSistema: TStringBuilder;
  LEntrada: TMensagemEntradaAnthropic;
begin
  if ARequisicao = nil then
    raise EContratoAnthropic.Create('A requisicao canonica deve ser informada.');
  Result := TRequisicaoMensagensAnthropic.Create;
  LMensagens := TObjectList<TMensagemEntradaAnthropic>.Create(True);
  LSistema := TStringBuilder.Create;
  try
    try
      Result.Modelo := Trim(ARequisicao.Modelo);
      if Result.Modelo = '' then
        Result.Modelo := AModeloPadrao;
      Result.MaximoTokens := AMaximoTokens;
      for LMensagem in ARequisicao.Mensagens do
        case LMensagem.Papel of
          TPapelMensagemIA.Sistema:
            begin
              if LSistema.Length > 0 then
                LSistema.Append(CSeparadorMensagensSistemaAnthropic);
              LSistema.Append(LMensagem.Texto);
            end;
          TPapelMensagemIA.Usuario, TPapelMensagemIA.Assistente:
            begin
              LEntrada := TMensagemEntradaAnthropic.Create;
              if LMensagem.Papel = TPapelMensagemIA.Usuario then
                LEntrada.Papel := CPapelUsuarioAnthropic
              else
                LEntrada.Papel := CPapelAssistenteAnthropic;
              LEntrada.Conteudo := LMensagem.Texto;
              LMensagens.Add(LEntrada);
            end;
        else
          raise EContratoAnthropic.Create(
            'Mensagens de ferramenta ainda nao sao suportadas pelo provedor Anthropic textual.');
        end;
      if LMensagens.Count = 0 then
        raise EContratoAnthropic.Create(
          'A Anthropic exige ao menos uma mensagem de usuario ou assistente.');
      Result.Sistema := LSistema.ToString;
      Result.Mensagens := LMensagens.ToArray;
      LMensagens.OwnsObjects := False;
    except
      Result.Free;
      raise;
    end;
  finally
    LSistema.Free;
    LMensagens.Free;
  end;
end;

function TMapeadorAnthropic.MapearResposta(
  AResposta: TRespostaAnthropic): IRespostaChatIA;
var
  LConteudo: TConteudoSaidaAnthropic;
  LPartesLista: TList<IParteConteudoIA>;
  LPartes: TArray<IParteConteudoIA>;
  LMensagem: IMensagemIA;
  LUso: IUsoIA;
begin
  if AResposta = nil then
    raise EContratoAnthropic.Create('A resposta Anthropic deve ser informada.');
  if not SameText(AResposta.Tipo, CTipoMensagemAnthropic) or
    not SameText(AResposta.Papel, CPapelAssistenteAnthropic) then
    raise EContratoAnthropic.Create('A resposta Anthropic nao e uma mensagem de assistente.');
  LPartesLista := TList<IParteConteudoIA>.Create;
  try
    for LConteudo in AResposta.Conteudo do
      if SameText(LConteudo.Tipo, CTipoTextoAnthropic) and
        (Trim(LConteudo.Texto) <> '') then
        LPartesLista.Add(TParteConteudoTextoIA.Create(LConteudo.Texto));
    if LPartesLista.Count = 0 then
      raise EContratoAnthropic.Create(
        'A resposta Anthropic nao possui conteudo textual.');
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
