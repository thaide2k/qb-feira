Config = {}

-- Configurações gerais
Config.RewardAmount = 5 -- Quantidade de kryon concedida por NPC
Config.NPCSpawnInterval = 15 -- Aumentado para 15 segundos para melhor controle
Config.MaxNPCs = 3 -- Reduzido para 3 NPCs simultâneos para melhor desempenho
Config.NPCCheckInterval = 30 -- Verificação a cada 30 segundos para garantir que existam NPCs ativos

-- Debug mode
Config.Debug = true  -- Set to false in production

-- Props para a mesa
Config.TableProp = 'bkr_prop_weed_table_01a' -- Modelo da mesa de weed

-- Modelos de NPCs que visitarão a mesa - mantendo apenas pedestres comuns
Config.NPCModels = {
    'a_m_m_beach_01',
    'a_m_m_bevhills_01',
    'a_m_m_bevhills_02',
    'a_m_y_beach_01',
    'a_m_y_beachvesp_01',
    'a_m_y_bevhills_01',
    'a_f_m_beach_01',
    'a_f_m_bevhills_01',
    'a_f_y_beach_01',
    'a_f_y_bevhills_01'
}

-- Distância máxima permitida do jogador à mesa
Config.MaxDistance = 15.0

-- Configuração de Animações
Config.Animations = {
    -- Animação do jogador ao colocar a mesa
    PlayerSetup = {
        dict = "anim@heists@narcotics@trash",
        anim = "drop_front"
    },
    -- Animação do NPC ao chegar na mesa
    NPCInteract = {
        dict = "mp_common",
        anim = "givetake1_a"
    }
}

-- Configuração do Texto 3D
Config.Text3D = {
    Scale = 0.35,
    Font = 4,
    Color = {r = 255, g = 255, b = 255, a = 255}
}