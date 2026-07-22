# Componentes Daikit e instalação no Delphi 12

## Componentes disponíveis

- `TChatIA`: fachada de envio, seleção do provedor, cancelamento cooperativo, eventos e histórico.
- `TConversaIA`: histórico compartilhável, com eventos `AoAdicionar`, `AoLimpar` e `AoAlterar`.
- `TProvedorOpenAI`: composição da integração OpenAI.
- `TProvedorAnthropic`: composição da integração Anthropic.
- `TProvedorGemini`: composição da integração Gemini e do contexto local opaco.

Os cinco componentes aparecem na página **Daikit**. Os provedores usam seus ícones de marca, sem letras ou texto no glyph; `TChatIA` e `TConversaIA` usam pictogramas próprios. O registro não acessa rede nem lê credenciais.

Os glyphs são BMPs de 24 × 24 pixels e usam `#FF00FF` uniforme como máscara de transparência exigida pelo carregamento de recursos do Delphi.

## Credenciais

Por padrão, cada provedor lê sua variável oficial:

- `OPENAI_API_KEY`;
- `ANTHROPIC_API_KEY`;
- `GEMINI_API_KEY`.

`ChaveAPI` pode ser definida apenas em tempo de execução. Seu getter retorna uma máscara e a propriedade usa `stored False`, portanto o valor não é salvo no DFM. Prefira variáveis de ambiente.

## Construir o instalador

Feche o Delphi e execute, na raiz do repositório:

```powershell
.\tools\instalador\Construir.ps1
```

O pipeline usa somente ferramentas do Delphi e do Windows:

1. compila `DaikitRuntimeD12` para Win32 e Win64;
2. compila `DaikitDesignD12` para Win32;
3. reúne BPL, DCP e DCUs de runtime por plataforma;
4. cria um ZIP e o incorpora ao EXE como recurso `RCDATA`;
5. compila o instalador VCL em modo Release.

O resultado fica em:

```text
tools\instalador\bin\Win32\Daikit.Instalador.exe
```

Esse EXE é autocontido. Os fontes e a pasta `packages` não precisam acompanhá-lo na distribuição.

## Instalar na IDE

1. Feche todas as instâncias do Delphi.
2. Execute `Daikit.Instalador.exe`.
3. Confirme que o instalador localizou o Delphi 12.
4. Clique em **Instalar**.
5. Abra o Delphi e confirme a página **Daikit**.

O instalador realiza automaticamente:

- BPL de design e runtime Win32 em `$(BDSCOMMONDIR)\Bpl`;
- BPL de runtime Win64 em `$(BDSCOMMONDIR)\Bpl\Win64`;
- DCP e DCUs em `$(BDSCOMMONDIR)\Dcp\Daikit\Win32` e `Win64`;
- inclusão idempotente dos dois diretórios no `Search Path` correspondente;
- registro da BPL de design em `Known Packages` para o usuário atual.

O código preserva entradas preexistentes do `Search Path`, não duplica o caminho Daikit e remove somente a entrada Daikit durante a desinstalação.

## Uso em projetos

Não é necessário adicionar os fontes ao projeto nem ao `Search Path`. Os DCUs instalados são específicos do Delphi 12 e da plataforma escolhida.

Quando **Link with runtime packages** estiver desabilitado, o código necessário é incorporado ao executável da aplicação. Quando estiver habilitado, as BPLs de runtime usadas pela aplicação também devem ser distribuídas com ela conforme as regras usuais do Delphi.

## Desinstalar

1. Feche o Delphi.
2. Execute o mesmo `Daikit.Instalador.exe`.
3. Clique em **Desinstalar** e confirme.

O processo remove o registro do pacote, as BPLs Daikit, os DCUs/DCP e somente as entradas Daikit do `Search Path`.

## Uso básico

Em tempo de design, coloque `TChatIA`, um `TConversaIA` e os provedores desejados no formulário ou data module. Aponte `ChatIA.Provedor` e `ChatIA.Conversa`.

```pascal
ChatIA.Provedor := ProvedorOpenAI;
ChatIA.Enviar('Quem é você?');

ChatIA.Provedor := ProvedorAnthropic;
ChatIA.Enviar('Continue a conversa.');
```

Os eventos de `TConversaIA` são disparados após a operação ser concluída com sucesso. `AoAdicionar` recebe a mensagem incluída; `AoLimpar` ocorre somente quando havia conteúdo; e `AoAlterar` sinaliza qualquer mudança efetiva no contexto. Nos eventos específicos, `AoAlterar` é chamado em seguida.
O padrão é `ModoConversa = ManterHistorico`. Use `MensagemIsolada` para não adicionar mensagens ao histórico e `LimparHistorico` para iniciar uma conversa nova.

