unit Daikit.Aplicacao.Log;

interface

{$SCOPEDENUMS ON}

type
  TNivelLogIA = (Informacao, Erro);
  TTipoEventoLogIA = (Requisicao, Resposta, Erro, Cancelamento);

  IEventoLogIA = interface
    ['{B98882BD-48A4-4372-8B95-D1EBA81D2CF6}']
    function ObterDataHoraUTC: TDateTime;
    function ObterTipo: TTipoEventoLogIA;
    function ObterNivel: TNivelLogIA;
    function ObterProvedor: string;
    function ObterMensagem: string;
    function ObterStatusHTTP: Integer;
    property DataHoraUTC: TDateTime read ObterDataHoraUTC;
    property Tipo: TTipoEventoLogIA read ObterTipo;
    property Nivel: TNivelLogIA read ObterNivel;
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
    FNivelLog: TNivelLogIA;
    FProvedor: string;
    FMensagem: string;
    FStatusHTTP: Integer;
    function ObterDataHoraUTC: TDateTime;
    function ObterTipo: TTipoEventoLogIA;
    function ObterNivel: TNivelLogIA;
    function ObterProvedor: string;
    function ObterMensagem: string;
    function ObterStatusHTTP: Integer;
  public
    constructor Create(ATipo: TTipoEventoLogIA; ANivel: TNivelLogIA;
      const AProvedor, AMensagem: string; AStatusHTTP: Integer);
  end;

implementation

uses
  System.SysUtils,
  System.DateUtils;

constructor TEventoLogIA.Create(ATipo: TTipoEventoLogIA;
  ANivel: TNivelLogIA; const AProvedor, AMensagem: string;
  AStatusHTTP: Integer);
begin
  inherited Create;
  FDataHoraUTC := TTimeZone.Local.ToUniversalTime(Now);
  FTipoEventoLog := ATipo;
  FNivelLog := ANivel;
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

function TEventoLogIA.ObterNivel: TNivelLogIA;
begin
  Result := FNivelLog;
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
