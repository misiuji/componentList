component = require("component")
local event = require("event")
local term = require("term")
local gpu = component.gpu
local width, height = gpu.getResolution()
local startingLine = 3
local endingLine = height - 1

local loop = true
local dataPath = "component"
data = component
local lookup = {}
local scroll = 0
local select = 1
local selectPrev = nil
local selectValue = ""
local selectMax = 0
for key, val in pairs(data) do
    selectMax = selectMax + 1
end

local function makeTable()
    gpu.set(1, 1, dataPath)
    gpu.fill(1, 2, width, 1, "-")
    gpu.fill(1, height, width, 1, "-")
    gpu.fill(1, 3, 1, height, "|")
    gpu.fill(24, 3, 1, height, "|")
    gpu.fill(width, 3, 1, height, "|")
    gpu.set(1, 2, "+")
    gpu.set(24, 2, "+")
    gpu.set(1, height, "+")
    gpu.set(24, height, "+")
    gpu.set(width, 2, "+")
    gpu.set(width, height, "+")
end

local function displayItem(pos, key, val)
    gpu.set(2, pos, key)                                --display the key
    if type(val) == "table" then                        --if the value type is table
        if val["name"] == nil then                      --and it has no name 
            gpu.set(25, pos, "table")                   --then it's a table
        else
            gpu.set(25, pos, "afunction")               --else it's really an addressed function
        end
    else        
        if type(val) ~= "function" then                 --if the value type isn't a function display it's content 
            gpu.set(25, pos, type(val) .. ": " .. tostring(val))
        else
            gpu.set(25, pos, "function")
        end
    end
end

local function generateList()
    i = startingLine
    lookup = {};
    for key, val in pairs(data) do
        lookup[i - startingLine + 1] = key;                     --add entry to lookup table
        if i - scroll > endingLine then                         --if current element is off the screen     
            gpu.fill(2, endingLine, width, endingLine, " ")     --replace the last line with "..."
            gpu.set(2, endingLine, "...")
        elseif i - scroll < startingLine then                   --if the element is too high up
            gpu.fill(2, startingLine, width, startingLine, " ") --display "..." at starting line
            gpu.set(2, startingLine, "...")
        elseif i - scroll > startingLine or scroll == 0 then    --display if the first element is offscreen
            displayItem(i - scroll, key, val)               
        end
        i = i + 1                                               --increse line
    end
    gpu.setForeground(0xFFFFFF)
    gpu.setBackground(0x000000)
end



local function reloadData()
    load("data = " .. dataPath)()              --reload data
    select = 1                                 --return to 1st value
    selectPrev = nil
    selectMax = 0                              --recalculate amount of items
    scroll = 0                             
    for key, val in pairs(data) do
        selectMax = selectMax + 1
    end
    gpu.fill(1, 1, width, height, " ")         --clear the screen    
    generateList()
    makeTable()
end


gpu.fill(1, 1, width, height, " ")
generateList()
makeTable()
while loop do
    selectValue = lookup[select]                                            --set selected value
    if selectPrev ~= nil then                                               --if there was a movment (to prevent crashes on data reload)
        displayItem(selectPrev + startingLine - scroll - 1, lookup[selectPrev], data[lookup[selectPrev]])    --unhighlight the previus item
    end 
    gpu.setForeground(0x000000)                                             --switch colors 
    gpu.setBackground(0xFFFFFF)
    displayItem(select + startingLine - scroll - 1, selectValue, data[selectValue])  --highlight current
    gpu.setForeground(0xFFFFFF)                                             --switch back colors
    gpu.setBackground(0x000000)
    selectPrev = select                                                     --set previus select
    local e, keyboard, char, key = event.pull(nil, "key_down")
    if key == 0x1C then                                         --enter
        if type(data[selectValue]) == "table" then
        dataPath = dataPath .. "." .. selectValue;              --add the new component to the end
        reloadData()
        end
    end
    if key == 0x0E then                                      --backspace
        if dataPath ~= "component" then
            while string.sub(dataPath, -1) ~= "." do            --remove characters until '.' 
                dataPath = string.sub(dataPath, 1, -2)          
            end
            dataPath = string.sub(dataPath, 1, -2)              --remove the '.'
            reloadData()                                        --reload data
        else
            loop = false
        end
    end
    if char == 81 or char == 113 then                           --q
        loop = false
    end
    if char == 69 or char == 101 then                                                   --e
        gpu.fill(1, 2, width, height, " ")                                              --clear all exept first line
        gpu.set(string.len(dataPath) + 1, 1 , "." .. selectValue )                      --add selected value to the 1st line
        term.setCursor(string.len(dataPath) + string.len(selectValue) + 2, 1)           --set cursor to end of first line
        local input = term.read()                                                       --take input from player
        local output = load("return " .. dataPath .. "." .. selectValue .. input)()     --execute the command and get the output                                        
        gpu.set(1, 2, tostring(output))                                                 --print output
        event.pull(nil, "key_down")                                                     --wait for any key input
        gpu.fill(1, 1, width, height, " ")                                              --clear the screen
        generateList()                                                                  --print the list
        makeTable()                                                                     --draw a table
    end
    if char == 76 or char == 108 then                                                   --l
        gpu.fill(1, 1, width, height, " ")                                              --clear the screen
        term.setCursor(1, 1)                                                            --set cursor to start of first line
        local input = term.read()                                                       --take input from player
        local output = load(input)()                                                    --execute the command and get the output                                        
        gpu.set(1, 2, tostring(output))                                                 --print output
        event.pull(nil, "key_down")                                                     --wait for any key input
        gpu.fill(1, 1, width, height, " ")                                              --clear the screen
        generateList()                                                                  --print the list
        makeTable()                                                                     --draw a table
    end
    if key == 0xD0 then                                             --down
        if select - scroll + startingLine == endingLine and select + 1 < selectMax then     --scroll
            scroll = scroll + 1 
            generateList()
            makeTable()
        end
        select = select + 1                                         --increment select
        if select > selectMax then select = select - 1 end                  --if to big
    end                  
    if key == 0xC8 then                                             --up
        if select - scroll < startingLine and scroll ~=  0 then     --scroll
            scroll = scroll - 1 
            generateList()
            makeTable()
        end
        select = select - 1                                         --decrement select
        if select < 1 then select = select + 1 end                  --if to small
    end 
end

os.execute("cls")