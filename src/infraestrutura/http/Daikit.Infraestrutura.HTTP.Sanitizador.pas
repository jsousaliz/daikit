unit Daikit.Infraestrutura.HTTP.Sanitizador;

interface

uses
  Daikit.Infraestrutura.HTTP.Interfaces;

type
  TSanitizadorHTTP = class
  private
    class function EhNomeSensivel(const ANome: string): Boolean; static;
  public
    class function SanitizarCabecalhos(
      const ACabecalhos: TArray<TCabecalhoHTTP>): TArray<TCabecalhoHTTP>; static;
    class function SanitizarURL(const AURL: string): string; static;
  end;

implementation

uses
  System.SysUtils,
  System.StrUtils,
  Daikit.Infraestrutura.HTTP.Constantes;

class function TSanitizadorHTTP.EhNomeSensivel(
  const ANome: string): Boolean;
var
  LNome: string;
begin
  LNome := LowerCase(Trim(ANome));
  Result := (LNome = 'authorization') or
    (LNome = 'proxy-authorization') or
    (LNome = 'x-api-key') or
    (LNome = 'api-key') or
    (LNome = 'api_key') or
    (LNome = 'apikey') or
    (LNome = 'access_token') or
    (LNome = 'key') or
    (LNome = 'chave') or
    (LNome = 'chave_api') or
    (LNome = 'cookie') or
    (LNome = 'set-cookie') or
    ContainsText(LNome, 'token') or
    ContainsText(LNome, 'secret') or
    ContainsText(LNome, 'senha') or
    ContainsText(LNome, 'password');
end;

class function TSanitizadorHTTP.SanitizarCabecalhos(
  const ACabecalhos: TArray<TCabecalhoHTTP>): TArray<TCabecalhoHTTP>;
var
  I: Integer;
begin
  SetLength(Result, Length(ACabecalhos));
  for I := Low(ACabecalhos) to High(ACabecalhos) do
  begin
    Result[I] := ACabecalhos[I];
    if EhNomeSensivel(Result[I].Nome) then
      Result[I].Valor := CValorSensivelRemovido;
  end;
end;

class function TSanitizadorHTTP.SanitizarURL(const AURL: string): string;
var
  LBase: string;
  LPosicaoConsulta: Integer;
  LPosicaoFragmento: Integer;
  LPosicaoEsquema: Integer;
  LPosicaoArroba: Integer;
  LPosicaoBarra: Integer;
begin
  LBase := AURL;
  LPosicaoFragmento := LBase.IndexOf('#');
  if LPosicaoFragmento >= 0 then
    LBase := LBase.Substring(CIndiceInicialTexto, LPosicaoFragmento);

  LPosicaoConsulta := LBase.IndexOf('?');
  if LPosicaoConsulta >= 0 then
    LBase := LBase.Substring(CIndiceInicialTexto, LPosicaoConsulta);

  LPosicaoEsquema := LBase.IndexOf(CSeparadorEsquemaURL);
  if LPosicaoEsquema >= 0 then
  begin
    LPosicaoArroba := LBase.IndexOf('@',
      LPosicaoEsquema + Length(CSeparadorEsquemaURL));
    LPosicaoBarra := LBase.IndexOf('/',
      LPosicaoEsquema + Length(CSeparadorEsquemaURL));
    if (LPosicaoArroba >= 0) and
      ((LPosicaoBarra < 0) or (LPosicaoArroba < LPosicaoBarra)) then
      LBase := LBase.Substring(CIndiceInicialTexto,
        LPosicaoEsquema + Length(CSeparadorEsquemaURL)) +
        CValorSensivelRemovido + LBase.Substring(LPosicaoArroba);
  end;

  Result := LBase;
end;

end.
