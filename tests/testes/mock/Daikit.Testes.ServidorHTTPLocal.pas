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
  LCorpo: string;
begin
  case FComportamento of
    TComportamentoServidorHTTPLocal.RespostaExcessiva:
      LCorpo := '12345678';
  else
    LCorpo := '{}';
  end;

  Result := 'HTTP/1.1 200 OK' + CSeparadorHTTP +
    'Content-Type: application/json' + CSeparadorHTTP +
    'Content-Length: ' + IntToStr(TEncoding.UTF8.GetByteCount(LCorpo)) +
    CSeparadorHTTP + 'Connection: close' + CSeparadorHTTP +
    CSeparadorHTTP + LCorpo;
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
  LCliente: TSocket;
begin
  while not Terminated do
  begin
    LCliente := nil;
    try
      LCliente := FEscutador.Accept(50);
      if LCliente = nil then
        Continue;
      TInterlocked.Increment(FQuantidadeRequisicoes);
      ReceberCabecalhosCompletos(LCliente);
      if FComportamento = TComportamentoServidorHTTPLocal.RespostaAtrasada then
        TThread.Sleep(FAtrasoMS);
      if not Terminated then
      begin
        EnviarRespostaCompleta(LCliente, CriarResposta);
        TThread.Sleep(CEsperaFechamentoConexaoMS);
      end;
    except
      if not Terminated then
        raise;
    end;
    LCliente.Free;
  end;
end;

procedure TServidorHTTPLocal.ReceberCabecalhosCompletos(ACliente: TSocket);
var
  LParte: string;
  LRequisicao: string;
begin
  LRequisicao := '';
  repeat
    LParte := ACliente.ReceiveString;
    if LParte = '' then
      Exit;
    LRequisicao := LRequisicao + LParte;
    if Length(LRequisicao) > CLimiteCabecalhosHTTPCaracteres then
      raise ESocketError.Create('Os cabecalhos HTTP locais excederam o limite.');
  until LRequisicao.Contains(CFimCabecalhosHTTP);
end;

procedure TServidorHTTPLocal.EnviarRespostaCompleta(ACliente: TSocket;
  const AResposta: string);
var
  LBytes: TBytes;
  LEnviados: Integer;
  LPosicao: Integer;
begin
  LBytes := TEncoding.UTF8.GetBytes(AResposta);
  LPosicao := 0;
  while LPosicao < Length(LBytes) do
  begin
    LEnviados := ACliente.Send(LBytes, LPosicao, Length(LBytes) - LPosicao);
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
