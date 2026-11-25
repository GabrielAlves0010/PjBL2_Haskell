-- |
-- Módulo: Leitura
--
-- Camada 3 do trabalho: leitura e validação do texto do campeonato, e
-- formatação da saída (tabela e números), tudo em funções puras.
--
-- Formato de entrada: uma partida por linha, no formato
--
-- > rodada;mandante;gols do mandante;gols do visitante;visitante
--
-- Linhas em branco (ou só com espaços) e linhas que começam com '#' são
-- ignoradas, mas continuam sendo contadas na numeração: os números de linha
-- informados nos erros são os números reais do texto.
--
-- Os erros são valores do tipo 'Erro', carregados por 'Either'. Nenhuma
-- função deste módulo faz entrada ou saída.
module Leitura
  ( Erro (..)
  , descreverErro
  , aparar
  , separar
  , lerNumero
  , lerPartida
  , lerCampeonato
  , verificarRodadas
  , todosOsErros
  , tabelaFormatada
  , formatarDecimal
  , formatarPartida
  ) where

import Classificacao (aproveitamento, pontosLinha, saldo)
import Data.Char (isDigit, isSpace)
import Data.Either (lefts, rights)
import Data.List (dropWhileEnd, group, intercalate, sort)
import Data.Maybe (listToMaybe)
import Text.Read (readMaybe)
import Tipos

-- ---------------------------------------------------------------------------
-- Erros
-- ---------------------------------------------------------------------------

-- | Tudo o que pode estar errado em uma entrada. Os números são sempre o
-- número real da linha no texto, exceto em 'TimeRepetidoNaRodada', que
-- informa a rodada e o time.
data Erro
  = CamposInvalidos Int            -- linha sem exatamente 5 campos
  | NumeroInvalido Int String      -- linha e o texto que não é número
  | PlacarNegativo Int             -- linha com gols negativos
  | MesmoTime Int                  -- linha em que mandante == visitante
  | RodadaInvalida Int             -- linha com rodada menor que 1
  | TimeVazio Int                  -- linha com nome de time vazio
  | TimeRepetidoNaRodada Int Time  -- rodada e time que jogou duas vezes
  deriving (Show, Eq)

-- | Mensagem legível, em português, para um erro.
descreverErro :: Erro -> String
descreverErro (CamposInvalidos n) =
  "Linha " ++ show n
    ++ ": esperados 5 campos separados por ';' "
    ++ "(rodada;mandante;gols mandante;gols visitante;visitante)."
descreverErro (NumeroInvalido n texto) =
  "Linha " ++ show n ++ ": \"" ++ texto ++ "\" não é um número inteiro válido."
descreverErro (PlacarNegativo n) =
  "Linha " ++ show n ++ ": o placar não pode ter gols negativos."
descreverErro (MesmoTime n) =
  "Linha " ++ show n ++ ": o mandante e o visitante são o mesmo time."
descreverErro (RodadaInvalida n) =
  "Linha " ++ show n ++ ": a rodada deve ser um número maior que zero."
descreverErro (TimeVazio n) =
  "Linha " ++ show n ++ ": o nome de um dos times está vazio."
descreverErro (TimeRepetidoNaRodada r t) =
  "Rodada " ++ show r ++ ": o time " ++ t ++ " aparece em mais de uma partida."

-- ---------------------------------------------------------------------------
-- Funções de texto
-- ---------------------------------------------------------------------------

-- | Divide o texto em cada ocorrência do separador. Campos vazios são
-- mantidos: @separar ';' "a;;b" == ["a","","b"]@ e @separar ';' "" == [""]@.
-- Implementada com 'foldr', sem recursão explícita.
separar :: Char -> String -> [String]
separar sep = foldr passo [""]
  where
    passo c (atual : resto)
      | c == sep  = "" : atual : resto
      | otherwise = (c : atual) : resto
    passo c [] = [[c]]

-- | Remove os espaços (e quebras de linha) das duas bordas do texto.
aparar :: String -> String
aparar = dropWhileEnd isSpace . dropWhile isSpace

-- | O texto tem o formato de um inteiro decimal: sinal '-' opcional seguido
-- de um ou mais dígitos? Recusa, por exemplo, "0x10", "(3)" e "+2".
formatoDeInteiro :: String -> Bool
formatoDeInteiro texto = not (null digitos) && all isDigit digitos
  where
    digitos = if take 1 texto == "-" then drop 1 texto else texto

