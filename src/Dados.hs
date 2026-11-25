-- |
-- Módulo: Dados
--
-- Dados de teste do trabalho, escritos como texto (String) no formato lido
-- pela camada 3. Os dados ficam em texto, e não em um arquivo, para que o
-- programa funcione também em ambientes sem acesso a arquivos (como um
-- compilador online) e para não exigir leitura de entrada.
--
-- Formato de cada linha: rodada;mandante;gols mandante;gols visitante;visitante
module Dados
  ( dadosCampeonato
  , textoComErros
  , textoTimeRepetido
  , textoVazio
  ) where

-- | Campeonato válido: 6 times, 5 rodadas, 3 jogos por rodada (turno único,
-- 15 partidas). Tem empates 0 x 0, uma goleada por 4 gols de diferença e
-- dois pares de times empatados em pontos na classificação final:
--
-- * Athletico e Londrina (9 pontos), decididos pelo número de vitórias;
-- * Paraná e Coritiba (8 pontos e 2 vitórias), decididos pelo saldo de gols.
dadosCampeonato :: String
dadosCampeonato = unlines
  [ "# Campeonato paranaense de teste (turno único)"
  , "# rodada;mandante;gols mandante;gols visitante;visitante"
  , ""
  , "# Rodada 1"
  , "1;Coritiba;0;2;Paraná"
  , "1;Athletico;2;1;Operário"
  , "1;Londrina;2;2;Cascavel"
  , ""
  , "# Rodada 2"
  , "2;Coritiba;2;0;Operário"
  , "2;Paraná;1;0;Cascavel"
  , "2;Athletico;0;1;Londrina"
  , ""
  , "# Rodada 3"
  , "3;Coritiba;0;0;Cascavel"
  , "3;Operário;0;2;Londrina"
  , "3;Paraná;0;1;Athletico"
  , ""
  , "# Rodada 4"
  , "4;Coritiba;1;1;Londrina"
  , "4;Cascavel;0;1;Athletico"
  , "4;Operário;0;0;Paraná"
  , ""
  , "# Rodada 5"
  , "5;Coritiba;1;0;Athletico"
  , "5;Londrina;2;2;Paraná"
  , "5;Cascavel;4;0;Operário"
  ]

-- | Texto com várias linhas inválidas, misturadas a comentários e linhas em
-- branco (que contam na numeração). Erros esperados, com o número real da
-- linha:
--
-- * linha 4: número inválido ("dois");
-- * linha 6: número de campos errado;
-- * linha 7: placar negativo;
-- * linha 9: mandante igual ao visitante;
-- * rodada 2: o Operário aparece nas linhas 10 e 11.
textoComErros :: String
textoComErros = unlines
  [ "# Entrada com erros para demonstração"
  , "1;Coritiba;0;2;Paraná"
  , ""
  , "1;Athletico;dois;1;Operário"
  , "   "
  , "1;Londrina;2;2"
  , "2;Coritiba;-1;0;Operário"
  , "# comentário no meio das partidas"
  , "2;Paraná;1;0;Paraná"
  , "2;Cascavel;1;0;Operário"
  , "2;Operário;0;0;Londrina"
  ]

-- | Texto sem nenhuma linha inválida, mas em que o Coritiba aparece em duas
-- partidas da mesma rodada.
textoTimeRepetido :: String
textoTimeRepetido = unlines
  [ "# Time repetido na mesma rodada"
  , "1;Coritiba;1;0;Paraná"
  , "1;Athletico;2;1;Coritiba"
  ]

-- | Texto sem nenhuma partida: só comentário e linha em branco.
textoVazio :: String
textoVazio = unlines
  [ "# Nenhuma partida cadastrada"
  , ""
  ]
