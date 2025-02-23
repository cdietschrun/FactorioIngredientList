local item_sprites = {"inserter", "transport-belt", "stone-furnace", "assembling-machine-3", "logistic-chest-storage", "sulfur", "utility-science-pack", "laser-turret"}

-- Make sure the intro cinematic of freeplay doesn't play every time we restart
-- This is just for convenience, don't worry if you don't understand how this works
script.on_init(function()
    local freeplay = remote.interfaces["freeplay"]
    if freeplay then  -- Disable freeplay popup-message
        if freeplay["set_skip_intro"] then remote.call("freeplay", "set_skip_intro", true) end
        if freeplay["set_disable_crashsite"] then remote.call("freeplay", "set_disable_crashsite", true) end
    end

    storage.players = {}
end)

script.on_event(defines.events.on_player_created, function (event)
    local player = game.get_player(event.player_index)
    
    game.print("player index: "..player.index)
    storage.players[player.index] = { controls_active = true, button_count = 0 } 

    local screen_element = player.gui.screen
    local main_frame = screen_element.add{type="frame", name="il_main_frame", caption={"il.hello_world"}}
    main_frame.style.size = {385, 165}
    main_frame.auto_center = true

    local content_frame = main_frame.add{type="frame", name="content_frame", direction="vertical", style="il_content_frame"}
    local controls_flow = content_frame.add{type="flow", name="controls_flow", direction="horizontal", style="il_controls_flow"}

    controls_flow.add{type="button", name="il_controls_toggle", caption={"il.deactivate"}}
    controls_flow.add{type="slider", name="il_controls_slider", value=0, minimum_value=0, maximum_value=#item_sprites, style="notched_slider"}
    controls_flow.add{type="textfield", name="il_controls_textfield", text="0", numeric=true, allow_decimal=false, allow_negative=false, style="il_controls_textfield"}
end)

script.on_event(defines.events.on_gui_click, function (event)
    if event.element.name == "il_controls_toggle" then
        local player_storage = storage.players[event.player_index]
        player_storage.controls_active = not player_storage.controls_active

        local controls_toggle = event.element
        controls_toggle.caption = (player_storage.controls_active) and {"il.deactivate"} or {"il.activate"}

        local player = game.get_player(event.player_index)
        local controls_flow = player.gui.screen.il_main_frame.content_frame.controls_flow
        controls_flow.il_controls_slider.enabled = player_storage.controls_active
        controls_flow.il_controls_textfield.enabled = player_storage.controls_active
    end
end)

script.on_event(defines.events.on_gui_value_changed, function(event)
    if event.element.name == "il_controls_slider" then
        local player = game.get_player(event.player_index)
        local player_global = storage.players[player.index]

        local new_button_count = event.element.slider_value
        player_global.button_count = new_button_count

        local controls_flow = player.gui.screen.il_main_frame.content_frame.controls_flow
        controls_flow.il_controls_textfield.text = tostring(new_button_count)
    end
end)

script.on_event(defines.events.on_gui_text_changed, function(event)
    if event.element.name == "il_controls_textfield" then
        local player = game.get_player(event.player_index)
        local player_global = storage.players[player.index]

        local new_button_count = tonumber(event.element.text) or 0
        local capped_button_count = math.min(new_button_count, #item_sprites)
        player_global.button_count = capped_button_count

        local controls_flow = player.gui.screen.il_main_frame.content_frame.controls_flow
        controls_flow.il_controls_slider.slider_value = capped_button_count
    end
end)