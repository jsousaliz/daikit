unit Daikit.Aplicacao.Log;

interface

{$SCOPEDENUMS ON}

type
  TTipoEventoLogIA = (Contexto, Requisicao, Resposta, RespostaErro, Erro);

  IEventoLogIA = interface
    ['{96D36126-1EFC-4C6B-9968-033FB3C44660}']
    function ObterDataHoraUTC: TDateTime;
    function ObterTipo: TTipoEventoLogIA;
    function ObterProvedor: string;
    function ObterMensagem: string;
    function ObterStatusHTTP: Integer;
    property DataHoraUTC: TDateTime read ObterDataHoraUTC;
    property Tipo: TTipoEventoLogIA read ObterTipo;
    property Provedor: string read ObterProvedor;
    property Mensagem: string read ObterMensagem;
    property StatusHTTP: Integer read ObterStatusHTTP;
  end;

  IReceptorLogIA = interface
    ['{9FB4BE61-BDD7-46CD-A98C-4A58C6042331}']
    procedure Registrar(const AEvento: IEventoLogIA);
  end;

  TEventoLogIA = class(TInterfacedObject, IEventoLogIA)
  private
    FDataHoraUTC: TDateTime;
    FTipoEventoLog: TTipoEventoLogIA;
    FProvedor: string;
    FMensagem: string;
    FStatusHTTP: Integer;
    function ObterDataHoraUTC: TDateTime;
    function ObterTipo: TTipoEventoLogIA;
    function ObterProvedor: string;
    function ObterMensagem: string;
    function ObterStatusHTTP: Integer;
  public
    constructor Create(ATipo: TTipoEventoLogIA;
      const AProvedor, AMensagem: string; AStatusHTTP: Integer);
  end;

implementation

uses
  System.SysUtils,
  System.DateUtils;

constructor TEventoLogIA.Create(ATipo: TTipoEventoLogIA;
  const AProvedor, AMensagem: string; AStatusHTTP: Integer);
begin
  inherited Create;
  FDataHoraUTC := TTimeZone.Local.ToUniversalTime(Now);
  FTipoEventoLog := ATipo;
  FProvedor := AProvedor;
  FMensagem := AMensagem;
  FStatusHTTP := AStatusHTTP;
end;

function TEventoLogIA.ObterDataHoraUTC: TDateTime;
begin
  Result := FDataHoraUTC;
end;

function TEventoLogIA.ObterMensagem: string;
begin
  Result := FMensagem;
end;

function TEventoLogIA.ObterProvedor: string;
begin
  Result := FProvedor;
end;

function TEventoLogIA.ObterStatusHTTP: Integer;
begin
  Result := FStatusHTTP;
end;

function TEventoLogIA.ObterTipo: TTipoEventoLogIA;
begin
  Result := FTipoEventoLog;
end;

end.
