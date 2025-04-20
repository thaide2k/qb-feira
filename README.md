# QB-Feira

Um sistema simples de barracas de venda para servidores QBCore. Os jogadores podem montar uma barraca de weed e ganhar kryon atendendo NPCs.

## Características

- Integrado ao sistema QB-Tablet e QB-Venices
- NPCs visitam a barraca periodicamente
- Ganhe 1 kryon por cada visita de cliente
- Sistema de posicionamento de barracas baseado na posição do jogador
- Verificações de distância para evitar que o jogador abandone a barraca

## Instalação

1. Coloque a pasta `qb-feira` em seu diretório de resources
2. Adicione `ensure qb-feira` ao seu server.cfg
3. Adicione o evento "Feira de Weed" à configuração do qb-tablet (config.lua)
4. Reinicie seu servidor

## Dependências

- QBCore Framework
- qb-tablet
- qb-venices

## Uso

Os jogadores podem iniciar uma feira através do tablet (F3), selecionando o evento "Feira de Weed".

### Comandos

- `/encerrarfeira` - Encerra manualmente sua barraca ativa
- `/encerrartodas` - (Admin) Encerra todas as barracas ativas no servidor

## Configuração

Você pode ajustar diversas configurações no arquivo `config.lua`:

- Quantidade de recompensa por NPC
- Intervalo de spawn de NPCs
- Modelos de NPCs utilizados
- Distância máxima permitida da barraca
- Animações utilizadas

## Integração

Este resource se integra com o qb-tablet para iniciar o evento e com o qb-venices para recompensar os jogadores com kryon.
