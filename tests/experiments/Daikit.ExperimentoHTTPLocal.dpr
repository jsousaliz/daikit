program DaikitExperimentoHTTPLocal;

{$APPTYPE CONSOLE}

uses
  System.Classes,
  System.SysUtils,
  Daikit.Testes.ServidorHTTPLocal in '..\testes\mock\Daikit.Testes.ServidorHTTPLocal.pas',
  Daikit.Aplicacao.Interfaces in '..\..\src\nucleo\aplicacao\Daikit.Aplicacao.Interfaces.pas',
  Daikit.Aplicacao.TokenCancelamento in '..\..\src\nucleo\aplicacao\Daikit.Aplicacao.TokenCancelamento.pas',
  Daikit.Dominio.Interfaces in '..\..\src\nucleo\dominio\Daikit.Dominio.Interfaces.pas',
  Daikit.Dominio.Excecoes in '..\..\src\nucleo\dominio\Daikit.Dominio.Excecoes.pas',
  Daikit.Infraestrutura.HTTP.Constantes in '..\..\src\infraestrutura\http\Daikit.Infraestrutura.HTTP.Constantes.pas',
  Daikit.Infraestrutura.HTTP.Interfaces in '..\..\src\infraestrutura\http\Daikit.Infraestrutura.HTTP.Interfaces.pas',
  Daikit.Infraestrutura.HTTP.Excecoes in '..\..\src\infraestrutura\http\Daikit.Infraestrutura.HTTP.Excecoes.pas',
  Daikit.Infraestrutura.HTTP.Modelos in '..\..\src\infraestrutura\http\Daikit.Infraestrutura.HTTP.Modelos.pas',
  Daikit.Infraestrutura.HTTP.FluxoLimitado in '..\..\src\infraestrutura\http\Daikit.Infraestrutura.HTTP.FluxoLimitado.pas',
  Daikit.Infraestrutura.HTTP.Sanitizador in '..\..\src\infraestrutura\http\Daikit.Infraestrutura.HTTP.Sanitizador.pas',
  Daikit.Infraestrutura.HTTP.Transporte in '..\..\src\infraestrutura\http\Daikit.Infraestrutura.HTTP.Transporte.pas';

const
  CAtrasoServidorMS = 500;
  CTimeoutRespostaMS = 100;
  CEsperaCancelamentoMS = 75;
  CLimiteRespostaBytes = 4;
  CCodigoSaidaErro = 1;

procedure Verificar(ACondicao: Boolean; const AMensagem: string);
begin
  if not ACondicao then
    raise Exception.Create(AMensagem);
end;

procedure VerificarResposta;
var
  LServidor: TServidorHTTPLocal;
  LTransporteHTTP: ITransporteHTTP;
  LOpcoesRequisicaoHTTP: TOpcoesRequisicaoHTTP;
  LRequisicaoHTTP: IRequisicaoHTTP;
  LRespostaHTTP: IRespostaHTTP;
begin
  LServidor := TServidorHTTPLocal.Create(
    TComportamentoServidorHTTPLocal.RespostaImediata);
  try
    LTransporteHTTP := TTransporteHTTPClient.Create;
    LOpcoesRequisicaoHTTP := TOpcoesRequisicaoHTTP.Padrao;
    LOpcoesRequisicaoHTTP.URL := LServidor.URL;
    LRequisicaoHTTP := TRequisicaoHTTP.Create(LOpcoesRequisicaoHTTP);
    LRespostaHTTP := LTransporteHTTP.Enviar(LRequisicaoHTTP);
    Verificar((LRespostaHTTP.Status = 200) and (LRespostaHTTP.Corpo = '{}'),
      'A resposta local nao corresponde ao esperado.');
  finally
    LServidor.Free;
  end;
end;

procedure VerificarTimeout;
var
  LServidor: TServidorHTTPLocal;
  LTransporteHTTP: ITransporteHTTP;
  LOpcoesRequisicaoHTTP: TOpcoesRequisicaoHTTP;
  LRequisicaoHTTP: IRequisicaoHTTP;
  LTimeoutOcorreu: Boolean;
