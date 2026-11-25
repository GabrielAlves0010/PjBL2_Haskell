# Tabela de classificação de campeonato em Haskell

Trabalho em três camadas, escrito em Haskell puro (somente a biblioteca `base`):

| Camada | Arquivo | Responsabilidade |
|---|---|---|
| 1 | `src/Tipos.hs` | Tipos do domínio (`Time`, `Resultado`, `Partida`, `Linha`) e funções básicas |
| 2 | `src/Classificacao.hs` | Pontuação, desempate, classificação e estatísticas (sem recursão explícita) |
| 3 | `src/Leitura.hs` | Leitura e validação do texto, mensagens de erro e tabela formatada |

Outros arquivos:

- `src/Dados.hs`: o campeonato de teste e textos com erros, todos escritos como `String`.
- `src/Main.hs`: demonstração das três camadas. A função `main` é a única com entrada e saída.
- `tests/Testes.hs`: testes com resultado esperado, conferidos à mão.
- `docs/decisoes.md`: decisões de modelagem com justificativa e limitações conhecidas.

## Ambiente

GHC local, versão 9.6, instalado pelo GHCup. Nenhuma biblioteca além da `base` é usada.

Verifique a instalação:

```
ghc --version
```

## Como compilar e executar

Os comandos abaixo devem ser executados na pasta `projeto`.

Compilar e executar a demonstração:

```
ghc -Wall -isrc -outputdir build -o tabela src/Main.hs
./tabela
```

No Windows, o executável é `tabela.exe` (no PowerShell: `.\tabela.exe`).

Executar sem gerar executável, com o interpretador:

```
runghc -isrc src/Main.hs
```

Compilar e executar os testes:

```
ghc -Wall -isrc -itests -outputdir build -o testes tests/Testes.hs
./testes
```

No Windows: `.\testes.exe`.

Cada teste imprime uma linha `OK` ou `FALHOU`. Os testes também podem ser executados direto pelo interpretador:

```
runghc -isrc -itests tests/Testes.hs
```

Todos os módulos devem compilar sem nenhum aviso com `-Wall`.

## Acentos no Windows

O campeonato de teste tem times com acento (Paraná, Operário). Tanto `main` quanto os testes configuram a saída padrão para UTF-8 com `hSetEncoding stdout utf8`, o que evita o erro `invalid character` do GHC no Windows.

Se, mesmo assim, o terminal mostrar os acentos errados, mude a página de código do terminal antes de executar:

```
chcp 65001
```

## Formato do texto de entrada

Cada linha representa uma partida:

```
rodada;mandante;gols do mandante;gols do visitante;visitante
```

Exemplo: `1;Coritiba;0;2;Paraná`.

- Espaços ao redor de cada campo são ignorados.
- Linhas em branco e linhas iniciadas por `#` são ignoradas, mas contam na numeração. Os números de linha das mensagens de erro são os números reais do texto.

## Critérios de classificação

1. Pontos (vitória 3, empate 1, derrota 0)
2. Número de vitórias
3. Saldo de gols
4. Gols pró
5. Nome do time, em ordem alfabética (garante uma ordem total e previsível)

Detalhes e limitações em `docs/decisoes.md`.
