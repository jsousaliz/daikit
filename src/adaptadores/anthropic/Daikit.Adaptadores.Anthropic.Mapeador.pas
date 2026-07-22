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
  LMensagensEntradaAnthropic: TObjectList<TMensagemEntradaAnthropic>;
  LInstrucaoSistema: TStringBuilder;
  LMensagemEntradaAnthropic: TMensagemEntradaAnthropic;
begin
  if ARequisicao = nil then
    raise EContratoAnthropic.Create('A requisicao canonica deve ser informada.');
  Result := TRequisicaoMensagensAnthropic.Create;
  LMensagensEntradaAnthropic := TObjectList<TMensagemEntradaAnthropic>.Create(True);
  LInstrucaoSistema := TStringBuilder.Create;
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
              if LInstrucaoSistema.Length > 0 then
                LInstrucaoSistema.Append(CSeparadorMensagensSistemaAnthropic);
              LInstrucaoSistema.Append(LMensagem.Texto);
            end;
          TPapelMensagemIA.Usuario, TPapelMensagemIA.Assistente:
            begin
              LMensagemEntradaAnthropic := TMensagemEntradaAnthropic.Create;
              if LMensagem.Papel = TPapelMensagemIA.Usuario then
                LMensagemEntradaAnthropic.Papel := CPapelUsuarioAnthropic
              else
                LMensagemEntradaAnthropic.Papel := CPapelAssistenteAnthropic;
              LMensagemEntradaAnthropic.Conteudo := LMensagem.Texto;
              LMensagensEntradaAnthropic.Add(LMensagemEntradaAnthropic);
            end;
        else
          raise EContratoAnthropic.Create(
            'Mensagens de ferramenta ainda nao sao suportadas pelo provedor Anthropic textual.');
        end;
      if LMensagensEntradaAnthropic.Count = 0 then
        raise EContratoAnthropic.Create(
          'A Anthropic exige ao menos uma mensagem de usuario ou assistente.');
      Result.Sistema := LInstrucaoSistema.ToString;
      Result.Mensagens := LMensagensEntradaAnthropic.ToArray;
      LMensagensEntradaAnthropic.OwnsObjects := False;
    except
      Result.Free;
      raise;
    end;
  finally
    LInstrucaoSistema.Free;
    LMensagensEntradaAnthropic.Free;
  end;
end;

function TMapeadorAnthropic.MapearResposta(
  AResposta: TRespostaAnthropic): IRespostaChatIA;
var
  LConteudoSaidaAnthropic: TConteudoSaidaAnthropic;
  LListaPartesConteudo: TList<IParteConteudoIA>;
  LPartesConteudo: TArray<IParteConteudoIA>;
  LMensagem: IMensagemIA;
  LUso: IUsoIA;
begin
  if AResposta = nil then
    raise EContratoAnthropic.Create('A resposta Anthropic deve ser informada.');
  if not SameText(AResposta.Tipo, CTipoMensagemAnthropic) or
    not SameText(AResposta.Papel, CPapelAssistenteAnthropic) then
    raise EContratoAnthropic.Create('A resposta Anthropic nao e uma mensagem de assistente.');
  LListaPartesConteudo := TList<IParteConteudoIA>.Create;
  try
    for LConteudoSaidaAnthropic in AResposta.Conteudo do
      if SameText(LConteudoSaidaAnthropic.Tipo, CTipoTextoAnthropic) and
        (Trim(LConteudoSaidaAnthropic.Texto) <> '') then
        LListaPartesConteudo.Add(TParteConteudoTextoIA.Create(LConteudoSaidaAnthropic.Texto));
    if LListaPartesConteudo.Count = 0 then
      raise EContratoAnthropic.Create(
        'A resposta Anthropic nao possui conteudo textual.');
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
