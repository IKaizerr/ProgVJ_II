local Player = require("player")
local Enemy = require("enemy")
local Wave = require("wave")
local Upgrade = require("upgrade")
local Combat = require("combat")
local Game = require("game")
local Boss = require("boss")
local Events = require("events")

-- Variables Globales

local uiHealth = 100
local uiMaxHealth = 100
local uiDamageRecived = nil
local selectingUpgrade = false

local normalMusic = nil
local bossMusic = nil

local normalBackground = nil
local bossBackground = nil 

local oneShotMode = false

local spawnCoroutine = nil
local bossIntroCoroutine = nil  
local bossIntroActive = false
local victoryCoroutine = nil

local enemies = {}
local boss = nil

local specialUpgradeChoices = 0


-- CARGAR JUEGO

function love.load()

    Player.load()
    Enemy.load()
    Boss.load()

    --Probar una oleada especifica

    --Wave.current = 10
    --Wave.maxReached = 10
    -- startWave()


    -- Cargar Backgrounds

    normalBackground = love.graphics.newImage("assets/backgrounds/normal.png")
    bossBackground = love.graphics.newImage("assets/backgrounds/boss.png")

    -- Cargar musica de las salas.

    normalMusic = love.audio.newSource("assets/music/normal.wav", "stream")
    bossMusic = love.audio.newSource("assets/music/boss.wav", "stream")  

    normalMusic:setLooping(true)
    bossMusic:setLooping(true)

    normalMusic:setVolume(0.5)
    bossMusic:setVolume(0.5)    

    print("Bienvenidos al juego de Oleadas Roguelite!")

    -- Evento: el jugador recibe daño

    Events.on("player_hit", function(data)

        uiHealth = data.health
        uiDamageRecived = data.damage

        print("Se recibio el evento player_hit")
        print("Vida mostrada en UI: " .. uiHealth)
    
    end)

    -- Evento: el jugador realiza un ataque

    Events.on("player_attack", function(data)
    
        -- Reproducir sonido de ataque

        if Player.attacksound:isPlaying() then
            Player.attacksound:stop()
        end

        Player.attacksound:play()

        print("Se recibio el evento player_attack")
        print("Daño del jugador: " .. data.damage)
        print("Direccion del ataque: " .. data.direction)

    end)


    -- Evento: el enemigo recibe daño.

    Events.on("enemy_hit", function(data)

        data.enemy.damageText = data.damage
        data.enemy.damageTextTimer = 0.5

        print("Se recibio el evento enemy_hit")
        print("Daño recibido por el enemigo: " .. data.damage)
        print("Vida restante del enemigo: " .. data.enemyHealth)

    end)


    -- Evento: el enemigo muere

    Events.on("enemy_died", function(data)

        print("Se recibio el evento enemy_died")
        print("El enemigo ha muerto")
        print("Tipo: " .. data.enemyType)

    end)

end

-- Musica 

local function stopMusic()
    if normalMusic ~= nil then
        normalMusic:stop()
    end

    if bossMusic ~= nil then
        bossMusic:stop()
    end
end

local function changeMusic(isBossRoom)
    local targetMusic

    if isBossRoom then
        targetMusic = bossMusic
    else
        targetMusic = normalMusic
    end

    if targetMusic:isPlaying() then
        return
    end

    stopMusic()
    targetMusic:play()
end

-- Corrutinas

local function startVictoryCoroutine()
    if victoryCoroutine ~= nil then
        return
    end

    victoryCoroutine = coroutine.create(function()
        local timer = 1

        while timer > 0 do
            timer = timer - coroutine.yield()
        end

        stopMusic()
        Game.setState(Game.VICTORY)
    end)
end

local function updateCoroutine(co, dt)
    if co == nil then 
        return nil
    end

    if coroutine.status(co) == "dead" then
        return nil
    end

    local success, err = coroutine.resume(co, dt)

    if not success then 
        error(err) 
    end

    if coroutine.status(co) == "dead" then
        return nil
    end
    
    return co
end


-- INICIAR OLEADA

