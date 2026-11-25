-- |
-- Módulo: Main (testes)
--
-- Testes das três camadas, com resultado esperado conferido à mão. Cada
-- teste imprime uma linha "OK" ou "FALHOU". Não usa nenhuma biblioteca de
-- testes: somente a função 'testar', abaixo.
--
-- Campeonato de teste (rodada; mandante; placar; visitante):
--
-- > 1  Coritiba 0x2 Paraná      1  Athletico 2x1 Operário    1  Londrina 2x2 Cascavel
-- > 2  Coritiba 2x0 Operário    2  Paraná 1x0 Cascavel       2  Athletico 0x1 Londrina
-- > 3  Coritiba 0x0 Cascavel    3  Operário 0x2 Londrina     3  Paraná 0x1 Athletico
-- > 4  Coritiba 1x1 Londrina    4  Cascavel 0x1 Athletico    4  Operário 0x0 Paraná
-- > 5  Coritiba 1x0 Athletico   5  Londrina 2x2 Paraná       5  Cascavel 4x0 Operário
--
-- Classificação final (conferida à mão):
--
-- > Time      P  J  V  E  D  GP GC  SG
-- > Athletico 9  5  3  0  2   4  3  +1
-- > Londrina  9  5  2  3  0   8  5  +3
-- > Paraná    8  5  2  2  1   5  3  +2
-- > Coritiba  8  5  2  2  1   4  3  +1
-- > Cascavel  5  5  1  2  2   6  4  +2
-- > Operário  1  5  0  1  4   1 10  -9
--
-- Classificação após a rodada 3 (conferida à mão):
--
-- > Londrina 7, Paraná 6, Athletico 6, Coritiba 4, Cascavel 2, Operário 0
module Main (main) where

import Classificacao
import Dados
import Data.Either (isRight)
import Leitura
import System.IO (hSetEncoding, stdout, utf8)
import Tipos

-- | Compara o valor obtido com o esperado e imprime OK ou FALHOU.
testar :: (Eq a, Show a) => String -> a -> a -> IO ()
testar nome obtido esperado
  | obtido == esperado = putStrLn ("OK      " ++ nome)
  | otherwise          = putStrLn ("FALHOU  " ++ nome ++ ": " ++ show obtido)

-- ---------------------------------------------------------------------------
-- Dados dos testes
-- ---------------------------------------------------------------------------

-- | O campeonato de teste como lista de partidas (o mesmo de 'dadosCampeonato').
partidasTeste :: [Partida]
partidasTeste =
  [ Partida 1 "Coritiba" 0 2 "Paraná"
  , Partida 1 "Athletico" 2 1 "Operário"
  , Partida 1 "Londrina" 2 2 "Cascavel"
  , Partida 2 "Coritiba" 2 0 "Operário"
  , Partida 2 "Paraná" 1 0 "Cascavel"
  , Partida 2 "Athletico" 0 1 "Londrina"
  , Partida 3 "Coritiba" 0 0 "Cascavel"
  , Partida 3 "Operário" 0 2 "Londrina"
  , Partida 3 "Paraná" 0 1 "Athletico"
  , Partida 4 "Coritiba" 1 1 "Londrina"
  , Partida 4 "Cascavel" 0 1 "Athletico"
  , Partida 4 "Operário" 0 0 "Paraná"
  , Partida 5 "Coritiba" 1 0 "Athletico"
  , Partida 5 "Londrina" 2 2 "Paraná"
  , Partida 5 "Cascavel" 4 0 "Operário"
  ]

-- | Primeira partida do campeonato: Coritiba 0 x 2 Paraná.
partidaExemplo :: Partida
partidaExemplo = Partida 1 "Coritiba" 0 2 "Paraná"

-- | Classificação final esperada (Linha: time, jogos, vitórias, empates,
-- derrotas, gols pró, gols contra).
tabelaFinalEsperada :: [Linha]
tabelaFinalEsperada =
  [ Linha "Athletico" 5 3 0 2 4 3
  , Linha "Londrina" 5 2 3 0 8 5
  , Linha "Paraná" 5 2 2 1 5 3
  , Linha "Coritiba" 5 2 2 1 4 3
  , Linha "Cascavel" 5 1 2 2 6 4
  , Linha "Operário" 5 0 1 4 1 10
  ]

