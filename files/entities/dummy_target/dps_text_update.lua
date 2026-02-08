dofile_once( "data/scripts/lib/utilities.lua" )
dofile_once( "mods/auto_wand_edit/files/lib/helper.lua" )

local entity_id = GetUpdatedEntityID()
local parent_id = EntityGetParent( entity_id )

local dps_comp = get_variable_storage_component( parent_id, "auto_wand_edit_current_dps" )
local dps = ComponentGetValue2( dps_comp, "value_float" )
ComponentSetValue2( dps_comp, "value_float", 0 )
local sprite_comp = EntityGetFirstComponent( entity_id, "SpriteComponent", "auto_wand_edit_dps" )
if sprite_comp then
	local text = format_damage( dps, ModSettingGet( "auto_wand_edit.dummy_target_show_full_damage_number" ), "i" )
	ComponentSetValue2( sprite_comp, "offset_x", center_text( text ) )
	ComponentSetValue2( sprite_comp, "text", text )
	EntityRefreshSprite( entity_id, sprite_comp )
end

local highest_dps_comp = get_variable_storage_component( parent_id, "auto_wand_edit_highest_dps" )
local highest_dps = ComponentGetValue2( highest_dps_comp, "value_float" )
local sprite_comp = EntityGetFirstComponent( entity_id, "SpriteComponent", "auto_wand_edit_highest_dps" )
if sprite_comp then
	local text = format_damage( highest_dps, ModSettingGet( "auto_wand_edit.dummy_target_show_full_damage_number" ), "i" )
	ComponentSetValue2( sprite_comp, "offset_x", center_text( text ) )
	ComponentSetValue2( sprite_comp, "text", text )
	EntityRefreshSprite( entity_id, sprite_comp )
end

-- EntitySetComponentIsEnabled( entity_id, GetUpdatedComponentID(), false )