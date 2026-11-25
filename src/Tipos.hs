-- |
-- Módulo: Tipos
--
-- Camada 1 do trabalho: o modelo de dados do campeonato.
--
-- Aqui ficam somente os tipos (Time, Resultado, Partida, Linha) e as
-- funções mais básicas sobre eles. Nada neste módulo conhece pontuação,
-- critérios de desempate ou leitura de texto: essas responsabilidades
-- pertencem às camadas 2 (Classificacao) e 3 (Leitura).
module Tipos
  ( Time
  , Resultado (..)
  , Partida (..)
  , Linha (..)
  , participou
  , resultadoPara
  , times
  ) where

import Data.List (nub, sort)

-- | O nome de um time. Sinônimo de tipo: não cria um tipo novo.
type Time = String

-- | O resultado de uma partida sob o ponto de vista de um time.
data Resultado = Vitoria | Empate | Derrota
  deriving (Show, Eq)

-- | Uma partida já disputada.
data Partida = Partida
  { rodada        :: Int
  , mandante      :: Time
  , golsMandante  :: Int
  , golsVisitante :: Int
  , visitante     :: Time
  }
  deriving (Show, Eq)

-- | Uma linha da tabela de classificação. Guarda apenas contadores brutos;
-- pontos e saldo de gols são derivados por funções (módulo Classificacao).
data Linha = Linha
  { time       :: Time
  , jogos      :: Int
  , vitorias   :: Int
  , empates    :: Int
  , derrotas   :: Int
  , golsPro    :: Int
  , golsContra :: Int
  }
  deriving (Show, Eq)

-- | O time disputou a partida (como mandante ou como visitante)?
participou :: Time -> Partida -> Bool
participou t p = t == mandante p || t == visitante p

-- | Resultado da partida para o time informado.
-- Devolve 'Nothing' se o time não jogou essa partida.
resultadoPara :: Time -> Partida -> Maybe Resultado
resultadoPara t p
  | t == mandante p  = Just (compararGols (golsMandante p) (golsVisitante p))
  | t == visitante p = Just (compararGols (golsVisitante p) (golsMandante p))
  | otherwise        = Nothing

-- | Compara os gols de um time (primeiro argumento) com os do adversário.
compararGols :: Int -> Int -> Resultado
compararGols feitos sofridos
  | feitos > sofridos = Vitoria
  | feitos < sofridos = Derrota
  | otherwise         = Empate

-- | Todos os times que aparecem nas partidas, sem repetição e em ordem
-- alfabética.
times :: [Partida] -> [Time]
times = sort . nub . concatMap (\p -> [mandante p, visitante p])