-- | Converte para 'Int' apenas se o valor couber nele, sem estouro.
caberEmInt :: Integer -> Maybe Int
caberEmInt valor =
  if valor >= toInteger (minBound :: Int) && valor <= toInteger (maxBound :: Int)
    then Just (fromInteger valor)
    else Nothing

-- | Lê um número inteiro, informando a linha e o texto no erro. Só aceita
-- sinal '-' opcional e dígitos decimais; lê como 'Integer' e recusa o que não
-- cabe em 'Int', para não haver estouro silencioso.
lerNumero :: Int -> String -> Either Erro Int
lerNumero n texto =
  maybe (Left (NumeroInvalido n texto)) Right
    (validar texto >>= readMaybe >>= caberEmInt)
  where
    validar t = if formatoDeInteiro t then Just t else Nothing

-- | Devolve @Right ()@ se a condição vale e @Left erro@ caso contrário.
exigir :: Bool -> Erro -> Either Erro ()
exigir condicao erro = if condicao then Right () else Left erro

-- ---------------------------------------------------------------------------
-- Leitura das partidas
-- ---------------------------------------------------------------------------

-- | Lê uma linha de partida. O primeiro argumento é o número da linha, usado
-- apenas para montar o erro. Validações, nesta ordem: quantidade de campos,
-- números válidos, rodada positiva, placar não negativo, nomes não vazios e
-- mandante diferente do visitante.
lerPartida :: Int -> String -> Either Erro Partida
lerPartida n linha =
  case map aparar (separar ';' linha) of
    [campoRodada, nomeMandante, campoGolsM, campoGolsV, nomeVisitante] -> do
      r  <- lerNumero n campoRodada
      gm <- lerNumero n campoGolsM
      gv <- lerNumero n campoGolsV
      exigir (r > 0) (RodadaInvalida n)
      exigir (gm >= 0 && gv >= 0) (PlacarNegativo n)
      exigir (not (null nomeMandante) && not (null nomeVisitante)) (TimeVazio n)
      exigir (nomeMandante /= nomeVisitante) (MesmoTime n)
      Right Partida
        { rodada        = r
        , mandante      = nomeMandante
        , golsMandante  = gm
        , golsVisitante = gv
        , visitante     = nomeVisitante
        }
    _ -> Left (CamposInvalidos n)

-- | A linha tem conteúdo? Falso para linhas em branco e para comentários.
relevante :: String -> Bool
relevante linha = case aparar linha of
  ""        -> False
  ('#' : _) -> False
  _         -> True

-- | Linhas relevantes do texto, cada uma com seu número real de linha.
-- A numeração é feita antes do filtro, para contar as linhas ignoradas.
linhasRelevantes :: String -> [(Int, String)]
linhasRelevantes = filter (relevante . snd) . zip [1 ..] . lines

-- | Pares (rodada, time) de uma partida: um para o mandante e um para o
-- visitante.
paresDaPartida :: Partida -> [(Int, Time)]
paresDaPartida p = [(rodada p, mandante p), (rodada p, visitante p)]

-- | Todos os pares (rodada, time) que aparecem mais de uma vez, cada um
-- listado uma única vez e em ordem crescente.
repetidos :: [Partida] -> [(Int, Time)]
repetidos =
  concatMap (take 1)
    . filter ((> 1) . length)
    . group
    . sort
    . concatMap paresDaPartida

-- | Garante que nenhum time joga duas vezes na mesma rodada. Em caso de
-- repetição, informa a primeira (menor rodada, depois ordem alfabética).
verificarRodadas :: [Partida] -> Either Erro [Partida]
verificarRodadas ps =
  maybe (Right ps) (Left . uncurry TimeRepetidoNaRodada) (listToMaybe (repetidos ps))

-- | Lê o texto inteiro, parando no primeiro erro (por isso 'traverse'), e em
-- seguida verifica a regra de um jogo por time em cada rodada.
lerCampeonato :: String -> Either Erro [Partida]
lerCampeonato texto =
  traverse (uncurry lerPartida) (linhasRelevantes texto) >>= verificarRodadas

