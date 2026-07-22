unit Daikit.Testes.JSON;

interface

uses
  DUnitX.TestFramework,
  REST.Json.Types;

type
  TContratoJSONTeste = class
  private
    [JSONName('nome_exato')]
    FNome: string;
    FDescricaoOpcional: string;
    FQuantidade: Integer;
    FItens: TArray<string>;
  public
    property Nome: string read FNome write FNome;
    property DescricaoOpcional: string read FDescricaoOpcional
      write FDescricaoOpcional;
    property Quantidade: Integer read FQuantidade write FQuantidade;
    property Itens: TArray<string> read FItens write FItens;
  end;

  [TestFixture]
  TTestesJSON = class
  public
    [Test] procedure Serializador_DeveUsarNomeJSONEAjusteCamelCase;
    [Test] procedure Serializador_DeveFazerIdaEVolta;
    [Test] procedure Serializador_DeveOmitirVaziosQuandoSolicitado;
    [Test] procedure Serializador_NaoDeveAceitarObjetoNulo;
    [Test] procedure Desserializador_NaoDeveAceitarJSONVazio;
    [Test] procedure Desserializador_NaoDeveVazarConteudoNoErro;
    [Test] procedure Desserializador_DeveIgnorarCamposDesconhecidos;
  end;

implementation

uses
  System.SysUtils,
  Daikit.Infraestrutura.JSON.Constantes,
  Daikit.Infraestrutura.JSON.Excecoes,
  Daikit.Infraestrutura.JSON.Serializador;

procedure TTestesJSON.Desserializador_NaoDeveAceitarJSONVazio;
begin
  Assert.WillRaise(
    TTestLocalMethod(procedure
    begin
      TSerializadorJSON.Desserializar<TContratoJSONTeste>('').Free;
    end), ESerializacaoJSON);
end;

procedure TTestesJSON.Desserializador_DeveIgnorarCamposDesconhecidos;
var
  LContrato: TContratoJSONTeste;
begin
  LContrato := TSerializadorJSON.Desserializar<TContratoJSONTeste>(
    '{"nome_exato":"Jean","novo_campo":true}');
  try
    Assert.AreEqual('Jean', LContrato.Nome);
  finally
    LContrato.Free;
  end;
end;

procedure TTestesJSON.Desserializador_NaoDeveVazarConteudoNoErro;
const
  CConteudoSensivelTeste = 'segredo-super-confidencial';
var
  LMensagem: string;
begin
  LMensagem := '';
  try
    TSerializadorJSON.Desserializar<TContratoJSONTeste>(
      '{"nome_exato":"' + CConteudoSensivelTeste + '"').Free;
  except
    on E: ESerializacaoJSON do
      LMensagem := E.Message;
  end;
  Assert.IsNotEmpty(LMensagem);
  Assert.IsFalse(LMensagem.Contains(CConteudoSensivelTeste));
end;

procedure TTestesJSON.Serializador_DeveFazerIdaEVolta;
var
  LOrigem: TContratoJSONTeste;
  LDestino: TContratoJSONTeste;
  LJSON: string;
  LItens: TArray<string>;
begin
  LOrigem := TContratoJSONTeste.Create;
  try
    LOrigem.Nome := 'Jean';
    LOrigem.DescricaoOpcional := 'teste';
    LOrigem.Quantidade := 7;
    SetLength(LItens, 2);
    LItens[0] := 'um';
    LItens[1] := 'dois';
    LOrigem.Itens := LItens;
    LJSON := TSerializadorJSON.Serializar(LOrigem);
  finally
    LOrigem.Free;
  end;
  LDestino := TSerializadorJSON.Desserializar<TContratoJSONTeste>(LJSON);
  try
    Assert.AreEqual('Jean', LDestino.Nome);
    Assert.AreEqual('teste', LDestino.DescricaoOpcional);
    Assert.AreEqual(7, LDestino.Quantidade);
    Assert.AreEqual(2, Integer(Length(LDestino.Itens)));
    Assert.AreEqual('dois', LDestino.Itens[1]);
  finally
    LDestino.Free;
  end;
end;

procedure TTestesJSON.Serializador_DeveOmitirVaziosQuandoSolicitado;
var
  LContrato: TContratoJSONTeste;
  LJSON: string;
begin
  LContrato := TContratoJSONTeste.Create;
  try
    LContrato.Nome := 'Jean';
    LContrato.DescricaoOpcional := '';
    LJSON := TSerializadorJSON.Serializar(LContrato, COpcoesJSONSemVazios);
  finally
    LContrato.Free;
  end;
  Assert.IsFalse(LJSON.Contains('descricaoOpcional'));
  Assert.IsFalse(LJSON.Contains('itens'));
end;

procedure TTestesJSON.Serializador_DeveUsarNomeJSONEAjusteCamelCase;
var
  LContrato: TContratoJSONTeste;
  LJSON: string;
begin
  LContrato := TContratoJSONTeste.Create;
  try
    LContrato.Nome := 'Jean';
    LContrato.DescricaoOpcional := 'descricao';
    LJSON := TSerializadorJSON.Serializar(LContrato);
  finally
    LContrato.Free;
  end;
  Assert.IsTrue(LJSON.Contains('"nome_exato":"Jean"'));
  Assert.IsTrue(LJSON.Contains('"descricaoOpcional":"descricao"'));
end;

procedure TTestesJSON.Serializador_NaoDeveAceitarObjetoNulo;
begin
  Assert.WillRaise(
    TTestLocalMethod(procedure
    begin
      TSerializadorJSON.Serializar(nil);
    end), ESerializacaoJSON);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesJSON);

end.