-- | Classificação esperada após a rodada 3.
tabelaRodada3Esperada :: [Linha]
tabelaRodada3Esperada =
  [ Linha "Londrina" 3 2 1 0 5 2
  , Linha "Paraná" 3 2 0 1 3 1
  , Linha "Athletico" 3 2 0 1 3 2
  , Linha "Coritiba" 3 1 1 1 2 2
  , Linha "Cascavel" 3 0 2 1 2 3
  , Linha "Operário" 3 0 0 3 1 6
  ]

-- | Tabela final formatada, linha a linha.
tabelaFinalTexto :: [String]
tabelaFinalTexto =
  [ "Pos Time        P   J   V   E   D  GP  GC   SG Aprov%"
  , replicate 53 '-'
  , "  1 Athletico   9   5   3   0   2   4   3   +1   60.0"
  , "  2 Londrina    9   5   2   3   0   8   5   +3   60.0"
  , "  3 Paraná      8   5   2   2   1   5   3   +2   53.3"
  , "  4 Coritiba    8   5   2   2   1   4   3   +1   53.3"
  , "  5 Cascavel    5   5   1   2   2   6   4   +2   33.3"
  , "  6 Operário    1   5   0   1   4   1  10   -9    6.7"
  ]

-- | Erros esperados para 'textoComErros', com o número real de cada linha.
errosEsperados :: [Erro]
errosEsperados =
  [ NumeroInvalido 4 "dois"
  , CamposInvalidos 6
  , PlacarNegativo 7
  , MesmoTime 9
  , TimeRepetidoNaRodada 2 "Operário"
  ]

-- ---------------------------------------------------------------------------
-- Camada 1
-- ---------------------------------------------------------------------------

testesCamada1 :: [IO ()]
testesCamada1 =
  [ testar "C1 participou: mandante" (participou "Coritiba" partidaExemplo) True
  , testar "C1 participou: visitante" (participou "Paraná" partidaExemplo) True
  , testar "C1 participou: time que não jogou" (participou "Londrina" partidaExemplo) False
  , testar "C1 resultadoPara: mandante derrotado"
      (resultadoPara "Coritiba" partidaExemplo) (Just Derrota)
  , testar "C1 resultadoPara: visitante vencedor"
      (resultadoPara "Paraná" partidaExemplo) (Just Vitoria)
  , testar "C1 resultadoPara: empate"
      (resultadoPara "Londrina" (Partida 1 "Londrina" 2 2 "Cascavel")) (Just Empate)
  , testar "C1 resultadoPara: time que não jogou"
      (resultadoPara "Londrina" partidaExemplo) Nothing
  , testar "C1 times: sem repetição e em ordem alfabética"
      (times partidasTeste)
      ["Athletico", "Cascavel", "Coritiba", "Londrina", "Operário", "Paraná"]
  , testar "C1 times: lista vazia" (times []) []
  ]

-- ---------------------------------------------------------------------------
-- Camada 2
-- ---------------------------------------------------------------------------

