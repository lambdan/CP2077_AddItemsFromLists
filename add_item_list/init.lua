local MOD_METADATA = {
    name = "Add Items from Lists",
    version = "1.0",
    date = "2022-05-07"
}

local LEX = require("Modules/LuaEX.lua")

local listsFolder = "ItemLists/" -- end with a slash
local itemLists = {}
local dropdownSelection = 0
local dropdownSelectionSub = 0
local listSelected = 0

registerForEvent('onInit', function()
    itemLists = refreshItemLists()
end)

registerForEvent("onOverlayOpen", function()
    show_UI = true
end)

registerForEvent("onOverlayClose", function()
    show_UI = false
end)

registerForEvent("onDraw", function()
    if(show_UI) then
        ImGui.Begin(MOD_METADATA.name)
        ImGui.Text("Item lists found: " .. tostring(LEX.tableLen(itemLists)))
        if ImGui.Button("Refresh") then
            itemLists = refreshItemLists()
        end

        ImGui.Separator()

        if LEX.tableLen(itemLists) > 0 then
            -- make list
            entriesForList = {}
            for k,v in pairs(itemLists) do
                s = v.name .. " (" .. tostring(v.amount) .. " items)"
                table.insert(entriesForList, s)
            end

            dropdownSelection = ImGui.Combo("Item Lists", dropdownSelection, entriesForList, LEX.tableLen(entriesForList), 5)
            if ImGui.Button("Select") then
                listSelected = dropdownSelection + 1 -- +1 because imgui starts tables at 0, lua starts at 1
            end
        else
            listSelected = 0
            ImGui.Text("No item lists found")
        end

        if listSelected > 0 then
            ImGui.Separator()
            local list = itemLists[listSelected]
            ImGui.Text(list.name .. " (" .. tostring(list.amount) ..  " items):")

            dropdownSelectionSub = ImGui.Combo("Items", dropdownSelectionSub, list.items, list.amount, 5)
            if ImGui.Button("Add 1x") then
                addItem(list.items[dropdownSelectionSub + 1], 1, true)
            end
            ImGui.SameLine()
            if ImGui.Button("Add 10x") then
                addItem(list.items[dropdownSelectionSub + 1], 10, true)
            end
            ImGui.SameLine()
            if ImGui.Button("Add 100x") then
                addItem(list.items[dropdownSelectionSub + 1], 100, true)
            end

            ImGui.Text("")

            if ImGui.Button("Add all items in list to inventory,\n EXCLuding items you already have") then
                for a,b in pairs(list.items) do
                    addItem(b, 1, false)
                end
            end


            if ImGui.Button("Add all items in list to inventory,\n INCLuding items you already have") then
                for a,b in pairs(list.items) do
                    addItem(b, 1, true)
                end
            end

            ImGui.Separator()

        end

        ImGui.End()
    end
end)

function addItem(name, amount, dupesAllowed)

    if dupesAllowed then
        Game.AddToInventory(name, amount)
        print("Added " .. tostring(amount) .. "x: " .. name)
    else
        if playerHasItem(name) then
            print("Not adding (dupe): " .. name)
        else
            Game.AddToInventory(name, amount)
            print("Added " .. tostring(amount) .. "x: " .. name)
        end
    end

end

function playerHasItem(name) -- cant remember where i got this from
    local player     = Game.GetPlayer()
    local ts         = Game.GetTransactionSystem()
    local __, itemlist = ts:GetItemList(player)

    for __, value in ipairs(itemlist) do
        if tostring(value:GetID().id) == tostring(ItemID.new(TweakDBID.new(name)).id) then
            return true
        end
    end

    return false
end

function ParseItemList(filename)
    local file = io.open(filename,"r")
    local lines = file:lines()
    local items = {}
    
    for line in lines do
        if (line ~= "") and (not LEX.stringStarts(line,"#")) and (not LEX.stringStarts(line,"//")) then
            if not LEX.tableHasValue(items, line) then
                table.insert(items, line)
            end
        end
    end

    file:close()
    return items

end

function listFilesInFolder(folder, ext)
    local files = {}
    for k,v in pairs(dir(folder)) do
        for a,b in pairs(v) do
            if a == "name" then
                if LEX.stringEnds(b, ext) then
                    table.insert(files, b)
                end
            end
        end
    end
    return files
end

function refreshItemLists()
    local lists = {}
    dropdownSelection = 0
    dropdownSelectionSub = 0
    listSelected = 0

    files = listFilesInFolder(listsFolder, ".txt")

    for k,v in pairs(files) do
        filepath = listsFolder .. v
        items = ParseItemList(filepath)
        entry = {
            name = v,
            items = items,
            amount = LEX.tableLen(items)
        }
        if entry.amount > 0 then -- dont add empty lists
            table.insert(lists, entry)
        end
    end

    return lists
end