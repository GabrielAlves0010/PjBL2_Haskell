-- |
-- Módulo: Classificacao
--
-- Camada 2 do trabalho: cálculo da tabela de classificação e de
-- estatísticas do campeonato.
--
-- Todas as funções são puras e não usam recursão explícita: o trabalho é
-- feito por funções de ordem superior (map, filter, foldl', sortBy) e por
-- composição de funções com (.).
module Classificacao
  ( pontos
  , linhaVazia
  , linhaDoTime
  , pontosLinha
  , saldo
  , aproveitamento
  , criterioDesempate
  , classificacao
  , ateRodada
  , diferencaGols
  , totalGols
  , maiorGoleada
  , mediaGols
  ) where

import Data.List (foldl', sortBy)
import Data.Ord (Down (..), comparing)
import Tipos

-- | Pontos ganhos por um resultado: vitória 3, empate 1, derrota 0.
pontos :: Resultado -> Int
pontos Vitoria = 3
pontos Empate  = 1
pontos Derrota = 0

-- | Linha de um time que ainda não jogou nenhuma partida.
linhaVazia :: Time -> Linha
linhaVazia t = Linha
  { time       = t
  , jogos      = 0
  , vitorias   = 0
  , empates    = 0
  , derrotas   = 0
  , golsPro    = 0
  , golsContra = 0
  }

-- | Gols (feitos, sofridos) do time na partida. Pressupõe que o time
-- participou da partida; se não for o mandante, é tratado como visitante.
golsDoTime :: Time -> Partida -> (Int, Int)
golsDoTime t p
  | t == mandante p = (golsMandante p, golsVisitante p)
  | otherwise       = (golsVisitante p, golsMandante p)

-- | Soma um ao contador correspondente ao resultado.
contar :: Resultado -> Linha -> Linha
contar Vitoria l = l { vitorias = vitorias l + 1 }
contar Empate  l = l { empates  = empates l + 1 }
contar Derrota l = l { derrotas = derrotas l + 1 }

-- | Passo da dobra: incorpora uma partida à linha do time.
-- Partidas em que o time não jogou deixam a linha como está.
acumular :: Time -> Linha -> Partida -> Linha
acumular t l p = case resultadoPara t p of
    Nothing -> l
    Just r  -> (contar r l)
      { jogos      = jogos l + 1
      , golsPro    = golsPro l + feitos
      , golsContra = golsContra l + sofridos
      }
  where
    (feitos, sofridos) = golsDoTime t p

-- | Linha do time, acumulada (foldl') sobre as partidas em que ele jogou.
linhaDoTime :: [Partida] -> Time -> Linha
linhaDoTime ps t = foldl' (acumular t) (linhaVazia t) (filter (participou t) ps)

-- | Total de pontos da linha, derivado dos contadores.
pontosLinha :: Linha -> Int
pontosLinha l =
  vitorias l * pontos Vitoria
    + empates l * pontos Empate
    + derrotas l * pontos Derrota

-- | Saldo de gols (gols pró menos gols contra).
saldo :: Linha -> Int
saldo l = golsPro l - golsContra l

-- | Aproveitamento: percentual (0 a 100) dos pontos disputados que o time
-- conquistou, isto é, pontos / (3 * jogos). Sem jogos, o valor é 0.
aproveitamento :: Linha -> Double
aproveitamento l
  | jogos l == 0 = 0
  | otherwise    = 100 * fromIntegral (pontosLinha l) / fromIntegral (3 * jogos l)

-- | Critérios de desempate, na ordem do Campeonato Brasileiro:
-- 1) pontos, 2) vitórias, 3) saldo de gols, 4) gols pró (todos em ordem
-- decrescente) e 5) nome do time em ordem alfabética. O quinto critério
-- torna a ordem total e determinística.
criterioDesempate :: Linha -> Linha -> Ordering
criterioDesempate =
  comparing (Down . pontosLinha)
    <> comparing (Down . vitorias)
    <> comparing (Down . saldo)
    <> comparing (Down . golsPro)
    <> comparing time

-- | Tabela de classificação: uma linha por time, ordenada pelos critérios
-- de 'criterioDesempate'.
classificacao :: [Partida] -> [Linha]
classificacao ps = sortBy criterioDesempate (map (linhaDoTime ps) (times ps))

-- | Mantém apenas as partidas até a rodada informada (inclusive).
ateRodada :: Int -> [Partida] -> [Partida]
ateRodada n = filter ((<= n) . rodada)

-- | Diferença (sempre positiva ou zero) entre os gols das duas equipes.
diferencaGols :: Partida -> Int
diferencaGols p = abs (golsMandante p - golsVisitante p)

-- | Total de gols marcados na partida.
totalGols :: Partida -> Int
totalGols p = golsMandante p + golsVisitante p

-- | Partida de maior diferença de gols. 'Nothing' para lista vazia.
-- Em caso de empate na diferença, vale a primeira partida da lista.
maiorGoleada :: [Partida] -> Maybe Partida
maiorGoleada = foldl' escolher Nothing

-- | Passo da dobra de 'maiorGoleada': só troca a escolhida quando a nova
-- partida tem diferença estritamente maior (por isso a primeira prevalece
-- em caso de empate).
escolher :: Maybe Partida -> Partida -> Maybe Partida
escolher Nothing p = Just p
escolher (Just melhor) p
  | diferencaGols p > diferencaGols melhor = Just p
  | otherwise                              = Just melhor

-- | Média de gols por partida. 'Nothing' para lista vazia.
mediaGols :: [Partida] -> Maybe Double
mediaGols [] = Nothing
mediaGols ps = Just (fromIntegral (sum (map totalGols ps)) / fromIntegral (length ps))
