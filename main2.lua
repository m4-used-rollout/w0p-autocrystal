package.path = package.path .. ";./json/json.lua;./luasocket/src/?.lua"


local desired_species = -1 
local atkdef
local spespc
local species
local highestAtkDef = 0
local highestSpeSpc = 0
local lastShinyTime = os.time()
local timeSinceLastShiny 
local item 
local flaskServerURL = "http://127.0.0.1:5000/update_data"
local printedMessage = false
local enemy_addr
local version = memory.readbyte(0x141)
local region = memory.readbyte(0x142)
local encounterCount = 5
local framesInDirection = 0
local maxFramesInDirection = 32
json = require("json")
socket = require("socket")
socket.http = require("socket.http")
input = {}
actions = {"A","Right", "Down", "A"}
currentActionIndex = 1
framesInAction = 0
framesPerAction = 2
input2 = {}
actions2 = {"Right", "Up", "Left", "Down", "A"}
currentActionIndex2 = 1
framesInAction2 = 0
framesPerAction2 = 2

-- version check
if version == 0x54 then
    if region == 0x44 or region == 0x46 or region == 0x49 or region == 0x53 then
        enemy_addr = 0xd20c
    elseif region == 0x45 then
        enemy_addr = 0xd20c
    elseif region == 0x4A then
        enemy_addr = 0xd23d
    end
else
    print("Script stopped")
    return
end

local dv_flag_addr = enemy_addr + 0x21
local species_addr = enemy_addr + 0x22

function shiny(atkdef, spespc)
    if spespc == 0xAA then
        if atkdef == 0x2A or atkdef == 0x3A or atkdef == 0x6A or atkdef == 0x7A or atkdef == 0xAA or atkdef == 0xBA or atkdef == 0xEA or atkdef == 0xFA then
            return true
        end
    end
    return false
end


while true do
    emu.frameadvance()
    
    if memory.readbyte(species_addr) == 0 then
        local currentAction = actions2[currentActionIndex2]

        input[currentAction] = true
        joypad.set(input)
        emu.frameadvance()
        input[currentAction] = false

        framesInAction2 = framesInAction2 + 1

        if framesInAction2 >= framesPerAction2 then
            framesInAction2 = 0
            currentActionIndex2 = (currentActionIndex2 % #actions2) + 1
            emu.frameadvance()
        end
    else
        species = memory.readbyte(species_addr)
                    
        if desired_species > 0 and desired_species ~= species then
            -- do something
        else
            while memory.readbyte(dv_flag_addr) ~= 0x01 do
                emu.frameadvance()
            end

            item = memory.readbyte(item_addr)
            atkdef = memory.readbyte(enemy_addr)
            spespc = memory.readbyte(enemy_addr + 1)
            highestAtkDef = math.max(highestAtkDef, atkdef)
            highestSpeSpc = math.max(highestSpeSpc, spespc)

            function send_data_to_flask(encounterCount, enemy_addr, item, lastShinyTime, species, spespc)
                local data = {
                    encounterCount = encounterCount,
                    enemy_addr = enemy_addr,
                    item = item,
                    lastShinyTime = lastShinyTime,
                    species = species,
                    spespc = spespc
                }
            
                -- Concatenate variables into a single string
                local concatenated_data = encounterCount .. "," .. enemy_addr .. "," .. item .. "," .. lastShinyTime .. "," .. species .. "," .. spespc
            
                -- Print the concatenated data
                print("Concatenated data:", concatenated_data)
            
                -- Send the concatenated data as the payload
                local status_code, response_body = comm.httpPost(flaskServerURL, concatenated_data)
            
                if status_code == 200 then
                    print("Data sent to Flask successfully")
                else
                    print("Failed to send data to Flask. Status code:", status_code)
                end
            end
            
            
            

            if shiny(atkdef, spespc) then
                print("Shiny found!!")
                lastShinyTime = os.time()
                local shinyInfo = "Shiny found!!"
                
                break
            
            end

            send_data_to_flask(encounterCount, enemy_addr, item, lastShinyTime, species, spespc)
            
        end
    end 

    if memory.readbyte(species_addr) ~= 0 then
        for i=1,55,1 do
            emu.frameadvance()
        end

        local currentAction = actions[currentActionIndex]

        input[currentAction] = true
        joypad.set(input)
        emu.frameadvance()
        input[currentAction] = false
				
        framesInAction = framesInAction + 1

        if framesInAction >= framesPerAction then
            framesInAction = 0
            currentActionIndex = (currentActionIndex % #actions) + 1
            emu.frameadvance()
        end
        
    end
end