testesCamada2 :: [IO ()]
testesCamada2 =
  [ testar "C2 pontos: vitória" (pontos Vitoria) 3
  , testar "C2 pontos: empate" (pontos Empate) 1
  , testar "C2 pontos: derrota" (pontos Derrota) 0
  , testar "C2 saldo de gols" (saldo (Linha "X" 5 3 0 2 4 3)) 1
  , testar "C2 saldo de gols negativo" (saldo (Linha "X" 5 0 1 4 1 10)) (-9)
  , testar "C2 pontosLinha" (pontosLinha (Linha "X" 5 2 3 0 8 5)) 9
  , testar "C2 aproveitamento de time sem jogos é 0" (aproveitamento (linhaVazia "X")) 0
  , testar "C2 aproveitamento com 9 pontos em 5 jogos"
      (aproveitamento (Linha "Athletico" 5 3 0 2 4 3)) 60
  , testar "C2 aproveitamento de 100%"
      (aproveitamento (Linha "X" 2 2 0 0 3 0)) 100
  , testar "C2 linhaDoTime: Athletico"
      (linhaDoTime partidasTeste "Athletico") (Linha "Athletico" 5 3 0 2 4 3)
  , testar "C2 linhaDoTime: time que não jogou"
      (linhaDoTime partidasTeste "Maringá") (linhaVazia "Maringá")
  , testar "C2 classificacao final completa"
      (classificacao partidasTeste) tabelaFinalEsperada
  -- Athletico e Londrina têm 9 pontos. O critério 1 (pontos) empata; o
  -- critério 2 (vitórias: 3 contra 2) decide. O saldo de gols (+1 contra +3)
  -- favoreceria a Londrina, o que mostra que foi mesmo o número de vitórias.
  , testar "C2 empate em pontos decidido por VITÓRIAS (critério 2): Athletico à frente de Londrina"
      (map time (take 2 (classificacao partidasTeste))) ["Athletico", "Londrina"]
  , testar "C2 pré-condição do critério 2: os dois têm 9 pontos"
      (map pontosLinha (take 2 (classificacao partidasTeste))) [9, 9]
  , testar "C2 pré-condição do critério 2: vitórias 3 e 2"
      (map vitorias (take 2 (classificacao partidasTeste))) [3, 2]
  , testar "C2 pré-condição do critério 2: saldos +1 e +3 (o saldo não decidiu)"
      (map saldo (take 2 (classificacao partidasTeste))) [1, 3]
  -- Paraná e Coritiba têm 8 pontos e 2 vitórias. Os critérios 1 e 2 empatam;
  -- o critério 3 (saldo de gols: +2 contra +1) decide.
  , testar "C2 empate em pontos e vitórias decidido por SALDO (critério 3): Paraná à frente de Coritiba"
      (map time (take 2 (drop 2 (classificacao partidasTeste)))) ["Paraná", "Coritiba"]
  , testar "C2 pré-condição do critério 3: pontos 8 e 8"
      (map pontosLinha (take 2 (drop 2 (classificacao partidasTeste)))) [8, 8]
  , testar "C2 pré-condição do critério 3: vitórias 2 e 2"
      (map vitorias (take 2 (drop 2 (classificacao partidasTeste)))) [2, 2]
  , testar "C2 pré-condição do critério 3: saldos +2 e +1"
      (map saldo (take 2 (drop 2 (classificacao partidasTeste)))) [2, 1]
  -- Tudo igual até o saldo (0): o critério 4 (gols pró) põe C e D (2 gols)
  -- à frente de A e B (1 gol); dentro de cada par, o critério 5 (nome).
  , testar "C2 desempate por GOLS PRÓ (critério 4) e depois por NOME (critério 5)"
      (map time (classificacao
        [Partida 1 "A" 1 1 "B", Partida 2 "C" 2 2 "D"]))
      ["C", "D", "A", "B"]
  , testar "C2 desempate por NOME (critério 5) quando tudo é igual"
      (map time (classificacao [Partida 1 "B" 0 0 "A"])) ["A", "B"]
  , testar "C2 ateRodada 3 mantém 9 partidas"
      (length (ateRodada 3 partidasTeste)) 9
  , testar "C2 ateRodada 0 não mantém nenhuma" (ateRodada 0 partidasTeste) []
  , testar "C2 classificacao após a rodada 3"
      (classificacao (ateRodada 3 partidasTeste)) tabelaRodada3Esperada
  , testar "C2 líder após a rodada 3 é Londrina"
      (map time (take 1 (classificacao (ateRodada 3 partidasTeste)))) ["Londrina"]
  , testar "C2 classificação da rodada 3 é diferente da final"
      (classificacao (ateRodada 3 partidasTeste) /= classificacao partidasTeste) True
  , testar "C2 líder final é diferente do líder da rodada 3"
      (map time (take 1 (classificacao partidasTeste))
        /= map time (take 1 (classificacao (ateRodada 3 partidasTeste))))
      True
  , testar "C2 classificacao [] é vazia" (classificacao []) []
  , testar "C2 maiorGoleada [] é Nothing" (maiorGoleada []) Nothing
  , testar "C2 mediaGols [] é Nothing" (mediaGols []) Nothing
  , testar "C2 maiorGoleada do campeonato de teste"
      (maiorGoleada partidasTeste) (Just (Partida 5 "Cascavel" 4 0 "Operário"))
  , testar "C2 maiorGoleada: em empate vale a primeira da lista"
      (maiorGoleada [Partida 1 "A" 3 0 "B", Partida 2 "C" 0 3 "D"])
      (Just (Partida 1 "A" 3 0 "B"))
  , testar "C2 mediaGols do campeonato de teste (28 gols em 15 partidas)"
      (mediaGols partidasTeste) (Just (28 / 15))
  , testar "C2 diferencaGols" (diferencaGols (Partida 1 "A" 1 4 "B")) 3
  , testar "C2 totalGols" (totalGols (Partida 1 "A" 1 4 "B")) 5
  ]

