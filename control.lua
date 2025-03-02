local function clamp(value)
    return math.max(0, math.min(1, value))
end

local function build_sprite_buttons(player, recipe)
    local player_storage = storage.players[player.index]

    local button_table = player_storage.elements.main_frame.content_frame.button_frame.button_table
    button_table.clear()

    -- local number_of_buttons = player_storage.button_count
    -- for i = 1, number_of_buttons do
    --     local sprite_name = item_sprites[i]
    --     local button_style = (sprite_name == player_storage.selected_item) and "yellow_slot_button" or "slot_button"
    --     button_table.add{type="sprite-button", sprite=("item/" .. sprite_name), tags={action="iw_select_button", item_name=sprite_name}, style=button_style}
    -- end

    for _, ingredient in ipairs(recipe.ingredients) do
        game.print("ingredient type: " .. ingredient.type)
        game.print("ingredient name: " .. ingredient.name)
        game.print("ingredient amount: " .. ingredient.amount)
        button_table.add{type="sprite-button", sprite=("item/" .. ingredient.name), style="slot_button"}
        local progress_str = game.get_player(player.index).character.get_item_count(ingredient.name) .. "/" .. ingredient.amount 
        button_table.add{type="label", caption=progress_str}
        local progress_value = 0
        progress_value = clamp(game.get_player(player.index).character.get_item_count(ingredient.name) / ingredient.amount)
        button_table.add{type="progressbar", value=progress_value}
    end
end

local function initialize_storage(player)
    game.print("player index: "..player.index)
    storage.players[player.index] = { elements = {} } 
end

local function build_interface(player, recipe)
    local player_storage = storage.players[player.index]

    local screen_element = player.gui.screen
    local main_frame = screen_element.add{type="frame", name="iw_main_frame", caption={"il.hello_world"}}
    main_frame.style.size = {385, 165}

    -- player.opened = main_frame
    player_storage.elements.main_frame = main_frame

    main_frame.add{type="sprite-button", style="frame_action_button", name="iw_close_button", tooltip = {"closers"}, sprite="utility/close"}
    local content_frame = main_frame.add{type="frame", name="content_frame", direction="vertical", style="iw_content_frame"}

    local button_frame = content_frame.add{type="frame", name="button_frame", direction="horizontal", style="iw_deep_frame"}
    local button_table = button_frame.add{type="table", name="button_table", column_count=3, style="filter_slot_table", draw_horizontal_lines=true, draw_vertical_lines=true}
    player_storage.elements.button = button_table

    build_sprite_buttons(player, recipe)
end

local function toggle_interface(player, recipe)
    -- if there are other root elements added, we have to remote them here too 
    recipe = recipe or {}
    local player_storage = storage.players[player.index]
    local main_frame = player_storage.elements.main_frame

    if main_frame == nil then
        build_interface(player, recipe)
    else
        main_frame.destroy()
        player_storage.elements = {}
    end
end

