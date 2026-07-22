unit Daikit.Infraestrutura.HTTP.Transporte;

interface

uses
  System.Classes,
  System.Net.HttpClient,
  System.Net.URLClient,
  Daikit.Aplicacao.Interfaces,
  Daikit.Infraestrutura.HTTP.Interfaces;

type
  TTransporteHTTPClient = class(TInterfacedObject, ITransporteHTTP)
  private
    class function MetodoComoTexto(AMetodo: TMetodoHTTP): string; static;
    class function FluxoComoTexto(AFluxo: TStream): string; static;
    class function ConverterCabecalhos(
      const ACabecalhos: TNetHeaders): TArray<TCabecalhoHTTP>; static;
    class procedure VerificarCancelamento(
      const ACancelamento: ITokenCancelamentoIA); static;
  protected
    function CriarCliente: THTTPClient; virtual;
  public
    function Enviar(const ARequisicao: IRequisicaoHTTP;
      const ACancelamento: ITokenCancelamentoIA = nil): IRespostaHTTP;
  end;

implementation

uses
  System.SysUtils,
  System.Types,
  System.Diagnostics,
  Daikit.Dominio.Excecoes,
  Daikit.Infraestrutura.HTTP.Constantes,
  Daikit.Infraestrutura.HTTP.Excecoes,
  Daikit.Infraestrutura.HTTP.FluxoLimitado,
  Daikit.Infraestrutura.HTTP.Modelos,
  Daikit.Infraestrutura.HTTP.Sanitizador;

function TTransporteHTTPClient.CriarCliente: THTTPClient;
begin
  Result := THTTPClient.Create;
  Result.SecureProtocols := [THTTPSecureProtocol.TLS12,
    THTTPSecureProtocol.TLS13];
  Result.HandleRedirects := False;
end;

class function TTransporteHTTPClient.ConverterCabecalhos(
  const ACabecalhos: TNetHeaders): TArray<TCabecalhoHTTP>;
var
  I: Integer;
begin
  SetLength(Result, Length(ACabecalhos));
  for I := Low(ACabecalhos) to High(ACabecalhos) do
    Result[I] := TCabecalhoHTTP.Criar(ACabecalhos[I].Name,
      ACabecalhos[I].Value);
end;

function TTransporteHTTPClient.Enviar(const ARequisicao: IRequisicaoHTTP;
  const ACancelamento: ITokenCancelamentoIA): IRespostaHTTP;
var
  LRequisicaoHTTPNativa: IHTTPRequest;
  LRespostaHTTPNativa: IHTTPResponse;
  LResultadoHTTPAssincrono: IAsyncResult;
  LStreamCorpoRequisicao: TStringStream;
  LFluxoRespostaHTTP: TFluxoRespostaLimitado;
  LCabecalhoHTTP: TCabecalhoHTTP;
  LRequisicaoCancelada: Boolean;
  LTimeoutExcedido: Boolean;
  LHTTPCliente: THTTPClient;
  LCronometro: TStopwatch;
