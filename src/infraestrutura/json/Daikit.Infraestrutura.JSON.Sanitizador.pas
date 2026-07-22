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
  LNomeNormalizado: string;
begin
  LNomeNormalizado := NormalizarNome(ANome);
  Result := (LNomeNormalizado = CChaveJSONTexto) or
    (LNomeNormalizado = CChaveJSONConteudo) or
    (LNomeNormalizado = CChaveJSONEntrada) or
    (LNomeNormalizado = CChaveJSONSaida) or
    (LNomeNormalizado = CChaveJSONSistema) or
    (LNomeNormalizado = CChaveJSONInstrucaoSistema) or
    (LNomeNormalizado = CChaveJSONPrompt) or
    (LNomeNormalizado = CChaveJSONMensagem) or
    (LNomeNormalizado = CChaveJSONMensagens) or
    (LNomeNormalizado = CChaveJSONResposta) or
    (LNomeNormalizado = CChaveJSONConclusao);
end;

class function TSanitizadorJSON.EhChaveOpaca(const ANome: string): Boolean;
var
  LNomeNormalizado: string;
begin
  LNomeNormalizado := NormalizarNome(ANome);
  Result := (LNomeNormalizado = CChaveJSONAssinatura) or
    (LNomeNormalizado = CChaveJSONAssinaturaPensamento) or
    (LNomeNormalizado = CChaveJSONConteudoCriptografado) or
    (LNomeNormalizado = CChaveJSONRaciocinio) or
    (LNomeNormalizado = CChaveJSONConteudoRaciocinio) or
    (LNomeNormalizado = CChaveJSONPensamento) or
    (LNomeNormalizado = CChaveJSONPensando) or
    (LNomeNormalizado = CChaveJSONResumo);
end;

class function TSanitizadorJSON.EhChaveSensivel(
  const ANome: string): Boolean;
var
  LNomeNormalizado: string;
begin
  LNomeNormalizado := NormalizarNome(ANome);
  Result := (LNomeNormalizado = CChaveJSONAutorizacao) or
    (LNomeNormalizado = CChaveJSONAutorizacaoProxy) or
    ContainsText(LNomeNormalizado, CChaveJSONAutorizacao) or
    (LNomeNormalizado = CChaveJSONChaveAPI) or
    (LNomeNormalizado = CChaveJSONChaveAPISemSeparador) or
    ContainsText(LNomeNormalizado, CChaveJSONChaveAPI) or
    ContainsText(LNomeNormalizado, CChaveJSONChaveAPISemSeparador) or
    (LNomeNormalizado = CChaveJSONChaveAPIGoogle) or
    (LNomeNormalizado = CChaveJSONChaveAPIComPrefixoX) or
    (LNomeNormalizado = CChaveJSONTokenAcesso) or
    (LNomeNormalizado = CChaveJSONTokenAtualizacao) or
    (LNomeNormalizado = CChaveJSONToken) or
    EndsText('_token', LNomeNormalizado) or
    ContainsText('_token_', LNomeNormalizado) or
    ContainsText(LNomeNormalizado, CChaveJSONSenha) or
    ContainsText(LNomeNormalizado, CChaveJSONSenhaPortugues) or
    ContainsText(LNomeNormalizado, CChaveJSONSegredo) or
    (LNomeNormalizado = CChaveJSONSegredoCliente) or
    ContainsText(LNomeNormalizado, CChaveJSONCookie) or
    (LNomeNormalizado = CChaveJSONCookieResposta) or
    (LNomeNormalizado = CChaveJSONChave) or
    EndsText('_' + CChaveJSONChave, LNomeNormalizado) or
    (LNomeNormalizado = CChaveJSONChavePortugues) or
    (LNomeNormalizado = CChaveJSONChaveAPIPortugues) or
    ContainsText(LNomeNormalizado, CChaveJSONCredencial);
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
  LEnvelopeJSON: TJSONObject;
begin
  LEnvelopeJSON := TJSONObject.Create;
  try
    LEnvelopeJSON.AddPair(CChaveEnvelopeJSONTruncado, TJSONBool.Create(True));
    LEnvelopeJSON.AddPair(CChaveEnvelopeJSONPrevia, APrevia);
    Result := LEnvelopeJSON.ToJSON;
  finally
    LEnvelopeJSON.Free;
  end;
end;

function CriarEnvelopeRemovido(const AMotivo: string): string;
var
  LEnvelopeJSON: TJSONObject;
begin
  LEnvelopeJSON := TJSONObject.Create;
  try
    LEnvelopeJSON.AddPair(CChaveEnvelopeJSONRemovido, AMotivo);
    Result := LEnvelopeJSON.ToJSON;
  finally
    LEnvelopeJSON.Free;
  end;
end;

function SanitizarValor(AValor: TJSONValue; const ANome: string;
  AIncluirConteudoConversa: Boolean; AProfundidade: Integer;
  AConteudoHerdado: Boolean): TJSONValue;
var
  I: Integer;
  LArrayJSON: TJSONArray;
  LArrayJSONResultado: TJSONArray;
  LEhConteudo: Boolean;
  LObjetoJSON: TJSONObject;
  LObjetoJSONResultado: TJSONObject;
  LParJSON: TJSONPair;
