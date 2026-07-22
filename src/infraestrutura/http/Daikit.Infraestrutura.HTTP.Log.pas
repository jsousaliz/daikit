unit Daikit.Infraestrutura.HTTP.Log;

interface

uses
  System.SysUtils,
  Daikit.Aplicacao.Interfaces,
  Daikit.Aplicacao.Log,
  Daikit.Infraestrutura.HTTP.Interfaces;

type
  TTransporteHTTPComLog = class(TInterfacedObject, ITransporteHTTP)
  private
    FTransporteHTTP: ITransporteHTTP;
    FReceptorLog: IReceptorLogIA;
    FNomeProvedor: string;
    function Sanitizar(const AJSON: string): string;
    procedure Publicar(ATipo: TTipoEventoLogIA; ANivel: TNivelLogIA;
      const AMensagem: string; AStatusHTTP: Integer);
  public
    constructor Create(const ATransporte: ITransporteHTTP;
      const AReceptor: IReceptorLogIA; const AProvedor: string = '');
    function Enviar(const ARequisicao: IRequisicaoHTTP;
      const ACancelamento: ITokenCancelamentoIA = nil): IRespostaHTTP;
  end;

implementation

uses
  Daikit.Dominio.Excecoes,
  Daikit.Infraestrutura.HTTP.Constantes,
  Daikit.Infraestrutura.HTTP.Excecoes,
  Daikit.Infraestrutura.JSON.Sanitizador;

constructor TTransporteHTTPComLog.Create(const ATransporte: ITransporteHTTP;
  const AReceptor: IReceptorLogIA; const AProvedor: string);
begin
  inherited Create;
  if ATransporte = nil then
    raise EValidacaoHTTP.Create(
      'O transporte HTTP observado deve ser informado.');
  if AReceptor = nil then
    raise EValidacaoHTTP.Create(
      'O receptor do log deve ser informado.');
  FTransporteHTTP := ATransporte;
  FReceptorLog := AReceptor;
  FNomeProvedor := AProvedor;
end;

function TTransporteHTTPComLog.Enviar(const ARequisicao: IRequisicaoHTTP;
  const ACancelamento: ITokenCancelamentoIA): IRespostaHTTP;
var
  LMensagemLog: string;
  LNivelLog: TNivelLogIA;
begin
  if ARequisicao = nil then
    LMensagemLog := ''
  else
    LMensagemLog := Sanitizar(ARequisicao.Corpo);
  Publicar(TTipoEventoLogIA.Requisicao, TNivelLogIA.Requisicao,
    LMensagemLog, CStatusHTTPNaoInformado);

  try
    Result := FTransporteHTTP.Enviar(ARequisicao, ACancelamento);
    if Result = nil then
    begin
      Publicar(TTipoEventoLogIA.Resposta, TNivelLogIA.Erro, '',
        CStatusHTTPNaoInformado);
      Exit;
    end;

    if Result.FoiSucesso then
      LNivelLog := TNivelLogIA.Resposta
    else
      LNivelLog := TNivelLogIA.RespostaErro;
    Publicar(TTipoEventoLogIA.Resposta, LNivelLog, Sanitizar(Result.Corpo),
      Result.Status);
  except
    on E: EOperacaoCanceladaIA do
    begin
      Publicar(TTipoEventoLogIA.Cancelamento, TNivelLogIA.Informacao,
        E.Message, CStatusHTTPNaoInformado);
      raise;
    end;
    on E: Exception do
    begin
      Publicar(TTipoEventoLogIA.Erro, TNivelLogIA.Erro, E.Message,
        CStatusHTTPNaoInformado);
      raise;
    end;
  end;
end;

procedure TTransporteHTTPComLog.Publicar(ATipo: TTipoEventoLogIA;
  ANivel: TNivelLogIA; const AMensagem: string; AStatusHTTP: Integer);
var
  LEventoLog: IEventoLogIA;
begin
  LEventoLog := TEventoLogIA.Create(ATipo, ANivel, FNomeProvedor,
    AMensagem, AStatusHTTP);
  FReceptorLog.Registrar(LEventoLog);
end;

function TTransporteHTTPComLog.Sanitizar(const AJSON: string): string;
var
  LJSONTruncado: Boolean;
begin
  if AJSON = '' then
    Exit('');
  Result := TSanitizadorJSON.Sanitizar(AJSON, True, MaxInt, LJSONTruncado);
end;

end.
