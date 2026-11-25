# Decisões de modelagem

Este documento explica as escolhas feitas em cada camada e lista as limitações conhecidas.

## Camada 1: tipos

### Record em vez de tupla

`Partida` e `Linha` são registros (`record`) com campos nomeados. Uma tupla `(Int, String, Int, Int, String)` não diz o que cada posição significa, e trocar dois campos do mesmo tipo (os gols do mandante e os do visitante, por exemplo) não gera nenhum erro de compilação. Com registros, o código se lê como o domínio (`golsMandante p`), os campos são acessados por nome e a atualização de um único campo é simples (`l { vitorias = vitorias l + 1 }`).

### `Resultado` como tipo soma

`Resultado` é `Vitoria | Empate | Derrota`. Um tipo soma torna impossível representar um resultado inválido (um `Int` ou uma `String` aceitaria valores sem sentido) e faz o compilador avisar, com `-Wincomplete-patterns`, sempre que uma função esquecer um dos casos. A pontuação fica concentrada em uma única função, `pontos`.

### `Linha` guarda contadores brutos

A `Linha` guarda somente o que é contado partida a partida: jogos, vitórias, empates, derrotas, gols pró e gols contra. Pontos e saldo de gols são calculados por funções (`pontosLinha`, `saldo`). Assim não existe estado inconsistente: seria possível, em um modelo com um campo `pontos`, ter uma linha com 3 vitórias e 0 pontos. Se a regra de pontuação mudar, só `pontos` muda.

### `resultadoPara` devolve `Maybe`

Um time que não jogou a partida não tem resultado, e isso é representado por `Nothing`, e não por um valor falso como "derrota". Quem chama é obrigado a tratar o caso.

### `times`

Usa `sort . nub . concatMap`: junta mandantes e visitantes, remove repetições e ordena. O custo de `nub` é quadrático, mas a lista de times é pequena. A ordem alfabética dá previsibilidade (a ordem em que os times aparecem no texto não importa).

## Camada 2: classificação

### Sem recursão explícita

Todas as funções usam funções de ordem superior (`map`, `filter`, `foldl'`, `sortBy`) e composição. A tabela é `map (linhaDoTime ps) (times ps)` ordenada; cada linha vem de uma dobra sobre as partidas do time.

### `foldl'` e não `foldr` em `linhaDoTime`

A linha é um acumulador que se atualiza partida a partida, da primeira para a última, e o resultado final é um valor único. Esse é o formato da dobra à esquerda. A versão estrita (`foldl'`) evita acumular uma cadeia de adiamentos de avaliação. Já `separar` usa `foldr` porque precisa construir uma lista decidindo caractere a caractere, olhando o que já foi construído à direita.

### Critérios de desempate

Seguem o Campeonato Brasileiro, em ordem:

1. pontos (decrescente);
2. número de vitórias (decrescente);
3. saldo de gols (decrescente);
4. gols pró (decrescente);
5. nome do time (crescente).

Os critérios são combinados com `comparing` e `<>`, o monoide de `Ordering`: o segundo critério só é consultado se o primeiro empatar, e assim por diante. `Down` inverte a ordem para os critérios decrescentes. O quinto critério, o nome, não faz parte do regulamento, mas garante uma ordem total: dois times nunca ficam "empatados" e o resultado de `classificacao` é sempre o mesmo para a mesma entrada.

No campeonato de teste, os dois critérios mais interessantes aparecem na classificação final:

- Athletico e Londrina, ambos com 9 pontos: decide o número de vitórias (3 contra 2). O saldo de gols favoreceria a Londrina (+3 contra +1), o que mostra que não foi o saldo que decidiu.
- Paraná e Coritiba, ambos com 8 pontos e 2 vitórias: decide o saldo de gols (+2 contra +1).

### `ateRodada`

É um `filter` por rodada menor ou igual ao número pedido. A classificação "após a rodada n" é simplesmente `classificacao (ateRodada n ps)`, sem nenhuma função especial.

### `aproveitamento`

É o percentual de pontos conquistados sobre o total possível (`3 * jogos`), de 0 a 100. Para um time sem jogos o denominador seria zero; o valor definido é 0, o que evita divisão por zero (que, em `Double`, resultaria em `NaN`) e é coerente: nenhum ponto foi conquistado.

### `maiorGoleada` e empates na diferença

Devolve `Maybe Partida`: `Nothing` para lista vazia. Foi implementada com `foldl'` e um acumulador `Maybe`, sem `maximum` (que é parcial: falha em lista vazia). O passo só troca a partida escolhida quando a nova tem diferença **estritamente maior**; portanto, em caso de empate na diferença, vale a **primeira** partida da lista (a mais antiga, se a lista estiver em ordem de rodada). Esse critério está documentado no código e coberto por teste.

### `mediaGols`

Devolve `Nothing` para lista vazia, pois a média de zero partidas não existe. A média é o total de gols dividido pelo número de partidas, com `fromIntegral` para converter os inteiros em `Double`.

## Camada 3: leitura

### Dados como `String`

O campeonato de teste fica no módulo `Dados` como texto (`unlines [...]`) em vez de ser lido de arquivo ou do teclado. Isso permite executar o programa em ambientes sem acesso a arquivos, como um compilador online (playground), e mantém `main` simples: o texto é um valor como outro qualquer, e toda a leitura é feita por funções puras.

