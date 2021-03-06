-- (C) 2016 Tai "DuCake" Kedzierski

-- This program is Free Software, you can modify and redistribute it as long as
-- that you provide the same rights to whomever you provide the original or
-- modified version of the software to, and provide the source to whomever you
-- distribute the software to.
-- Released under the terms of the GPLv3


bbattle = {}

bbattle.radius = tonumber(minetest.setting_get("buildbattle.radius") ) or 16 -- NE PAS modifier ici - modifier le minetest.conf
bbattle.mods = minetest.setting_get("buildbattle.mods") or "default,flowers,bones,doors,"..
	"farming,stairs,vessels,walls,xpanes,moreblocks,moretrees,moreores"
bbattle.forbidden = minetest.setting_get("buildbattle.forbidden") or "moreblocks:circular_saw,default:book_closed,default:book_open"

bbattle.mods = bbattle.mods:split(",")
bbattle.forbidden = bbattle.forbidden:split(",")

local function is_in_array(item,array)
	for k,v in pairs(array) do
		if v == item then
			return true
		end
	end
	return false
end

local is_in_bbfield = function(pos)
	local mcount = minetest.find_nodes_in_area(
	{x=pos.x-bbattle.radius,y=pos.y-bbattle.radius,z=pos.z-bbattle.radius},
	{x=pos.x+bbattle.radius,y=pos.y+bbattle.radius,z=pos.z+bbattle.radius},
	{"build_battle:marker"}
	)

	return #mcount > 0
end


local battlefy = function(name)
	return "build_battle:"..name:gsub(":","_")
end

local battlize = function(name)
	if type(name) == "string" then
		return battlefy(name)
	elseif type(name) == "table" then
		local newnames = {}
		for key,value in pairs(name) do
			newnames[#newnames+1] = battlefy(key)
		end
		return newnames
	else
		return name
	end
			
end

local function deepclone (t) -- deep-copy a table -- from https://gist.github.com/MihailJP/3931841
	if type(t) ~= "table" then return t end

	local target = {}
	
	for k, v in pairs(t) do
		if k ~= "__index" and type(v) == "table" then -- omit circular reference
			target[k] = deepclone(v)
		else
			target[k] = v
		end
	end
	return target
end 

minetest.register_on_placenode( function(pos, newnode, placer, oldnode, itemstack, pointed_thing)
	local node = newnode.name
	if not node:find("build_battle:") then return end

	if not is_in_bbfield(pos) then
		minetest.chat_send_player(placer:get_player_name(),node.." can only be placed in a Build Battle Arena!")
		minetest.swap_node(pos,{name = oldnode.name})
		return true
	end
end
)

for oldnode,olddef in pairs(minetest.registered_nodes) do
	local nodeparts = oldnode:split(":")
	if not oldnode:find("build_battle:")
			and is_in_array(nodeparts[1],bbattle.mods)
			and not is_in_array(oldnode,bbattle.forbidden) then
		
		local node = battlize(oldnode)
		local def = deepclone(olddef)

		def.on_place = nil -- Defining on_place prevents on_placenode handlers from being called

		def.drop = node
		local desc = def.description or "("..oldnode..")"
		def.description = desc.." +"
		
		if def.liquid_alternative_flowing or def.liquid_alternative_source then
			def.liquid_alternative_flowing = node:gsub("_source","_flowing")
			def.liquid_alternative_source = node:gsub("_flowing","_source")
		end

		if def.groups == nil then def.groups = {} end
		def.groups.not_in_creative_inventory = 1

		minetest.register_node(node,def)
		if not minetest.registered_nodes[node] then
			minetest.log("info", "BB - Failed to register "..node) -- not error, these may show in client window
		end
	end
end

minetest.register_node("build_battle:marker", {
	description = "Build Battle Marker",
	tiles = {
			"moreblocks_circle_stone_bricks_.png",
			"moreblocks_circle_stone_bricks_.png",
			"build_battle_protec.png^protector_logo.png"
				},
	groups = {unbreakable = 1}
})

dofile(minetest.get_modpath("build_battle").."/api.lua")
dofile(minetest.get_modpath("build_battle").."/buildbook.lua")
dofile(minetest.get_modpath("build_battle").."/areas.lua")
