local Enemy = {}



-- TIPOS DE ENEMIGO

local EnemyTypes = {

    basic = {

        maxHealth = 100,
        damage = 10,
        speed = 100,
        attackRange = 50,

        width = 40,
        height = 40,

        color = {0.8, 0.8, 0.8}

    },


    fast = {

        maxHealth = 60,
        damage = 5,
        speed = 180,
        attackRange = 40,

        width = 30,
        height = 30,

        color = {0.2, 0.8, 1}

    }

}


-- CREAR ENEMIGO

function Enemy.new(x, y, enemyType, wave)

    local enemy = {}

    enemyType = enemyType or "basic"

    enemy.type = enemyType

    local stats =
        EnemyTypes[enemyType]

    wave = wave or 1


    enemy.x = x
    enemy.y = y

    enemy.width =
        stats.width

    enemy.height =
        stats.height

    enemy.color =
        stats.color


    -- ESCALADO DE DIFICULTAD

local healthMultiplier =
        1 + ((wave - 1) * 0.20)

    local damageMultiplier =
        1 + ((wave - 1) * 0.10)


    enemy.maxHealth =
        stats.maxHealth *
        healthMultiplier

    enemy.health =
        enemy.maxHealth


    enemy.damage =
        stats.damage *
        damageMultiplier

    enemy.speed =
        stats.speed

    enemy.attackCooldown = 1
    enemy.attackTimer = 0

    enemy.attackRange =
        stats.attackRange

    enemy.alive = true


    -- ESTADO DE MUERTE

enemy.dying = false
    enemy.deathTimer = 0
    enemy.deathDuration = 0.5


    -- FEEDBACK DE DAÑO

enemy.hitTimer = 0
    enemy.hitDuration = 0.20


    return enemy

end


-- ACTUALIZAR ENEMIGO

function Enemy.update(enemy, dt, player, enemies)

    if not enemy.alive then
        return
    end


    -- ESTADO DE MUERTE

if enemy.dying then

        enemy.deathTimer =
            enemy.deathTimer - dt


        if enemy.deathTimer <= 0 then

            enemy.deathTimer = 0

            enemy.dying = false
            enemy.alive = false

        end


        return

    end


    -- REDUCIR COOLDOWN DEL ATAQUE

if enemy.attackTimer > 0 then

        enemy.attackTimer =
            enemy.attackTimer - dt

    end


    if enemy.attackTimer < 0 then

        enemy.attackTimer = 0

    end



    -- FEEDBACK DE DAÑO

if enemy.hitTimer > 0 then

        enemy.hitTimer =
            enemy.hitTimer - dt

    end


    if enemy.hitTimer < 0 then

        enemy.hitTimer = 0

    end


    
    -- CALCULAR DIRECCIÓN HACIA EL JUGADOR

local dx =
        player.x - enemy.x

    local dy =
        player.y - enemy.y

    local distance =
        math.sqrt(dx * dx + dy * dy)


    
    -- MOVERSE HACIA EL JUGADOR

if distance > enemy.attackRange then

        enemy.x =
            enemy.x +
            (dx / distance) *
            enemy.speed *
            dt

        enemy.y =
            enemy.y +
            (dy / distance) *
            enemy.speed *
            dt

    end


    
    -- SEPARACIÓN ENTRE ENEMIGOS

if enemies then

        for _, other in ipairs(enemies) do

            if other ~= enemy
                and other.alive
                and not other.dying then

                local separationX =
                    enemy.x - other.x

                local separationY =
                    enemy.y - other.y

                local separationDistance =
                    math.sqrt(
                        separationX * separationX +
                        separationY * separationY
                    )


                local minimumDistance =
                    (enemy.width + other.width) / 2 + 10


                if separationDistance > 0
                    and separationDistance < minimumDistance then

                    local push =
                        (minimumDistance - separationDistance) * 0.5


                    enemy.x =
                        enemy.x +
                        (separationX / separationDistance) *
                        push

                    enemy.y =
                        enemy.y +
                        (separationY / separationDistance) *
                        push

                end

            end

        end

    end

    
    -- COMPROBAR RANGO DE ATAQUE

if distance <= enemy.attackRange
        and enemy.attackTimer <= 0 then

        player.takeDamage(
            enemy.damage
        )

        enemy.attackTimer =
            enemy.attackCooldown

    end

end



-- RECIBIR DAÑO

function Enemy.takeDamage(enemy, damage, player)

    if not enemy.alive or enemy.dying then
        return
    end


    
    -- QUITAR VIDA

enemy.health =
        enemy.health - damage


    
    -- ACTIVAR EFECTO DE GOLPE

enemy.hitTimer =
        enemy.hitDuration


    
    -- KNOCKBACK

if player then

        local dx =
            enemy.x - player.x

        local dy =
            enemy.y - player.y

        local distance =
            math.sqrt(dx * dx + dy * dy)


        if distance > 0 then

            local knockback = 30

            enemy.x =
                enemy.x +
                (dx / distance) * knockback

            enemy.y =
                enemy.y +
                (dy / distance) * knockback

        end

    end


    
    -- COMPROBAR MUERTE

if enemy.health <= 0 then

        enemy.health = 0

        enemy.dying = true

        enemy.deathTimer =
            enemy.deathDuration

    end

end



-- DIBUJAR ENEMIGO

function Enemy.draw(enemy)

    if not enemy.alive then
        return
    end


    
    -- EFECTO DE MUERTE

local deathScale = 1
    local deathAlpha = 1


    if enemy.dying then

        deathScale =
            enemy.deathTimer /
            enemy.deathDuration

        deathAlpha =
            deathScale

    end



    -- CENTRO DEL ENEMIGO

    local centerX =
        enemy.x + enemy.width / 2

    local centerY =
        enemy.y + enemy.height / 2


    -- COLOR DEL ENEMIGO

    if enemy.hitTimer > 0 then

        love.graphics.setColor(
            1,
            1,
            1,
            deathAlpha
        )

    else

        love.graphics.setColor(
            enemy.color[1],
            enemy.color[2],
            enemy.color[3],
            deathAlpha
        )

    end


    -- DIBUJAR CUERPO

    love.graphics.rectangle(
        "fill",
        centerX -
            (enemy.width * deathScale) / 2,

        centerY -
            (enemy.height * deathScale) / 2,

        enemy.width * deathScale,
        enemy.height * deathScale
    )


    -- RANGO DE ATAQUE

    if not enemy.dying then

        love.graphics.setColor(
            1,
            1,
            1,
            0.2
        )

        love.graphics.circle(
            "line",
            centerX,
            centerY,
            enemy.attackRange
        )

    end


    -- RESTAURAR COLOR

    love.graphics.setColor(
        1,
        1,
        1
    )


    -- TIPO DE ENEMIGO

    love.graphics.print(
        enemy.type,
        enemy.x,
        enemy.y - 25
    )


    -- BARRA DE VIDA

    local healthPercentage =
        enemy.health / enemy.maxHealth


    love.graphics.setColor(
        0.2,
        0.2,
        0.2
    )


    love.graphics.rectangle(
        "fill",
        enemy.x,
        enemy.y - 10,
        enemy.width,
        5
    )


    love.graphics.setColor(
        0.2,
        1,
        0.2
    )


    love.graphics.rectangle(
        "fill",
        enemy.x,
        enemy.y - 10,
        enemy.width * healthPercentage,
        5
    )


    love.graphics.setColor(
        1,
        1,
        1
    )

end


return Enemy