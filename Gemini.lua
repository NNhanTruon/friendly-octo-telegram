local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Auto Farm Story",
    SubTitle = "by Gemini",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main Auto", Icon = "swords" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Options = Fluent.Options

-- Cấu hình thứ tự Map chuẩn theo hình ảnh hiển thị trong game (World 1 -> World 12)
local MapList = {
    "Green Planet",    -- World 1
    "Desert",          -- World 2
    "Double Dungeon",  -- World 3
    "Titan City",      -- World 4
    "Beach Harbor",    -- World 5
    "Gold District",   -- World 6
    "Soul Haven",      -- World 7
    "Realm Seven",     -- World 8
    "Heroic City",     -- World 9
    "Magic Kingdom",   -- World 10 (Locked)
    "The Eclipse",     -- World 11 (Locked)
    "Rome"             -- World 12 (Locked)
}

-- Biến quản lý trạng thái farm
local currentMapIndex = 1
local currentStage = 1

do
    Tabs.Main:AddParagraph({
        Title = "Hướng dẫn",
        Content = "Chọn Map, Stage bắt đầu và Độ khó. Khi hiện bảng kết quả, script sẽ delay 2s rồi tự động Next sang màn mới luôn."
    })

    -- Dropdown chọn Map
    local MapDropdown = Tabs.Main:AddDropdown("SelectedMap", {
        Title = "Chọn Bản Đồ (Map)",
        Values = MapList,
        Multi = false,
        Default = "Green Planet",
    })

    -- Dropdown chọn Stage (1 -> 7)
    local StageDropdown = Tabs.Main:AddDropdown("SelectedStage", {
        Title = "Chọn Màn (Stage)",
        Values = {"1", "2", "3", "4", "5", "6", "7"},
        Multi = false,
        Default = "1",
    })

    -- Dropdown chọn Độ khó
    local DiffDropdown = Tabs.Main:AddDropdown("Difficulty", {
        Title = "Độ khó (Difficulty)",
        Values = {"Normal", "Hard", "Nightmare"},
        Multi = false,
        Default = "Normal",
    })

    MapDropdown:OnChanged(function(Value)
        for i, mapName in ipairs(MapList) do
            if mapName == Value then
                currentMapIndex = i
                break
            end
        end
    end)

    StageDropdown:OnChanged(function(Value)
        currentStage = tonumber(Value) or 1
    end)

    -- Toggle bật/tắt Auto
    local AutoToggle = Tabs.Main:AddToggle("AutoStory", {Title = "Kích Hoạt Auto Farm", Default = false })

    -- Hàm gửi request bắt đầu trận đấu
    local function fireStartBattle(map, stage, diff)
        local remote = game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("Utils"):WaitForChild("network"):WaitForChild("RemoteEvent")
        local args = {
            "battle_start",
            "story",
            map,
            stage,
            diff
        }
        remote:FireServer(unpack(args))
    end

    -- Vòng lặp chính điều khiển Auto Farm
    task.spawn(function()
        local resultGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("battle"):WaitForChild("Result")

        while true do
            task.wait(1)
            
            if Options.AutoStory.Value then
                -- Kiểm tra trạng thái UI bằng Attribute Open
                local isOpen = resultGui:GetAttribute("Open")

                -- Nếu GUI kết quả CHƯA MỞ (đang trong trận hoặc game vừa nhận lệnh qua màn mới và đang chuẩn bị load)
                if not isOpen then
                    local mapName = MapList[currentMapIndex]
                    local diff = Options.Difficulty.Value
                    
                    if mapName then
                        Fluent:Notify({
                            Title = "Auto Farm",
                            Content = string.format("Đang chuẩn bị vào: %s - Màn %d (%s)", mapName, currentStage, diff),
                            Duration = 3
                        })
                        
                        fireStartBattle(mapName, currentStage, diff)
                        task.wait(10) -- Chờ lệnh fire được xử lý và load màn ổn định
                    end
                end

                -- Vòng lặp chờ trận đấu kết thúc (GUI Result hiển thị)
                while Options.AutoStory.Value do
                    local currentOpenStatus = resultGui:GetAttribute("Open")

                    -- ĐIỀU KIỆN: Khi bảng kết quả xuất hiện (Open == true)
                    if currentOpenStatus == true then
                        
                        -- CƯỚNG CHẾ DELAY ĐÚNG 2 GIÂY theo yêu cầu trước khi chuyển màn
                        task.wait(2) 
                        
                        -- Tính toán chuyển màn hoặc chuyển sang map mới tiếp theo
                        if currentStage < 7 then
                            currentStage = currentStage + 1
                        else
                            currentStage = 1
                            if currentMapIndex < #MapList then
                                currentMapIndex = currentMapIndex + 1
                            else
                                currentMapIndex = 1 -- Quay lại vòng từ đầu nếu đi hết map
                            end
                        end

                        -- Cập nhật giao diện Fluent hiển thị trực quan
                        local nextMapName = MapList[currentMapIndex]
                        MapDropdown:SetValue(nextMapName)
                        StageDropdown:SetValue(tostring(currentStage))

                        Fluent:Notify({
                            Title = "Auto Next",
                            Content = string.format("Đang tự động chuyển tiếp sang: %s - Màn %d", nextMapName, currentStage),
                            Duration = 4
                        })

                        task.wait(2) -- Chờ xíu để vòng lặp lớn nhận diện trạng thái và thực hiện fire trận mới
                        break 
                    end
                    task.wait(0.5) -- Kiểm tra liên tục để không bỏ lỡ khoảnh khắc kết thúc trận
                end
            end
        end
    end)
end

-- Khởi chạy SaveManager
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("FluentAutoStory")
SaveManager:SetFolder("FluentAutoStory/game-config")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)

Fluent:Notify({
    Title = "Fluent GUI",
    Content = "Đã bỏ lệnh Leave Room! Script sẽ delay 2s rồi Auto Next màn mới thẳng luôn.",
    Duration = 5
})

SaveManager:LoadAutoloadConfig()
