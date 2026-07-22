unit Daikit.Infraestrutura.HTTP.Constantes;

interface

const
  CTimeoutConexaoPadraoMS = 30000;
  CTimeoutRespostaPadraoMS = 60000;
  CLimiteRespostaPadraoBytes = 16 * 1024 * 1024;
  CLimiteCorpoRequisicaoBytes = 16 * 1024 * 1024;
  CLimiteURLCaracteres = 8192;
  CIntervaloVerificacaoCancelamentoMS = 25;
  CStatusHTTPMinimo = 100;
  CStatusHTTPMaximo = 599;
  CStatusHTTPSucessoMinimo = 200;
  CStatusHTTPSucessoMaximo = 299;
  CStatusHTTPNaoInformado = 0;
  CDuracaoLogInicialMS = 0;
  CResultadoSucessoCriacaoIdLog = 0;
  CDescricaoLogRequisicaoHTTP = 'Requisicao HTTP iniciada.';
  CDescricaoLogRespostaHTTP = 'Resposta HTTP recebida com status %d.';
  CDescricaoLogFalhaHTTP = 'Falha no transporte HTTP (%s).';
  CDescricaoLogCancelamentoHTTP = 'Operacao HTTP cancelada.';
  CValorSensivelRemovido = '[REMOVIDO]';
  CSeparadorEsquemaURL = '://';
  CIndiceInicialTexto = 0;
  CCaractereRetornoCarro = #13;
  CCaractereNovaLinha = #10;

implementation

end.
