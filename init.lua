
-- init.lua
-- bees + candles minetest mod, by rickmcfarley
-- Copyright (C) Rick McFarley 2015 <rickmcfarley@gmail.com>
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful, but
-- WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
-- See the GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>


-- It's really just a mix of the bees mod by Bas080 https://github.com/bas080/bees
-- and the candles mod by darkrose https://github.com/darkrose/minetest_mods/tree/master/candles
-- I replaced bees: and candles: with bees_candles:
-- It is all of the bees mod and most of the candles mod.


--The below code (until line 818) was copied from:
--Bees
------
--Author	Bas080
--Version	2.2
--License	WTFPL

--VARIABLES
  local bees = {}
  local formspecs = {}

--FUNCTIONS
  function formspecs.hive_wild(pos, grafting)
    local spos = pos.x .. ',' .. pos.y .. ',' ..pos.z
    local formspec =
      'size[8,9]'..
      'list[nodemeta:'.. spos .. ';combs;1.5,3;5,1;]'..
      'list[current_player;main;0,5;8,4;]'
    if grafting then
      formspec = formspec..'list[nodemeta:'.. spos .. ';queen;3.5,1;1,1;]'
    end
    return formspec
  end

  function formspecs.hive_artificial(pos)
    local spos = pos.x..','..pos.y..','..pos.z
    local formspec =
      'size[8,9]'..
      'list[nodemeta:'..spos..';queen;3.5,1;1,1;]'..
      'list[nodemeta:'..spos..';frames;0,3;8,1;]'..
      'list[current_player;main;0,5;8,4;]'
    return formspec
  end

  function bees.polinate_flower(pos, flower)
    local spawn_pos = { x=pos.x+math.random(-3,3) , y=pos.y+math.random(-3,3) , z=pos.z+math.random(-3,3) }
    local floor_pos = { x=spawn_pos.x , y=spawn_pos.y-1 , z=spawn_pos.z }
    local spawn = minetest.get_node(spawn_pos).name
    local floor = minetest.get_node(floor_pos).name
    if floor == 'default:dirt_with_grass' and spawn == 'air' then
      minetest.set_node(spawn_pos, {name=flower})
    end
  end

