unit Daikit.Infraestrutura.HTTP.Interfaces;

interface

{$SCOPEDENUMS ON}

uses
  Daikit.Aplicacao.Interfaces;

type
  TMetodoHTTP = (Get, Post, Put, Patch, Delete);

  TCabecalhoHTTP = record
    Nome: string;
    Valor: string;
    class function Criar(const ANome, AValor: string): TCabecalhoHTTP; static;
    class function ObterValor(const ACabecalhos: TArray<TCabecalhoHTTP>;
      const ANome: string): string; static;
  end;

  IRequisicaoHTTP = interface
    ['{E26CC8CB-F52D-480E-9A15-27F1EA93F4D0}']
    function ObterMetodo: TMetodoHTTP;
    function ObterURL: string;
    function ObterCabecalhos: TArray<TCabecalhoHTTP>;
    function ObterCorpo: string;
    function ObterTimeoutConexaoMS: Integer;
    function ObterTimeoutRespostaMS: Integer;
    function ObterLimiteRespostaBytes: Int64;
    property Metodo: TMetodoHTTP read ObterMetodo;
    property URL: string read ObterURL;
    property Cabecalhos: TArray<TCabecalhoHTTP> read ObterCabecalhos;
    property Corpo: string read ObterCorpo;
    property TimeoutConexaoMS: Integer read ObterTimeoutConexaoMS;
    property TimeoutRespostaMS: Integer read ObterTimeoutRespostaMS;
    property LimiteRespostaBytes: Int64 read ObterLimiteRespostaBytes;
  end;

  IRespostaHTTP = interface
    ['{FA8DC503-312D-44C5-BAD9-BFEAE947F1BC}']
    function ObterStatus: Integer;
    function ObterMotivo: string;
    function ObterCabecalhos: TArray<TCabecalhoHTTP>;
    function ObterCorpo: string;
    function ObterFoiSucesso: Boolean;
    property Status: Integer read ObterStatus;
    property Motivo: string read ObterMotivo;
    property Cabecalhos: TArray<TCabecalhoHTTP> read ObterCabecalhos;
    property Corpo: string read ObterCorpo;
    property FoiSucesso: Boolean read ObterFoiSucesso;
  end;

  ITransporteHTTP = interface
    ['{FBD6CB3F-C0E9-49F2-AED9-E773DE87CC0A}']
    function Enviar(const ARequisicao: IRequisicaoHTTP;
      const ACancelamento: ITokenCancelamentoIA = nil): IRespostaHTTP;
  end;

implementation

uses
  System.SysUtils;

class function TCabecalhoHTTP.Criar(const ANome,
  AValor: string): TCabecalhoHTTP;
begin
  Result.Nome := ANome;
  Result.Valor := AValor;
end;

class function TCabecalhoHTTP.ObterValor(
  const ACabecalhos: TArray<TCabecalhoHTTP>;
  const ANome: string): string;
var
  LCabecalhoHTTP: TCabecalhoHTTP;
begin
  Result := '';
  for LCabecalhoHTTP in ACabecalhos do
    if SameText(LCabecalhoHTTP.Nome, ANome) then
      Exit(LCabecalhoHTTP.Valor);
end;

end.
