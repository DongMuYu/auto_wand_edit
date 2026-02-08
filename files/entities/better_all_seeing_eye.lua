local entity_id = GetUpdatedEntityID()

-- 始终启用照明和移除战争迷雾
local lighting = 1
local fog_of_war_removing = 1

ComponentSetValue2( EntityGetFirstComponent( entity_id, "LightComponent" ), "mAlpha", lighting )
ComponentSetValue2( EntityGetFirstComponent( entity_id, "SpriteComponent" ), "alpha", fog_of_war_removing )