local QBCore = exports['qb-core']:GetCoreObject()
local feiraActive = false
local tableObject = nil
local spawnedNPCs = {}
local tableCoords = nil
local blip = nil

-- Função de debug
function DebugPrint(message)
    if Config.Debug then
        print("[DEBUG] " .. message)
    end
end

-- Listener para evento para iniciar a feira
RegisterNetEvent('qb-feira:client:startFeira')
AddEventHandler('qb-feira:client:startFeira', function()
    if feiraActive then
        QBCore.Functions.Notify('Você já está com uma feira ativa!', 'error')
        return
    end

    -- Verificar se o jogador está em um veículo
    if IsPedInAnyVehicle(PlayerPedId(), false) then
        QBCore.Functions.Notify('Você não pode iniciar uma feira dentro de um veículo!', 'error')
        return
    end

    -- Iniciar a feira
    SetupFeira()
end)

-- Função para configurar a feira
function SetupFeira()
    DebugPrint("Iniciando configuração da feira")
    
    -- Obter posição do jogador
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)
    
    -- Offset para colocar mesa na frente do jogador
    local forward = GetEntityForwardVector(playerPed)
    local posX = coords.x + forward.x * 1.0
    local posY = coords.y + forward.y * 1.0
    tableCoords = vector3(posX, posY, coords.z - 1.0)
    
    DebugPrint("Posição da mesa: " .. tableCoords.x .. ", " .. tableCoords.y .. ", " .. tableCoords.z)
    
    -- Carregar modelo da mesa
    local tableModel = Config.TableProp
    DebugPrint("Carregando modelo da mesa: " .. tableModel)
    
    if not HasModelLoaded(GetHashKey(tableModel)) then
        RequestModel(GetHashKey(tableModel))
        while not HasModelLoaded(GetHashKey(tableModel)) do
            Citizen.Wait(1)
        end
    end
    
    -- Carregar animação de colocar a mesa
    local animDict = Config.Animations.PlayerSetup.dict
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Citizen.Wait(1)
    end
    
    -- Animação de colocar a mesa
    TaskPlayAnim(playerPed, animDict, Config.Animations.PlayerSetup.anim, 8.0, -8.0, -1, 0, 0, false, false, false)
    Citizen.Wait(1500)
    
    -- Criar a mesa
    tableObject = CreateObject(GetHashKey(tableModel), tableCoords.x, tableCoords.y, tableCoords.z, true, false, false)
    PlaceObjectOnGroundProperly(tableObject)
    SetEntityHeading(tableObject, heading)
    FreezeEntityPosition(tableObject, true)
    
    DebugPrint("Mesa criada com ID: " .. tableObject)
    
    -- Adicionar blip ao mapa
    blip = AddBlipForCoord(tableCoords.x, tableCoords.y, tableCoords.z)
    SetBlipSprite(blip, 140)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.8)
    SetBlipColour(blip, 2)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Sua Feira de Weed")
    EndTextCommandSetBlipName(blip)
    
    QBCore.Functions.Notify('Feira iniciada! Fique por perto para receber clientes.', 'success')
    
    -- Iniciar loop da feira
    feiraActive = true
    StartFeiraLoop()
end