O método `Enviar` inicia a operação em uma thread de trabalho e retorna imediatamente. A resposta é entregue em `AoReceberResposta`, falhas da operação em `AoOcorrerErro` e o encerramento em `AoConcluir`. Esses eventos, assim como `AoRegistrarLog`, são entregues na thread principal e podem atualizar controles VCL diretamente. Use `Cancelar` para solicitar o cancelamento da operação atual. Um segundo envio é recusado enquanto `Estado` for `Executando` ou `Cancelando`.

## Modelos disponíveis

`TChatIA.CarregarModelos` consulta assincronamente o provedor selecionado. O resultado é entregue na thread principal pelo evento `AoReceberModelos` como `TArray<IModeloIA>`. Cada item possui `Id`, usado nas requisições, e `Nome`, apropriado para exibição.

```pascal
procedure TFormPrincipal.ChatIAAoReceberModelos(Sender: TObject;
  const AModelos: TArray<IModeloIA>);
var
  LModelo: IModeloIA;
begin
  ComboModelo.Clear;
  for LModelo in AModelos do
    ComboModelo.Items.Add(LModelo.Id);
end;

procedure TFormPrincipal.CarregarModelos;
begin
  ChatIA.Provedor := ProvedorOpenAI;
  ChatIA.CarregarModelos;
end;
```

Os componentes de provedor expõem `EndpointModelos`, permitindo usar gateways e proxies sem modificar os adaptadores. `ModeloPadrao` continua sendo definido pelo Daikit ou personalizado pelo desenvolvedor, pois as APIs não indicam um modelo padrão.

Na OpenAI, a API mistura modelos de diferentes finalidades; o adaptador entrega somente identificadores das famílias de conversa reconhecidas. Na Gemini, são aceitos somente modelos que anunciam suporte a `generateContent`.

## Log

`TChatIA` publica todos os registros de transporte pelo evento `AoRegistrarLog`. Não existe modo de log nem filtro interno: a aplicação que consome o evento decide quais registros mostrar ou persistir.

O objeto `IEventoLogIA` contém:

- `DataHoraUTC`;
- `Tipo`: `Requisicao`, `Resposta`, `Erro` ou `Cancelamento`;
- `Nivel`: `Informacao`, `Requisicao`, `Resposta`, `RespostaErro` ou `Erro`;
- `Provedor`;
- `Mensagem`;
- `StatusHTTP`, usando zero quando não houver resposta HTTP.

Em requisições e respostas, `Mensagem` contém o JSON sanitizado e o nível
correspondente é, respectivamente, `Requisicao` ou `Resposta`. Uma resposta
HTTP sem sucesso usa `RespostaErro`, preservando o JSON recebido e o
`StatusHTTP`. Em erros sem resposta e cancelamentos, `Mensagem` contém a
descrição correspondente.

Quando um provedor devolve o campo `message` em um erro, o adaptador inclui seu
conteúdo sanitizado em `Exception.Message` e na propriedade `MensagemAPI` da
exceção específica. Chaves conhecidas, caracteres de controle e conteúdo além
do limite de segurança são removidos antes da exposição.

Adicione `Daikit.Aplicacao.Log` à cláusula `uses` da unit que declara o handler.

```pascal
procedure TFormPrincipal.ChatIAAoRegistrarLog(Sender: TObject;
  const AEvento: IEventoLogIA);
begin
  if AEvento.Nivel = TNivelLogIA.Erro then
    MemoLog.Lines.Add('ERRO: ' + AEvento.Mensagem)
  else
    MemoLog.Lines.Add(AEvento.Mensagem);
end;
```

Credenciais, cookies, senhas, tokens, segredos, assinaturas e raciocínio opaco são removidos automaticamente. O conteúdo da conversa é preservado para permitir a inspeção da troca com o provedor, portanto pode conter dados pessoais ou confidenciais.

Os callbacks de log são enfileirados para a thread principal. O Daikit não grava logs em arquivo, DFM, Registro ou banco. Exceções lançadas pelo código do evento não são ocultadas.

## Exemplo VCL

Abra `examples\VCL.Conversa\Daikit.ExemploVCL.dproj`. Depois da instalação autocontida, o exemplo compila sem precisar apontar para `src`. Cada evento recebido é incluído em um `TClientDataSet`, cujos campos são criados em tempo de execução e exibidos por um `TDBGrid`. O painel permite limpar a visualização e mantém no máximo 300 registros de log em memória.
