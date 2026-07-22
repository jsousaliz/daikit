unit Daikit.Testes.ServidorHTTPLocal;

interface

uses
  System.Classes,
  System.Net.Socket;

type
  TComportamentoServidorHTTPLocal = (RespostaImediata, RespostaAtrasada,
    RespostaExcessiva);

  TServidorHTTPLocal = class(TThread)
  private
    FComportamento: TComportamentoServidorHTTPLocal;
    FAtrasoMS: Integer;
    FEscutador: TSocket;
    FPorta: Integer;
    FQuantidadeRequisicoes: Integer;
    function CriarResposta: string;
    procedure EnviarRespostaCompleta(ACliente: TSocket;
      const AResposta: string);
    procedure ReceberCabecalhosCompletos(ACliente: TSocket);
    function ObterQuantidadeRequisicoes: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(AComportamento: TComportamentoServidorHTTPLocal;
      AAtrasoMS: Integer = 0);
    destructor Destroy; override;
    function URL(const ACaminho: string = '/teste'): string;
    property Porta: Integer read FPorta;
    property QuantidadeRequisicoes: Integer read ObterQuantidadeRequisicoes;
  end;

implementation

uses
  System.SysUtils,
  System.SyncObjs;

const
  CEsperaFechamentoConexaoMS = 20;
  CFimCabecalhosHTTP = #13#10#13#10;
  CLimiteCabecalhosHTTPCaracteres = 64 * 1024;

constructor TServidorHTTPLocal.Create(
  AComportamento: TComportamentoServidorHTTPLocal; AAtrasoMS: Integer);
begin
  inherited Create(False);
  FreeOnTerminate := False;
  FComportamento := AComportamento;
  FAtrasoMS := AAtrasoMS;
  FEscutador := TSocket.Create(TSocketType.TCP, TEncoding.UTF8);
  try
    FEscutador.Listen(TNetEndpoint.Create(127, 0, 0, 1, 0));
    FPorta := FEscutador.LocalPort;
  except
    FEscutador.Free;
    FEscutador := nil;
    raise;
  end;
end;

function TServidorHTTPLocal.CriarResposta: string;
const
  CSeparadorHTTP = #13#10;
var
  LCorpoRespostaHTTP: string;
begin
  case FComportamento of
    TComportamentoServidorHTTPLocal.RespostaExcessiva:
      LCorpoRespostaHTTP := '12345678';
  else
    LCorpoRespostaHTTP := '{}';
  end;

  Result := 'HTTP/1.1 200 OK' + CSeparadorHTTP +
    'Content-Type: application/json' + CSeparadorHTTP +
    'Content-Length: ' + IntToStr(TEncoding.UTF8.GetByteCount(LCorpoRespostaHTTP)) +
    CSeparadorHTTP + 'Connection: close' + CSeparadorHTTP +
    CSeparadorHTTP + LCorpoRespostaHTTP;
end;

destructor TServidorHTTPLocal.Destroy;
begin
  Terminate;
  if FEscutador <> nil then
    FEscutador.Close(True);
  WaitFor;
  FEscutador.Free;
  inherited;
end;

procedure TServidorHTTPLocal.Execute;
var
  LSocketCliente: TSocket;
begin
  while not Terminated do
  begin
    LSocketCliente := nil;
    try
      LSocketCliente := FEscutador.Accept(50);
      if LSocketCliente = nil then
        Continue;
      TInterlocked.Increment(FQuantidadeRequisicoes);
      ReceberCabecalhosCompletos(LSocketCliente);
      if FComportamento = TComportamentoServidorHTTPLocal.RespostaAtrasada then
        TThread.Sleep(FAtrasoMS);
      if not Terminated then
      begin
        EnviarRespostaCompleta(LSocketCliente, CriarResposta);
        TThread.Sleep(CEsperaFechamentoConexaoMS);
      end;
    except
      if not Terminated then
        raise;
    end;
    LSocketCliente.Free;
  end;
end;

procedure TServidorHTTPLocal.ReceberCabecalhosCompletos(ACliente: TSocket);
var
  LParteRequisicaoHTTP: string;
  LTextoRequisicaoHTTP: string;
begin
  LTextoRequisicaoHTTP := '';
  repeat
    LParteRequisicaoHTTP := ACliente.ReceiveString;
    if LParteRequisicaoHTTP = '' then
      Exit;
    LTextoRequisicaoHTTP := LTextoRequisicaoHTTP + LParteRequisicaoHTTP;
    if Length(LTextoRequisicaoHTTP) > CLimiteCabecalhosHTTPCaracteres then
      raise ESocketError.Create('Os cabecalhos HTTP locais excederam o limite.');
  until LTextoRequisicaoHTTP.Contains(CFimCabecalhosHTTP);
end;

procedure TServidorHTTPLocal.EnviarRespostaCompleta(ACliente: TSocket;
  const AResposta: string);
var
  LBytesRespostaHTTP: TBytes;
  LEnviados: Integer;
  LPosicao: Integer;
begin
  LBytesRespostaHTTP := TEncoding.UTF8.GetBytes(AResposta);
  LPosicao := 0;
  while LPosicao < Length(LBytesRespostaHTTP) do
  begin
    LEnviados := ACliente.Send(LBytesRespostaHTTP, LPosicao, Length(LBytesRespostaHTTP) - LPosicao);
    if LEnviados <= 0 then
      Exit;
    Inc(LPosicao, LEnviados);
  end;
end;

function TServidorHTTPLocal.ObterQuantidadeRequisicoes: Integer;
begin
  Result := TInterlocked.CompareExchange(FQuantidadeRequisicoes, 0, 0);
end;

function TServidorHTTPLocal.URL(const ACaminho: string): string;
begin
  Result := Format('http://127.0.0.1:%d%s', [FPorta, ACaminho]);
end;

end.