-- ---------------------------------------------------------------------------
-- Camada 3
-- ---------------------------------------------------------------------------

testesCamada3 :: [IO ()]
testesCamada3 =
  [ testar "C3 lerCampeonato da entrada válida é Right"
      (isRight (lerCampeonato dadosCampeonato)) True
  , testar "C3 lerCampeonato da entrada válida tem 15 partidas"
      (fmap length (lerCampeonato dadosCampeonato)) (Right 15)
  , testar "C3 lerCampeonato da entrada válida é igual à lista esperada"
      (lerCampeonato dadosCampeonato) (Right partidasTeste)
  , testar "C3 lerPartida válida (com espaços nas bordas dos campos)"
      (lerPartida 1 " 2 ; Coritiba ;1; 0 ; Paraná ")
      (Right (Partida 2 "Coritiba" 1 0 "Paraná"))
  , testar "C3 NumeroInvalido: placar \"dois\""
      (lerPartida 7 "1;Coritiba;dois;0;Paraná") (Left (NumeroInvalido 7 "dois"))
  , testar "C3 NumeroInvalido: rodada vazia"
      (lerPartida 2 ";Coritiba;1;0;Paraná") (Left (NumeroInvalido 2 ""))
  , testar "C3 NumeroInvalido: estouro de Int (99999999999999999999)"
      (lerNumero 9 "99999999999999999999")
      (Left (NumeroInvalido 9 "99999999999999999999"))
  , testar "C3 NumeroInvalido: hexadecimal \"0x10\""
      (lerNumero 9 "0x10") (Left (NumeroInvalido 9 "0x10"))
  , testar "C3 NumeroInvalido: parênteses \"(3)\""
      (lerNumero 9 "(3)") (Left (NumeroInvalido 9 "(3)"))
  , testar "C3 NumeroInvalido: sinal positivo \"+2\""
      (lerNumero 9 "+2") (Left (NumeroInvalido 9 "+2"))
  , testar "C3 NumeroInvalido: só o sinal \"-\""
      (lerNumero 9 "-") (Left (NumeroInvalido 9 "-"))
  , testar "C3 lerNumero aceita negativo e zeros à esquerda"
      (map (lerNumero 1) ["-1", "007"]) [Right (-1), Right 7]
  , testar "C3 lerNumero aceita os limites de Int"
      (map (lerNumero 1) [show (maxBound :: Int), show (minBound :: Int)])
      [Right maxBound, Right minBound]
  , testar "C3 NumeroInvalido: um acima do máximo de Int"
      (lerNumero 1 "9223372036854775808")
      (Left (NumeroInvalido 1 "9223372036854775808"))
  , testar "C3 CamposInvalidos: só 4 campos"
      (lerPartida 3 "1;A;2;1") (Left (CamposInvalidos 3))
  , testar "C3 CamposInvalidos: 6 campos"
      (lerPartida 3 "1;A;2;1;B;C") (Left (CamposInvalidos 3))
  , testar "C3 PlacarNegativo: gols do mandante -1"
      (lerPartida 5 "1;Coritiba;-1;0;Paraná") (Left (PlacarNegativo 5))
  , testar "C3 MesmoTime: mandante igual ao visitante"
      (lerPartida 2 "1;Coritiba;1;0;Coritiba") (Left (MesmoTime 2))
  , testar "C3 RodadaInvalida: rodada 0"
      (lerPartida 4 "0;A;1;0;B") (Left (RodadaInvalida 4))
  , testar "C3 TimeVazio: nome do mandante vazio"
      (lerPartida 6 "1; ;1;0;B") (Left (TimeVazio 6))
  , testar "C3 TimeRepetidoNaRodada: mesmo time duas vezes na rodada 1"
      (lerCampeonato "1;Coritiba;1;0;Paraná\n1;Athletico;2;1;Coritiba")
      (Left (TimeRepetidoNaRodada 1 "Coritiba"))
  , testar "C3 TimeRepetidoNaRodada: texto de demonstração"
      (lerCampeonato textoTimeRepetido)
      (Left (TimeRepetidoNaRodada 1 "Coritiba"))
  , testar "C3 verificarRodadas aceita o campeonato de teste"
      (verificarRodadas partidasTeste) (Right partidasTeste)
  , testar "C3 verificarRodadas recusa time repetido"
      (verificarRodadas [Partida 3 "A" 1 0 "B", Partida 3 "C" 0 0 "A"])
      (Left (TimeRepetidoNaRodada 3 "A"))
  , testar "C3 comentários e linhas em branco são ignorados"
      (lerCampeonato "# comentário\n\n1;A;1;0;B\n   \n# fim\n")
      (Right [Partida 1 "A" 1 0 "B"])
  , testar "C3 número de linha real, contando as ignoradas (erro na linha 4)"
      (lerCampeonato "# c\n\n  \n1;A;x;0;B")
      (Left (NumeroInvalido 4 "x"))
  , testar "C3 lerCampeonato para no primeiro erro"
      (lerCampeonato textoComErros) (Left (NumeroInvalido 4 "dois"))
  , testar "C3 texto vazio dá campeonato vazio"
      (lerCampeonato textoVazio) (Right [])
  , testar "C3 lerNumero válido" (lerNumero 1 "12") (Right 12)
  , testar "C3 lerNumero inválido" (lerNumero 9 "x") (Left (NumeroInvalido 9 "x"))
  , testar "C3 separar: três campos" (separar ';' "1;A;2") ["1", "A", "2"]
  , testar "C3 separar: texto vazio" (separar ';' "") [""]
  , testar "C3 separar: só o separador" (separar ';' ";") ["", ""]
  , testar "C3 separar: campo vazio no meio" (separar ';' "a;;b") ["a", "", "b"]
  , testar "C3 aparar" (aparar "  oi  \r") "oi"
  , testar "C3 todosOsErros lista todos os erros do texto"
      (todosOsErros textoComErros) errosEsperados
  , testar "C3 todosOsErros: campeonato válido não tem erros"
      (todosOsErros dadosCampeonato) []
  , testar "C3 todosOsErros: texto vazio não tem erros" (todosOsErros "") []
  , testar "C3 descreverErro: placar negativo"
      (descreverErro (PlacarNegativo 5))
      "Linha 5: o placar não pode ter gols negativos."
  , testar "C3 descreverErro: time repetido"
      (descreverErro (TimeRepetidoNaRodada 1 "Coritiba"))
      "Rodada 1: o time Coritiba aparece em mais de uma partida."
  , testar "C3 formatarDecimal: uma casa" (formatarDecimal 1 60) "60.0"
  , testar "C3 formatarDecimal: arredonda para cima" (formatarDecimal 1 (100 / 15)) "6.7"
  , testar "C3 formatarDecimal: duas casas" (formatarDecimal 2 (28 / 15)) "1.87"
  , testar "C3 formatarDecimal: zero com duas casas" (formatarDecimal 2 0) "0.00"
  , testar "C3 formatarPartida"
      (formatarPartida (Partida 5 "Cascavel" 4 0 "Operário"))
      "Rodada 5: Cascavel 4 x 0 Operário"
  , testar "C3 tabelaFormatada da classificação final"
      (lines (tabelaFormatada (classificacao partidasTeste))) tabelaFinalTexto
  , testar "C3 tabelaFormatada de lista vazia tem só cabeçalho e traço"
      (length (lines (tabelaFormatada []))) 2
  ]

-- ---------------------------------------------------------------------------
-- Programa de testes
-- ---------------------------------------------------------------------------

-- | Executa todos os testes. Procure por linhas "FALHOU" na saída.
main :: IO ()
main = do
  hSetEncoding stdout utf8
  sequence_ (testesCamada1 ++ testesCamada2 ++ testesCamada3)
  putStrLn "Fim dos testes. Qualquer linha FALHOU acima indica um defeito."
