local Events = {}

Events.listeners = {}


function Events.on(eventName, callback)

    if not Events.listeners[eventName] then

        Events.listeners[eventName] = {}

    end


    table.insert(
        Events.listeners[eventName],
        callback
    )

end


function Events.emit(eventName, data)

    local listeners =
        Events.listeners[eventName]


    if not listeners then
        return
    end


    for _, callback in ipairs(listeners) do

        callback(data)

    end

end


return Events