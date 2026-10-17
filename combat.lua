local Combat = {}
local Events = require("events")


-- OBTENER ÁREA DE ATAQUE

function Combat.getAttackArea(player)

    local attackX = player.x
    local attackY = player.y

    local attackWidth = player.width
    local attackHeight = player.height


    if player.direction == "right" then

        attackX = player.x + player.width
        attackWidth = player.attackRange


    elseif player.direction == "left" then

        attackX = player.x - player.attackRange
        attackWidth = player.attackRange


    elseif player.direction == "down" then

        attackY = player.y + player.height
        attackHeight = player.attackRange


    elseif player.direction == "up" then

        attackY = player.y - player.attackRange
        attackHeight = player.attackRange

    end


    return
        attackX,
        attackY,
        attackWidth,
        attackHeight

end


-- COMPROBAR COLISIÓN

function Combat.checkCollision(
    attackX,
    attackY,
    attackWidth,
    attackHeight,
    enemy
)

    return
        attackX < enemy.x + enemy.width
        and attackX + attackWidth > enemy.x
        and attackY < enemy.y + enemy.height
        and attackY + attackHeight > enemy.y

end


-- INICIAR ATAQUE

function Combat.attack(player, enemies, Enemy)

    -- No permite atacar si el jugador esta muerto 

    if player.health <= 0 then

        return

    end


    if not player.attack() then

        return

    end


    -- El ataque queda pendiente
    -- hasta que llegue el frame del golpe

    player.attackPending = true

end


-- APLICAR DAÑO DEL ATAQUE

function Combat.applyAttackDamage(
    player,
    enemies,
    Enemy
)

    if not player.attackPending then

        return

    end


    local attackX,
          attackY,
          attackWidth,
          attackHeight =
        Combat.getAttackArea(player)



    -- COMPROBAR TODOS LOS ENEMIGOS

    for _, enemy in ipairs(enemies) do

        if enemy.alive then

            local collision =
                Combat.checkCollision(
                    attackX,
                    attackY,
                    attackWidth,
                    attackHeight,
                    enemy
                )


            if collision then

                Enemy.takeDamage(
                    enemy,
                    player.damage,
                    player
                )

                -- Prototipo 3: evento personalizado de impacto 

                Events.emit("enemy_hit", {
                    damage = player.damage,
                    enemyHealth = enemy.health,
                    x = enemy.x,
                    y = enemy.y,
                    enemy = enemy
                })

            end

        end

    end


    -- El ataque ya aplico el daño 

    player.attackPending = false

end


return Combat