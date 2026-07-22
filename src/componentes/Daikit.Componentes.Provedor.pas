unit Daikit.Componentes.Provedor;

interface

uses
  System.Classes,
  Daikit.Aplicacao.Interfaces,
  Daikit.Aplicacao.Log,
  Daikit.Componentes.Constantes,
  Daikit.Infraestrutura.HTTP.Interfaces;

type
  TProvedorIA = class abstract(TComponent)
  private
    FChaveAPI: string;
    FTransporte: ITransporteHTTP;
    FEndpoint: string;
    FModeloPadrao: string;
    FVariavelAmbienteChaveAPI: string;
    FTimeoutConexaoMS: Integer;
    FTimeoutRespostaMS: Integer;
    FLimiteRespostaBytes: Int64;
    function ObterChaveAPI: string;
    procedure DefinirChaveAPI(const AValor: string);
    function ObterEndpoint: string;
    function ObterModeloPadrao: string;
    function ObterVariavelAmbienteChaveAPI: string;
    function ArmazenarEndpoint: Boolean;
    function ArmazenarModeloPadrao: Boolean;
    function ArmazenarVariavelAmbienteChaveAPI: Boolean;
  protected
    function ObterEndpointPadrao: string; virtual; abstract;
    function ObterModeloPadraoDoAdaptador: string; virtual; abstract;
    function ObterVariavelAmbienteChaveAPIPadrao: string;
      virtual; abstract;
    function ObterTransporte: ITransporteHTTP;
    function ObterChaveAPIEmMemoria: string;
    function ObterNomeProvedorLog: string; virtual; abstract;
    function CriarAdaptadorComTransporte(
      const ATransporte: ITransporteHTTP): IAdaptadorIA; virtual; abstract;
  public
    constructor Create(AOwner: TComponent); override;
    procedure DefinirTransporte(const ATransporte: ITransporteHTTP);
    procedure LimparChaveAPI;
    function TemChaveAPIEmMemoria: Boolean;
    function CriarAdaptador(
      const AReceptorLog: IReceptorLogIA = nil): IAdaptadorIA;
  published
    property ChaveAPI: string read ObterChaveAPI write DefinirChaveAPI
      stored False;
    property Endpoint: string read ObterEndpoint write FEndpoint
      stored ArmazenarEndpoint;
    property ModeloPadrao: string read ObterModeloPadrao write FModeloPadrao
      stored ArmazenarModeloPadrao;
    property VariavelAmbienteChaveAPI: string
      read ObterVariavelAmbienteChaveAPI write FVariavelAmbienteChaveAPI
      stored ArmazenarVariavelAmbienteChaveAPI;
    property TimeoutConexaoMS: Integer read FTimeoutConexaoMS
      write FTimeoutConexaoMS default CTimeoutConexaoComponentePadraoMS;
    property TimeoutRespostaMS: Integer read FTimeoutRespostaMS
      write FTimeoutRespostaMS default CTimeoutRespostaComponentePadraoMS;
    property LimiteRespostaBytes: Int64 read FLimiteRespostaBytes
      write FLimiteRespostaBytes default CLimiteRespostaComponentePadraoBytes;
  end;

implementation

uses
  System.SysUtils,
  Daikit.Infraestrutura.HTTP.Transporte,
  Daikit.Infraestrutura.HTTP.Log;

constructor TProvedorIA.Create(AOwner: TComponent);
begin
  inherited;
  FTimeoutConexaoMS := CTimeoutConexaoComponentePadraoMS;
  FTimeoutRespostaMS := CTimeoutRespostaComponentePadraoMS;
  FLimiteRespostaBytes := CLimiteRespostaComponentePadraoBytes;
end;

function TProvedorIA.CriarAdaptador(
  const AReceptorLog: IReceptorLogIA): IAdaptadorIA;
var
  LTransporte: ITransporteHTTP;
begin
  LTransporte := ObterTransporte;
  if AReceptorLog <> nil then
    LTransporte := TTransporteHTTPComLog.Create(LTransporte, AReceptorLog,
      ObterNomeProvedorLog);
  Result := CriarAdaptadorComTransporte(LTransporte);
end;

function TProvedorIA.ArmazenarEndpoint: Boolean;
begin
  Result := FEndpoint <> '';
end;

function TProvedorIA.ArmazenarModeloPadrao: Boolean;
begin
  Result := FModeloPadrao <> '';
end;

function TProvedorIA.ArmazenarVariavelAmbienteChaveAPI: Boolean;
begin
  Result := FVariavelAmbienteChaveAPI <> '';
end;

procedure TProvedorIA.DefinirChaveAPI(const AValor: string);
begin
  if (AValor = CValorChaveAPIMascarada) and (FChaveAPI <> '') then
    Exit;
  FChaveAPI := AValor;
end;

procedure TProvedorIA.DefinirTransporte(
  const ATransporte: ITransporteHTTP);
begin
  FTransporte := ATransporte;
end;

function TProvedorIA.ObterChaveAPI: string;
begin
  if FChaveAPI = '' then
    Result := ''
  else
    Result := CValorChaveAPIMascarada;
end;

function TProvedorIA.ObterChaveAPIEmMemoria: string;
begin
  Result := FChaveAPI;
end;

function TProvedorIA.ObterEndpoint: string;
begin
  if FEndpoint = '' then
    Result := ObterEndpointPadrao
  else
    Result := FEndpoint;
end;

function TProvedorIA.ObterModeloPadrao: string;
begin
  if FModeloPadrao = '' then
    Result := ObterModeloPadraoDoAdaptador
  else
    Result := FModeloPadrao;
end;

function TProvedorIA.ObterTransporte: ITransporteHTTP;
begin
  if FTransporte = nil then
    FTransporte := TTransporteHTTPClient.Create;
  Result := FTransporte;
end;

function TProvedorIA.ObterVariavelAmbienteChaveAPI: string;
begin
  if FVariavelAmbienteChaveAPI = '' then
    Result := ObterVariavelAmbienteChaveAPIPadrao
  else
    Result := FVariavelAmbienteChaveAPI;
end;

procedure TProvedorIA.LimparChaveAPI;
begin
  FChaveAPI := '';
end;

function TProvedorIA.TemChaveAPIEmMemoria: Boolean;
begin
  Result := Trim(FChaveAPI) <> '';
end;

end.
