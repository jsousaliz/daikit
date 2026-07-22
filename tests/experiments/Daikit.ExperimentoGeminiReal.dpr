program DaikitExperimentoGeminiReal;

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
  Daikit.Adaptadores.Gemini.Constantes in '..\..\src\adaptadores\gemini\Daikit.Adaptadores.Gemini.Constantes.pas',
  Daikit.Adaptadores.Gemini.Excecoes in '..\..\src\adaptadores\gemini\Daikit.Adaptadores.Gemini.Excecoes.pas',
  Daikit.Adaptadores.Gemini.Contratos in '..\..\src\adaptadores\gemini\Daikit.Adaptadores.Gemini.Contratos.pas',
  Daikit.Adaptadores.Gemini.Interfaces in '..\..\src\adaptadores\gemini\Daikit.Adaptadores.Gemini.Interfaces.pas',
  Daikit.Adaptadores.Gemini.Configuracao in '..\..\src\adaptadores\gemini\Daikit.Adaptadores.Gemini.Configuracao.pas',
  Daikit.Adaptadores.Gemini.Armazenamento in '..\..\src\adaptadores\gemini\Daikit.Adaptadores.Gemini.Armazenamento.pas',
  Daikit.Adaptadores.Gemini.Mapeador in '..\..\src\adaptadores\gemini\Daikit.Adaptadores.Gemini.Mapeador.pas',
  Daikit.Adaptadores.Gemini.Adaptador in '..\..\src\adaptadores\gemini\Daikit.Adaptadores.Gemini.Adaptador.pas';

const
  CVariavelExecutar = 'DAIKIT_EXECUTAR_GEMINI_REAL';
  CVariavelModelo = 'GEMINI_MODEL';
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

function CriarSegundaRequisicao(const AModelo: string;
  const APrimeiraResposta: IRespostaChatIA): IRequisicaoChatIA;
var
  LMensagens: TArray<IMensagemIA>;
begin
  SetLength(LMensagens, 3);
  LMensagens[0] := TMensagemIA.CriarTexto(TPapelMensagemIA.Usuario,
    'Quem e voce?');
  LMensagens[1] := APrimeiraResposta.Mensagem;
  LMensagens[2] := TMensagemIA.CriarTexto(TPapelMensagemIA.Usuario,
    'Qual foi a pergunta anterior que eu fiz?');
  Result := TRequisicaoChatIA.Create(AModelo, LMensagens);
end;

var
  LModelo: string;
  LTransporteHTTP: ITransporteHTTP;
  LFonteChaveAPI: IFonteChaveAPI;
  LConfiguracaoGemini: IConfiguracaoGemini;
  LMapeadorGemini: IMapeadorGemini;
  LAdaptadorGemini: IAdaptadorIA;
  LRespostaChat: IRespostaChatIA;
  LPrimeiraRespostaChat: IRespostaChatIA;
  LArmazenamentoContextoGemini: IArmazenamentoContextoGemini;
begin
  ReportMemoryLeaksOnShutdown := True;
  if GetEnvironmentVariable(CVariavelExecutar) <> CValorExecutar then
  begin
    Writeln('IGNORADO: defina ', CVariavelExecutar,
      '=1 para autorizar uma chamada real com custo.');
    Exit;
  end;
  if Trim(GetEnvironmentVariable(CVariavelAmbienteChaveGemini)) = '' then
  begin
    Writeln('IGNORADO: a variavel ', CVariavelAmbienteChaveGemini,
      ' nao foi definida.');
    Exit;
  end;
  LModelo := Trim(GetEnvironmentVariable(CVariavelModelo));
  if LModelo = '' then
    LModelo := CModeloGeminiPadrao;
  try
    LArmazenamentoContextoGemini := TArmazenamentoContextoGemini.Create;
    LTransporteHTTP := TTransporteHTTPClient.Create;
    LFonteChaveAPI := TFonteChaveAPIAmbiente.Create(
      CVariavelAmbienteChaveGemini);
    LConfiguracaoGemini := TConfiguracaoGemini.Create;
    LMapeadorGemini := TMapeadorGemini.Create(
      LArmazenamentoContextoGemini);
    LAdaptadorGemini := TAdaptadorGemini.Create(LTransporteHTTP,
      LFonteChaveAPI, LConfiguracaoGemini, LMapeadorGemini);
    LPrimeiraRespostaChat := LAdaptadorGemini.Concluir(CriarRequisicao(LModelo));
    Writeln('SUCESSO TURNO 1: id=', LPrimeiraRespostaChat.Id, '; resposta=',
      LPrimeiraRespostaChat.Mensagem.Texto);
    LRespostaChat := LAdaptadorGemini.Concluir(
      CriarSegundaRequisicao(LModelo, LPrimeiraRespostaChat));
    Writeln('SUCESSO TURNO 2: id=', LRespostaChat.Id, '; resposta=',
      LRespostaChat.Mensagem.Texto);
  except
    on E: Exception do
    begin
      Writeln('FALHA: ', E.ClassName, ': ', E.Message);
      ExitCode := CCodigoErro;
    end;
  end;
end.