### `Either` e `traverse`: parar no primeiro erro

`lerPartida` devolve `Either Erro Partida` e usa a notação `do` na mônada `Either`: ao primeiro `Left`, o restante é abandonado. `lerCampeonato` aplica `traverse (uncurry lerPartida)` sobre as linhas relevantes, o que também para no primeiro erro e devolve `Left` com ele. Esse é o comportamento ideal quando basta saber se o texto é utilizável e qual é o primeiro problema.

`lerNumero` usa `readMaybe` (que devolve `Maybe`) e `maybe (Left ...) Right` para converter a falha em um erro descritivo. `readMaybe` foi escolhida no lugar de `read` porque `read` é parcial: aborta o programa com uma exceção em entrada inválida. Antes de ler, o formato é validado (sinal `-` opcional e só dígitos decimais, via `isDigit`), o que recusa `0x10`, `(3)` e `+2`; o texto é lido como `Integer` e só é aceito se couber em `Int` (entre `minBound` e `maxBound`), evitando o estouro silencioso de valores como `99999999999999999999`.

### `todosOsErros`: acumular todos

Para quem quer corrigir o texto de uma vez, `todosOsErros` não para no primeiro erro. Aplica `lerPartida` a todas as linhas e junta, com `lefts`, todos os erros de linha; depois procura os times repetidos em uma rodada **somente nas partidas válidas** (`rights`), porque uma linha inválida não tem partida confiável para entrar na verificação. A lista termina com todos os times repetidos, e não apenas o primeiro.

### Números de linha reais

A numeração é feita **antes** do filtro de linhas ignoradas: `zip [1 ..] (lines texto)` e só depois `filter`. Assim, comentários e linhas em branco continuam contando, e o número que aparece na mensagem de erro é o mesmo que o usuário vê no editor. Se a numeração fosse feita depois do filtro, todos os números ficariam deslocados.

### Verificação de rodadas separada da leitura de linhas

A regra "nenhum time joga duas vezes na mesma rodada" envolve várias linhas, por isso não pode ser verificada em `lerPartida`. É uma função própria, `verificarRodadas`, que monta os pares (rodada, time) de cada partida, ordena, agrupa e escolhe o primeiro grupo com mais de um elemento (`listToMaybe`).

### Tipo `Erro`

`NumeroInvalido` guarda o texto que não pôde ser lido, para que a mensagem mostre exatamente o que estava escrito. Além dos erros mínimos, foram incluídos `RodadaInvalida` (rodada menor que 1) e `TimeVazio` (nome de time vazio), ambos testados. A ordem das validações em `lerPartida` é: quantidade de campos, números, rodada, placar, nomes, mandante diferente do visitante.

### `separar` com `foldr`

`separar` percorre o texto de trás para frente, mantendo uma lista de campos. Para cada caractere: se for o separador, abre um campo novo vazio; caso contrário, acrescenta o caractere ao campo da frente. A última equação (`passo c [] = [[c]]`) nunca é usada na prática, pois o acumulador inicial é `[""]`, mas torna a função total (sem aviso de padrão incompleto). Campos vazios são preservados (`"a;;b"` dá três campos), o que permite detectar uma linha com campo faltando.

### Formatação sem `printf`

O aproveitamento é mostrado com casas decimais fixas sem `Text.Printf`: o número é multiplicado por 10 elevado ao número de casas, arredondado, e separado em parte inteira e decimal com `divMod`. A parte decimal é completada com zeros à esquerda (`1.05` e não `1.5`). O alinhamento da tabela usa `replicate` para preencher com espaços.

### Codificação da saída

`main` e os testes executam `hSetEncoding stdout utf8`. Sem isso, o GHC no Windows pode lançar uma exceção ao imprimir caracteres como `á` e `ô` em terminais que não usam UTF-8.

## Limitações conhecidas

- **Nomes de time são comparados literalmente.** Maiúsculas, minúsculas, acentos e espaços internos contam: `Parana`, `Paraná` e `paraná` seriam três times diferentes. Apenas os espaços das bordas do campo são removidos.
- **Partida duplicada entre rodadas não é detectada.** O mesmo confronto (mesmos times e placar) em duas rodadas diferentes é aceito, pois a única regra verificada é a de um jogo por time em cada rodada. Também não se verifica que o confronto não se repete no turno.
- **O campeonato não precisa ser completo.** Não se valida que todos os times se enfrentam, nem que todas as rodadas têm o mesmo número de jogos.
- **Confronto direto não é critério de desempate.** O regulamento do Campeonato Brasileiro usa o confronto direto em alguns casos; aqui, o desempate vai direto de gols pró para o nome do time.
- **O caractere `;` não pode aparecer em nome de time.** `separar` não trata aspas nem escape.
- **Nomes de times muito longos.** A largura da coluna do time é calculada pelo maior nome, mas a tabela não é cortada se a linha ficar maior que o terminal.
- **Partidas sem data nem ordem interna.** Dentro de uma rodada, a ordem das partidas no texto não tem significado.
- **Acentos no console do Windows.** Se o terminal não usar UTF-8, os acentos podem aparecer errados mesmo com `hSetEncoding`; nesse caso, execute `chcp 65001` antes do programa.
- **`nub` tem custo quadrático.** Adequado para a quantidade de times de um campeonato, mas não para listas muito grandes.
