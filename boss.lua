local Boss = {}


-- IMAGEN DEL JEFE

Boss.image = nil


-- CARGAR ASSET DEL JEFE

function Boss.load()

    if love.filesystem.getInfo(
        "assets/slime_king.png"
    ) then

        Boss.image =
            love.graphics.newImage(
                "assets/slime_king.png"
            )

    end

end



function Boss.new(x, y, bossType)

    local boss = {}

    boss.x = x
    boss.y = y

    boss.width = 80
    boss.height = 80

    boss.type = bossType


    -- JEFE REY

    if bossType == "king" then

        boss.name = "Rey"

        boss.maxHealth = 500
        boss.health = boss.maxHealth

        boss.speed = 80
        boss.damage = 20
        boss.attackRange = 70
        boss.attackCooldown = 1

    end


    boss.attackTimer = 0


    -- ATAQUE ESPECIAL

    boss.specialCooldown = 5
    boss.specialTimer = 5


    -- ESTADO DEL ATAQUE ESPECIAL

    boss.specialActive = false

    boss.alive = true

    return boss

end


function Boss.update(boss, dt, player)

    if not boss.alive then
        return
    end


    -- MOVIMIENTO HACIA EL JUGADOR

    local dx =
        player.x - boss.x

    local dy =
        player.y - boss.y

    local distance =
        math.sqrt(
            dx * dx +
            dy * dy
        )


    if distance > boss.attackRange then

        boss.x =
            boss.x +
            (dx / distance) *
            boss.speed *
            dt

        boss.y =
            boss.y +
            (dy / distance) *
            boss.speed *
            dt

    end


    -- ATAQUE NORMAL

    if boss.attackTimer > 0 then

        boss.attackTimer =
            boss.attackTimer - dt

    end


    if distance <= boss.attackRange
        and boss.attackTimer <= 0 then

        player.health =
            player.health -
            boss.damage

        boss.attackTimer =
            boss.attackCooldown

    end



    -- ATAQUE ESPECIAL DEL REY SLIME

    if boss.specialTimer > 0 then

        boss.specialTimer =
            boss.specialTimer - dt

    end


    if boss.specialTimer <= 0 then

        -- ACTIVAR EFECTO DEL ESPECIAL

        boss.specialActive = true


        local specialRange = 180

        if distance <= specialRange then

            player.health =
                player.health - 40

        end

        boss.specialTimer =
            boss.specialCooldown


        -- TERMINAR EFECTO DEL ESPECIAL

        boss.specialActive = false


    end


end


function Boss.takeDamage(boss, damage)

    if not boss.alive then
        return
    end


    boss.health =
        boss.health -
        damage


    if boss.health <= 0 then

        boss.health = 0
        boss.alive = false

    end

end


function Boss.draw(boss)

    if not boss.alive then
        return
    end


    -- OBTENER IMAGEN DEL JEFE

    local image =
        Boss.image


    -- DIBUJAR SPRITE DEL JEFE

    if image then

        love.graphics.setColor(
            1,
            1,
            1
        )


        love.graphics.draw(
            image,
            boss.x + boss.width / 2,
            boss.y + boss.height / 2,
            0,
            boss.width / image:getWidth(),
            boss.height / image:getHeight(),
            image:getWidth() / 2,
            image:getHeight() / 2
        )

    else

        love.graphics.setColor(
            0.6,
            0.1,
            0.1
        )


        love.graphics.rectangle(
            "fill",
            boss.x,
            boss.y,
            boss.width,
            boss.height
        )


    end


    -- NOMBRE DEL JEFE

    love.graphics.setColor(
        1,
        1,
        1
    )

    love.graphics.printf(
        boss.name,
        boss.x - 20,
        boss.y - 40,
        boss.width + 40,
        "center"
    )


    -- INDICADOR DEL ATAQUE ESPECIAL

    if boss.specialActive then

        love.graphics.setColor(
            1,
            0,
            0,
            0.45
        )

        love.graphics.circle(
            "fill",
            boss.x + boss.width / 2,
            boss.y + boss.height / 2,
            180
        )

    elseif boss.specialTimer <= 1 then

        love.graphics.setColor(
            1,
            0.3,
            0.3,
            0.25
        )

        love.graphics.circle(
            "fill",
            boss.x + boss.width / 2,
            boss.y + boss.height / 2,
            180
        )

    end


    -- BARRA DE VIDA DEL JEFE

    local screenWidth =
        love.graphics.getWidth()

    local barWidth = 500
    local barHeight = 20

    local barX =
        (screenWidth - barWidth) / 2

    local barY = 30


    -- FONDO DE LA BARRA

    love.graphics.setColor(
        0.15,
        0.15,
        0.15
    )

    love.graphics.rectangle(
        "fill",
        barX,
        barY,
        barWidth,
        barHeight
    )


    -- VIDA ACTUAL

    local healthPercentage =
        boss.health /
        boss.maxHealth


    love.graphics.setColor(
        0.8,
        0.1,
        0.1
    )

    love.graphics.rectangle(
        "fill",
        barX,
        barY,
        barWidth * healthPercentage,
        barHeight
    )


    -- TEXTO DE VIDA

    love.graphics.setColor(
        1,
        1,
        1
    )

    love.graphics.printf(
        boss.name
        .. "  "
        .. math.floor(boss.health)
        .. " / "
        .. boss.maxHealth,
        barX,
        barY + 25,
        barWidth,
        "center"
    )


end


return Boss