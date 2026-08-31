local Player = require("player")
local Enemy = require("enemy")
local Wave = require("wave")
local Upgrade = require("upgrade")
local Combat = require("combat")
local Game = require("game")


local enemies = {}


-- CARGAR JUEGO

function love.load()

    Player.load()

    startWave()

end


-- INICIAR OLEADA

function startWave()

    enemies = {}

    local enemyCount =
        Wave.getEnemyCount()


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

    end


    Game.setState(
        Game.PLAYING
    )

end


-- ACTUALIZAR JUEGO

function love.update(dt)

    if not Game.isPlaying() then
        return
    end


    -- JUGADOR

    Player.update(dt)


    -- APLICAR DAÑO EN EL MOMENTO DEL GOLPE

    if Player.attackHit then

        Combat.applyAttackDamage(
            Player,
            enemies,
            Enemy
        )

        Player.attackHit = false

    end


    -- COMPROBAR MUERTE DEL JUGADOR

    if Player.health <= 0 then

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


    -- COMPROBAR MUERTE DEL JUGADOR

    if Player.health <= 0 then

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

    local aliveEnemies = 0


    for _, enemy in ipairs(enemies) do

        if enemy.alive then

            aliveEnemies =
                aliveEnemies + 1

        end

    end


    if aliveEnemies == 0 then

        Wave.next()


        if Wave.isFinished() then

            Game.setState(
                Game.VICTORY
            )

        else

            Upgrade.generateChoices()

            Game.setState(
                Game.UPGRADE
            )

        end

    end

end


-- TECLAS

function love.keypressed(key)


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


    -- REINICIAR PARTIDA

    if key == "r" and
       (Game.isGameOver() or Game.isVictory()) then


        -- ESTADÍSTICAS DEL JUGADOR

        Player.damage = 25
        Player.speed = 200

        Player.attackRange = 50
        Player.attackCooldown = 0.5

        Player.maxHealth = 100
        Player.health = Player.maxHealth


        -- POSICIÓN

        Player.x = 400
        Player.y = 300


        -- DIRECCIÓN

        Player.direction = "right"


        -- ATAQUE

        Player.attackTimer = 0
        Player.isAttacking = false
        Player.isAttackingAnimation = false
        Player.attackHit = false
        Player.attackPending = false


        -- ANIMACIÓN

        Player.animation = "idle"
        Player.currentFrame = 1
        Player.animationTimer = 0


        -- FEEDBACK DE DAÑO

        Player.hitTimer = 0


        -- OLEADAS

        Wave.current = 1
        Wave.maxReached = 1


        -- MEJORAS

        Upgrade.currentChoices = {}


        -- INICIAR NUEVA PARTIDA

        startWave()

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

        if key == "1" then

            Upgrade.apply(
                1,
                Player
            )

            startWave()


        elseif key == "2" then

            Upgrade.apply(
                2,
                Player
            )

            startWave()


        elseif key == "3" then

            Upgrade.apply(
                3,
                Player
            )

            startWave()

        end

    end

end


-- DIBUJAR JUEGO

function love.draw()


    -- JUGADOR

    Player.draw()


    -- ENEMIGOS

    for _, enemy in ipairs(enemies) do

        Enemy.draw(enemy)

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


        love.graphics.print(
            "Elige una mejora:",
            385,
            160
        )


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
            .. Wave.max.Reached,
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


    -- RESTAURAR COLOR

    love.graphics.setColor(
        1,
        1,
        1
    )

end