function startWave()

    -- Cancelar referencias a corroutinas anteriores

    spawnCoroutine = nil
    bossIntroCoroutine = nil
    victoryCoroutine = nil

    bossIntroActive = false

    enemies = {}
    boss= nil

    local enemyCount = Wave.getEnemyCount()

    changeMusic(Wave.current == 10)

    --Oleada 10 exclusiva de Boss
    
    if Wave.current == 10 then
        bossIntroCoroutine = coroutine.create(function()
            bossIntroActive = true
            Game.setState(Game.BOSS_INTRO)

            local timer = 2

            while timer > 0 do
                timer = timer - coroutine.yield()
            end
        
        boss = Boss.new(
            600,
            200,
            "king"
        )

        bossIntroActive = false

        Game.setState(
            Game.PLAYING
        )
    end)
        return
    end


-- Aparicion progresiva de enemigos 

spawnCoroutine = coroutine.create(function()
    for i = 1, enemyCount do
        local x =
            100 + (i * 150)
        local y = 100

        local enemyType =
            Wave.getEnemyType(i)

        table.insert(
            enemies,
            Enemy.new(
                x,
                y,
                enemyType,
                Wave.current
            )
        )

        if i < enemyCount then 
            local timer = 0.8

            while timer > 0 do 
                timer = timer - coroutine.yield()
            end
        end
 end


    Game.setState(
        Game.PLAYING)
    end)
end


-- ACTUALIZAR JUEGO

function love.update(dt)
    -- Actualizar Corrutinas

    victoryCoroutine = updateCoroutine(victoryCoroutine, dt)
    spawnCoroutine = updateCoroutine(spawnCoroutine, dt)
    bossIntroCoroutine = updateCoroutine(bossIntroCoroutine, dt)


    if not Game.isPlaying() then
        return
    end


    -- Actualizar Jugador 

    Player.update(dt)


    -- Procesar ataque cuando el golpe alncanza su momento activo 

    if Player.attackHit then
        local attackX, attackY, attackWidth, attackHeight = 
            Combat.getAttackArea(Player)

        if oneShotMode then 
            --Eliminar enemigos alcanzados

            for _, enemy in ipairs(enemies) do
                if enemy.alive and Combat.checkCollision(
                    attackX,
                    attackY,
                    attackWidth,
                    attackHeight,
                    enemy
                ) then 
                    Enemy.takeDamage(enemy, 999999, Player)
                end
            end

        -- Eliminar al jefe si recibe el golpe

        if boss ~= nil and boss.alive
            and Combat.checkCollision(
                attackX,
                attackY,
                attackWidth,
                attackHeight,
                boss
            ) then
            Boss.takeDamage(boss, 999999)
        end
    else
        -- Daño normal a enemigos 

        Combat.applyAttackDamage(
            Player,
            enemies,
            Enemy
        )

        -- Daño normal al jefe 

        if boss ~= nil and boss.alive
            and Combat.checkCollision(
                attackX,
                attackY,
                attackWidth,
                attackHeight,
                boss
            ) then
            Boss.takeDamage(boss, Player.damage)
        end
    end

        Player.attackHit = false

    end


    -- Comprobar muerte del Player antes de actualizar a los enemigos 

    if Player.health <= 0 then
        stopMusic()
        Game.setState(
            Game.GAME_OVER
        )

        return

    end


    -- ACTUALIZAR ENEMIGOS

    for _, enemy in ipairs(enemies) do

        Enemy.update(
            enemy,
            dt,
            Player,
            enemies
        )

    end


    -- ACTUALIZAR BOSS

    if boss ~= nil and boss.alive then

        Boss.update(
            boss,
            dt,
            Player
        )

    end


    -- Comprobar muerte del Player despues del combate

    if Player.health <= 0 then
        stopMusic()
        Game.setState(
            Game.GAME_OVER
        )

        return

    end


    -- COMPROBAR OLEADA

    checkWaveComplete()

end


-- COMPROBAR SI TERMINÓ LA OLEADA