begin
  LServidor := TServidorHTTPLocal.Create(
    TComportamentoServidorHTTPLocal.RespostaAtrasada, CAtrasoServidorMS);
  try
    LTransporteHTTP := TTransporteHTTPClient.Create;
    LOpcoesRequisicaoHTTP := TOpcoesRequisicaoHTTP.Padrao;
    LOpcoesRequisicaoHTTP.URL := LServidor.URL;
    LOpcoesRequisicaoHTTP.TimeoutRespostaMS := CTimeoutRespostaMS;
    LRequisicaoHTTP := TRequisicaoHTTP.Create(LOpcoesRequisicaoHTTP);
    LTimeoutOcorreu := False;
    try
      LTransporteHTTP.Enviar(LRequisicaoHTTP);
    except
      on E: ETimeoutHTTP do
        LTimeoutOcorreu := True;
    end;
    Verificar(LTimeoutOcorreu, 'O timeout local nao foi respeitado.');
  finally
    LServidor.Free;
  end;
end;

procedure VerificarLimite;
var
  LServidor: TServidorHTTPLocal;
  LTransporteHTTP: ITransporteHTTP;
  LOpcoesRequisicaoHTTP: TOpcoesRequisicaoHTTP;
  LRequisicaoHTTP: IRequisicaoHTTP;
  LLimiteOcorreu: Boolean;
begin
  LServidor := TServidorHTTPLocal.Create(
    TComportamentoServidorHTTPLocal.RespostaExcessiva);
  try
    LTransporteHTTP := TTransporteHTTPClient.Create;
    LOpcoesRequisicaoHTTP := TOpcoesRequisicaoHTTP.Padrao;
    LOpcoesRequisicaoHTTP.URL := LServidor.URL;
    LOpcoesRequisicaoHTTP.LimiteRespostaBytes := CLimiteRespostaBytes;
    LRequisicaoHTTP := TRequisicaoHTTP.Create(LOpcoesRequisicaoHTTP);
    LLimiteOcorreu := False;
    try
      LTransporteHTTP.Enviar(LRequisicaoHTTP);
    except
      on E: ELimiteRespostaHTTP do
        LLimiteOcorreu := True;
    end;
    Verificar(LLimiteOcorreu, 'O limite da resposta local nao foi respeitado.');
  finally
    LServidor.Free;
  end;
end;

procedure VerificarCancelamento;
var
  LServidor: TServidorHTTPLocal;
  LTransporteHTTP: ITransporteHTTP;
  LOpcoesRequisicaoHTTP: TOpcoesRequisicaoHTTP;
  LRequisicaoHTTP: IRequisicaoHTTP;
  LTokenCancelamento: ITokenCancelamentoIA;
  LThread: TThread;
  LCancelamentoOcorreu: Boolean;
begin
  LServidor := TServidorHTTPLocal.Create(
    TComportamentoServidorHTTPLocal.RespostaAtrasada, CAtrasoServidorMS);
  LThread := nil;
  try
    LTransporteHTTP := TTransporteHTTPClient.Create;
    LOpcoesRequisicaoHTTP := TOpcoesRequisicaoHTTP.Padrao;
    LOpcoesRequisicaoHTTP.URL := LServidor.URL;
    LRequisicaoHTTP := TRequisicaoHTTP.Create(LOpcoesRequisicaoHTTP);
    LTokenCancelamento := TTokenCancelamentoIA.Create;
    LThread := TThread.CreateAnonymousThread(
      procedure
      begin
        TThread.Sleep(CEsperaCancelamentoMS);
        LTokenCancelamento.Cancelar;
      end);
    LThread.FreeOnTerminate := False;
    LThread.Start;
    LCancelamentoOcorreu := False;
    try
      LTransporteHTTP.Enviar(LRequisicaoHTTP, LTokenCancelamento);
    except
      on E: EOperacaoCanceladaIA do
        LCancelamentoOcorreu := True;
    end;
    Verificar(LCancelamentoOcorreu,
      'O cancelamento local em andamento nao foi respeitado.');
  finally
    if LThread <> nil then
    begin
      LThread.WaitFor;
      LThread.Free;
    end;
    LServidor.Free;
  end;
end;

begin
  ReportMemoryLeaksOnShutdown := True;
  try
    VerificarResposta;
    VerificarTimeout;
    VerificarLimite;
    VerificarCancelamento;
    Writeln('Experimento HTTP local concluido com sucesso.');
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      ExitCode := CCodigoSaidaErro;
    end;
  end;
end.
