unit Daikit.Componentes.Constantes;

interface

const
  CNomePaletaDaikit = 'Daikit';
  CValorChaveAPIMascarada = '********';
  CTimeoutConexaoComponentePadraoMS = 30000;
  CTimeoutRespostaComponentePadraoMS = 60000;
  CLimiteRespostaComponentePadraoBytes = 16 * 1024 * 1024;
  CMaximoTokensComponentePadrao = 1024;
  CStatusHTTPNaoInformadoLog = 0;
  CNomeProvedorLogOpenAI = 'OpenAI';
  CNomeProvedorLogAnthropic = 'Anthropic';
  CNomeProvedorLogGemini = 'Gemini';
  CLogInicioEnvioMensagem =
    'Iniciando envio de mensagem. Modelo=%s; modo=%s.';
  CLogConclusaoEnvioMensagem = 'Envio de mensagem concluido com sucesso.';
  CLogInicioConsultaModelos =
    'Iniciando consulta de modelos disponiveis.';
  CLogConclusaoConsultaModelos =
    'Consulta concluida. Modelos encontrados: %d.';
  CLogSolicitacaoCancelamento = 'Cancelamento da operacao solicitado.';
  CLogConclusaoCancelamento = 'Operacao cancelada.';
  CLogHistoricoLimpo = 'Historico da conversa limpo. Mensagens removidas: %d.';

implementation

end.