function checkWaveComplete()

    if Game.state ~= Game.PLAYING then 
        return
    end

    -- Final del combate contra el jefe

    if Wave.current == 10 then
        if boss ~= nil and not boss.alive then
            startVictoryCoroutine()
        end

        return
    end

    local aliveEnemies = 0

    for _, enemy in ipairs(enemies) do
        if enemy.alive then
            aliveEnemies =
                aliveEnemies + 1
        end
    end


    if aliveEnemies ~= 0 then
        return
    end

    local completedWave = Wave.current

    -- Bloquea nuevas comprobaciones cuando se elijen las mejoras
    Game.setState(Game.UPGRADE)

        selectingUpgrade = false

        Player.health = Player.maxHealth

            -- CADA 5 OLEADAS, DAR 3 MEJORAS, SINO SOLO 1

            if completedWave % 5 == 0 then

                specialUpgradeChoices = 3

            else

                specialUpgradeChoices = 1

            end

            if completedWave >= Wave.maxWaves
        then
                stopMusic()
                Game.setState(Game.VICTORY)
                return
        end

        Upgrade.generateChoices()
    end

-- Aplicar mejora seleccionada

local function selectUpgrade(choice)

    if not Game.isUpgrade() then
        return
    end

    if selectingUpgrade then
        return
    end

    selectingUpgrade = true

    Upgrade.apply(choice, Player)

    if specialUpgradeChoices > 1 then 
        specialUpgradeChoices = specialUpgradeChoices -1
        Upgrade.generateChoices()
        selectingUpgrade = false
    return
    end

        specialUpgradeChoices = 0

        Game.setState(Game.PLAYING)
        Wave.next()
        startWave()
    end

-- Reiniciar partida 

function resetGame()
    -- Restaurar estadisticas del jugador

    Player.damage = 25
    Player.speed = 200 

    Player.attackRange = 50
    Player.attackCooldown = 0.5

    Player.maxHealth = 100
    Player.health = Player.maxHealth

    -- Restaurar posición y dirección.

    Player.x = 400
    Player.y = 300

    Player.direction = "right"

    -- Restaurar ataque.

    Player.attackTimer = 0
    Player.isAttacking = false
    Player.isAttackingAnimation = false
    Player.attackHit = false
    Player.attackPending = false

    -- Restaurar animación.

    Player.animation = "idle"
    Player.currentFrame = 1
    Player.animationTimer = 0

    -- Restaurar feedback de daño.

    Player.hitTimer = 0

    -- Restaurar oleadas y mejoras.

    Wave.current = 1
    Wave.maxReached = 1

    Upgrade.currentChoices = {}

    specialUpgradeChoices = 0
    oneShotMode = false
    selectingUpgrade = false

    -- Restaurar datos de la interfaz.

    uiHealth = Player.health
    uiMaxHealth = Player.maxHealth
    uiDamageRecived = 0

    -- Reiniciar partida.

    startWave()
end


-- Controles del teclado

function love.keypressed(key, scancode, isrepeat)

    -- Menu Inicial

    if Game.isMenu() then 
        if key == "return" or key == "space" then 
            resetGame()
        elseif key == "c" then 
            Game.setState(Game.CONTROLS)
        elseif key == "escape" then 
            love.event.quit()
        end

        return
    end


    -- Pantalla de controles 

    if Game.isControls() then
        if key == "escape" or key == "backspace" then
            Game.setState(Game.MENU)
        end

        return
    end


    -- PAUSA

    if key == "escape" then

        if Game.isPlaying() then

            Game.setState(
                Game.PAUSED
            )

        elseif Game.isPaused() then

            Game.setState(
                Game.PLAYING
            )

        end

        return

    end

    -- Modo de prueba One Shot 

    if key == "o" then 
        oneShotMode = not oneShotMode

        if oneShotMode then 
            print("One shot Mode activado")
        else
            print("One shot Mode desactivado")
        end
    end


    -- Reiniciar partida por victoria o derrota 

    if key == "r" and
       (Game.isGameOver() or Game.isVictory()) then
        resetGame()
        return
    end


    -- ATAQUE

    if key == "space" and Game.isPlaying() then

        Combat.attack(
            Player,
            enemies,
            Enemy
        )

    end


    -- MEJORAS

    if Game.isUpgrade() then
        if isrepeat then
            return
        end

        if key == "1" then
            selectUpgrade(1)
        elseif key == "2" then 
            selectUpgrade(2)
        elseif key == "3" then
            selectUpgrade(3)
        end
    end
