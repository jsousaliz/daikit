unit Daikit.Infraestrutura.JSON.Sanitizador;

interface

type
  TSanitizadorJSON = class sealed
  private
    class function EhChaveConteudo(const ANome: string): Boolean; static;
    class function EhChaveOpaca(const ANome: string): Boolean; static;
    class function EhChaveSensivel(const ANome: string): Boolean; static;
    class function LimitarJSON(const AJSON: string; ALimiteBytes: Integer;
      out ATruncado: Boolean): string; static;
    class function NormalizarNome(const ANome: string): string; static;
  public
    class function Sanitizar(const AJSON: string;
      AIncluirConteudoConversa: Boolean; ALimiteBytes: Integer;
      out ATruncado: Boolean): string; static;
  end;

implementation

uses
  System.SysUtils,
  System.StrUtils,
  System.JSON,
  System.Generics.Collections,
  Daikit.Infraestrutura.JSON.Constantes;

class function TSanitizadorJSON.EhChaveConteudo(
  const ANome: string): Boolean;
var
  LNome: string;
begin
  LNome := NormalizarNome(ANome);
  Result := (LNome = CChaveJSONTexto) or
    (LNome = CChaveJSONConteudo) or
    (LNome = CChaveJSONEntrada) or
    (LNome = CChaveJSONSaida) or
    (LNome = CChaveJSONSistema) or
    (LNome = CChaveJSONInstrucaoSistema) or
    (LNome = CChaveJSONPrompt) or
    (LNome = CChaveJSONMensagem) or
    (LNome = CChaveJSONMensagens) or
    (LNome = CChaveJSONResposta) or
    (LNome = CChaveJSONConclusao);
end;

class function TSanitizadorJSON.EhChaveOpaca(const ANome: string): Boolean;
var
  LNome: string;
begin
  LNome := NormalizarNome(ANome);
  Result := (LNome = CChaveJSONAssinatura) or
    (LNome = CChaveJSONAssinaturaPensamento) or
    (LNome = CChaveJSONConteudoCriptografado) or
    (LNome = CChaveJSONRaciocinio) or
    (LNome = CChaveJSONConteudoRaciocinio) or
    (LNome = CChaveJSONPensamento) or
    (LNome = CChaveJSONPensando) or
    (LNome = CChaveJSONResumo);
end;

class function TSanitizadorJSON.EhChaveSensivel(
  const ANome: string): Boolean;
var
  LNome: string;
begin
  LNome := NormalizarNome(ANome);
  Result := (LNome = CChaveJSONAutorizacao) or
    (LNome = CChaveJSONAutorizacaoProxy) or
    ContainsText(LNome, CChaveJSONAutorizacao) or
    (LNome = CChaveJSONChaveAPI) or
    (LNome = CChaveJSONChaveAPISemSeparador) or
    ContainsText(LNome, CChaveJSONChaveAPI) or
    ContainsText(LNome, CChaveJSONChaveAPISemSeparador) or
    (LNome = CChaveJSONChaveAPIGoogle) or
    (LNome = CChaveJSONChaveAPIComPrefixoX) or
    (LNome = CChaveJSONTokenAcesso) or
    (LNome = CChaveJSONTokenAtualizacao) or
    (LNome = CChaveJSONToken) or
    EndsText('_token', LNome) or
    ContainsText('_token_', LNome) or
    ContainsText(LNome, CChaveJSONSenha) or
    ContainsText(LNome, CChaveJSONSenhaPortugues) or
    ContainsText(LNome, CChaveJSONSegredo) or
    (LNome = CChaveJSONSegredoCliente) or
    ContainsText(LNome, CChaveJSONCookie) or
    (LNome = CChaveJSONCookieResposta) or
    (LNome = CChaveJSONChave) or
    EndsText('_' + CChaveJSONChave, LNome) or
    (LNome = CChaveJSONChavePortugues) or
    (LNome = CChaveJSONChaveAPIPortugues) or
    ContainsText(LNome, CChaveJSONCredencial);