-- Função para iniciar o loop principal da feira
function StartFeiraLoop()
    DebugPrint("Iniciando loop principal da feira")
    
    -- Thread para verificar a distância do jogador
    Citizen.CreateThread(function()
        while feiraActive do
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local distance = #(playerCoords - tableCoords)
            
            -- Mostrar texto 3D na mesa
            DrawText3D(tableCoords.x, tableCoords.y, tableCoords.z + 1.0, "Feira de Weed")
            
            -- Verificar se o jogador está muito longe
            if distance > Config.MaxDistance then
                QBCore.Functions.Notify('Você se afastou muito da sua feira! Encerrando...', 'error')
                EndFeira()
                break
            end
            
            -- Verificar se o jogador entrou em um veículo
            if IsPedInAnyVehicle(playerPed, false) then
                QBCore.Functions.Notify('Você entrou em um veículo! Encerrando feira...', 'error')
                EndFeira()
                break
            end
            
            Citizen.Wait(1000)
        end
    end)
    
    -- Thread para spawnar NPCs periodicamente
    Citizen.CreateThread(function()
        while feiraActive do
            -- Verificar se podemos spawnar mais NPCs
            if #spawnedNPCs < Config.MaxNPCs then
                DebugPrint("Tentando spawnar NPC. NPCs atuais: " .. #spawnedNPCs .. "/" .. Config.MaxNPCs)
                SpawnNPC()
            else
                DebugPrint("Limite máximo de NPCs atingido: " .. #spawnedNPCs .. "/" .. Config.MaxNPCs)
            end
            
            Citizen.Wait(Config.NPCSpawnInterval * 1000)
        end
    end)
end

-- Função para spawnar um NPC
function SpawnNPC()
    DebugPrint("Tentando spawnar NPC...")
    
    -- Selecionar modelo aleatório
    local randomModelIndex = math.random(1, #Config.NPCModels)
    local modelName = Config.NPCModels[randomModelIndex]
    local modelHash = GetHashKey(modelName)
    
    -- Solicitar modelo
    DebugPrint("Carregando modelo: " .. modelName .. " (Hash: " .. modelHash .. ")")
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do
        Citizen.Wait(1)
    end
    
    -- Encontrar posição próxima para spawn
    DebugPrint("Procurando ponto de spawn...")
    local spawnPoint = FindSpawnPointAroundTable()
    if spawnPoint then
        DebugPrint("Ponto encontrado: " .. spawnPoint.x .. ", " .. spawnPoint.y .. ", " .. spawnPoint.z)
        
        -- Criar NPC com garantia de que ele não spawne em veículos
        local npc = CreatePed(4, modelHash, spawnPoint.x, spawnPoint.y, spawnPoint.z, 0.0, true, false)
        if DoesEntityExist(npc) then
            DebugPrint("NPC criado com ID: " .. npc)
            
            -- Configurar comportamento do NPC
            SetEntityInvincible(npc, true)
            SetBlockingOfNonTemporaryEvents(npc, true)
            SetPedConfigFlag(npc, 32, false) -- Disable NPC entering vehicles
            SetPedCanRagdoll(npc, false)
            
            -- Adicionar à lista
            table.insert(spawnedNPCs, npc)
            DebugPrint("NPC adicionado à lista. Total de NPCs: " .. #spawnedNPCs)
            
            -- Iniciar comportamento do NPC
            SetNPCBehavior(npc)
        else
            DebugPrint("Falha ao criar o NPC!")
        end
    else
        DebugPrint("Falha ao encontrar ponto de spawn!")
    end
    
    -- Liberar modelo
    SetModelAsNoLongerNeeded(modelHash)
end

-- Função para encontrar ponto de spawn ao redor da mesa
function FindSpawnPointAroundTable()
    -- Decreased spawn radius to 5.0 (from 20.0) so NPCs spawn closer
    local radius = 5.0
    local angle = math.random() * 2 * math.pi
    
    local x = tableCoords.x + radius * math.cos(angle)
    local y = tableCoords.y + radius * math.sin(angle)
    local z = tableCoords.z
    
    -- Fix the GetGroundZFor_3dCoord usage - capture both return values properly
    local groundZ, groundFound = GetGroundZFor_3dCoord(x, y, z, true)
    
    DebugPrint("GetGroundZFor_3dCoord result: groundZ=" .. tostring(groundZ) .. ", found=" .. tostring(groundFound))
    
    if groundFound then
        -- Use the actual numeric groundZ value
        return vector3(x, y, groundZ)
    else
        -- Fallback value - using tableCoords.z to ensure safe height
        DebugPrint("Solo não encontrado, usando fallback")
        return vector3(x, y, tableCoords.z - 0.5)
    end
end

-- Função para definir o comportamento do NPC
function SetNPCBehavior(npc)
    Citizen.CreateThread(function()
        -- Ensure NPC is not in a vehicle
        if IsPedInAnyVehicle(npc, false) then
            TaskLeaveVehicle(npc, GetVehiclePedIsIn(npc, false), 0)
            Citizen.Wait(1000)
        end
        
        -- Force NPC to walk, not drive
        SetPedCanBeKnockedOffVehicle(npc, 1)
        SetPedConfigFlag(npc, 32, false) -- Disable NPC entering vehicles
        
        -- NPC caminha até a mesa
        DebugPrint("NPC " .. npc .. " iniciando caminhada até a mesa")
        ClearPedTasksImmediately(npc)
        TaskGoStraightToCoord(npc, tableCoords.x, tableCoords.y, tableCoords.z, 1.0, -1, 0.0, 0.0)
        
        -- Esperar até que o NPC chegue perto da mesa ou seja removido
        local arrived = false
        local startTime = GetGameTimer()
        local timeout = 30000 -- 30 segundos timeout
        
        while not arrived and feiraActive and (GetGameTimer() - startTime) < timeout do
            if DoesEntityExist(npc) then
                local npcCoords = GetEntityCoords(npc)
                local distanceToTable = #(npcCoords - tableCoords)
                
                if distanceToTable < 1.5 then
                    arrived = true
                    DebugPrint("NPC " .. npc .. " chegou à mesa! Distância: " .. distanceToTable)
                end
            else
                DebugPrint("NPC " .. npc .. " não existe mais!")
                return
            end
            
            Citizen.Wait(500)
        end
        
        -- Verificar se timeout ocorreu
        if (GetGameTimer() - startTime) >= timeout and not arrived then
            DebugPrint("NPC " .. npc .. " teve timeout ao tentar chegar à mesa")
        end
        
        -- Se chegou na mesa, realizar interação
        if arrived and feiraActive and DoesEntityExist(npc) then
            -- Carregar animação
            local animDict = Config.Animations.NPCInteract.dict
            RequestAnimDict(animDict)
            while not HasAnimDictLoaded(animDict) do
                Citizen.Wait(1)
            end
            
            -- Fazer NPC olhar para a mesa
            TaskTurnPedToFaceCoord(npc, tableCoords.x, tableCoords.y, tableCoords.z, 1000)
            Citizen.Wait(1000)
            
            -- Executar animação
            TaskPlayAnim(npc, animDict, Config.Animations.NPCInteract.anim, 8.0, -8.0, 3000, 0, 0, false, false, false)
            Citizen.Wait(3000)
            
            -- Recompensar o jogador
            DebugPrint("Enviando evento de recompensa para o servidor")
            TriggerServerEvent('qb-feira:server:rewardPlayer')
            
            -- Esperar um pouco
            Citizen.Wait(2000)
        end
        
        -- NPC vai embora
        if DoesEntityExist(npc) then
            DebugPrint("NPC " .. npc .. " vai embora")
            local awayPoint = FindSpawnPointAroundTable()
            if awayPoint then
                TaskGoStraightToCoord(npc, awayPoint.x, awayPoint.y, awayPoint.z, 1.0, -1, 0.0, 0.0)
                
                -- Esperar até que o NPC esteja longe ou timeout
                local gone = false
                startTime = GetGameTimer()
                timeout = 30000 -- 30 segundos timeout
                
                while not gone and (GetGameTimer() - startTime) < timeout do
                    if DoesEntityExist(npc) then
                        local npcCoords = GetEntityCoords(npc)
                        local distanceToTable = #(npcCoords - tableCoords)
                        
                        if distanceToTable > 25.0 then
                            gone = true
                            DebugPrint("NPC " .. npc .. " está suficientemente longe. Removendo...")
                        end
                        
                        Citizen.Wait(500)
                    else
                        gone = true
                        DebugPrint("NPC " .. npc .. " não existe mais durante a saída")
                    end
                end
            end
            
            -- Remover NPC da lista e deletar
            for i, ped in ipairs(spawnedNPCs) do
                if ped == npc then
                    table.remove(spawnedNPCs, i)
                    DebugPrint("NPC " .. npc .. " removido da lista. Total de NPCs: " .. #spawnedNPCs)
                    break
                end
            end
            
            DeleteEntity(npc)
            DebugPrint("NPC " .. npc .. " deletado")
        end
    end)
end

-- Função para encerrar a feira
function EndFeira()
    if feiraActive then
        DebugPrint("Encerrando feira")
        feiraActive = false
        
        -- Remover mesa
        if DoesEntityExist(tableObject) then
            DeleteEntity(tableObject)
            tableObject = nil
            DebugPrint("Mesa removida")
        end
        
        -- Remover NPCs
        DebugPrint("Removendo " .. #spawnedNPCs .. " NPCs")
        for _, npc in ipairs(spawnedNPCs) do
            if DoesEntityExist(npc) then
                DeleteEntity(npc)
                DebugPrint("NPC " .. npc .. " removido")
            end
        end
        spawnedNPCs = {}
        
        -- Remover blip
        if blip then
            RemoveBlip(blip)
            blip = nil
            DebugPrint("Blip removido")
        end
        
        -- Notificar servidor que a feira foi encerrada
        TriggerServerEvent('qb-feira:server:endFeira')
        DebugPrint("Evento de encerramento enviado ao servidor")
    end
end

-- Função para desenhar texto 3D
function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    
    if onScreen then
        SetTextScale(Config.Text3D.Scale, Config.Text3D.Scale)
        SetTextFont(Config.Text3D.Font)
        SetTextProportional(1)
        SetTextColour(Config.Text3D.Color.r, Config.Text3D.Color.g, Config.Text3D.Color.b, Config.Text3D.Color.a)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

-- Listener para evento para forçar o encerramento da feira
RegisterNetEvent('qb-feira:client:forcedEnd')
AddEventHandler('qb-feira:client:forcedEnd', function()
    EndFeira()
    QBCore.Functions.Notify('Sua feira foi encerrada.', 'inform')
end)

-- Adicionar comando para encerrar a feira manualmente
RegisterCommand('encerrarfeira', function()
    if feiraActive then
        EndFeira()
        QBCore.Functions.Notify('Feira encerrada manualmente!', 'success')
    else
        QBCore.Functions.Notify('Você não tem uma feira ativa!', 'error')
    end
end, false)

-- Comando para debug
RegisterCommand('debugfeira', function()
    if feiraActive then
        QBCore.Functions.Notify('Status da feira: Ativa', 'primary')
        QBCore.Functions.Notify('NPCs ativos: ' .. #spawnedNPCs .. '/' .. Config.MaxNPCs, 'primary')
        QBCore.Functions.Notify('Posição da mesa: ' .. math.floor(tableCoords.x) .. ', ' .. math.floor(tableCoords.y) .. ', ' .. math.floor(tableCoords.z), 'primary')
        
        DebugPrint("=== DEBUG FEIRA ===")
        DebugPrint("Status: Ativa")
        DebugPrint("NPCs: " .. #spawnedNPCs .. "/" .. Config.MaxNPCs)
        DebugPrint("Posição da mesa: " .. tableCoords.x .. ", " .. tableCoords.y .. ", " .. tableCoords.z)
        for i, npc in ipairs(spawnedNPCs) do
            if DoesEntityExist(npc) then
                local coords = GetEntityCoords(npc)
                DebugPrint("NPC " .. i .. " (ID: " .. npc .. ") - Posição: " .. coords.x .. ", " .. coords.y .. ", " .. coords.z)
            else
                DebugPrint("NPC " .. i .. " (ID: " .. npc .. ") - Não existe mais")
            end
        end
    else
        QBCore.Functions.Notify('Nenhuma feira ativa!', 'error')
    end
end, false)

-- Comando para forçar spawn de NPC (debug)
RegisterCommand('spawnfeiranpc', function()
    if feiraActive then
        SpawnNPC()
        QBCore.Functions.Notify('Tentando spawnar NPC para a feira...', 'primary')
    else
        QBCore.Functions.Notify('Nenhuma feira ativa!', 'error')
    end
end, false)

-- Evento para quando o jogador desconectar
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() and feiraActive then
        EndFeira()
    end
end)

-- Evento para quando o jogador morrer
AddEventHandler('baseevents:onPlayerDied', function()
    if feiraActive then
        EndFeira()
        QBCore.Functions.Notify('Feira encerrada porque você morreu!', 'error')
    end
end)
