unit Daikit.Testes.SanitizadorJSON;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestesSanitizadorJSON = class
  public
    [Test] procedure Objeto_DeveRemoverSegredosEOcultarConteudo;
    [Test] procedure Array_DeveManterEstruturaValida;
    [Test] procedure ConteudoHabilitado_DevePreservarConversaMasNaoRaciocinio;
    [Test] procedure JSONInvalido_DeveSerSubstituidoSemVazarEntrada;
    [Test] procedure JSONGrande_DeveSerTruncadoEmEnvelopeValido;
    [Test] procedure LimiteInvalido_DeveSerRecusado;
  end;

implementation

uses
  System.SysUtils,
  System.JSON,
  Daikit.Infraestrutura.JSON.Constantes,
  Daikit.Infraestrutura.JSON.Sanitizador;

const
  CLimiteTesteBytes = 512;
  CLimiteTruncamentoTesteBytes = 256;
  CQuantidadeRepeticoesTextoGrande = 500;
  CQuantidadeEsperadaTokens = 10;
  CCodigoSurrogateEmojiAlto = $D83D;
  CCodigoSurrogateEmojiBaixo = $DE00;

procedure ValidarJSON(const AJSON: string; AClasseEsperada: TClass);
var
  LValor: TJSONValue;
begin
  LValor := TJSONObject.ParseJSONValue(AJSON);
  try
    Assert.IsNotNull(LValor);
    Assert.IsTrue(LValor.InheritsFrom(AClasseEsperada));
  finally
    LValor.Free;
  end;
end;

function CitarJSON(const AValor: string): string;
begin
  Result := Char(34) + AValor + Char(34);
end;

function NomeJSON(const ANome: string): string;
begin
  Result := CitarJSON(ANome) + ':';
end;

function CampoTextoJSON(const ANome, AValor: string): string;
begin
  Result := NomeJSON(ANome) + CitarJSON(AValor);
end;

procedure TTestesSanitizadorJSON.Objeto_DeveRemoverSegredosEOcultarConteudo;
var
  LJSONValido: string;
  LResultado: string;
  LTruncado: Boolean;
begin
  LJSONValido := '{' + CampoTextoJSON('model', 'modelo-teste') + ',' +
    CampoTextoJSON('xAPIKey', 'segredo-chave') + ',' + NomeJSON('input') +
    '[{' + CampoTextoJSON('role', 'user') + ',' +
    CampoTextoJSON('content', 'conteudo-privado') + '}],' +
    NomeJSON('usage') + '{' + NomeJSON('input_tokens') + '10},' +
    NomeJSON('nested') + '{' + CampoTextoJSON('clientSecret',
      'segredo-cliente') + ',' + CampoTextoJSON('databasePassword',
      'senha-banco') + ',' + CampoTextoJSON('privateKey',
      'chave-privada') + ',' + CampoTextoJSON('serviceCredentials',
      'credencial-servico') + '}}';
  LResultado := TSanitizadorJSON.Sanitizar(LJSONValido, False,
    CLimiteTesteBytes, LTruncado);
  ValidarJSON(LResultado, TJSONObject);
  Assert.IsFalse(LTruncado);
  Assert.IsTrue(LResultado.Contains('modelo-teste'));
  Assert.IsTrue(LResultado.Contains(CQuantidadeEsperadaTokens.ToString));
  Assert.IsFalse(LResultado.Contains('segredo-chave'));
  Assert.IsFalse(LResultado.Contains('segredo-cliente'));
  Assert.IsFalse(LResultado.Contains('senha-banco'));
  Assert.IsFalse(LResultado.Contains('chave-privada'));
  Assert.IsFalse(LResultado.Contains('credencial-servico'));
  Assert.IsFalse(LResultado.Contains('conteudo-privado'));
  Assert.IsTrue(LResultado.Contains(CValorJSONConteudoOculto));
end;

procedure TTestesSanitizadorJSON.Array_DeveManterEstruturaValida;
var
  LJSONValido: string;
  LResultado: string;
  LTruncado: Boolean;