script.on_event("iw_toggle", function (event)
    game.print("input name: " .. event.input_name)
    game.print("event name: " .. event.name)
    
    local player_storage = storage.players[event.player_index]
    local main_frame = player_storage.elements.main_frame
    if main_frame ~= nil then
        main_frame.destroy()
        player_storage.elements = {} 
    end

    if event.selected_prototype then
        game.print("selected prototype name: " .. event.selected_prototype.name)
        game.print("selected prototype base type: " .. event.selected_prototype.base_type)
        game.print("selected prototype derived type: " .. event.selected_prototype.derived_type)
        if event.selected_prototype.base_type == "recipe" then
            game.print(game.get_player(event.player_index).character.get_item_count(event.selected_prototype.name))
            local recipe = prototypes.recipe[event.selected_prototype.name]
            game.print("recipe object_name: " .. recipe.object_name)
            game.print("recipe name: " .. recipe.name)
            game.print("recipe energy: " .. recipe.energy)
            game.print("recipe # ingredients: " .. #recipe.ingredients)
            for _, ingredient in ipairs(recipe.ingredients) do
                game.print("ingredient type: " .. ingredient.type)
                game.print("ingredient name: " .. ingredient.name)
                game.print("ingredient amount: " .. ingredient.amount)
            end

            local player = game.get_player(event.player_index)
            toggle_interface(player, recipe)
        end
    end
end)

-- Make sure the intro cinematic of freeplay doesn't play every time we restart
-- This is just for convenience, don't worry if you don't understand how this works
script.on_init(function()
    local freeplay = remote.interfaces["freeplay"]
    if freeplay then  -- Disable freeplay popup-message
        if freeplay["set_skip_intro"] then remote.call("freeplay", "set_skip_intro", true) end
        if freeplay["set_disable_crashsite"] then remote.call("freeplay", "set_disable_crashsite", true) end
    end

    storage.players = {}

    for _, player in pairs(game.players) do
        initialize_storage(player)
    end
end)

-- custom input prototype with selected prototype mode on, bind it to leftclick, when it triggers check if the crafting gui open, 
-- then if it matches flag the player to be checked during the next tick (since custom input events fire before the game processes them for guis and such)
-- and if during the next tick that item is not in the queue the player failed to craft it (assuming the recipe wasn't done within 1 tick)

script.on_event(defines.events.on_pre_player_crafted_item, function (event)
    game.print("pre_craft: "..event.recipe.name)    
end)

script.on_event(defines.events.on_player_created, function (event)
    local player = game.get_player(event.player_index)

    initialize_storage(player)
end)

script.on_event(defines.events.on_gui_click, function (event)
    game.print("event: " .. event.name)
    game.print("element: " .. event.element.name)

    if event.element.name == "iw_close_button" then

        game.print("close")
        -- local player_storage = storage.players[event.player_index]
        toggle_interface(game.get_player(event.player_index))
        -- player_storage.controls_active = not player_storage.controls_active

        -- local controls_toggle = event.element
        -- controls_toggle.caption = (player_storage.controls_active) and {"il.deactivate"} or {"il.activate"}

        -- player_storage.elements.controls_slider.enabled = player_storage.controls_active
        -- player_storage.elements.controls_textfield.enabled = player_storage.controls_active

        -- build_sprite_buttons(player)
    -- elseif event.element.tags.action == "iw_select_button" then
    --     local player = game.get_player(event.player_index)
    --     local player_storage = storage.players[player.index]

    --     local clicked_item_name = event.element.tags.item_name
    --     player_storage.selected_item = clicked_item_name

    --     build_sprite_buttons(player)
    -- else
    --     game.print("event: " .. event.name)
    --     game.print("element: " .. event.element.name)
    end
end)

-- script.on_event(defines.events.on_gui_value_changed, function(event)
--     if event.element.name == "iw_controls_slider" then
--         local player = game.get_player(event.player_index)
--         local player_storage = storage.players[player.index]

--         local new_button_count = event.element.slider_value
--         player_storage.button_count = new_button_count

--         local controls_flow = player_storage.elements.main_frame.content_frame.controls_flow
--         controls_flow.iw_controls_textfield.text = tostring(new_button_count)

--         build_sprite_buttons(player)
--     end
-- end)

script.on_event(defines.events.on_player_removed, function (event)
    storage.players[event.player_index] = nil
end)

script.on_event(defines.events.on_gui_closed, function (event)
    if event.element and event.element.name == "iw_main_frame" then
        local player = game.get_player(event.player_index)
        toggle_interface(player)
    end
end)

script.on_configuration_changed(function(config_changed_data)
    if config_changed_data.mod_changes["ingredient-list"] then
        for _, player in pairs(game.players) do
            local player_storage = storage.players[player.index]
            local main_frame = player_storage.elements.main_frame
            if main_frame ~= nil then toggle_interface(player) end
        end
    end
end)