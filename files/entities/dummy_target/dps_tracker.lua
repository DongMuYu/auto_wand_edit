dofile_once( "mods/auto_wand_edit/files/lib/helper.lua" )
dofile_once( "mods/auto_wand_edit/files/lib/variables.lua" )
dofile_once( "data/scripts/lib/utilities.lua" )

local function get_variable_storage_component( entity_id, name )
	local components = EntityGetComponent( entity_id, "VariableStorageComponent" ) or {}
	for _, component in ipairs( components ) do
		if ComponentGetValue2( component, "name" ) == name then
			return component
		end
	end
	return nil
end

local function set_text( entity_id, tag_sprite, value, offset_y )
	local child_id = ( EntityGetAllChildren( entity_id, "auto_wand_edit_dummy_target_child" ) or {} )[1]
	if not EntityGetIsAlive( child_id ) then return end
	local sprite_comp = EntityGetFirstComponent( child_id, "SpriteComponent", tag_sprite )
	if not sprite_comp then return end
	local text = format_damage( value, not ModSettingGet( "auto_wand_edit.dummy_target_show_full_damage_number" ), "i" )
	ComponentSetValue2( sprite_comp, "offset_x", center_text( text ) )
	ComponentSetValue2( sprite_comp, "text", text )
	EntityRefreshSprite( entity_id, sprite_comp )
end

function damage_received( damage, message, entity_thats_responsible, is_fatal )
	local now = GameGetFrameNum()
	local entity_id = GetUpdatedEntityID()
	
	local last_hit_frame_comp = get_variable_storage_component( entity_id, "auto_wand_edit_last_hit_frame" )
	if last_hit_frame_comp == nil then
		return
	end
	
	local last_hit_frame = ComponentGetValue2( last_hit_frame_comp, "value_int" ) or 0
	ComponentSetValue2( last_hit_frame_comp, "value_int", now )
	local reset = ( now - last_hit_frame > 180 )

	local first_hit_frame_comp = get_variable_storage_component( entity_id, "auto_wand_edit_first_hit_frame" )
	if first_hit_frame_comp == nil then
		GamePrint("ERROR: first_hit_frame_comp is nil!")
		return
	end
	
	local first_hit_frame = ComponentGetValue2( first_hit_frame_comp, "value_int" ) or now
	if reset then
		ComponentSetValue2( first_hit_frame_comp, "value_int", now )
		first_hit_frame = now
	end

	local current_dps_comp = get_variable_storage_component( entity_id, "auto_wand_edit_current_dps" )
	if current_dps_comp == nil then
		GamePrint("ERROR: current_dps_comp is nil!")
		return
	end
	
	local current_dps = ComponentGetValue2( current_dps_comp, "value_float" ) or 0
	current_dps = current_dps + damage
	ComponentSetValue2( current_dps_comp, "value_float", current_dps )

	local highest_dps_comp = get_variable_storage_component( entity_id, "auto_wand_edit_highest_dps" )
	if highest_dps_comp == nil then
		GamePrint("ERROR: highest_dps_comp is nil!")
		return
	end
	
	local highest_dps = reset and 0 or (ComponentGetValue2( highest_dps_comp, "value_float" ) or 0)
	if current_dps > highest_dps then
		ComponentSetValue2( highest_dps_comp, "value_float", current_dps )
	end
	
	local total_damage_comp = get_variable_storage_component( entity_id, "auto_wand_edit_total_damage" )
	if total_damage_comp == nil then
		GamePrint("ERROR: total_damage_comp is nil!")
		return
	end
	
	local total_damage = ( reset and 0 or (ComponentGetValue2( total_damage_comp, "value_float" ) or 0) ) + damage
	ComponentSetValue2( total_damage_comp, "value_float", total_damage )
	-- GamePrint("Total damage recorded: " .. total_damage)
	set_text( entity_id, "auto_wand_edit_total_damage", total_damage )

	local average_dps = total_damage / ( now - first_hit_frame + 1 ) * 60
	set_text( entity_id, "auto_wand_edit_average_dps", average_dps )

	local this_frame_damage_comp = get_variable_storage_component( entity_id, "auto_wand_edit_last_frame_damage" )
	if this_frame_damage_comp == nil then
		GamePrint("ERROR: this_frame_damage_comp is nil!")
		return
	end
	
	local this_frame_damage = GameGetFrameNum() == last_hit_frame
		and ComponentGetValue2( this_frame_damage_comp, "value_float" ) or 0
	this_frame_damage = this_frame_damage + damage
	ComponentSetValue2( this_frame_damage_comp, "value_float", this_frame_damage )
	set_text( entity_id, "auto_wand_edit_last_frame_damage", this_frame_damage )

	local child_id = EntityGetAllChildren( entity_id, "auto_wand_edit_dummy_target_child" )
	if EntityGetIsAlive( child_id ) then
		EntitySetComponentsWithTagEnabled( child_id, "invincible", true )
	end
endid = EntityGetAllChildren( entity_id, "auto_wand_edit_dummy_target_child" )
	if EntityGetIsAlive( child_id ) then
		EntitySetComponentsWithTagEnabled( child_id, "invincible", true )
	end
end