local QBCore = exports['qb-core']:GetCoreObject()
local feiraActive = false
local tableObject = nil
local spawnedNPCs = {}
local tableCoords = nil
local blip = nil

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
    -- Obter posição do jogador
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)
    
    -- Offset para colocar mesa na frente do jogador
    local forward = GetEntityForwardVector(playerPed)
    local posX = coords.x + forward.x * 1.0
    local posY = coords.y + forward.y * 1.0
    tableCoords = vector3(posX, posY, coords.z - 1.0)
    
    -- Carregar modelo da mesa
    local tableModel = Config.TableProp
    if not HasModelLoaded(tableModel) then
        RequestModel(tableModel)
        while not HasModelLoaded(tableModel) do
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
                SpawnNPC()
            end
            
            Citizen.Wait(Config.NPCSpawnInterval * 1000)
        end
    end)
end

-- Função para spawnar um NPC
function SpawnNPC()
    -- Selecionar modelo aleatório
    local modelHash = GetHashKey(Config.NPCModels[math.random(1, #Config.NPCModels)])
    
    -- Solicitar modelo
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do
        Citizen.Wait(1)
    end
    
    -- Encontrar posição próxima para spawn
    local spawnPoint = FindSpawnPointAroundTable()
    if spawnPoint then
        -- Criar NPC
        local npc = CreatePed(4, modelHash, spawnPoint.x, spawnPoint.y, spawnPoint.z, 0.0, true, false)
        SetEntityInvincible(npc, true)
        SetBlockingOfNonTemporaryEvents(npc, true)
        
        -- Adicionar à lista
        table.insert(spawnedNPCs, npc)
        
        -- Iniciar comportamento do NPC
        SetNPCBehavior(npc)
    end
    
    -- Liberar modelo
    SetModelAsNoLongerNeeded(modelHash)
end

-- Função para encontrar ponto de spawn ao redor da mesa
function FindSpawnPointAroundTable()
    local radius = 20.0
    local angle = math.random() * 2 * math.pi
    
    local x = tableCoords.x + radius * math.cos(angle)
    local y = tableCoords.y + radius * math.sin(angle)
    local z = tableCoords.z
    
    -- Obter altura do solo
    local groundZ, groundFound = GetGroundZFor_3dCoord(x, y, z, false)
    if groundFound then
        return vector3(x, y, groundZ)
    end
    
    return nil
end

-- Função para definir o comportamento do NPC
function SetNPCBehavior(npc)
    Citizen.CreateThread(function()
        -- NPC caminha até a mesa
        TaskGoToCoordAnyMeans(npc, tableCoords.x, tableCoords.y, tableCoords.z, 1.0, 0, 0, 786603, 0)
        
        -- Esperar até que o NPC chegue perto da mesa ou seja removido
        local arrived = false
        local startTime = GetGameTimer()
        local timeout = 30000 -- 30 segundos timeout
        
        while not arrived and feiraActive and (GetGameTimer() - startTime) < timeout do
            local npcCoords = GetEntityCoords(npc)
            local distanceToTable = #(npcCoords - tableCoords)
            
            if distanceToTable < 1.5 then
                arrived = true
            end
            
            -- Verificar se o NPC ainda existe
            if not DoesEntityExist(npc) then
                return
            end
            
            Citizen.Wait(500)
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
            TriggerServerEvent('qb-feira:server:rewardPlayer')
            
            -- Esperar um pouco
            Citizen.Wait(2000)
        end
        
        -- NPC vai embora
        if DoesEntityExist(npc) then
            local awayPoint = FindSpawnPointAroundTable()
            if awayPoint then
                TaskGoToCoordAnyMeans(npc, awayPoint.x, awayPoint.y, awayPoint.z, 1.0, 0, 0, 786603, 0)
                
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
                        end
                        
                        Citizen.Wait(500)
                    else
                        gone = true
                    end
                end
            end
            
            -- Remover NPC da lista e deletar
            for i, ped in ipairs(spawnedNPCs) do
                if ped == npc then
                    table.remove(spawnedNPCs, i)
                    break
                end
            end
            
            DeleteEntity(npc)
        end
    end)
end

-- Função para encerrar a feira
function EndFeira()
    if feiraActive then
        feiraActive = false
        
        -- Remover mesa
        if DoesEntityExist(tableObject) then
            DeleteEntity(tableObject)
            tableObject = nil
        end
        
        -- Remover NPCs
        for _, npc in ipairs(spawnedNPCs) do
            if DoesEntityExist(npc) then
                DeleteEntity(npc)
            end
        end
        spawnedNPCs = {}
        
        -- Remover blip
        if blip then
            RemoveBlip(blip)
            blip = nil
        end
        
        -- Notificar servidor que a feira foi encerrada
        TriggerServerEvent('qb-feira:server:endFeira')
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
