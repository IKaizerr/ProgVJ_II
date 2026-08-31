local Game = {}


Game.PLAYING = "PLAYING"
Game.UPGRADE = "UPGRADE"
Game.VICTORY = "VICTORY"
Game.GAME_OVER = "GAME_OVER"
Game.PAUSED = "PAUSED"


Game.state = Game.PLAYING


function Game.setState(newState)

    Game.state = newState

end


function Game.isPlaying()

    return Game.state == Game.PLAYING

end


function Game.isUpgrade()

    return Game.state == Game.UPGRADE

end


function Game.isVictory()

    return Game.state == Game.VICTORY

end


function Game.isGameOver()

    return Game.state == Game.GAME_OVER

end


    function Game.isPaused()

        return Game.state == Game.PAUSED

    end


return Game