end;

function PrefixoUnicodeSeguro(const ATexto: string;
  AQuantidadeCaracteres: Integer): string;
begin
  if AQuantidadeCaracteres <= 0 then
    Exit('');
  if (AQuantidadeCaracteres < Length(ATexto)) and
    (Ord(ATexto[AQuantidadeCaracteres]) >= CPrimeiroCodigoSurrogateAlto) and
    (Ord(ATexto[AQuantidadeCaracteres]) <= CUltimoCodigoSurrogateAlto) then
    Dec(AQuantidadeCaracteres);
  Result := Copy(ATexto, 1, AQuantidadeCaracteres);
end;

function CriarEnvelopeTruncado(const APrevia: string): string;
var
  LEnvelope: TJSONObject;
begin
  LEnvelope := TJSONObject.Create;
  try
    LEnvelope.AddPair(CChaveEnvelopeJSONTruncado, TJSONBool.Create(True));
    LEnvelope.AddPair(CChaveEnvelopeJSONPrevia, APrevia);
    Result := LEnvelope.ToJSON;
  finally
    LEnvelope.Free;
  end;
end;

function CriarEnvelopeRemovido(const AMotivo: string): string;
var
  LEnvelope: TJSONObject;
begin
  LEnvelope := TJSONObject.Create;
  try
    LEnvelope.AddPair(CChaveEnvelopeJSONRemovido, AMotivo);
    Result := LEnvelope.ToJSON;
  finally
    LEnvelope.Free;
  end;
end;

function SanitizarValor(AValor: TJSONValue; const ANome: string;
  AIncluirConteudoConversa: Boolean; AProfundidade: Integer;
  AConteudoHerdado: Boolean): TJSONValue;
var
  I: Integer;
  LArray: TJSONArray;
  LArrayResultado: TJSONArray;
  LConteudo: Boolean;
  LObjeto: TJSONObject;
  LObjetoResultado: TJSONObject;
  LPar: TJSONPair;
begin
  if AProfundidade > CLimiteProfundidadeJSONLog then
    Exit(TJSONString.Create(CValorJSONProfundidadeRemovida));
  if TSanitizadorJSON.EhChaveSensivel(ANome) or
    TSanitizadorJSON.EhChaveOpaca(ANome) then
    Exit(TJSONString.Create(CValorJSONSensivelRemovido));

  LConteudo := AConteudoHerdado or TSanitizadorJSON.EhChaveConteudo(ANome);
  if AValor is TJSONObject then
  begin
    LObjeto := TJSONObject(AValor);
    LObjetoResultado := TJSONObject.Create;
    try
      for I := 0 to LObjeto.Count - 1 do
      begin
        LPar := LObjeto.Pairs[I];
        LObjetoResultado.AddPair(LPar.JsonString.Value,
          SanitizarValor(LPar.JsonValue, LPar.JsonString.Value,
            AIncluirConteudoConversa, AProfundidade + 1, LConteudo));
      end;
      Exit(LObjetoResultado);
    except
      LObjetoResultado.Free;
      raise;
    end;
  end;

  if AValor is TJSONArray then
  begin
    LArray := TJSONArray(AValor);
    LArrayResultado := TJSONArray.Create;
    try
      for I := 0 to LArray.Count - 1 do
        LArrayResultado.AddElement(SanitizarValor(LArray.Items[I], '',
          AIncluirConteudoConversa, AProfundidade + 1, LConteudo));
      Exit(LArrayResultado);
    except
      LArrayResultado.Free;
      raise;
    end;
  end;

  if LConteudo and not AIncluirConteudoConversa then
    Exit(TJSONString.Create(CValorJSONConteudoOculto));
  Result := TJSONObject.ParseJSONValue(AValor.ToJSON);
  if Result = nil then
    Result := TJSONString.Create(CValorJSONSensivelRemovido);
end;