--NODES
  minetest.register_node('bees_candles:extractor', {
    description = 'honey extractor',
    tiles = {"bees_extractor.png", "bees_extractor.png", "bees_extractor.png", "bees_extractor.png", "bees_extractor.png", "bees_extractor_front.png"},
    paramtype2 = "facedir",
    groups = {choppy=2,oddly_breakable_by_hand=2,tubedevice=1,tubedevice_receiver=1},
    on_construct = function(pos, node)
      local meta = minetest.get_meta(pos)
      local inv  = meta:get_inventory()
      local pos = pos.x..','..pos.y..','..pos.z
      inv:set_size('frames_filled'  ,1)
      inv:set_size('frames_emptied' ,1)
      inv:set_size('bottles_empty'  ,1)
      inv:set_size('bottles_full' ,1)
      inv:set_size('wax',1)
      meta:set_string('formspec',
        'size[8,9]'..
        --input
        'list[nodemeta:'..pos..';frames_filled;2,1;1,1;]'..
        'list[nodemeta:'..pos..';bottles_empty;2,3;1,1;]'..
        --output
        'list[nodemeta:'..pos..';frames_emptied;5,0.5;1,1;]'..
        'list[nodemeta:'..pos..';wax;5,2;1,1;]'..
        'list[nodemeta:'..pos..';bottles_full;5,3.5;1,1;]'..
        --player inventory
        'list[current_player;main;0,5;8,4;]'
      )
    end,
    on_timer = function(pos, node)
      local meta = minetest.get_meta(pos)
      local inv  = meta:get_inventory()
      if not inv:contains_item('frames_filled','bees_candles:frame_full') or not inv:contains_item('bottles_empty','vessels:glass_bottle') then
        return
      end
      if inv:room_for_item('frames_emptied', 'bees_candles:frame_empty') 
      and inv:room_for_item('wax','bees_candles:wax') 
      and inv:room_for_item('bottles_full', 'bees_candles:bottle_honey') then
        --add to output
        inv:add_item('frames_emptied', 'bees_candles:frame_empty')
        inv:add_item('wax', 'bees_candles:wax')
        inv:add_item('bottles_full', 'bees_candles:bottle_honey')
        --remove from input
        inv:remove_item('bottles_empty','vessels:glass_bottle')
        inv:remove_item('frames_filled','bees_candles:frame_full')
        local p = {x=pos.x+math.random()-0.5, y=pos.y+math.random()-0.5, z=pos.z+math.random()-0.5}
        --wax flying all over the place
        minetest.add_particle({
          pos = {x=pos.x, y=pos.y, z=pos.z},
          velocity = {x=math.random(-4,4),y=math.random(8),z=math.random(-4,4)},
          acceleration = {x=0,y=-6,z=0},
          expirationtime = 2,
          size = math.random(1,3),
          collisiondetection = false,
          texture = 'bees_wax_particle.png',
        })
        local timer = minetest.get_node_timer(pos)
        timer:start(5)
      else
        local timer = minetest.get_node_timer(pos)
        timer:start(1) -- Try again in 1 second
      end
    end,
    tube = {
      insert_object = function(pos, node, stack, direction)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        local timer = minetest.get_node_timer(pos)
        if stack:get_name() == "bees_candles:frame_full" then
          if inv:is_empty("frames_filled") then
            timer:start(5)
          end
          return inv:add_item("frames_filled",stack)
        elseif stack:get_name() == "vessels:glass_bottle" then
          if inv:is_empty("bottles_empty") then
            timer:start(5)
          end
          return inv:add_item("bottles_empty",stack)
        end
        return stack
      end,
      can_insert = function(pos,node,stack,direction)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        if stack:get_name() == "bees_candles:frame_full" then
          return inv:room_for_item("frames_filled",stack)
        elseif stack:get_name() == "vessels:glass_bottle" then
          return inv:room_for_item("bottles_empty",stack)
        end
        return false
      end,
      input_inventory = {"frames_emptied", "bottles_full", "wax"},
      connect_sides = {left=1, right=1, back=1, front=1, bottom=1, top=1}
    },
    on_metadata_inventory_put = function(pos, listname, index, stack, player)
      local timer = minetest.get_node_timer(pos)
      local meta = minetest.get_meta(pos)
      local inv = meta:get_inventory()
      if inv:get_stack(listname, 1):get_count() == stack:get_count() then -- inv was empty -> start the timer
          timer:start(5) --create a honey bottle and empty frame and wax every 5 seconds
      end
    end,
    allow_metadata_inventory_put = function(pos, listname, index, stack, player)
      if (listname == 'bottles_empty' and stack:get_name() == 'vessels:glass_bottle') or (listname == 'frames_filled' and stack:get_name() == 'bees_candles:frame_full') then
        return stack:get_count()
      else
        return 0
      end  
    end,
    allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
      return 0
    end,
  })

  minetest.register_node('bees_candles:bees', {
    description = 'flying bees',
    drawtype = 'plantlike',
    paramtype = 'light',
    groups = { not_in_creative_inventory=1 },
    tiles = {
      {
        name='bees_strip.png', 
        animation={type='vertical_frames', aspect_w=16,aspect_h=16, length=2.0}
      }
    },
    damage_per_second = 1,
    walkable = false,
    buildable_to = true,
    pointable = false,
    on_punch = function(pos, node, puncher)
      local health = puncher:get_hp()
      puncher:set_hp(health-2)
    end,
  })

  minetest.register_node('bees_candles:hive_wild', {
    description = 'wild bee hive',
    tile_images = {'bees_hive_wild.png','bees_hive_wild.png','bees_hive_wild.png', 'bees_hive_wild.png', 'bees_hive_wild_bottom.png'}, --Neuromancer's base texture
    drawtype = 'nodebox',
    paramtype = 'light',
    paramtype2 = 'wallmounted',
    drop = {
      max_items = 6,
      items = {
        { items = {'bees_candles:honey_comb'}, rarity = 5}
      }
    },
    groups = {choppy=2,oddly_breakable_by_hand=2,flammable=3,attached_node=1},
    node_box = { --VanessaE's wild hive nodebox contribution
      type = 'fixed',
      fixed = {
        {-0.250000,-0.500000,-0.250000,0.250000,0.375000,0.250000}, --NodeBox 2
        {-0.312500,-0.375000,-0.312500,0.312500,0.250000,0.312500}, --NodeBox 4
        {-0.375000,-0.250000,-0.375000,0.375000,0.125000,0.375000}, --NodeBox 5
        {-0.062500,-0.500000,-0.062500,0.062500,0.500000,0.062500}, --NodeBox 6
      }
    },
    on_timer = function(pos)
      local meta = minetest.get_meta(pos)
      local inv  = meta:get_inventory()
      local timer= minetest.get_node_timer(pos)
      local rad  = 10
      local minp = {x=pos.x-rad, y=pos.y-rad, z=pos.z-rad}
      local maxp = {x=pos.x+rad, y=pos.y+rad, z=pos.z+rad}
      local flowers = minetest.find_nodes_in_area(minp, maxp, 'group:flower')
      if #flowers == 0 then 
        inv:set_stack('queen', 1, '')
        meta:set_string('infotext', 'this colony died, not enough flowers in area')
        return 
      end --not any flowers nearby The queen dies!
      if #flowers < 3 then return end --requires 2 or more flowers before can make honey
      local flower = flowers[math.random(#flowers)] 
      bees.polinate_flower(flower, minetest.get_node(flower).name)
      local stacks = inv:get_list('combs')
      for k, v in pairs(stacks) do
        if inv:get_stack('combs', k):is_empty() then --then replace that with a full one and reset pro..
          inv:set_stack('combs',k,'bees_candles:honey_comb')
          timer:start(1000/#flowers)
          return
        end
      end
      --what to do if all combs are filled
    end,
    on_construct = function(pos)
      minetest.get_node(pos).param2 = 0
      local meta = minetest.get_meta(pos)
      local inv  = meta:get_inventory()
      local timer = minetest.get_node_timer(pos)
      meta:set_int('agressive', 1)
      timer:start(100+math.random(100))
      inv:set_size('queen', 1)
      inv:set_size('combs', 5)
      inv:set_stack('queen', 1, 'bees_candles:queen')
      for i=1,math.random(3) do
        inv:set_stack('combs', i, 'bees_candles:honey_comb')
      end
    end,
    on_punch = function(pos, node, puncher)
      local meta = minetest.get_meta(pos)
      local inv = meta:get_inventory()
      if inv:contains_item('queen','bees_candles:queen') then
        local health = puncher:get_hp()
        puncher:set_hp(health-4)
      end
    end,
    on_metadata_inventory_take = function(pos, listname, index, stack, taker)
      local meta = minetest.get_meta(pos)
      local inv  = meta:get_inventory()
      local timer= minetest.get_node_timer(pos)
      if listname == 'combs' and inv:contains_item('queen', 'bees_candles:queen') then
        local health = taker:get_hp()
        timer:start(10)
        taker:set_hp(health-2)
      end
    end,
    on_metadata_inventory_put = function(pos, listname, index, stack, taker) --restart the colony by adding a queen
      local timer = minetest.get_node_timer(pos)
      if not timer:is_started() then
        timer:start(10)
      end
    end,
    allow_metadata_inventory_put = function(pos, listname, index, stack, player)
      if listname == 'queen' and stack:get_name() == 'bees_candles:queen' then
        return 1
      else
        return 0
      end
    end,
    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
      minetest.show_formspec(
        clicker:get_player_name(),
        'bees_candles:hive_artificial',
        formspecs.hive_wild(pos, (itemstack:get_name() == 'bees_candles:grafting_tool'))
      )
      local meta = minetest.get_meta(pos)
      local inv  = meta:get_inventory()
      if meta:get_int('agressive') == 1 and inv:contains_item('queen', 'bees_candles:queen') then
        local health = clicker:get_hp()
        clicker:set_hp(health-4)
      else
        meta:set_int('agressive', 1)
      end
    end,
    can_dig = function(pos,player)
      local meta = minetest.get_meta(pos)
      local inv  = meta:get_inventory()
      if inv:is_empty('queen') and inv:is_empty('combs') then
        return true
      else
        return false
      end
    end,
    after_dig_node = function(pos, oldnode, oldmetadata, user)
      local wielded if user:get_wielded_item() ~= nil then wielded = user:get_wielded_item() else return end
      if 'bees_candles:grafting_tool' == wielded:get_name() then 
        local inv = user:get_inventory()
        if inv then
          inv:add_item('main', ItemStack('bees_candles:queen'))
        end
      end
    end
  })

  minetest.register_node('bees_candles:hive_artificial', {
    description = 'bee hive',
    tiles = {'default_wood.png','default_wood.png','default_wood.png', 'default_wood.png','default_wood.png','bees_hive_artificial.png'},
    drawtype = 'nodebox',
    paramtype = 'light',
    paramtype2 = 'facedir',
    groups = {snappy=1,choppy=2,oddly_breakable_by_hand=2,flammable=3,wood=1},
    sounds = default.node_sound_wood_defaults(),
    node_box = {
      type = 'fixed',
      fixed = {
        {-4/8, 2/8, -4/8, 4/8, 3/8, 4/8},
        {-3/8, -4/8, -2/8, 3/8, 2/8, 3/8},
        {-3/8, 0/8, -3/8, 3/8, 2/8, -2/8},
        {-3/8, -4/8, -3/8, 3/8, -1/8, -2/8},
        {-3/8, -1/8, -3/8, -1/8, 0/8, -2/8},
        {1/8, -1/8, -3/8, 3/8, 0/8, -2/8},
      }
    },
    on_construct = function(pos)
      local timer = minetest.get_node_timer(pos)
      local meta = minetest.get_meta(pos)
      local inv = meta:get_inventory()
      meta:set_int('agressive', 1)
      inv:set_size('queen', 1)
      inv:set_size('frames', 8)
      meta:set_string('infotext','requires queen bee to function')
    end,
    on_rightclick = function(pos, node, clicker, itemstack)
      minetest.show_formspec(
        clicker:get_player_name(),
        'bees_candles:hive_artificial',
        formspecs.hive_artificial(pos)
      )
      local meta = minetest.get_meta(pos)
      local inv  = meta:get_inventory()
      if meta:get_int('agressive') == 1 and inv:contains_item('queen', 'bees_candles:queen') then
        local health = clicker:get_hp()
        clicker:set_hp(health-4)
      else
        meta:set_int('agressive', 1)
      end
    end,
    on_timer = function(pos,elapsed)
      local meta = minetest.get_meta(pos)
      local inv = meta:get_inventory()
      local timer = minetest.get_node_timer(pos)
      if inv:contains_item('queen', 'bees_candles:queen') then
        if inv:contains_item('frames', 'bees_candles:frame_empty') then
          timer:start(30)
          local rad  = 10
          local minp = {x=pos.x-rad, y=pos.y-rad, z=pos.z-rad}
          local maxp = {x=pos.x+rad, y=pos.y+rad, z=pos.z+rad}
          local flowers = minetest.find_nodes_in_area(minp, maxp, 'group:flower')
          local progress = meta:get_int('progress')
          progress = progress + #flowers
          meta:set_int('progress', progress)
          if progress > 1000 then
            local flower = flowers[math.random(#flowers)] 
            bees.polinate_flower(flower, minetest.get_node(flower).name)
            local stacks = inv:get_list('frames')
            for k, v in pairs(stacks) do
              if inv:get_stack('frames', k):get_name() == 'bees_candles:frame_empty' then
                meta:set_int('progress', 0)
                inv:set_stack('frames',k,'bees_candles:frame_full')
                return
              end
            end
          else
            meta:set_string('infotext', 'progress: '..progress..'+'..#flowers..'/1000')
          end
        else
          meta:set_string('infotext', 'does not have empty frame(s)')
          timer:stop()
        end
      end
    end,
    on_metadata_inventory_take = function(pos, listname, index, stack, player)
      if listname == 'queen' then
        local timer = minetest.get_node_timer(pos)
        local meta = minetest.get_meta(pos)
        meta:set_string('infotext','requires queen bee to function')
        timer:stop()
      end
    end,
    allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
      local inv = minetest.get_meta(pos):get_inventory()
      if from_list == to_list then 
        if inv:get_stack(to_list, to_index):is_empty() then
          return 1
        else
          return 0
        end
      else
        return 0
      end
    end,
    on_metadata_inventory_put = function(pos, listname, index, stack, player)
      local meta = minetest.get_meta(pos)
      local inv = meta:get_inventory()
      local timer = minetest.get_node_timer(pos)
      if listname == 'queen' or listname == 'frames' then
        meta:set_string('queen', stack:get_name())
        meta:set_string('infotext','queen is inserted, now for the empty frames');
        if inv:contains_item('frames', 'bees_candles:frame_empty') then
          timer:start(30)
          meta:set_string('infotext','bees are aclimating');
        end
      end
    end,
    allow_metadata_inventory_put = function(pos, listname, index, stack, player)
      if not minetest.get_meta(pos):get_inventory():get_stack(listname, index):is_empty() then return 0 end
      if listname == 'queen' then
        if stack:get_name():match('bees_candles:queen*') then
          return 1
        end
      elseif listname == 'frames' then
        if stack:get_name() == ('bees_candles:frame_empty') then
          return 1
        end
      end
      return 0
    end,
  })

--ABMS
  minetest.register_abm({ --particles
    nodenames = {'bees_candles:hive_artificial', 'bees_candles:hive_wild', 'bees_candles:hive_industrial'},
    interval  = 10,
    chance    = 4,
    action = function(pos)
      minetest.add_particle({
        pos = {x=pos.x, y=pos.y, z=pos.z},
        velocity = {x=(math.random()-0.5)*5,y=(math.random()-0.5)*5,z=(math.random()-0.5)*5},
        acceleration = {x=math.random()-0.5,y=math.random()-0.5,z=math.random()-0.5},
        expirationtime = math.random(2.5),
        size = math.random(3),
        collisiondetection = true,
        texture = 'bees_particle_bee.png',
      })
    end,
  })

  minetest.register_abm({ --spawn abm. This should be changed to a more realistic type of spawning
    nodenames = {'group:leaves'},
    neighbors = {''},
    interval = 1600,
    chance = 20,
    action = function(pos, node, _, _)
      local p = {x=pos.x, y=pos.y-1, z=pos.z}
      if minetest.get_node(p).walkable == false then return end
      if (minetest.find_node_near(p, 5, 'group:flora') ~= nil and minetest.find_node_near(p, 40, 'bees_candles:hive_wild') == nil) then
        minetest.add_node(p, {name='bees_candles:hive_wild'})
      end
    end,
  })

  minetest.register_abm({ --spawning bees around bee hive
    nodenames = {'bees_candles:hive_wild', 'bees_candles:hive_artificial', 'bees_candles:hive_industrial'},
    neighbors = {'group:flowers', 'group:leaves'},
    interval = 30,
    chance = 4,
    action = function(pos, node, _, _)
      local p = {x=pos.x+math.random(-5,5), y=pos.y-math.random(0,3), z=pos.z+math.random(-5,5)}
      if minetest.get_node(p).name == 'air' then
        minetest.add_node(p, {name='bees_candles:bees'})
      end
    end,
  })

  minetest.register_abm({ --remove bees
    nodenames = {'bees_candles:bees'},
    interval = 30,
    chance = 5,
    action = function(pos, node, _, _)
      minetest.remove_node(pos)
    end,
  })

--ITEMS
  minetest.register_craftitem('bees_candles:frame_empty', {
    description = 'empty hive frame',
    inventory_image = 'bees_frame_empty.png',
    stack_max = 24,
  })

  minetest.register_craftitem('bees_candles:frame_full', {
    description = 'filled hive frame',
    inventory_image = 'bees_frame_full.png',
    stack_max = 12,
  })

  minetest.register_craftitem('bees_candles:bottle_honey', {
    description = 'honey bottle',
    inventory_image = 'bees_bottle_honey.png',
    stack_max = 12,
    on_use = minetest.item_eat(3, "vessels:glass_bottle"),
  })
  
  minetest.register_craftitem('bees_candles:wax', {
    description = 'bees wax',
    inventory_image = 'bees_wax.png',
    stack_max = 48,
  })

  minetest.register_craftitem('bees_candles:honey_comb', {
    description = 'honey comb',
    inventory_image = 'bees_comb.png',
    on_use = minetest.item_eat(2),
    stack_max = 8,
  })

  minetest.register_craftitem('bees_candles:queen', {
    description = 'Queen Bee',
    inventory_image = 'bees_particle_bee.png',
    stack_max = 1,
  })

--CRAFTS
  minetest.register_craft({
    output = 'bees_candles:extractor',
    recipe = {
      {'','default:steel_ingot',''},
      {'default:steel_ingot','default:stick','default:steel_ingot'},
      {'default:mese_crystal','default:steel_ingot','default:mese_crystal'},
    }
  })

  minetest.register_craft({
    output = 'bees_candles:smoker',
    recipe = {
      {'default:steel_ingot', 'wool:red', ''},
      {'', 'default:torch', ''},
      {'', 'default:steel_ingot',''},
    }
  })

  minetest.register_craft({
    output = 'bees_candles:hive_artificial',
    recipe = {
      {'group:wood','group:wood','group:wood'},
      {'group:wood','default:stick','group:wood'},
      {'group:wood','default:stick','group:wood'},
    }
  })

  minetest.register_craft({
    output = 'bees_candles:grafting_tool',
    recipe = {
      {'', '', 'default:steel_ingot'},
      {'', 'default:stick', ''},
      {'', '', ''},
    }
  })
  
  minetest.register_craft({
    output = 'bees_candles:frame_empty',
    recipe = {
      {'group:wood',  'group:wood',  'group:wood'},
      {'default:stick', 'default:stick', 'default:stick'},
      {'default:stick', 'default:stick', 'default:stick'},
    }
  })

--TOOLS
  minetest.register_tool('bees_candles:smoker', {
    description = 'smoker',
    inventory_image = 'bees_smoker.png',
    tool_capabilities = {
      full_punch_interval = 3.0,
      max_drop_level=0,
      damage_groups = {fleshy=2},
    },
    on_use = function(tool, user, node)
      if node then
        local pos = node.under
        if pos then
          for i=1,6 do
            minetest.add_particle({
              pos = {x=pos.x+math.random()-0.5, y=pos.y, z=pos.z+math.random()-0.5},
              velocity = {x=0,y=0.5+math.random(),z=0},
              acceleration = {x=0,y=0,z=0},
              expirationtime = 2+math.random(2.5),
              size = math.random(3),
              collisiondetection = false,
              texture = 'bees_smoke_particle.png',
            })
          end
          --tool:add_wear(2)
          local meta = minetest.get_meta(pos)
          meta:set_int('agressive', 0)
          return nil
        end
      end
    end,
  })

  minetest.register_tool('bees_candles:grafting_tool', {
    description = 'grafting tool',
    inventory_image = 'bees_grafting_tool.png',
    tool_capabilities = {
      full_punch_interval = 3.0,
      max_drop_level=0,
      damage_groups = {fleshy=2},
    },
  })

--COMPATIBILTY --remove after all has been updated
  --ALIASES
    minetest.register_alias('bees_candles:honey_extractor', 'bees_candles:extractor')
  --BACKWARDS COMPATIBILITY WITH OLDER VERSION  
    minetest.register_alias('bees_candles:honey_bottle', 'bees_candles:bottle_honey')
    minetest.register_abm({
      nodenames = {'bees_candles:hive', 'bees_candles:hive_artificial_inhabited'},
      interval = 0,
      chance = 1,
      action = function(pos, node)
        if node.name == 'bees_candles:hive' then
          minetest.set_node(pos, { name = 'bees_candles:hive_wild' })
          local meta = minetest.get_meta(pos)
          local inv  = meta:get_inventory()
          inv:set_stack('queen', 1, 'bees_candles:queen')
        end
        if node.name == 'bees_candles:hive_artificial_inhabited' then
          minetest.set_node(pos, { name = 'bees_candles:hive_artificial' })
          local meta = minetest.get_meta(pos)
          local inv  = meta:get_inventory()
          inv:set_stack('queen', 1, 'bees_candles:queen')
          local timer = minetest.get_node_timer(pos)
          timer:start(60)
        end
      end,
    })

  --PIPEWORKS
    if minetest.get_modpath("pipeworks") then
      minetest.register_node('bees_candles:hive_industrial', {
        description = 'industrial bee hive',
        tiles = { 'bees_hive_industrial.png'},
        paramtype2 = 'facedir',
        groups = {snappy=1,choppy=2,oddly_breakable_by_hand=2,tubedevice=1,tubedevice_receiver=1},
        sounds = default.node_sound_wood_defaults(),
        tube = {
          insert_object = function(pos, node, stack, direction)
            local meta = minetest.get_meta(pos)
            local inv = meta:get_inventory()
            if stack:get_name() ~= "bees_candles:frame_empty" or stack:get_count() > 1 then
              return stack
            end
            for i = 1, 8 do
              if inv:get_stack("frames", i):is_empty() then
                inv:set_stack("frames", i, stack)
                local timer = minetest.get_node_timer(pos)
                timer:start(30)
                meta:set_string('infotext','bees are aclimating')
                return ItemStack("")
              end
            end
            return stack
          end,
          can_insert = function(pos,node,stack,direction)
            local meta = minetest.get_meta(pos)
            local inv = meta:get_inventory()
            if stack:get_name() ~= "bees_candles:frame_empty" or stack:get_count() > 1 then
              return false
            end
            for i = 1, 8 do
              if inv:get_stack("frames", i):is_empty() then
                return true
              end
            end
            return false
          end,
          can_remove = function(pos,node,stack,direction)
            if stack:get_name() == "bees_candles:frame_full" then
              return 1
            else
              return 0
            end
          end,
          input_inventory = "frames",
          connect_sides = {left=1, right=1, back=1, front=1, bottom=1, top=1}
        },
        on_construct = function(pos)
          local timer = minetest.get_node_timer(pos)
          local meta = minetest.get_meta(pos)
          local inv = meta:get_inventory()
          meta:set_int('agressive', 1)
          inv:set_size('queen', 1)
          inv:set_size('frames', 8)
          meta:set_string('infotext','requires queen bee to function')
        end,
        on_rightclick = function(pos, node, clicker, itemstack)
          minetest.show_formspec(
            clicker:get_player_name(),
            'bees_candles:hive_artificial',
            formspecs.hive_artificial(pos)
          )
          local meta = minetest.get_meta(pos)
          local inv  = meta:get_inventory()
          if meta:get_int('agressive') == 1 and inv:contains_item('queen', 'bees_candles:queen') then
            local health = clicker:get_hp()
            clicker:set_hp(health-4)
          else
            meta:set_int('agressive', 1)
          end
        end,
        on_timer = function(pos,elapsed)
          local meta = minetest.get_meta(pos)
          local inv = meta:get_inventory()
          local timer = minetest.get_node_timer(pos)
          if inv:contains_item('queen', 'bees_candles:queen') then
            if inv:contains_item('frames', 'bees_candles:frame_empty') then
              timer:start(30)
              local rad  = 10
              local minp = {x=pos.x-rad, y=pos.y-rad, z=pos.z-rad}
              local maxp = {x=pos.x+rad, y=pos.y+rad, z=pos.z+rad}
              local flowers = minetest.find_nodes_in_area(minp, maxp, 'group:flower')
              local progress = meta:get_int('progress')
              progress = progress + #flowers
              meta:set_int('progress', progress)
              if progress > 1000 then
                local flower = flowers[math.random(#flowers)] 
                bees.polinate_flower(flower, minetest.get_node(flower).name)
                local stacks = inv:get_list('frames')
                for k, v in pairs(stacks) do
                  if inv:get_stack('frames', k):get_name() == 'bees_candles:frame_empty' then
                    meta:set_int('progress', 0)
                    inv:set_stack('frames',k,'bees_candles:frame_full')
                    return
                  end
                end
              else
                meta:set_string('infotext', 'progress: '..progress..'+'..#flowers..'/1000')
              end
            else
              meta:set_string('infotext', 'does not have empty frame(s)')
              timer:stop()
            end
          end
        end,
        on_metadata_inventory_take = function(pos, listname, index, stack, player)
          if listname == 'queen' then
            local timer = minetest.get_node_timer(pos)
            local meta = minetest.get_meta(pos)
            meta:set_string('infotext','requires queen bee to function')
            timer:stop()
          end
        end,
        allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
          local inv = minetest.get_meta(pos):get_inventory()
          if from_list == to_list then 
            if inv:get_stack(to_list, to_index):is_empty() then
              return 1
            else
              return 0
            end
          else
            return 0
          end
        end,
        on_metadata_inventory_put = function(pos, listname, index, stack, player)
          local meta = minetest.get_meta(pos)
          local inv = meta:get_inventory()
          local timer = minetest.get_node_timer(pos)
          if listname == 'queen' or listname == 'frames' then
            meta:set_string('queen', stack:get_name())
            meta:set_string('infotext','queen is inserted, now for the empty frames');
            if inv:contains_item('frames', 'bees_candles:frame_empty') then
              timer:start(30)
              meta:set_string('infotext','bees are aclimating');
            end
          end
        end,
        allow_metadata_inventory_put = function(pos, listname, index, stack, player)
          if not minetest.get_meta(pos):get_inventory():get_stack(listname, index):is_empty() then return 0 end
          if listname == 'queen' then
            if stack:get_name():match('bees_candles:queen*') then
              return 1
            end
          elseif listname == 'frames' then
            if stack:get_name() == ('bees_candles:frame_empty') then
              return 1
            end
          end
          return 0
        end,
      })
    end

print('[Mod]Bees Loaded!')


--The below code was copied from:
-- init.lua
-- candles minetest mod, by darkrose
-- Copyright (C) Lisa Milne 2013 <lisa@ltmnet.com>

local candles = {};

candles.types = {
	{
		unlit = 'bees_candles:candle',
		lit = 'bees_candles:candle_lit',
		name = 'Candle',
		ingot = nil,
		image = 'candles_candle'
	},
	{
		unlit = 'bees_candles:candle_wall_steel',
		lit = 'bees_candles:candle_wall_steel_lit',
		name = 'Steel Wall-Mount Candle',
		ingot = 'default:steel_ingot',
		image = 'candles_candle_steel'
	},
	{
		unlit = 'bees_candles:candle_wall_copper',
		lit = 'bees_candles:candle_wall_copper_lit',
		name = 'Copper Wall-Mount Candle',
		ingot = 'deafault:copper_ingot',
		image = 'candles_candle_copper'
	},
	{
		unlit = 'bees_candles:candle_wall_silver',
		lit = 'bees_candles:candle_wall_silver_lit',
		name = 'Silver Wall-Mount Candle',
		ingot = 'moreores:silver_ingot',
		image = 'candles_candle_silver'
	},
	{
		unlit = 'bees_candles:candle_wall_gold',
		lit = 'bees_candles:candle_wall_gold_lit',
		name = 'Gold Wall-Mount Candle',
		ingot = 'default:gold_ingot',
		image = 'candles_candle_gold'
	},
	{
		unlit = 'bees_candles:candle_wall_bronze',
		lit = 'bees_candles:candle_wall_bronze_lit',
		name = 'Bronze Wall-Mount Candle',
		ingot = 'default:bronze_ingot',
		image = 'candles_candle_bronze'
	},
	{
		unlit = 'bees_candles:candelabra_steel',
		lit = 'bees_candles:candelabra_steel_lit',
		name = 'Steel Candelebra',
		ingot = 'default:steel_ingot',
		image = 'candles_candelabra_steel'
	},
	{
		unlit = 'bees_candles:candelabra_copper',
		lit = 'bees_candles:candelabra_copper_lit',
		name = 'Copper Candelebra',
		ingot = 'default:copper_ingot',
		image = 'candles_candelabra_copper'
	},
	{
		unlit = 'bees_candles:candelabra_silver',
		lit = 'bees_candles:candelabra_silver_lit',
		name = 'Silver Candelebra',
		ingot = 'moreores:silver_ingot',
		image = 'candles_candelabra_silver'
	},
	{
		unlit = 'bees_candles:candelabra_gold',
		lit = 'bees_candles:candelabra_gold_lit',
		name = 'Gold Candelebra',
		ingot = 'default:gold_ingot',
		image = 'candles_candelabra_gold'
	},
	{
		unlit = 'bees_candles:candelabra_bronze',
		lit = 'bees_candles:candelabra_bronze_lit',
		name = 'Bronze Candelebra',
		ingot = 'deafault:bronze_ingot',
		image = 'candles_candelabra_bronze'
	},
}

candles.find_lit = function(name)
	for i,n in ipairs(candles.types) do
		if n.unlit == name then
			return n.lit
		end
	end
	return nil
end

candles.find_unlit = function(name)
	for i,n in ipairs(candles.types) do
		if n.lit == name then
			return n.unlit
		end
	end
	return nil
end

candles.light = function(pos, node, puncher)
	if not puncher or not node then
		return
	end
	local wield = puncher:get_wielded_item()
	if not wield then
		return
	end
	wield = wield:get_name()
	if wield and wield == 'default:torch' then
		local litname = candles.find_lit(node.name)
		minetest.env:add_node(pos,{name=litname, param1=node.param1, param2=node.param2})
	end
end

candles.snuff = function(pos, node, puncher)
	if not puncher or not node then
		return
	end
	local wield = puncher:get_wielded_item()
	if not wield then
		return
	end
	wield = wield:get_name()
	if not wield or wield ~= 'default:torch' then
		local unlitname = candles.find_unlit(node.name)
		minetest.env:add_node(pos,{name=unlitname, param1=node.param1, param2=node.param2})
	end
end

candles.create_wall = function(ctype)
	minetest.register_node(ctype.unlit, {
		description = ctype.name,
		tile_images = {ctype.image.."_top.png",ctype.image.."_top.png",ctype.image..".png"},
		drawtype = "nodebox",
		paramtype = "light",
		paramtype2 = "facedir",
		groups = {crumbly=3,oddly_breakable_by_hand=1},
		on_punch = candles.light,
		sunlight_propagates = true,
		walkable = false,
		node_box = {
			type = "fixed",
			fixed = {
				-- x,y,z,x,y,z
				-- body
				{0.11, -0.3, -0.07, 0.27, 0.2, 0.07},
				-- wick
				{0.18, 0.2, -0.02, 0.22, 0.3, 0.02},
				-- holder
				{0.1, -0.4, -0.1, 0.3, -0.27, 0.1},
				{0.1, -0.35, -0.05, 0.5, -0.3, 0.05},
				{0.45, -0.40, -0.12, 0.5, -0.25, 0.12},
			},
		},
		selection_box = {
			type = "fixed",
			fixed = {0.05, -0.45, -0.2, 0.5, 0.3, 0.15}
		},
		on_place = function(itemstack, placer, pointed_thing)
			local above = pointed_thing.above
			local under = pointed_thing.under
			local dir = {x = under.x - above.x,
				     y = under.y - above.y,
				     z = under.z - above.z}

			local wdir = minetest.dir_to_wallmounted(dir)
			local fdir = minetest.dir_to_facedir(dir)

			if wdir == 0 or wdir == 1 then
				return itemstack
			else
				fdir = fdir-1
				if fdir < 0 then
					fdir = 3
				end
				minetest.env:add_node(above, {name = itemstack:get_name(), param2 = fdir})
				itemstack:take_item()
				return itemstack
			end
		end
	})

	minetest.register_node(ctype.lit, {
		description = ctype.name,
		tile_images = {ctype.image.."_top.png",ctype.image.."_top.png",ctype.image.."_lit.png"},
		drawtype = "nodebox",
		paramtype = "light",
		paramtype2 = "facedir",
		groups = {},
		on_punch = candles.snuff,
		sunlight_propagates = true,
		walkable = false,
		light_source = 8,
		drop = ctype.unlit,
		node_box = {
			type = "fixed",
			fixed = {
				-- x,y,z,x,y,z
				-- body
				{0.11, -0.3, -0.07, 0.27, 0.2, 0.07},
				-- wick
				{0.18, 0.2, -0.02, 0.22, 0.42, 0.02},
				-- flame
				{0.14, 0.25, -0.06, 0.26, 0.3, 0.06},
				{0.16, 0.3, -0.04, 0.24, 0.37, 0.04},
				-- holder
				{0.1, -0.4, -0.1, 0.3, -0.27, 0.1},
				{0.1, -0.35, -0.05, 0.5, -0.3, 0.05},
				{0.45, -0.40, -0.12, 0.5, -0.25, 0.12},
			},
		},
		selection_box = {
			type = "fixed",
			fixed = {0.05, -0.45, -0.2, 0.5, 0.45, 0.15}
		},
		can_dig = function(pos,player)
			return false
		end,
	})
	minetest.register_craft({
		output = ctype.unlit,
		recipe = {
			{'bees_candles:candle'},
			{ctype.ingot},
		}
	})
end

candles.create_candelabra = function(ctype)
	minetest.register_node(ctype.unlit, {
		description = ctype.name,
		tile_images = {ctype.image.."_top.png",ctype.image.."_top.png",ctype.image..".png"},
		drawtype = "nodebox",
		paramtype = "light",
		paramtype2 = "facedir",
		groups = {crumbly=3,oddly_breakable_by_hand=1},
		on_punch = candles.light,
		sunlight_propagates = true,
		walkable = false,
		node_box = {
			type = "fixed",
			fixed = {
				-- x,y,z,x,y,z
				-- body
				{-0.08, -0.3, -0.48, 0.08, 0.2, -0.32},
				{-0.08, -0.3, -0.08, 0.08, 0.2, 0.08},
				{-0.08, -0.3, 0.32, 0.08, 0.2, 0.48},
				-- wick
				{-0.02, 0.2, -0.42, 0.02, 0.3, -0.38},
				{-0.02, 0.2, -0.02, 0.02, 0.3, 0.02},
				{-0.02, 0.2, 0.38, 0.02, 0.3, 0.42},
				-- holder
				{-0.1, -0.27, -0.5, 0.1, -0.2, -0.3},
				{-0.1, -0.27, -0.1, 0.1, -0.2, 0.1},
				{-0.1, -0.27, 0.3, 0.1, -0.2, 0.5},
				-- stand
				{-0.05, -0.32, -0.45, 0.05, -0.27, 0.45},
				-- base
				{-0.05, -0.45, -0.05, 0.05, -0.3, 0.05},
				{-0.1, -0.49, -0.1, 0.1, -0.45, 0.1},
				{-0.15, -0.5, -0.15, 0.15, -0.49, 0.15},
			},
		},
		on_place = function(itemstack, placer, pointed_thing)
			local above = pointed_thing.above
			local under = pointed_thing.under
			local dir = {x = under.x - above.x,
				     y = under.y - above.y,
				     z = under.z - above.z}

			local wdir = minetest.dir_to_wallmounted(dir)
			local fdir = minetest.dir_to_facedir(dir)

			if wdir == 1 then
				minetest.env:add_node(above, {name = itemstack:get_name(), param2 = fdir})
				itemstack:take_item()
			end
			return itemstack
		end
	})

	minetest.register_node(ctype.lit, {
		description = ctype.name,
		tile_images = {ctype.image.."_top.png",ctype.image.."_top.png",ctype.image.."_lit.png"},
		drawtype = "nodebox",
		paramtype = "light",
		paramtype2 = "facedir",
		groups = {},
		on_punch = candles.snuff,
		sunlight_propagates = true,
		walkable = false,
		light_source = 12,
		drop = ctype.unlit,
		node_box = {
			type = "fixed",
			fixed = {
				-- x,y,z,x,y,z
				-- body
				{-0.08, -0.3, -0.48, 0.08, 0.2, -0.32},
				{-0.08, -0.3, -0.08, 0.08, 0.2, 0.08},
				{-0.08, -0.3, 0.32, 0.08, 0.2, 0.48},
				-- wick
				{-0.02, 0.2, -0.42, 0.02, 0.45, -0.38},
				{-0.02, 0.2, -0.02, 0.02, 0.45, 0.02},
				{-0.02, 0.2, 0.38, 0.02, 0.45, 0.42},
				-- flame
				{-0.06, 0.25, -0.46, 0.06, 0.3, -0.34},
				{-0.04, 0.3, -0.44, 0.04, 0.37, -0.36},
				{-0.06, 0.25, -0.06, 0.06, 0.3, 0.06},
				{-0.04, 0.3, -0.04, 0.04, 0.37, 0.04},
				{-0.06, 0.25, 0.34, 0.06, 0.3, 0.46},
				{-0.04, 0.3, 0.36, 0.04, 0.37, 0.44},
				-- holder
				{-0.1, -0.27, -0.5, 0.1, -0.2, -0.3},
				{-0.1, -0.27, -0.1, 0.1, -0.2, 0.1},
				{-0.1, -0.27, 0.3, 0.1, -0.2, 0.5},
				-- stand
				{-0.05, -0.32, -0.45, 0.05, -0.27, 0.45},
				-- base
				{-0.05, -0.45, -0.05, 0.05, -0.3, 0.05},
				{-0.1, -0.49, -0.1, 0.1, -0.45, 0.1},
				{-0.15, -0.5, -0.15, 0.15, -0.49, 0.15},
			},
		},
		can_dig = function(pos,player)
			return false
		end,
	})
	minetest.register_craft({
		output = ctype.unlit,
		recipe = {
			{'bees_candles:candle','bees_candles:candle','bees_candles:candle'},
			{ctype.ingot,ctype.ingot,ctype.ingot},
		}
	})
end

minetest.register_node("bees_candles:candle", {
	description = "Candle",
	tile_images = {"candles_candle_top.png","candles_candle.png"},
	drawtype = "nodebox",
	paramtype = "light",
	groups = {crumbly=3,oddly_breakable_by_hand=1},
	on_punch = candles.light,
	sunlight_propagates = true,
	walkable = false,
	node_box = {
		type = "fixed",
		fixed = {
			-- x,y,z,x,y,z
			-- body
			{-0.08, -0.5, -0.08, 0.08, 0.0, 0.08},
			-- wick
			{-0.02, 0.0, -0.02, 0.02, 0.1, 0.02},
		},
	},
	selection_box = {
		type = "fixed",
		fixed = {-0.1, -0.5, -0.1, 0.1, 0.12, 0.1}
	},
	on_place = function(itemstack, placer, pointed_thing)
		local above = pointed_thing.above
		local under = pointed_thing.under
		local dir = {x = under.x - above.x,
			     y = under.y - above.y,
			     z = under.z - above.z}

		local wdir = minetest.dir_to_wallmounted(dir)

		if wdir == 1 then
			minetest.env:add_node(above, {name = 'bees_candles:candle'})
			itemstack:take_item()
		end
		return itemstack
	end
})

minetest.register_node("bees_candles:candle_lit", {
	description = "Candle",
	tile_images = {"candles_candle_top.png","candles_candle_lit.png"},
	drawtype = "nodebox",
	paramtype = "light",
	groups = {},
	on_punch = candles.snuff,
	sunlight_propagates = true,
	walkable = false,
	light_source = 8,
	drop = 'bees_candles:candle',
	node_box = {
		type = "fixed",
		fixed = {
			-- x,y,z,x,y,z
			-- body
			{-0.08, -0.5, -0.08, 0.08, 0.0, 0.08},
			-- wick
			{-0.02, 0.0, -0.02, 0.02, 0.25, 0.02},
			-- flame
			{-0.06, 0.1, -0.06, 0.06, 0.15, 0.06},
			{-0.04, 0.15, -0.04, 0.04, 0.22, 0.04},
		},
	},
	selection_box = {
		type = "fixed",
		fixed = {-0.1, -0.5, -0.1, 0.1, 0.37, 0.1}
	},
	can_dig = function(pos,player)
		return false
	end,
})

minetest.register_craft({
	output = 'bees_candles:candle',
	recipe = {
		{'bees_candles:wax','farming:string','bees_candles:wax'},
	}
})

for i,n in ipairs(candles.types) do
	if n.ingot then
		if string.find(n.unlit,'candelabra') then
			candles.create_candelabra(n)
		else
			candles.create_wall(n)
		end
	end
end

print('[Mod]Beeswax Candles Loaded!')
