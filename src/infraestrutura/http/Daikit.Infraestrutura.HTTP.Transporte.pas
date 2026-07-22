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
  LRequisicaoNativa: IHTTPRequest;
  LRespostaNativa: IHTTPResponse;
  LResultadoAssincrono: IAsyncResult;
  LCorpoRequisicao: TStringStream;
  LFluxoResposta: TFluxoRespostaLimitado;
  LCabecalho: TCabecalhoHTTP;
  LCancelado: Boolean;
  LExcedeuTimeout: Boolean;
  LCliente: THTTPClient;
  LCronometro: TStopwatch;
begin
  if ARequisicao = nil then
    raise EValidacaoHTTP.Create('A requisicao HTTP deve ser informada.');
  VerificarCancelamento(ACancelamento);

  LCorpoRequisicao := nil;
  LCliente := nil;
  LFluxoResposta := nil;
  try
    LCliente := CriarCliente;
    LFluxoResposta := TFluxoRespostaLimitado.Create(
      ARequisicao.LimiteRespostaBytes);
    try
      LRequisicaoNativa := LCliente.GetRequest(
        MetodoComoTexto(ARequisicao.Metodo), ARequisicao.URL);
      (LRequisicaoNativa as TURLRequest).ConnectionTimeout :=
        ARequisicao.TimeoutConexaoMS;
      (LRequisicaoNativa as TURLRequest).ResponseTimeout :=
        ARequisicao.TimeoutRespostaMS;

      for LCabecalho in ARequisicao.Cabecalhos do
        LRequisicaoNativa.SetHeaderValue(LCabecalho.Nome, LCabecalho.Valor);

      if ARequisicao.Corpo <> '' then
      begin
        LCorpoRequisicao := TStringStream.Create(ARequisicao.Corpo,
          TEncoding.UTF8);
        LRequisicaoNativa.SourceStream := LCorpoRequisicao;
      end;

      LResultadoAssincrono := LCliente.BeginExecute(LRequisicaoNativa,
        LFluxoResposta);
      LCancelado := False;
      LExcedeuTimeout := False;
      LCronometro := TStopwatch.StartNew;
      while not LResultadoAssincrono.IsCompleted do
      begin
        if (ACancelamento <> nil) and ACancelamento.FoiCancelado then
        begin
          LCancelado := True;
          LRequisicaoNativa.Cancel;
          LResultadoAssincrono.Cancel;
          Break;
        end;
        if LCronometro.ElapsedMilliseconds >=
          ARequisicao.TimeoutRespostaMS then
        begin
          LExcedeuTimeout := True;
          LRequisicaoNativa.Cancel;
          LResultadoAssincrono.Cancel;
          Break;
        end;
        LResultadoAssincrono.AsyncWaitEvent.WaitFor(
          CIntervaloVerificacaoCancelamentoMS);
      end;

      if (ACancelamento <> nil) and ACancelamento.FoiCancelado then
        LCancelado := True;
      if LCronometro.ElapsedMilliseconds >= ARequisicao.TimeoutRespostaMS then
        LExcedeuTimeout := True;

      if LCancelado or LExcedeuTimeout then
      begin
        try
          THTTPClient.EndAsyncHTTP(LResultadoAssincrono);
        except
          on E: Exception do
          begin
            if LExcedeuTimeout then
              raise ETimeoutHTTP.CreateFmt(
                'O tempo limite da requisicao %s em %s foi excedido.',
                [MetodoComoTexto(ARequisicao.Metodo),
                 TSanitizadorHTTP.SanitizarURL(ARequisicao.URL)]);
            raise EOperacaoCanceladaIA.Create(
              'A operacao HTTP foi cancelada.');
          end;
        end;
        if LExcedeuTimeout then
          raise ETimeoutHTTP.CreateFmt(
            'O tempo limite da requisicao %s em %s foi excedido.',
            [MetodoComoTexto(ARequisicao.Metodo),
             TSanitizadorHTTP.SanitizarURL(ARequisicao.URL)]);
        raise EOperacaoCanceladaIA.Create('A operacao HTTP foi cancelada.');
      end;

      LRespostaNativa := THTTPClient.EndAsyncHTTP(LResultadoAssincrono);
      Result := TRespostaHTTP.Create(LRespostaNativa.StatusCode,
        LRespostaNativa.StatusText,
        ConverterCabecalhos(LRespostaNativa.Headers),
        FluxoComoTexto(LFluxoResposta));
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
    LCorpoRequisicao.Free;
    LFluxoResposta.Free;
    LCliente.Free;
  end;
end;

class function TTransporteHTTPClient.FluxoComoTexto(
  AFluxo: TStream): string;
var
  LBytes: TBytes;
begin
  SetLength(LBytes, AFluxo.Size);
  AFluxo.Position := 0;
  if Length(LBytes) > 0 then
    AFluxo.ReadBuffer(LBytes[Low(LBytes)], Length(LBytes));
  Result := TEncoding.UTF8.GetString(LBytes);
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