-- | Todos os erros do texto: primeiro os de cada linha inválida (na ordem
-- em que aparecem) e depois todos os times repetidos em uma rodada, estes
-- calculados somente sobre as partidas válidas.
todosOsErros :: String -> [Erro]
todosOsErros texto =
  lefts resultados
    ++ map (uncurry TimeRepetidoNaRodada) (repetidos (rights resultados))
  where
    resultados = map (uncurry lerPartida) (linhasRelevantes texto)

-- ---------------------------------------------------------------------------
-- Formatação
-- ---------------------------------------------------------------------------

-- | Completa com espaços à esquerda até a largura dada.
alinharDireita :: Int -> String -> String
alinharDireita largura texto = replicate (largura - length texto) ' ' ++ texto

-- | Completa com espaços à direita até a largura dada.
alinharEsquerda :: Int -> String -> String
alinharEsquerda largura texto = texto ++ replicate (largura - length texto) ' '

-- | Completa com zeros à esquerda até a largura dada.
preencherZeros :: Int -> String -> String
preencherZeros largura texto = replicate (largura - length texto) '0' ++ texto

-- | Formata um número com o total de casas decimais pedido, sem usar
-- bibliotecas de formatação: arredonda para um inteiro escalado e separa a
-- parte inteira da decimal com 'divMod'.
-- Exemplo: @formatarDecimal 1 53.33 == "53.3"@.
formatarDecimal :: Int -> Double -> String
formatarDecimal casas x = sinal ++ show inteiro ++ decimais
  where
    fator    = 10 ^ casas :: Int
    escalado = round (abs x * fromIntegral fator) :: Int
    (inteiro, fracao) = escalado `divMod` fator
    sinal    = if x < 0 && escalado /= 0 then "-" else ""
    decimais
      | casas > 0 = "." ++ preencherZeros casas (show fracao)
      | otherwise = ""

-- | Saldo de gols com sinal explícito para valores positivos.
formatarSaldo :: Int -> String
formatarSaldo s
  | s > 0     = '+' : show s
  | otherwise = show s

-- | Larguras das colunas numéricas: P, J, V, E, D, GP, GC, SG, Aprov%.
largurasNumericas :: [Int]
largurasNumericas = [3, 3, 3, 3, 3, 3, 3, 4, 6]

-- | Monta uma linha da tabela a partir das células: posição, nome do time e
-- as colunas numéricas. Células fora desse formato são apenas unidas.
montarLinha :: Int -> [String] -> String
montarLinha larguraTime (posicao : nome : numeros) =
  unwords
    ( alinharDireita 3 posicao
        : alinharEsquerda larguraTime nome
        : zipWith alinharDireita largurasNumericas numeros
    )
montarLinha _ outras = unwords outras

-- | Células de uma linha da tabela, na ordem do cabeçalho.
celulasDaLinha :: Int -> Linha -> [String]
celulasDaLinha posicao l =
  [ show posicao
  , time l
  , show (pontosLinha l)
  , show (jogos l)
  , show (vitorias l)
  , show (empates l)
  , show (derrotas l)
  , show (golsPro l)
  , show (golsContra l)
  , formatarSaldo (saldo l)
  , formatarDecimal 1 (aproveitamento l)
  ]

-- | Tabela de classificação alinhada, com as colunas Pos, Time, P (pontos),
-- J (jogos), V, E, D, GP (gols pró), GC (gols contra), SG (saldo de gols) e
-- Aprov% (aproveitamento). Sem quebra de linha no final. A posição é a
-- ordem da lista recebida.
tabelaFormatada :: [Linha] -> String
tabelaFormatada ls =
  intercalate "\n" (cabecalho : traco : zipWith linhaDaTabela [1 ..] ls)
  where
    larguraTime = foldr (max . length . time) (length "Time") ls
    cabecalho =
      montarLinha larguraTime
        ["Pos", "Time", "P", "J", "V", "E", "D", "GP", "GC", "SG", "Aprov%"]
    traco = replicate (length cabecalho) '-'
    linhaDaTabela posicao l = montarLinha larguraTime (celulasDaLinha posicao l)

-- | Descrição de uma partida em uma linha, por exemplo
-- @Rodada 5: Cascavel 4 x 0 Operário@.
formatarPartida :: Partida -> String
formatarPartida p =
  "Rodada " ++ show (rodada p) ++ ": " ++ mandante p ++ " "
    ++ show (golsMandante p) ++ " x " ++ show (golsVisitante p)
    ++ " " ++ visitante p