begin
  LJSONValido := '[{' + CampoTextoJSON('type', 'text') + ',' +
    CampoTextoJSON('text', 'texto-privado') + '},{' +
    CampoTextoJSON('password', 'senha-secreta') + '}]';
  LResultado := TSanitizadorJSON.Sanitizar(LJSONValido, False,
    CLimiteTesteBytes, LTruncado);
  ValidarJSON(LResultado, TJSONArray);
  Assert.IsFalse(LTruncado);
  Assert.IsFalse(LResultado.Contains('texto-privado'));
  Assert.IsFalse(LResultado.Contains('senha-secreta'));
end;

procedure TTestesSanitizadorJSON.ConteudoHabilitado_DevePreservarConversaMasNaoRaciocinio;
var
  LJSONValido: string;
  LResultado: string;
  LTruncado: Boolean;
begin
  LJSONValido := '{' + NomeJSON('content') + '[{' +
    CampoTextoJSON('type', 'text') + ',' +
    CampoTextoJSON('text', 'resposta-visivel') + '}],' +
    CampoTextoJSON('thoughtSignature', 'assinatura-secreta') + ',' +
    NomeJSON('summary') + '[{' + CampoTextoJSON('text',
      'raciocinio-privado') + '}]}';
  LResultado := TSanitizadorJSON.Sanitizar(LJSONValido, True,
    CLimiteTesteBytes, LTruncado);
  ValidarJSON(LResultado, TJSONObject);
  Assert.IsFalse(LTruncado);
  Assert.IsTrue(LResultado.Contains('resposta-visivel'));
  Assert.IsFalse(LResultado.Contains('assinatura-secreta'));
  Assert.IsFalse(LResultado.Contains('raciocinio-privado'));
end;

procedure TTestesSanitizadorJSON.JSONInvalido_DeveSerSubstituidoSemVazarEntrada;
var
  LJSONInvalido: string;
  LResultado: string;
  LTruncado: Boolean;
begin
  LJSONInvalido := '{' + CampoTextoJSON('api_key', 'segredo-exposto');
  LResultado := TSanitizadorJSON.Sanitizar(LJSONInvalido, True,
    CLimiteTesteBytes, LTruncado);
  ValidarJSON(LResultado, TJSONObject);
  Assert.IsFalse(LTruncado);
  Assert.IsTrue(LResultado.Contains(CJSONInvalidoRemovido));
  Assert.IsFalse(LResultado.Contains('segredo-exposto'));
end;

procedure TTestesSanitizadorJSON.JSONGrande_DeveSerTruncadoEmEnvelopeValido;
var
  I: Integer;
  LJSON: string;
  LResultado: string;
  LTextoGrande: string;
  LTruncado: Boolean;
begin
  LTextoGrande := '';
  for I := 1 to CQuantidadeRepeticoesTextoGrande do
    LTextoGrande := LTextoGrande + 'acao' + Char(CCodigoSurrogateEmojiAlto) +
      Char(CCodigoSurrogateEmojiBaixo);
  LJSON := '{' + Char(34) + 'content' + Char(34) + ':' + Char(34) +
    LTextoGrande + Char(34) + '}';
  LResultado := TSanitizadorJSON.Sanitizar(LJSON, True,
    CLimiteTruncamentoTesteBytes, LTruncado);
  ValidarJSON(LResultado, TJSONObject);
  Assert.IsTrue(LTruncado);
  Assert.IsTrue(LResultado.Contains(CChaveEnvelopeJSONTruncado));
  Assert.IsTrue(TEncoding.UTF8.GetByteCount(LResultado) <=
    CLimiteTruncamentoTesteBytes);
end;

procedure TTestesSanitizadorJSON.LimiteInvalido_DeveSerRecusado;
var
  LTruncado: Boolean;
begin
  Assert.WillRaise(
    TTestLocalMethod(procedure
    begin
      TSanitizadorJSON.Sanitizar('{}', False,
        CLimiteJSONLogMinimoBytes - 1, LTruncado);
    end), EArgumentOutOfRangeException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesSanitizadorJSON);

end.
