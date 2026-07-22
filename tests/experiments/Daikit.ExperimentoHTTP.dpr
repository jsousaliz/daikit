program DaikitExperimentoHTTP;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Daikit.Aplicacao.Interfaces in '..\..\src\nucleo\aplicacao\Daikit.Aplicacao.Interfaces.pas',
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
  CEnderecoExperimentoTLS = 'https://example.com/';
  CCodigoSaidaRespostaInvalida = 1;
  CCodigoSaidaErro = 2;

var
  LTransporteHTTP: ITransporteHTTP;
  LOpcoesRequisicaoHTTP: TOpcoesRequisicaoHTTP;
  LRequisicaoHTTP: IRequisicaoHTTP;
  LRespostaHTTP: IRespostaHTTP;
begin
  ReportMemoryLeaksOnShutdown := True;
  try
    LTransporteHTTP := TTransporteHTTPClient.Create;
    LOpcoesRequisicaoHTTP := TOpcoesRequisicaoHTTP.Padrao;
    LOpcoesRequisicaoHTTP.URL := CEnderecoExperimentoTLS;
    LRequisicaoHTTP := TRequisicaoHTTP.Create(LOpcoesRequisicaoHTTP);
    LRespostaHTTP := LTransporteHTTP.Enviar(LRequisicaoHTTP);
    Writeln('Status HTTPS: ', LRespostaHTTP.Status, ' ', LRespostaHTTP.Motivo);
    Writeln('Bytes recebidos: ', TEncoding.UTF8.GetByteCount(LRespostaHTTP.Corpo));
    if not LRespostaHTTP.FoiSucesso then
      ExitCode := CCodigoSaidaRespostaInvalida;
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      ExitCode := CCodigoSaidaErro;
    end;
  end;
end.
