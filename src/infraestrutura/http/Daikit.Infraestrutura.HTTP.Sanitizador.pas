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
  LNomeCabecalhoNormalizado: string;
begin
  LNomeCabecalhoNormalizado := LowerCase(Trim(ANome));
  Result := (LNomeCabecalhoNormalizado = 'authorization') or
    (LNomeCabecalhoNormalizado = 'proxy-authorization') or
    (LNomeCabecalhoNormalizado = 'x-api-key') or
    (LNomeCabecalhoNormalizado = 'api-key') or
    (LNomeCabecalhoNormalizado = 'api_key') or
    (LNomeCabecalhoNormalizado = 'apikey') or
    (LNomeCabecalhoNormalizado = 'access_token') or
    (LNomeCabecalhoNormalizado = 'key') or
    (LNomeCabecalhoNormalizado = 'chave') or
    (LNomeCabecalhoNormalizado = 'chave_api') or
    (LNomeCabecalhoNormalizado = 'cookie') or
    (LNomeCabecalhoNormalizado = 'set-cookie') or
    ContainsText(LNomeCabecalhoNormalizado, 'token') or
    ContainsText(LNomeCabecalhoNormalizado, 'secret') or
    ContainsText(LNomeCabecalhoNormalizado, 'senha') or
    ContainsText(LNomeCabecalhoNormalizado, 'password');
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
  LURLBase: string;
  LPosicaoConsulta: Integer;
  LPosicaoFragmento: Integer;
  LPosicaoEsquema: Integer;
  LPosicaoArroba: Integer;
  LPosicaoBarra: Integer;
begin
  LURLBase := AURL;
  LPosicaoFragmento := LURLBase.IndexOf('#');
  if LPosicaoFragmento >= 0 then
    LURLBase := LURLBase.Substring(CIndiceInicialTexto, LPosicaoFragmento);

  LPosicaoConsulta := LURLBase.IndexOf('?');
  if LPosicaoConsulta >= 0 then
    LURLBase := LURLBase.Substring(CIndiceInicialTexto, LPosicaoConsulta);

  LPosicaoEsquema := LURLBase.IndexOf(CSeparadorEsquemaURL);
  if LPosicaoEsquema >= 0 then
  begin
    LPosicaoArroba := LURLBase.IndexOf('@',
      LPosicaoEsquema + Length(CSeparadorEsquemaURL));
    LPosicaoBarra := LURLBase.IndexOf('/',
      LPosicaoEsquema + Length(CSeparadorEsquemaURL));
    if (LPosicaoArroba >= 0) and
      ((LPosicaoBarra < 0) or (LPosicaoArroba < LPosicaoBarra)) then
      LURLBase := LURLBase.Substring(CIndiceInicialTexto,
        LPosicaoEsquema + Length(CSeparadorEsquemaURL)) +
        CValorSensivelRemovido + LURLBase.Substring(LPosicaoArroba);
  end;

  Result := LURLBase;
end;

end.