class function TSanitizadorJSON.LimitarJSON(const AJSON: string;
  ALimiteBytes: Integer; out ATruncado: Boolean): string;
var
  LAlto: Integer;
  LBaixo: Integer;
  LCandidato: string;
  LMelhor: string;
  LMeio: Integer;
  LPrevia: string;
begin
  if ALimiteBytes < CLimiteJSONLogMinimoBytes then
    raise EArgumentOutOfRangeException.CreateFmt(
      CMensagemLimiteJSONLogInvalido,
      [CLimiteJSONLogMinimoBytes]);
  if TEncoding.UTF8.GetByteCount(AJSON) <= ALimiteBytes then
  begin
    ATruncado := False;
    Exit(AJSON);
  end;

  ATruncado := True;
  LBaixo := 0;
  LAlto := Length(AJSON);
  LMelhor := CriarEnvelopeTruncado('');
  while LBaixo <= LAlto do
  begin
    LMeio := LBaixo + ((LAlto - LBaixo) div 2);
    LPrevia := PrefixoUnicodeSeguro(AJSON, LMeio);
    LCandidato := CriarEnvelopeTruncado(LPrevia);
    if TEncoding.UTF8.GetByteCount(LCandidato) <= ALimiteBytes then
    begin
      LMelhor := LCandidato;
      LBaixo := LMeio + 1;
    end
    else
      LAlto := LMeio - 1;
  end;
  Result := LMelhor;
end;

class function TSanitizadorJSON.NormalizarNome(const ANome: string): string;
var
  I: Integer;
  LAnterior: Char;
  LAtual: Char;
  LTexto: string;
begin
  LTexto := Trim(ANome);
  Result := '';
  for I := 1 to Length(LTexto) do
  begin
    LAtual := LTexto[I];
    if I > 1 then
    begin
      LAnterior := LTexto[I - 1];
      if (LAtual >= 'A') and (LAtual <= 'Z') and
        (not ((LAnterior >= 'A') and (LAnterior <= 'Z')) or
          ((I < Length(LTexto)) and (LTexto[I + 1] >= 'a') and
            (LTexto[I + 1] <= 'z'))) and
        (LAnterior <> '_') and (LAnterior <> '-') then
        Result := Result + '_';
    end;
    Result := Result + LowerCase(LAtual);
  end;
  Result := StringReplace(Result, '-', '_', [rfReplaceAll]);
end;

class function TSanitizadorJSON.Sanitizar(const AJSON: string;
  AIncluirConteudoConversa: Boolean; ALimiteBytes: Integer;
  out ATruncado: Boolean): string;
var
  LJSON: TJSONValue;
  LSanitizado: TJSONValue;
  LTextoSanitizado: string;
begin
  ATruncado := False;
  if ALimiteBytes < CLimiteJSONLogMinimoBytes then
    raise EArgumentOutOfRangeException.CreateFmt(
      CMensagemLimiteJSONLogInvalido,
      [CLimiteJSONLogMinimoBytes]);
  if Trim(AJSON) = '' then
    Exit('');
  if TEncoding.UTF8.GetByteCount(AJSON) > CLimiteEntradaJSONLogBytes then
  begin
    ATruncado := True;
    Exit(CriarEnvelopeRemovido(CJSONExcessivoRemovido));
  end;

  LJSON := TJSONObject.ParseJSONValue(AJSON);
  if LJSON = nil then
    Exit(LimitarJSON(CriarEnvelopeRemovido(CJSONInvalidoRemovido),
      ALimiteBytes, ATruncado));
  try
    LSanitizado := SanitizarValor(LJSON, '', AIncluirConteudoConversa,
      0, False);
    try
      LTextoSanitizado := LSanitizado.ToJSON;
    finally
      LSanitizado.Free;
    end;
  finally
    LJSON.Free;
  end;
  Result := LimitarJSON(LTextoSanitizado, ALimiteBytes, ATruncado);
end;

end.
