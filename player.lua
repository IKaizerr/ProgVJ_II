local Player = {}
local Events = require("events")

Player.image = nil
Player.spriteSheet = nil


-- CONTROL DE ANIMACIONES

Player.isAttackingAnimation = false

Player.frames = {}

Player.animation = "idle"
Player.currentFrame = 1
Player.animationTimer = 0
Player.animationSpeed = 0.15

-- Frame en el que ocurre el golpe
Player.attackHitFrame = 3
Player.attackHit = false


-- POSICIÓN

Player.x = 400
Player.y = 300

Player.width = 40
Player.height = 40

Player.speed = 200


-- ESTADÍSTICAS DE COMBATE

Player.damage = 25
Player.attackRange = 50
Player.attackCooldown = 0.5


-- FEEDBACK DE DAÑO

Player.hitTimer = 0
Player.hitDuration = 0.15


-- ESTADÍSTICAS DE VIDA

Player.maxHealth = 100
Player.health = Player.maxHealth


-- DIRECCIÓN

Player.direction = "right"


-- CONTROL DEL ATAQUE

Player.attackTimer = 0
Player.isAttacking = false

-- Efecto visual del ataque
Player.attackEffectTimer = 0
Player.attackEffectDuration = 0.10


-- UPDATE

function Player.update(dt)

    local isMoving = false


    -- COOLDOWN DEL ATAQUE

    if Player.attackTimer > 0 then

        Player.attackTimer =
            Player.attackTimer - dt

    end


    if Player.attackTimer < 0 then

        Player.attackTimer = 0

    end


    -- FEEDBACK DE DAÑO

    if Player.hitTimer > 0 then

        Player.hitTimer =
            Player.hitTimer - dt

    end


    if Player.hitTimer < 0 then

        Player.hitTimer = 0

    end


    -- MOVIMIENTO

    -- El jugador NO puede moverse mientras ataca

    if not Player.isAttackingAnimation then


        if love.keyboard.isDown("w") then

            Player.y =
                Player.y - Player.speed * dt

            Player.direction = "up"

            isMoving = true

        end


        if love.keyboard.isDown("s") then

            Player.y =
                Player.y + Player.speed * dt

            Player.direction = "down"

            isMoving = true

        end


        if love.keyboard.isDown("a") then

            Player.x =
                Player.x - Player.speed * dt

            Player.direction = "left"

            isMoving = true

        end


        if love.keyboard.isDown("d") then

            Player.x =
                Player.x + Player.speed * dt

            Player.direction = "right"

            isMoving = true

        end

    end


    -- LIMITAR AL JUGADOR

    if Player.x < 0 then

        Player.x = 0

    end


    if Player.y < 0 then

        Player.y = 0

    end


    if Player.x + Player.width >
        love.graphics.getWidth() then

        Player.x =
            love.graphics.getWidth() - Player.width

    end


    if Player.y + Player.height >
        love.graphics.getHeight() then

        Player.y =
            love.graphics.getHeight() - Player.height

    end


    -- ANIMACIÓN DE MOVIMIENTO

    if not Player.isAttackingAnimation then

        if isMoving then

            Player.animation = "walk"

        else

            Player.animation = "idle"

        end

    end


    -- ACTUALIZAR ANIMACIÓN

    Player.updateAnimation(dt)

end


-- LOAD

function Player.load()

    Player.image = love.graphics.newImage(
        "assets/player.png"
    )


    Player.spriteSheet = love.graphics.newImage(
        "assets/player_sheet.png"
    )


    local frameWidth =
        Player.spriteSheet:getWidth() / 4

    local frameHeight =
        Player.spriteSheet:getHeight() / 5


    Player.attacksound = love.audio.newSource(
        "assets/attack.wav",
        "static"
    )


    -- ANIMACIÓN IDLE

    Player.frames.idle = {}

    for i = 0, 3 do

        Player.frames.idle[i + 1] =
            love.graphics.newQuad(
                i * frameWidth,
                0,
                frameWidth,
                frameHeight,
                Player.spriteSheet:getWidth(),
                Player.spriteSheet:getHeight()
            )

    end


    -- ANIMACIÓN WALK

    Player.frames.walk = {}

    for i = 0, 3 do

        Player.frames.walk[i + 1] =
            love.graphics.newQuad(
                i * frameWidth,
                frameHeight,
                frameWidth,
                frameHeight,
                Player.spriteSheet:getWidth(),
                Player.spriteSheet:getHeight()
            )

    end


    -- ANIMACIÓN ATTACK

    Player.frames.attack = {}

    for i = 0, 3 do

        Player.frames.attack[i + 1] =
            love.graphics.newQuad(
                i * frameWidth,
                frameHeight * 2,
                frameWidth,
                frameHeight,
                Player.spriteSheet:getWidth(),
                Player.spriteSheet:getHeight()
            )

    end

end


-- ACTUALIZAR ANIMACIÓN

function Player.updateAnimation(dt)

    Player.animationTimer =
        Player.animationTimer + dt


    if Player.animationTimer >= Player.animationSpeed then

        Player.animationTimer = 0

        Player.currentFrame =
            Player.currentFrame + 1


        -- ANIMACIÓN DE ATAQUE

        if Player.isAttackingAnimation then

            if Player.currentFrame ==
                Player.attackHitFrame then

                Player.attackHit = true

            end


            if Player.currentFrame >
                #Player.frames.attack then

                Player.currentFrame = 1

                Player.isAttackingAnimation = false
                Player.isAttacking = false

            end


        -- ANIMACIONES NORMALES

        else

            if Player.currentFrame >
                #Player.frames[Player.animation] then

                Player.currentFrame = 1

            end

        end

    end

