local Wave = {}

Wave.current = 1
Wave.maxWaves = 10
Wave.maxReached = 1


-- CANTIDAD DE ENEMIGOS

function Wave.getEnemyCount()

    --OLEADA DEL JEFE 
    if Wave.current == 10 then 

        return 0
    end

    return math.min(Wave.current, 4)

end


-- TIPO DE ENEMIGO

function Wave.getEnemyType(index)

    -- OLEADA 1
    -- 1 enemigo básico

    if Wave.current == 1 then

        return "basic"

    end


    -- OLEADA 2
    -- 1 básico
    -- 1 rápido

    if Wave.current == 2 then

        if index == 1 then

            return "basic"

        else

            return "fast"

        end

    end


    -- OLEADA 3
    -- 2 básicos
    -- 1 rápido

    if Wave.current == 3 then

        if index == 3 then

            return "fast"

        else

            return "basic"

        end

    end

    if Wave.current >= 4 and Wave.current <= 9 then

        if index % 3 == 0 then

            return "fast"

        else

            return "basic"

        end

    end

    if Wave.current == 10 then

        return nil

    end


    -- VALOR POR DEFECTO

    return "basic"

end


-- SIGUIENTE OLEADA

function Wave.next()

    Wave.current =
        Wave.current + 1

    if Wave.current <= Wave.maxWaves then
        
        if Wave.current > Wave.maxReached then

        Wave.maxReached =
        Wave.current 

        end

    end

end


-- COMPROBAR SI TERMINÓ

function Wave.isFinished()

    return Wave.current >
        Wave.maxWaves

end


return Wave