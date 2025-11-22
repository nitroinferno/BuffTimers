local API_VERSION = 1

local customEffects = {}

local API = {}

--- Get the API version.
--- @return number The API version
function API.getVersion()
    return API_VERSION
end

--- Registers a new custom spell effect handler.
--- @param predicate function Predicate function for matching spells that need special handling
--- @param factory function Factory function to create custom effects for UI
function API.registerCustomEffect(predicate, factory)
    table.insert(customEffects, {
        predicate = predicate,
        factory = factory,
    })
end

--- Get custom effects for the spell, if applicable
--- @param spell table The active spell object
--- @return table? List of effects to render, or nil if no match
function API.getCustomEffects(spell)
    for _, effects in ipairs(customEffects) do
        if effects.predicate(spell) then
            return effects.factory(spell)
        end
    end
    return nil
end

return {
    interface = API,
}
