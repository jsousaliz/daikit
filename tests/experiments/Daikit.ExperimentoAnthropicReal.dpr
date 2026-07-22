program DaikitExperimentoAnthropicReal;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Daikit.Dominio.Interfaces in '..\..\src\nucleo\dominio\Daikit.Dominio.Interfaces.pas',
  Daikit.Dominio.Constantes in '..\..\src\nucleo\dominio\Daikit.Dominio.Constantes.pas',
  Daikit.Dominio.Excecoes in '..\..\src\nucleo\dominio\Daikit.Dominio.Excecoes.pas',
  Daikit.Dominio.Mensagem in '..\..\src\nucleo\dominio\Daikit.Dominio.Mensagem.pas',
  Daikit.Dominio.RequisicaoResposta in '..\..\src\nucleo\dominio\Daikit.Dominio.RequisicaoResposta.pas',
  Daikit.Aplicacao.Interfaces in '..\..\src\nucleo\aplicacao\Daikit.Aplicacao.Interfaces.pas',
  Daikit.Aplicacao.CapacidadesAdaptador in '..\..\src\nucleo\aplicacao\Daikit.Aplicacao.CapacidadesAdaptador.pas',
  Daikit.Infraestrutura.HTTP.Constantes in '..\..\src\infraestrutura\http\Daikit.Infraestrutura.HTTP.Constantes.pas',
  Daikit.Infraestrutura.HTTP.Interfaces in '..\..\src\infraestrutura\http\Daikit.Infraestrutura.HTTP.Interfaces.pas',
  Daikit.Infraestrutura.HTTP.Excecoes in '..\..\src\infraestrutura\http\Daikit.Infraestrutura.HTTP.Excecoes.pas',
  Daikit.Infraestrutura.HTTP.Modelos in '..\..\src\infraestrutura\http\Daikit.Infraestrutura.HTTP.Modelos.pas',
  Daikit.Infraestrutura.HTTP.FluxoLimitado in '..\..\src\infraestrutura\http\Daikit.Infraestrutura.HTTP.FluxoLimitado.pas',
  Daikit.Infraestrutura.HTTP.Sanitizador in '..\..\src\infraestrutura\http\Daikit.Infraestrutura.HTTP.Sanitizador.pas',
  Daikit.Infraestrutura.HTTP.Transporte in '..\..\src\infraestrutura\http\Daikit.Infraestrutura.HTTP.Transporte.pas',
  Daikit.Infraestrutura.JSON.Constantes in '..\..\src\infraestrutura\json\Daikit.Infraestrutura.JSON.Constantes.pas',
  Daikit.Infraestrutura.JSON.Excecoes in '..\..\src\infraestrutura\json\Daikit.Infraestrutura.JSON.Excecoes.pas',
  Daikit.Infraestrutura.JSON.Serializador in '..\..\src\infraestrutura\json\Daikit.Infraestrutura.JSON.Serializador.pas',
  Daikit.Adaptadores.Anthropic.Constantes in '..\..\src\adaptadores\anthropic\Daikit.Adaptadores.Anthropic.Constantes.pas',
  Daikit.Adaptadores.Anthropic.Excecoes in '..\..\src\adaptadores\anthropic\Daikit.Adaptadores.Anthropic.Excecoes.pas',
  Daikit.Adaptadores.Anthropic.Contratos in '..\..\src\adaptadores\anthropic\Daikit.Adaptadores.Anthropic.Contratos.pas',
  Daikit.Adaptadores.Anthropic.Interfaces in '..\..\src\adaptadores\anthropic\Daikit.Adaptadores.Anthropic.Interfaces.pas',
  Daikit.Adaptadores.Anthropic.Configuracao in '..\..\src\adaptadores\anthropic\Daikit.Adaptadores.Anthropic.Configuracao.pas',
  Daikit.Adaptadores.Anthropic.Mapeador in '..\..\src\adaptadores\anthropic\Daikit.Adaptadores.Anthropic.Mapeador.pas',
  Daikit.Adaptadores.Anthropic.Adaptador in '..\..\src\adaptadores\anthropic\Daikit.Adaptadores.Anthropic.Adaptador.pas';

const
  CVariavelExecutar = 'DAIKIT_EXECUTAR_ANTHROPIC_REAL';
  CVariavelModelo = 'ANTHROPIC_MODEL';
  CValorExecutar = '1';
  CCodigoErro = 1;

function CriarRequisicao(const AModelo: string): IRequisicaoChatIA;
var
  LMensagens: TArray<IMensagemIA>;
begin
  SetLength(LMensagens, 1);
  LMensagens[0] := TMensagemIA.CriarTexto(TPapelMensagemIA.Usuario,
    'Quem e voce?');
  Result := TRequisicaoChatIA.Create(AModelo, LMensagens);
end;

var
  LModelo: string;
  LAdaptador: IAdaptadorIA;
  LResposta: IRespostaChatIA;
begin
  ReportMemoryLeaksOnShutdown := True;
  if GetEnvironmentVariable(CVariavelExecutar) <> CValorExecutar then
  begin
    Writeln('IGNORADO: defina ', CVariavelExecutar,
      '=1 para autorizar uma chamada real com custo.');
    Exit;
  end;
  if Trim(GetEnvironmentVariable(CVariavelAmbienteChaveAnthropic)) = '' then
  begin
    Writeln('IGNORADO: a variavel ', CVariavelAmbienteChaveAnthropic,
      ' nao foi definida.');
    Exit;
  end;
  LModelo := Trim(GetEnvironmentVariable(CVariavelModelo));
  if LModelo = '' then
    LModelo := CModeloAnthropicPadrao;
  try
    LAdaptador := TAdaptadorAnthropic.Create(TTransporteHTTPClient.Create,
      TFonteChaveAnthropicAmbiente.Create, TConfiguracaoAnthropic.Create,
      TMapeadorAnthropic.Create);
    LResposta := LAdaptador.Concluir(CriarRequisicao(LModelo));
    Writeln('SUCESSO: id=', LResposta.Id, '; resposta=',
      LResposta.Mensagem.Texto);
  except
    on E: Exception do
    begin
      Writeln('FALHA: ', E.ClassName, ': ', E.Message);
      ExitCode := CCodigoErro;
    end;
  end;
end.
