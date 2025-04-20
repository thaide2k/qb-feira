Config = {}

-- Configurações gerais
Config.RewardAmount = 1 -- Quantidade de kryon concedida por NPC
Config.NPCSpawnInterval = 10 -- Intervalo em segundos para spawn de NPCs
Config.MaxNPCs = 5 -- Número máximo de NPCs simultâneos

-- Props para a mesa
Config.TableProp = 'bkr_prop_weed_table_01a' -- Modelo da mesa de weed

-- Modelos de NPCs que visitarão a mesa
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
