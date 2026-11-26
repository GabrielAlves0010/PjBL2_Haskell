-- |
-- Módulo: Main
--
-- Demonstração das três camadas. A função 'main' é a única que faz entrada
-- ou saída; todo o texto do relatório é montado por funções puras.
--
-- Etapas da demonstração:
--
-- 1. tabela final do campeonato de teste;
-- 2. tabela após a rodada 3;
-- 3. estatísticas da camada 2 (maior goleada, média de gols, times, líder
--    e aproveitamento);
-- 4. tratamento de entradas com erro (primeiro erro e todos os erros) e
--    campeonato vazio.
module Main (main) where

import Classificacao
import Dados
import Data.List (intercalate)
import Data.Maybe (listToMaybe)
import Leitura
import System.IO (hSetEncoding, stdout, utf8)
import Tipos

-- | Configura a saída para UTF-8 (evita erro com "Paraná" e "Operário" no
-- Windows) e imprime o relatório.
main :: IO ()
main = do
  hSetEncoding stdout utf8
  putStrLn relatorio

-- | Relatório completo da demonstração.
relatorio :: String
relatorio =
  intercalate "\n\n" (secoesDoCampeonato ++ [secaoErros, secaoVazio])
  where
    secoesDoCampeonato =
      either
        (\erro -> ["Falha ao ler o campeonato de teste: " ++ descreverErro erro])
        secoesDasPartidas
        (lerCampeonato dadosCampeonato)

-- | As três primeiras seções: classificação final, classificação após a
-- rodada 3 e estatísticas.
secoesDasPartidas :: [Partida] -> [String]
secoesDasPartidas ps =
  [ secao "1) Classificação final" (tabelaFormatada (classificacao ps))
  , secao "2) Classificação após a rodada 3"
      (tabelaFormatada (classificacao (ateRodada 3 ps)))
  , secao "3) Estatísticas" (estatisticas ps)
  ]

-- | Título sublinhado seguido do corpo.
secao :: String -> String -> String
secao titulo corpo =
  titulo ++ "\n" ++ replicate (length titulo) '=' ++ "\n" ++ corpo

-- | Estatísticas das partidas. Funciona também para lista vazia, usando
-- 'maybe' para os valores que podem não existir.
estatisticas :: [Partida] -> String
estatisticas ps =
  intercalate "\n"
    [ "Times (" ++ show (length (times ps)) ++ "): " ++ listaDeTimes (times ps)
    , "Maior goleada: "
        ++ maybe "nenhuma (não há partidas)" formatarPartida (maiorGoleada ps)
    , "Média de gols por partida: "
        ++ maybe "indisponível (não há partidas)" (formatarDecimal 2) (mediaGols ps)
    , "Líder: "
        ++ maybe "nenhum (não há times)" descreverLider (listToMaybe tabela)
    , "Aproveitamento: " ++ aproveitamentos tabela
    ]
  where
    tabela = classificacao ps

-- | Os nomes separados por vírgula, ou "nenhum" se não houver times.
listaDeTimes :: [Time] -> String
listaDeTimes [] = "nenhum"
listaDeTimes ts = intercalate ", " ts

-- | Líder com seus pontos e aproveitamento.
descreverLider :: Linha -> String
descreverLider l =
  time l ++ " com " ++ show (pontosLinha l) ++ " pontos ("
    ++ formatarDecimal 1 (aproveitamento l) ++ "% de aproveitamento)"

-- | Aproveitamento de todos os times, na ordem da tabela.
aproveitamentos :: [Linha] -> String
aproveitamentos [] = "nenhum"
aproveitamentos ls = intercalate "; " (map descrever ls)
  where
    descrever l = time l ++ " " ++ formatarDecimal 1 (aproveitamento l) ++ "%"

-- | Seção 4: dois textos inválidos, com o primeiro erro e todos os erros.
secaoErros :: String
secaoErros =
  secao "4) Tratamento de entrada com erros"
    (intercalate "\n\n"
      [ demonstrarEntrada "Texto com várias linhas inválidas" textoComErros
      , demonstrarEntrada "Texto com time repetido na rodada" textoTimeRepetido
      ])

-- | Mostra o primeiro erro (lerCampeonato) e todos os erros (todosOsErros)
-- de um texto.
demonstrarEntrada :: String -> String -> String
demonstrarEntrada rotulo texto =
  intercalate "\n" $
    [ rotulo ++ ":"
    , "  Primeiro erro (lerCampeonato):"
    , "    " ++ either descreverErro (const "nenhum erro encontrado") (lerCampeonato texto)
    , "  Todos os erros (todosOsErros):"
    ]
      ++ map (("    " ++) . descreverErro) (todosOsErros texto)

-- | Seção 5: campeonato sem partidas (classificação vazia, estatísticas
-- ausentes).
secaoVazio :: String
secaoVazio =
  secao "5) Campeonato vazio"
    (either descreverErro mostrarVazio (lerCampeonato textoVazio))
  where
    mostrarVazio ps =
      tabelaFormatada (classificacao ps) ++ "\n" ++ estatisticas ps