begin
  if ARequisicao = nil then
    raise EValidacaoHTTP.Create('A requisicao HTTP deve ser informada.');
  VerificarCancelamento(ACancelamento);

  LStreamCorpoRequisicao := nil;
  LHTTPCliente := nil;
  LFluxoRespostaHTTP := nil;
  try
    LHTTPCliente := CriarCliente;
    LFluxoRespostaHTTP := TFluxoRespostaLimitado.Create(
      ARequisicao.LimiteRespostaBytes);
    try
      LRequisicaoHTTPNativa := LHTTPCliente.GetRequest(
        MetodoComoTexto(ARequisicao.Metodo), ARequisicao.URL);
      (LRequisicaoHTTPNativa as TURLRequest).ConnectionTimeout :=
        ARequisicao.TimeoutConexaoMS;
      (LRequisicaoHTTPNativa as TURLRequest).ResponseTimeout :=
        ARequisicao.TimeoutRespostaMS;

      for LCabecalhoHTTP in ARequisicao.Cabecalhos do
        LRequisicaoHTTPNativa.SetHeaderValue(LCabecalhoHTTP.Nome, LCabecalhoHTTP.Valor);

      if ARequisicao.Corpo <> '' then
      begin
        LStreamCorpoRequisicao := TStringStream.Create(ARequisicao.Corpo,
          TEncoding.UTF8);
        LRequisicaoHTTPNativa.SourceStream := LStreamCorpoRequisicao;
      end;

      LResultadoHTTPAssincrono := LHTTPCliente.BeginExecute(LRequisicaoHTTPNativa,
        LFluxoRespostaHTTP);
      LRequisicaoCancelada := False;
      LTimeoutExcedido := False;
      LCronometro := TStopwatch.StartNew;
      while not LResultadoHTTPAssincrono.IsCompleted do
      begin
        if (ACancelamento <> nil) and ACancelamento.FoiCancelado then
        begin
          LRequisicaoCancelada := True;
          LRequisicaoHTTPNativa.Cancel;
          LResultadoHTTPAssincrono.Cancel;
          Break;
        end;
        if LCronometro.ElapsedMilliseconds >=
          ARequisicao.TimeoutRespostaMS then
        begin
          LTimeoutExcedido := True;
          LRequisicaoHTTPNativa.Cancel;
          LResultadoHTTPAssincrono.Cancel;
          Break;
        end;
        LResultadoHTTPAssincrono.AsyncWaitEvent.WaitFor(
          CIntervaloVerificacaoCancelamentoMS);
      end;

      if (ACancelamento <> nil) and ACancelamento.FoiCancelado then
        LRequisicaoCancelada := True;
      if LCronometro.ElapsedMilliseconds >= ARequisicao.TimeoutRespostaMS then
        LTimeoutExcedido := True;

      if LRequisicaoCancelada or LTimeoutExcedido then
      begin
        try
          THTTPClient.EndAsyncHTTP(LResultadoHTTPAssincrono);
        except
          on E: Exception do
          begin
            if LTimeoutExcedido then
              raise ETimeoutHTTP.CreateFmt(
                'O tempo limite da requisicao %s em %s foi excedido.',
                [MetodoComoTexto(ARequisicao.Metodo),
                 TSanitizadorHTTP.SanitizarURL(ARequisicao.URL)]);
            raise EOperacaoCanceladaIA.Create(
              'A operacao HTTP foi cancelada.');
          end;
        end;
        if LTimeoutExcedido then
          raise ETimeoutHTTP.CreateFmt(
            'O tempo limite da requisicao %s em %s foi excedido.',
            [MetodoComoTexto(ARequisicao.Metodo),
             TSanitizadorHTTP.SanitizarURL(ARequisicao.URL)]);
        raise EOperacaoCanceladaIA.Create('A operacao HTTP foi cancelada.');
      end;

      LRespostaHTTPNativa := THTTPClient.EndAsyncHTTP(LResultadoHTTPAssincrono);
      Result := TRespostaHTTP.Create(LRespostaHTTPNativa.StatusCode,
        LRespostaHTTPNativa.StatusText,
        ConverterCabecalhos(LRespostaHTTPNativa.Headers),
        FluxoComoTexto(LFluxoRespostaHTTP));
    except
      on E: EOperacaoCanceladaIA do
        raise;
      on E: ELimiteRespostaHTTP do
        raise;
      on E: EValidacaoHTTP do
        raise;
      on E: ETransporteHTTP do
        raise;
      on E: Exception do
        raise ETransporteHTTP.CreateFmt('Falha ao executar %s em %s (%s).',
          [MetodoComoTexto(ARequisicao.Metodo),
           TSanitizadorHTTP.SanitizarURL(ARequisicao.URL), E.ClassName]);
    end;
  finally
    LStreamCorpoRequisicao.Free;
    LFluxoRespostaHTTP.Free;
    LHTTPCliente.Free;
  end;
end;

class function TTransporteHTTPClient.FluxoComoTexto(
  AFluxo: TStream): string;
var
  LBytesResposta: TBytes;
begin
  SetLength(LBytesResposta, AFluxo.Size);
  AFluxo.Position := 0;
  if Length(LBytesResposta) > 0 then
    AFluxo.ReadBuffer(LBytesResposta[Low(LBytesResposta)], Length(LBytesResposta));
  Result := TEncoding.UTF8.GetString(LBytesResposta);
end;

class function TTransporteHTTPClient.MetodoComoTexto(
  AMetodo: TMetodoHTTP): string;
begin
  case AMetodo of
    TMetodoHTTP.Get: Result := sHTTPMethodGet;
    TMetodoHTTP.Post: Result := sHTTPMethodPost;
    TMetodoHTTP.Put: Result := sHTTPMethodPut;
    TMetodoHTTP.Patch: Result := sHTTPMethodPatch;
    TMetodoHTTP.Delete: Result := sHTTPMethodDelete;
  else
    raise EValidacaoHTTP.Create('O metodo HTTP informado nao e suportado.');
  end;
end;

class procedure TTransporteHTTPClient.VerificarCancelamento(
  const ACancelamento: ITokenCancelamentoIA);
begin
  if (ACancelamento <> nil) and ACancelamento.FoiCancelado then
    raise EOperacaoCanceladaIA.Create('A operacao HTTP foi cancelada.');
end;

end.