begin
  if AProfundidade > CLimiteProfundidadeJSONLog then
    Exit(TJSONString.Create(CValorJSONProfundidadeRemovida));
  if TSanitizadorJSON.EhChaveSensivel(ANome) or
    TSanitizadorJSON.EhChaveOpaca(ANome) then
    Exit(TJSONString.Create(CValorJSONSensivelRemovido));

  LEhConteudo := AConteudoHerdado or TSanitizadorJSON.EhChaveConteudo(ANome);
  if AValor is TJSONObject then
  begin
    LObjetoJSON := TJSONObject(AValor);
    LObjetoJSONResultado := TJSONObject.Create;
    try
      for I := 0 to LObjetoJSON.Count - 1 do
      begin
        LParJSON := LObjetoJSON.Pairs[I];
        LObjetoJSONResultado.AddPair(LParJSON.JsonString.Value,
          SanitizarValor(LParJSON.JsonValue, LParJSON.JsonString.Value,
            AIncluirConteudoConversa, AProfundidade + 1, LEhConteudo));
      end;
      Exit(LObjetoJSONResultado);
    except
      LObjetoJSONResultado.Free;
      raise;
    end;
  end;

  if AValor is TJSONArray then
  begin
    LArrayJSON := TJSONArray(AValor);
    LArrayJSONResultado := TJSONArray.Create;
    try
      for I := 0 to LArrayJSON.Count - 1 do
        LArrayJSONResultado.AddElement(SanitizarValor(LArrayJSON.Items[I], '',
          AIncluirConteudoConversa, AProfundidade + 1, LEhConteudo));
      Exit(LArrayJSONResultado);
    except
      LArrayJSONResultado.Free;
      raise;
    end;
  end;

  if LEhConteudo and not AIncluirConteudoConversa then
    Exit(TJSONString.Create(CValorJSONConteudoOculto));
  Result := TJSONObject.ParseJSONValue(AValor.ToJSON);
  if Result = nil then
    Result := TJSONString.Create(CValorJSONSensivelRemovido);
end;

class function TSanitizadorJSON.LimitarJSON(const AJSON: string;
  ALimiteBytes: Integer; out ATruncado: Boolean): string;
var
  LIndiceSuperior: Integer;
  LIndiceInferior: Integer;
  LJSONCandidato: string;
  LMelhorJSON: string;
  LIndiceCentral: Integer;
  LPrefixoJSON: string;
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
  LIndiceInferior := 0;
  LIndiceSuperior := Length(AJSON);
  LMelhorJSON := CriarEnvelopeTruncado('');
  while LIndiceInferior <= LIndiceSuperior do
  begin
    LIndiceCentral := LIndiceInferior + ((LIndiceSuperior - LIndiceInferior) div 2);
    LPrefixoJSON := PrefixoUnicodeSeguro(AJSON, LIndiceCentral);
    LJSONCandidato := CriarEnvelopeTruncado(LPrefixoJSON);
    if TEncoding.UTF8.GetByteCount(LJSONCandidato) <= ALimiteBytes then
    begin
      LMelhorJSON := LJSONCandidato;
      LIndiceInferior := LIndiceCentral + 1;
    end
    else
      LIndiceSuperior := LIndiceCentral - 1;
  end;
  Result := LMelhorJSON;
end;

class function TSanitizadorJSON.NormalizarNome(const ANome: string): string;
var
  I: Integer;
  LCaractereAnterior: Char;
  LCaractereAtual: Char;
  LNomeNormalizado: string;
begin
  LNomeNormalizado := Trim(ANome);
  Result := '';
  for I := 1 to Length(LNomeNormalizado) do
  begin
    LCaractereAtual := LNomeNormalizado[I];
    if I > 1 then
    begin
      LCaractereAnterior := LNomeNormalizado[I - 1];
      if (LCaractereAtual >= 'A') and (LCaractereAtual <= 'Z') and
        (not ((LCaractereAnterior >= 'A') and (LCaractereAnterior <= 'Z')) or
          ((I < Length(LNomeNormalizado)) and (LNomeNormalizado[I + 1] >= 'a') and
            (LNomeNormalizado[I + 1] <= 'z'))) and
        (LCaractereAnterior <> '_') and (LCaractereAnterior <> '-') then
        Result := Result + '_';
    end;
    Result := Result + LowerCase(LCaractereAtual);
  end;
  Result := StringReplace(Result, '-', '_', [rfReplaceAll]);
end;

class function TSanitizadorJSON.Sanitizar(const AJSON: string;
  AIncluirConteudoConversa: Boolean; ALimiteBytes: Integer;
  out ATruncado: Boolean): string;
var
  LValorJSON: TJSONValue;
  LValorJSONSanitizado: TJSONValue;
  LJSONSanitizado: string;
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

  LValorJSON := TJSONObject.ParseJSONValue(AJSON);
  if LValorJSON = nil then
    Exit(LimitarJSON(CriarEnvelopeRemovido(CJSONInvalidoRemovido),
      ALimiteBytes, ATruncado));
  try
    LValorJSONSanitizado := SanitizarValor(LValorJSON, '', AIncluirConteudoConversa,
      0, False);
    try
      LJSONSanitizado := LValorJSONSanitizado.ToJSON;
    finally
      LValorJSONSanitizado.Free;
    end;
  finally
    LValorJSON.Free;
  end;
  Result := LimitarJSON(LJSONSanitizado, ALimiteBytes, ATruncado);
end;

end.
