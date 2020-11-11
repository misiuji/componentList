component = require("component")
local event = require("event")
local gpu = component.gpu
local width, height = gpu.getResolution()
local startingLine = 3
local endingLine = height - 1

local loop = true
local dataPath = "component"
data = component
local scroll = 0
local select = 1
local selectValue = ""
local selectMax = 0
for key, val in pairs(data) do
    selectMax = selectMax + 1
end


local function reloadData()
    load("data = " .. dataPath)()              --reload data
    select = 1                                 --return to 1st value
    selectMax = 0                              --recalculate amount of items
    scroll = 0                             
    for key, val in pairs(data) do
        selectMax = selectMax + 1
    end
    gpu.fill(1, 1, width, height, " ")         --clear the screen
end

while loop do
    gpu.fill(1, 1, width, height, " ")
    i = startingLine
    for key, val in pairs(data) do
        if select + startingLine - 1 == i then      --if currently selected item
            selectValue = key;                      --set its value
            gpu.setForeground(0x000000)             --highlight it
            gpu.setBackground(0xFFFFFF)
        else
            gpu.setForeground(0xFFFFFF)             --dislable highlight
            gpu.setBackground(0x000000)
        end
        if i - scroll > endingLine then                             --if current element is off the screen     
            gpu.fill(2, endingLine, width, endingLine, " ")             --replace the last line with "..."
            gpu.set(2, endingLine, "...")
        elseif i - scroll < startingLine then                   --if the element is too high up
            gpu.fill(2, startingLine, width, startingLine, " ") --display "..." at starting line
            gpu.set(2, startingLine, "...")
        elseif i - scroll > startingLine or scroll == 0 then    --display if the first element is offscreen
            gpu.set(2, i - scroll, key)                         --display the key
            if type(val) == "table" then                        --if the value type is table
                if val["name"] == nil then                      --and it has no name 
                    gpu.set(25, i - scroll, "table")            --then it's a table
                else
                    gpu.set(25, i - scroll, "afunction")        --else it's really an addressed function
                end
            else        
                if type(val) ~= "function" then                 --if the value type isn't a function display it's content 
                    gpu.set(25, i - scroll, type(val) .. ": " .. tostring(val))
                else
                    gpu.set(25, i - scroll, "function")
                end
            end
        end
        i = i + 1                                               --increse line
    end
    gpu.setForeground(0xFFFFFF)
    gpu.setBackground(0x000000)
    gpu.set(1, 1, dataPath)
    gpu.fill(1, 2, width, 1, "-")
    gpu.fill(1, height, width, 1, "-")
    gpu.fill(1, 3, 1, height, "|")
    gpu.fill(24, 3, 1, height, "|")
    gpu.fill(width, 3, 1, height, "|")
    gpu.set(1, 2, "+")
    gpu.set(1, height, "+")
    gpu.set(24, height, "+")
    gpu.set(width, 2, "+")
    gpu.set(width, height, "+")
    local e, keyboard, char, key = event.pull(nil, "key_down")
    if key == 0x1C then                                         --enter
        if type(data[selectValue]) == "table" then
        dataPath = dataPath .. "." .. selectValue;          --add the new component to the end
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
    if key == 0xD0 then                                             --down
        if select - scroll + startingLine == endingLine and select + 1 < selectMax then     --scroll
            scroll = scroll + 1 
        end
        select = select + 1                                         --increment select
        if select > selectMax then select = select - 1 end                  --if to big
    end                  
    if key == 0xC8 then                                             --up
        if select - scroll < startingLine and scroll ~=  0 then     --scroll
            scroll = scroll - 1 
        end
        select = select - 1                                         --decrement select
        if select < 1 then select = select + 1 end                  --if to small
    end 
end

os.execute("cls")