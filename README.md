<h1><img src="src/design/branding/Daikit.png" alt="Ícone do Daikit" width="80" align="absmiddle"> Daikit</h1>

Biblioteca didática de componentes Delphi para conversar com diferentes provedores de IA por uma API única. A evolução planejada inclui componentes para clientes e servidores MCP.

O projeto usa somente recursos nativos do Delphi, sem componentes de terceiros, Indy ou DLLs adicionais.

## Funcionalidades atuais

- componentes não visuais para OpenAI, Anthropic e Google Gemini;
- troca de provedor sem alterar o código de conversa;
- histórico compartilhável ou mensagens isoladas;
- contratos JSON tipados com serialização automática por `REST.Json`;
- transporte HTTPS nativo baseado em `THTTPClient`;
- cancelamento cooperativo, timeouts e limites de resposta;
- log de requisição, resposta, erro e cancelamento pelo evento `AoRegistrarLog`;
- credenciais em memória ou variáveis de ambiente, sem persistência no DFM;
- interfaces e injeção de dependência;
- testes unitários DUnitX sem acesso à rede;
- suporte a aplicações Win32 e Win64.

## Componentes

- `TChatIA`: fachada usada pela aplicação para enviar mensagens.
- `TConversaIA`: mantém e compartilha o histórico da conversa.
- `TProvedorOpenAI`: configura a integração com a OpenAI.
- `TProvedorAnthropic`: configura a integração com a Anthropic.
- `TProvedorGemini`: configura a integração com o Google Gemini.

Os componentes são instalados na página **Daikit** da Tool Palette.

## Requisitos

- Delphi 12 Athens;
- Windows;
- plataforma Win32 ou Win64;
- DUnitX fornecido com o Delphi para executar os testes.

## Instalação

O instalador autocontido é gerado por:

```powershell
.\tools\instalador\Construir.ps1
```

Ele instala os pacotes, DCPs e DCUs necessários para compilar aplicações sem adicionar os fontes ao `Search Path`.

Consulte [Componentes e instalação](documentacao/COMPONENTES_E_INSTALACAO.md) para o procedimento completo de construção, instalação e desinstalação.

## Uso básico

Adicione ao formulário ou data module:

- um `TChatIA`;
- um `TConversaIA`;
- os provedores que deseja utilizar.

Configure `ChatIA.Conversa` e selecione o provedor:

```pascal
ChatIA.Provedor := ProvedorOpenAI;
ChatIA.Enviar('Quem é você?');

ChatIA.Provedor := ProvedorAnthropic;
ChatIA.Enviar('Continue a conversa.');
```

`Enviar` inicia uma operação assíncrona e retorna imediatamente, sem bloquear a VCL. Use `AoReceberResposta`, `AoOcorrerErro` e `AoConcluir` para acompanhar o resultado. `Cancelar` solicita o cancelamento da operação atual.

Para carregar os modelos disponíveis do provedor selecionado, associe o evento `AoReceberModelos` e chame:

```pascal
ChatIA.CarregarModelos;
```

A consulta também é assíncrona. Cada provedor possui `EndpointModelos` configurável e mantém `ModeloPadrao` como alternativa quando `ChatIA.Modelo` estiver vazio.

## Credenciais

Por padrão, os provedores procuram estas variáveis de ambiente:

```text
OPENAI_API_KEY
ANTHROPIC_API_KEY
GEMINI_API_KEY
```

Também é possível informar `ChaveAPI` em tempo de execução. Seu valor é mascarado e nunca é gravado no DFM.

Não coloque chaves em fontes, DFMs, argumentos de linha de comando ou arquivos versionados. Se uma chave for exposta, revogue-a no provedor correspondente.

## Log

`TChatIA.AoRegistrarLog` recebe todos os registros produzidos pelo componente e pelo transporte. O objeto `IEventoLogIA` informa data e hora UTC, tipo, provedor, mensagem e status HTTP.

Os tipos são `Contexto`, `Requisicao`, `Resposta`, `RespostaErro` e `Erro`.
JSON enviado usa `Requisicao`; JSON recebido com sucesso usa `Resposta`; JSON
recebido com status HTTP sem sucesso usa `RespostaErro`. `Erro` registra a
mensagem de uma exceção nos pontos em que o log já acompanha o transporte.

Para declarar o handler manualmente, inclua `Daikit.Aplicacao.Log` na cláusula `uses`.

```pascal
procedure TFormPrincipal.ChatIAAoRegistrarLog(Sender: TObject;
  const AEvento: IEventoLogIA);
begin
  MemoLog.Lines.Add(AEvento.Mensagem);
end;
```

O Daikit não filtra nem persiste os eventos. A aplicação decide o que mostrar ou armazenar. O JSON preserva o conteúdo da conversa, mas credenciais e dados classificados como sigilosos são sanitizados automaticamente.

`Requisicao`, `Resposta` e `RespostaErro` são exclusivos para JSON. Os registros
de ciclo de vida, cancelamento e limpeza do histórico usam `Contexto`.

Quando a API devolve um campo `message` em um erro, seu conteúdo sanitizado é
incluído na exceção do adaptador e disponibilizado em `MensagemAPI`.

## Exemplo VCL

Abra [Daikit.ExemploVCL.dproj](examples/VCL.Conversa/Daikit.ExemploVCL.dproj). O exemplo demonstra:

- troca entre os três provedores;
- seleção do modelo;
- histórico ou mensagem isolada;
- uso de tokens retornado pelo provedor;
- consumo e exibição do evento de log em um `TDBGrid`.

## Testes

Abra [Daikit.Testes.dproj](tests/testes/Daikit.Testes.dproj), selecione Win32 ou Win64 e compile.

Os executáveis são gerados em:

```text
tests/bin/Win32/testes/Daikit.Testes.exe
tests/bin/Win64/testes/Daikit.Testes.exe
```

Os testes automatizados usam transportes falsos e não consomem APIs pagas.

## Experimentos reais

Os projetos em `tests/experiments` são separados da suíte automática. Uma chamada real só é executada quando a variável de autorização e a chave correspondente estão definidas:

```text
DAIKIT_EXECUTAR_OPENAI_REAL=1
DAIKIT_EXECUTAR_ANTHROPIC_REAL=1
DAIKIT_EXECUTAR_GEMINI_REAL=1
```

Esses experimentos podem consumir créditos. As variáveis `OPENAI_MODEL`, `ANTHROPIC_MODEL` e `GEMINI_MODEL` permitem substituir o modelo padrão sem alterar o fonte.

## Arquitetura

O domínio trabalha apenas com contratos canônicos. Cada provedor implementa `IAdaptadorIA` e converte seus próprios objetos JSON para esses contratos. Assim, um novo provedor pode ser adicionado sem alterar o serviço de conversa nem os componentes existentes.

O log HTTP usa um Decorator sobre `ITransporteHTTP`, mantendo a observabilidade separada dos adaptadores e do transporte nativo.

## Estado do projeto

O chat textual com OpenAI, Anthropic e Gemini está implementado. Streaming, ferramentas, MCP, RAG, embeddings, áudio e geração de imagens permanecem como evoluções futuras.