end


-- DIBUJAR JUEGO

function love.draw()
    -- Menu Inicial 

    if Game.isMenu() then
        love.graphics.clear(0.06, 0.07, 0.11, 1)

        local screenWidth, screenHeight =
            love.graphics.getDimensions()

        love.graphics.setColor(0.95, 0.95, 1)
        love.graphics.setFont(love.graphics.newFont(42))

        love.graphics.printf(
            "ROGUELITE",
            0,
            screenHeight * 0.20,
            screenWidth,
            "center"
        )

        love.graphics.setFont(love.graphics.newFont(16))
        love.graphics.setColor(0.65, 0.70, 0.80)

        love.graphics.printf(
            "Sobrevive a las oleadas",
            0,
            screenHeight * 0.20 + 60,
            screenWidth,
            "center"
        )

        local buttonWidth = 280
        local buttonHeight = 52
        local buttonX = (screenWidth - buttonWidth) / 2
        local buttonY = screenHeight * 0.43

        local mouseX, mouseY = love.mouse.getPosition()

        -- Boton jugar 

        if mouseX >= buttonX and mouseX <= buttonX + buttonWidth
            and mouseY >= buttonY and mouseY <= buttonY + buttonHeight then
            love.graphics.setColor(0.30, 0.50, 0.85)
        else
            love.graphics.setColor(0.18, 0.35, 0.65)
        end

        love.graphics.rectangle(
            "fill",
            buttonX,
            buttonY,
            buttonWidth,
            buttonHeight,
            8,
            8
        )

        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(love.graphics.newFont(22))

        love.graphics.printf(
            "Jugar",
            buttonX,
            buttonY + 13,
            buttonWidth,
            "center"
        )

        -- Boton Controles 

        buttonY = buttonY + 70 

        if mouseX >= buttonX and mouseX <= buttonX + buttonWidth
            and mouseY >= buttonY and mouseY <= buttonY + buttonHeight then
            love.graphics.setColor(0.30, 0.35, 0.48)
        else
            love.graphics.setColor(0.15, 0.17, 0.23)
        end

        love.graphics.rectangle(
            "fill",
            buttonX,
            buttonY,
            buttonWidth,
            buttonHeight,
            8,
            8
        )

        love.graphics.setColor(1, 1, 1)

        love.graphics.printf(
            "Controles",
            buttonX,
            buttonY + 13,
            buttonWidth,
            "center"
        )

        -- Boton Salir 

        buttonY = buttonY + 70

        if mouseX >= buttonX and mouseX <= buttonX + buttonWidth
            and mouseY >= buttonY and mouseY <= buttonY + buttonHeight then
            love.graphics.setColor(0.55, 0.22, 0.25)
        else
            love.graphics.setColor(0.15, 0.17, 0.23)
        end

        love.graphics.rectangle(
            "fill",
            buttonX,
            buttonY,
            buttonWidth,
            buttonHeight,
            8,
            8
        )

        love.graphics.setColor(1, 1, 1)

        love.graphics.printf(
            "Salir",
            buttonX,
            buttonY + 13,
            buttonWidth,
            "center"
        )

        love.graphics.setColor(1, 1, 1)
        return
    end

    -- Pantalla de controles 

    if Game.isControls() then
        love.graphics.clear(0.06, 0.07, 0.11, 1)

        local screenWidth, screenHeight =
            love.graphics.getDimensions()

        love.graphics.setColor(0.95, 0.95, 1)
        love.graphics.setFont(love.graphics.newFont(34))

        love.graphics.printf(
            "CONTROLES",
            0,
            screenHeight * 0.18,
            screenWidth,
            "center"
        )

        love.graphics.setFont(love.graphics.newFont(20))
        love.graphics.setColor(0.80, 0.83, 0.90)

        love.graphics.printf(
            "WASD: mover al personaje",
            0,
            screenHeight * 0.35,
            screenWidth,
            "center"
        )

        love.graphics.printf(
            "Espacio: atacar",
            0,
            screenHeight * 0.35 + 45,
            screenWidth,
            "center"
        )

        love.graphics.printf(
            "o: activar o desactivar One shote mode",
            0,
            screenHeight * 0.35 + 90,
            screenWidth,
            "center"
        )

        love.graphics.setFont(love.graphics.newFont(16))
        love.graphics.setColor(0.55, 0.65, 0.80)

        love.graphics.printf(
            "Presiona ESC para volver al menu",
            0,
            screenHeight,
            screenWidth,
            "center"
        )

        love.graphics.setColor(1, 1, 1)
        return
    end

    -- Elementos del juego 

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(14))

    -- Dibujar el fondo segun la oleada 

    love.graphics.setColor(1, 1, 1, 1)

    local background

    if Wave.current == 10 then 
        background = bossBackground
    else
        background = normalBackground
    end

    local screenWidth, screenHeight = 
        love.graphics.getDimensions()

    love.graphics.draw(
        background,
        0,
        0,
        0,
        screenWidth /
    background:getWidth(),
        screenHeight /
    background:getHeight()
    )
    
    Player.draw()

    -- Informacion de daño recibido 

    if uiDamageRecived ~= nil then 

        love.graphics.print(
            "Ultimo daño recibido: " .. uiDamageRecived,
            20,
            120
        )
    
    end

    -- ENEMIGOS

    for _, enemy in ipairs(enemies) do

        Enemy.draw(enemy)

    end

    -- Jefe 

    if boss ~= nil and boss.alive then

        Boss.draw(boss)

    end


    -- INFORMACIÓN DE OLEADA

    love.graphics.print(
        "Oleada: "
        .. Wave.current
        .. "/"
        .. Wave.maxWaves,
        20,
        100
    )


    -- PANTALLA DE MEJORAS

    if Game.isUpgrade() then


        love.graphics.print(
            "¡OLEADA COMPLETADA!",
            360,
            120
        )

        if specialUpgradeChoices > 1 then

            love.graphics.print(
                " Mejoras Especiales:",
                350,
                160
            )

            love.graphics.print(
                "Elige una mejora -Elecciones restantes:"
                .. specialUpgradeChoices,
                280,
                185
                
            )
        
        else 

            love.graphics.print(
                " Elige una mejora:",
                385,
                160
            )

        end


        -- MEJORA 1

        love.graphics.rectangle(
            "line",
            120,
            210,
            300,
            100
        )


        love.graphics.print(
            "1",
            135,
            225
        )


        love.graphics.print(
            Upgrade.getName(1),
            170,
            225
        )


        love.graphics.printf(
            Upgrade.getDescription(1),
            140,
            255,
            260,
            "left"
        )


        -- MEJORA 2

        love.graphics.rectangle(
            "line",
            480,
            210,
            300,
            100
        )


        love.graphics.print(
            "2",
            495,
            225
        )


        love.graphics.print(
            Upgrade.getName(2),
            530,
            225
        )


        love.graphics.printf(
            Upgrade.getDescription(2),
            500,
            255,
            260,
            "left"
        )


        -- MEJORA 3

        love.graphics.rectangle(
            "line",
            300,
            340,
            300,
            100
        )


        love.graphics.print(
            "3",
            315,
            355
        )


        love.graphics.print(
            Upgrade.getName(3),
            350,
            355
        )


        love.graphics.printf(
            Upgrade.getDescription(3),
            320,
            385,
            260,
            "left"
        )

    end


    -- VICTORIA

    if Game.isVictory() then


        love.graphics.setColor(
            0,
            0,
            0,
            0.7
        )


        love.graphics.rectangle(
            "fill",
            0,
            0,
            love.graphics.getWidth(),
            love.graphics.getHeight()
        )


        love.graphics.setColor(
            1,
            1,
            1
        )


        love.graphics.printf(
            "¡VICTORIA!",
            0,
            150,
            love.graphics.getWidth(),
            "center"
        )


        love.graphics.printf(
            "Completaste todas las Oleadas.",
            0,
            200,
            love.graphics.getWidth(),
            "center"
        )


        love.graphics.printf(
            "Oleadas Completadas: "
            .. Wave.maxWaves,
            0,
            230,
            love.graphics.getWidth(),
            "center"
        )


        love.graphics.printf(
            "Presiona R para reiniciar",
            0,
            280,
            love.graphics.getWidth(),
            "center"
        )

    end


    -- GAME OVER

    if Game.isGameOver() then


        love.graphics.setColor(
            0,
            0,
            0,
            0.7
        )


        love.graphics.rectangle(
            "fill",
            0,
            0,
            love.graphics.getWidth(),
            love.graphics.getHeight()
        )


        love.graphics.setColor(
            1,
            1,
            1
        )


        love.graphics.printf(
            "GAME OVER",
            0,
            159,
            love.graphics.getWidth(),
            "center"
        )


        love.graphics.printf(
            "Tu oleada máxima: "
            .. Wave.maxReached,
            0,
            200,
            love.graphics.getWidth(),
            "center"
        )


        love.graphics.printf(
            "Presiona R para reiniciar",
            0,
            250,
            love.graphics.getWidth(),
            "center"
        )

    end


    -- PANTALLA DE PAUSA

    if Game.isPaused() then


        love.graphics.setColor(
            0,
            0,
            0,
            0.7
        )


        love.graphics.rectangle(
            "fill",
            0,
            0,
            love.graphics.getWidth(),
            love.graphics.getHeight()
        )


        love.graphics.setColor(
            1,
            1,
            1
        )


        love.graphics.printf(
            "PAUSA",
            0,
            150,
            love.graphics.getWidth(),
            "center"
        )


        love.graphics.printf(
            "Presiona ESC para continuar",
            0,
            210,
            love.graphics.getWidth(),
            "center"
        )

    end

    -- Presentacion visual del jefe 

    if bossIntroActive then
        local screenWidth = love.graphics.getWidth()
        local screenHeight = love.graphics.getHeight()

        love.graphics.setColor(0, 0, 0, 0.8)

        love.graphics.rectangle(
            "fill",
            0,
            0,
            screenWidth,
            screenHeight
        )

        love.graphics.setColor(1, 0.15, 0.15, 1)
        love.graphics.setFont(love.graphics.newFont(34))

        love.graphics.printf(
            "¡EL JEFE SE ACERCA!",
            0,
            screenHeight / 2 - 25,
            screenWidth,
            "center"
        )
    end


    -- Restaurar color y fuente 

    love.graphics.setColor(
        1,
        1,
        1
    )
    love.graphics.setFont(love.graphics.newFont(14))
end

-- Controles del mouse 

function love.mousepressed(x, y, button)
    if button ~= 1 then 
        return
    end

    if not Game.isMenu() then 
        return
    end

    local screenWidth, screenHeight = 
        love.graphics.getDimensions()

    local buttonWidth = 280
    local buttonHeight = 52
    local buttonX = (screenWidth - buttonWidth) / 2
    local firstButtonY = screenHeight * 0.43

    -- Jugar 

    if x >= buttonX and x <= buttonX + buttonWidth
        and y >= firstButtonY
        and y <= firstButtonY + buttonHeight then 
        resetGame()
        return
    end

    -- Controles 

    local controlsY = firstButtonY + 70

    if x >= buttonX and x <= buttonX + buttonWidth
        and y >= controlsY
        and y <= controlsY + buttonHeight then
        Game.setState(Game.CONTROLS)
        return
    end

    -- Salir 

    local exitY = firstButtonY + 140

    if x >= buttonX and x <= buttonX + buttonWidth
        and y >= exitY
        and y <= exitY + buttonHeight then
        love.event.quit()
        end

    end