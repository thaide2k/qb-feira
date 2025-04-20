local QBCore = exports['qb-core']:GetCoreObject()
local activeStands = {}

-- Evento para iniciar o evento de feira via tablet
RegisterNetEvent('qb-feira:server:startEvent', function(playerId)
    local src = source
    if src == '' then src = playerId end -- Compatibilidade com chamadas de outros scripts
    
    -- Verificar se o jogador já tem uma feira ativa
    if activeStands[src] then
        TriggerClientEvent('QBCore:Notify', src, 'Você já está com uma feira ativa!', 'error')
        return
    end
    
    -- Marcar como ativa
    activeStands[src] = true
    
    -- Iniciar feira para o cliente
    TriggerClientEvent('qb-feira:client:startFeira', src)
end)

-- Registrar evento no tablet
RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        -- Apenas para debug no console
        print("Jogador carregado: " .. Player.PlayerData.name .. " - Registrando eventos")
    end
end)

-- Evento para quando o jogador encerrar a feira
RegisterNetEvent('qb-feira:server:endFeira', function()
    local src = source
    if activeStands[src] then
        activeStands[src] = nil
        
        -- Adicione aqui qualquer lógica adicional para quando a feira terminar
        -- Por exemplo, estatísticas, cooldowns, etc.
        
        -- Notificar ao tablet que o evento foi concluído (se necessário)
        exports['qb-tablet']:MarkEventCompleted(src, 'event_feira')
    end
end)

-- Evento para recompensar o jogador quando um NPC interage com a mesa
RegisterNetEvent('qb-feira:server:rewardPlayer', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player and activeStands[src] then
        -- Adicionar kryon ao jogador usando o sistema qb-venices
        local success = exports['qb-venices']:AddVenice(src, 'kryon', Config.RewardAmount)
        
        if success then
            -- Notificar o jogador sobre a recompensa
            TriggerClientEvent('QBCore:Notify', src, 'Cliente atendido! +' .. Config.RewardAmount .. ' kryon', 'success')
        else
            -- Notificar erro (apenas para debug)
            TriggerClientEvent('QBCore:Notify', src, 'Erro ao adicionar kryon!', 'error')
            print("Erro ao adicionar kryon para o jogador ID: " .. src)
        end
    else
        print("Tentativa de recompensa falhou - Jogador inválido ou sem feira ativa: " .. src)
    end
end)

-- Se o jogador desconectar, encerrar a feira
AddEventHandler('playerDropped', function()
    local src = source
    if activeStands[src] then
        activeStands[src] = nil
        TriggerClientEvent('qb-feira:client:forcedEnd', src)
    end
end)

-- Registrar comando administrativo para encerrar todas as feiras
QBCore.Commands.Add('encerrartodas', 'Encerra todas as feiras ativas', {}, true, function(source, args)
    for src, _ in pairs(activeStands) do
        TriggerClientEvent('qb-feira:client:forcedEnd', src)
        TriggerClientEvent('QBCore:Notify', src, 'Um administrador encerrou sua feira!', 'error')
        activeStands[src] = nil
    end
    
    TriggerClientEvent('QBCore:Notify', source, 'Todas as feiras foram encerradas!', 'success')
end, 'admin')
