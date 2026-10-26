local Upgrade = {}


-- OPCIONES ACTUALES

Upgrade.currentChoices = {}


-- LISTA DE MEJORAS

Upgrade.list = {

    -- 1. DAÑO

    {
        name = "Daño +20",
        descripcion = "Aumenta el daño del jugador en 20 puntos.",

        apply = function(player)

            player.damage =
                player.damage + 20

        end
    },


    -- 2. VELOCIDAD

    {
        name = "Velocidad +20",
        descripcion = "Aumenta la velocidad del jugador en 20 puntos.",

        apply = function(player)

            player.speed =
                player.speed + 20

        end
    },


    -- 3. VIDA MÁXIMA

    {
        name = "Vida maxima +50",
        descripcion = "Aumenta la vida máxima del jugador en 50 puntos.",
        
        apply = function(player)

            player.maxHealth =
                player.maxHealth + 50

            player.health =
                player.maxHealth

        end
    },


    -- 4. RANGO DE ATAQUE

    {
        name = "Rango de ataque +10",
        descripcion = "Aumenta el rango de ataque del jugador en 10 puntos.",

        apply = function(player)

            player.attackRange =
                player.attackRange + 10

        end
    },


    -- 5. COOLDOWN DE ATAQUE

    {
        name = "Cooldown de ataque -0.1",
        descripcion = "Reduce el tiempo de espera entre ataques en 0.1 segundos.",

        apply = function(player)

            player.attackCooldown =
                player.attackCooldown - 0.1


            -- Evitar que el cooldown llegue a valores absurdamente bajos

            if player.attackCooldown < 0.1 then

                player.attackCooldown = 0.1

            end

        end
    }

}


-- GENERAR OPCIONES ALEATORIAS

function Upgrade.generateChoices()

    Upgrade.currentChoices = {}

    local available = {}


    -- Copiar todas las mejoras disponibles

    for i = 1, #Upgrade.list do

        table.insert(
            available,
            i
        )

    end


    -- Elegir 3 mejoras diferentes

    for i = 1, 3 do

        local randomIndex =
            math.random(
                1,
                #available
            )


        local choice =
            table.remove(
                available,
                randomIndex
            )


        table.insert(
            Upgrade.currentChoices,
            choice
        )

    end

end


-- APLICAR MEJORA

function Upgrade.apply(choice, player)

    local upgradeIndex =
        Upgrade.currentChoices[choice]


    if not upgradeIndex then
        return
    end


    local upgrade =
        Upgrade.list[upgradeIndex]


    if upgrade then

        upgrade.apply(player)

    end

end


-- OBTENER NOMBRE DE MEJORA

function Upgrade.getName(choice)

    local upgradeIndex =
        Upgrade.currentChoices[choice]


    if not upgradeIndex then
        return ""
    end


    local upgrade =
        Upgrade.list[upgradeIndex]


    if upgrade then

        return upgrade.name

    end


    return ""

end


-- OBTENER DESCRIPCIÓN DE MEJORA

function Upgrade.getDescription(choice)

    local upgradeIndex =
        Upgrade.currentChoices[choice]


    if not upgradeIndex then
        return ""
    end


    local upgrade =
        Upgrade.list[upgradeIndex]


    if upgrade then

        return upgrade.descripcion

    end


    return ""

end


return Upgrade