end


-- ATAQUE

function Player.attack()

    if Player.attackTimer <= 0 then

        Player.attackTimer =
            Player.attackCooldown


        -- SONIDO DE ATAQUE

        -- if Player.attacksound:isPlaying() then

           -- Player.attacksound:stop()

        -- end

        -- Player.attacksound:play()


        -- ACTIVAR ATAQUE

        Player.isAttacking = true

        Player.isAttackingAnimation = true

        Player.animation = "attack"

        Player.currentFrame = 1

        Player.animationTimer = 0

        Player.attackHit = false

        Player.attackPending = false

        -- Prototipo 3: evento personalizado de ataque

        print("daño del jugador:", Player.damage)

        Events.emit("player_attack", {
            damage = Player.damage,
            direction = Player.direction,
            x = Player.x,
            y = Player.y,   
        })

        -- ACTIVAR EFECTO VISUAL

        Player.attackEffectTimer =
            Player.attackEffectDuration


        return true

    end


    return false

end


-- RECIBIR DAÑO

function Player.takeDamage(damage)

    Player.health =
        Player.health - damage


    -- Activar feedback visual

    Player.hitTimer =
        Player.hitDuration


    if Player.health < 0 then

        Player.health = 0

    end

    -- Prototipo 3: evento personalizado 
    
    Events.emit("player_hit", {
        damage = damage,
        health = Player.health
    })

end


-- DRAW

function Player.draw()


    -- COLOR DEL JUGADOR

    if Player.hitTimer > 0 then

        love.graphics.setColor(
            1,
            0.2,
            0.2
        )

    else

        love.graphics.setColor(
            1,
            1,
            1
        )

    end


    -- DIBUJAR JUGADOR

    if Player.spriteSheet then

        local quad =
            Player.frames[Player.animation]
            [Player.currentFrame]


        local frameWidth =
            Player.spriteSheet:getWidth() / 4

        local frameHeight =
            Player.spriteSheet:getHeight() / 5


        local scaleX =
            Player.width / frameWidth

        local scaleY =
            Player.height / frameHeight


        local drawX = Player.x
        local drawScaleX = scaleX


        -- Girar hacia la izquierda

        if Player.direction == "left" then

            drawX =
                Player.x + Player.width

            drawScaleX =
                -scaleX

        end


        love.graphics.draw(
            Player.spriteSheet,
            quad,
            drawX,
            Player.y,
            0,
            drawScaleX,
            scaleY
        )


    elseif Player.image then

        local scaleX =
            Player.width /
            Player.image:getWidth()

        local scaleY =
            Player.height /
            Player.image:getHeight()


        love.graphics.draw(
            Player.image,
            Player.x,
            Player.y,
            0,
            scaleX,
            scaleY
        )


    else

        love.graphics.rectangle(
            "fill",
            Player.x,
            Player.y,
            Player.width,
            Player.height
        )

    end


    -- RESTAURAR COLOR

    love.graphics.setColor(
        1,
        1,
        1
    )


    -- ZONA DE ATAQUE

    if Player.isAttackingAnimation then

        local attackX = Player.x
        local attackY = Player.y

        local attackWidth =
            Player.width

        local attackHeight =
            Player.height


        if Player.direction == "right" then

            attackX =
                Player.x + Player.width

            attackWidth =
                Player.attackRange


        elseif Player.direction == "left" then

            attackX =
                Player.x - Player.attackRange

            attackWidth =
                Player.attackRange


        elseif Player.direction == "down" then

            attackY =
                Player.y + Player.height

            attackHeight =
                Player.attackRange


        elseif Player.direction == "up" then

            attackY =
                Player.y - Player.attackRange

            attackHeight =
                Player.attackRange

        end


        -- HITBOX DEL ATAQUE

        love.graphics.rectangle(
            "line",
            attackX,
            attackY,
            attackWidth,
            attackHeight
        )


        -- EFECTO VISUAL DEL GOLPE

        if Player.attackEffectTimer > 0 then

            love.graphics.setColor(
                1,
                1,
                0.2
            )

            love.graphics.rectangle(
                "fill",
                attackX,
                attackY,
                attackWidth,
                attackHeight
            )

            love.graphics.setColor(
                1,
                1,
                1
            )

        end

    end


    -- BARRA DE VIDA

    local healthPercentage =
        Player.health / Player.maxHealth


    love.graphics.rectangle(
        "line",
        20,
        5,
        150,
        10
    )


    love.graphics.rectangle(
        "fill",
        20,
        5,
        150 * healthPercentage,
        10
    )


    -- ESTADÍSTICAS

    love.graphics.print(
        "Vida: "
        .. Player.health
        .. " / "
        .. Player.maxHealth,
        20,
        20
    )


    love.graphics.print(
        "Daño: "
        .. Player.damage,
        20,
        40
    )


    love.graphics.print(
        "Velocidad: "
        .. Player.speed,
        20,
        60
    )


    -- ESTADO DEL ATAQUE

    if Player.isAttackingAnimation then

        love.graphics.print(
            "Ataque: "
            .. Player.attackRange
            .. " (Distancia de Ataque)",
            20,
            80
        )

    end

end


return Player