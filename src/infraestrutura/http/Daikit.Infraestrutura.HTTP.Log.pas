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
    FTransporte: ITransporteHTTP;
    FReceptor: IReceptorLogIA;
    FProvedor: string;
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
  FTransporte := ATransporte;
  FReceptor := AReceptor;
  FProvedor := AProvedor;
end;

function TTransporteHTTPComLog.Enviar(const ARequisicao: IRequisicaoHTTP;
  const ACancelamento: ITokenCancelamentoIA): IRespostaHTTP;
var
  LMensagem: string;
  LNivel: TNivelLogIA;
begin
  if ARequisicao = nil then
    LMensagem := ''
  else
    LMensagem := Sanitizar(ARequisicao.Corpo);
  Publicar(TTipoEventoLogIA.Requisicao, TNivelLogIA.Informacao,
    LMensagem, CStatusHTTPNaoInformado);

  try
    Result := FTransporte.Enviar(ARequisicao, ACancelamento);
    if Result = nil then
    begin
      Publicar(TTipoEventoLogIA.Resposta, TNivelLogIA.Erro, '',
        CStatusHTTPNaoInformado);
      Exit;
    end;

    if Result.FoiSucesso then
      LNivel := TNivelLogIA.Informacao
    else
      LNivel := TNivelLogIA.Erro;
    Publicar(TTipoEventoLogIA.Resposta, LNivel, Sanitizar(Result.Corpo),
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
begin
  FReceptor.Registrar(TEventoLogIA.Create(ATipo, ANivel, FProvedor,
    AMensagem, AStatusHTTP));
end;

function TTransporteHTTPComLog.Sanitizar(const AJSON: string): string;
var
  LTruncado: Boolean;
begin
  if AJSON = '' then
    Exit('');
  Result := TSanitizadorJSON.Sanitizar(AJSON, True, MaxInt, LTruncado);
end;

end.
