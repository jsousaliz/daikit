program DaikitExperimentoOpenAIReal;

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
  Daikit.Adaptadores.Interfaces in '..\..\src\adaptadores\Daikit.Adaptadores.Interfaces.pas',
  Daikit.Adaptadores.ChaveAPI in '..\..\src\adaptadores\Daikit.Adaptadores.ChaveAPI.pas',
  Daikit.Adaptadores.OpenAI.Constantes in '..\..\src\adaptadores\openai\Daikit.Adaptadores.OpenAI.Constantes.pas',
  Daikit.Adaptadores.OpenAI.Excecoes in '..\..\src\adaptadores\openai\Daikit.Adaptadores.OpenAI.Excecoes.pas',
  Daikit.Adaptadores.OpenAI.Contratos in '..\..\src\adaptadores\openai\Daikit.Adaptadores.OpenAI.Contratos.pas',
  Daikit.Adaptadores.OpenAI.Interfaces in '..\..\src\adaptadores\openai\Daikit.Adaptadores.OpenAI.Interfaces.pas',
  Daikit.Adaptadores.OpenAI.Configuracao in '..\..\src\adaptadores\openai\Daikit.Adaptadores.OpenAI.Configuracao.pas',
  Daikit.Adaptadores.OpenAI.Mapeador in '..\..\src\adaptadores\openai\Daikit.Adaptadores.OpenAI.Mapeador.pas',
  Daikit.Adaptadores.OpenAI.Adaptador in '..\..\src\adaptadores\openai\Daikit.Adaptadores.OpenAI.Adaptador.pas';

const
  CVariavelExecutar = 'DAIKIT_EXECUTAR_OPENAI_REAL';
  CVariavelModelo = 'OPENAI_MODEL';
  CValorExecutar = '1';
  CCodigoErro = 1;

function CriarRequisicao(const AModelo: string): IRequisicaoChatIA;
var
  LMensagens: TArray<IMensagemIA>;
begin
  SetLength(LMensagens, 1);
  LMensagens[0] := TMensagemIA.CriarTexto(TPapelMensagemIA.Usuario,
    'quem é você?');
  Result := TRequisicaoChatIA.Create(AModelo, LMensagens);
end;

var
  LModelo: string;
  LTransporteHTTP: ITransporteHTTP;
  LFonteChaveAPI: IFonteChaveAPI;
  LConfiguracaoOpenAI: IConfiguracaoOpenAI;
  LMapeadorOpenAI: IMapeadorOpenAI;
  LAdaptadorOpenAI: IAdaptadorIA;
  LRespostaChat: IRespostaChatIA;
begin
  ReportMemoryLeaksOnShutdown := True;
  if GetEnvironmentVariable(CVariavelExecutar) <> CValorExecutar then
  begin
    Writeln('IGNORADO: defina ', CVariavelExecutar,
      '=1 para autorizar uma chamada real com custo.');
    Exit;
  end;
  if Trim(GetEnvironmentVariable(CVariavelAmbienteChaveOpenAI)) = '' then
  begin
    Writeln('IGNORADO: a variavel ', CVariavelAmbienteChaveOpenAI,
      ' nao foi definida.');
    Exit;
  end;
  LModelo := Trim(GetEnvironmentVariable(CVariavelModelo));
  if LModelo = '' then
    LModelo := CModeloOpenAIRecomendado;
  try
    LTransporteHTTP := TTransporteHTTPClient.Create;
    LFonteChaveAPI := TFonteChaveAPIAmbiente.Create(
      CVariavelAmbienteChaveOpenAI);
    LConfiguracaoOpenAI := TConfiguracaoOpenAI.Create;
    LMapeadorOpenAI := TMapeadorOpenAI.Create;
    LAdaptadorOpenAI := TAdaptadorOpenAI.Create(LTransporteHTTP,
      LFonteChaveAPI, LConfiguracaoOpenAI, LMapeadorOpenAI);
    LRespostaChat := LAdaptadorOpenAI.Concluir(CriarRequisicao(LModelo));
    Writeln('SUCESSO: id=', LRespostaChat.Id, '; resposta=',
      LRespostaChat.Mensagem.Texto);
  except
    on E: Exception do
    begin
      Writeln('FALHA: ', E.ClassName, ': ', E.Message);
      ExitCode := CCodigoErro;
    end;
  end;
end.
