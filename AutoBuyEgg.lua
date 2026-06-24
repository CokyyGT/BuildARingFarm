local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local Player = Players.LocalPlayer
local UIS = game:GetService("UserInputService")

local WEBHOOK = "https://discord.com/api/webhooks/1514898766040137779/WqgxA1O9VZX7qxtmY3hfMsbHCjCZuVKmWuiBND2DZzup8S84ZfpvcMqeMP1VlA0PhXtW"
local Req = (syn and syn.request) or http_request or request

-- ════════════════════════════════════════
--              CONFIG
-- ════════════════════════════════════════
local Enabled = false
local TierPriority = "Legendary"
local BuyDelay = 30
local EggsBought = 0
local StartTime = os.time()
local Running = false

local TIER_ORDER = {["Legendary"] = 1, ["Epic"] = 2, ["Rare"] = 3, ["Common"] = 4}
local C = {
    bg = Color3.fromRGB(20, 20, 25),
    header = Color3.fromRGB(35, 35, 40),
    card = Color3.fromRGB(40, 40, 50),
    text = Color3.fromRGB(255, 255, 255),
    muted = Color3.fromRGB(150, 150, 150),
    green = Color3.fromRGB(76, 175, 80),
    red = Color3.fromRGB(244, 67, 54),
    blue = Color3.fromRGB(33, 150, 243),
    gold = Color3.fromRGB(255, 193, 7),
}

-- ════════════════════════════════════════
--              UI SETUP
-- ════════════════════════════════════════
local PG = Player:WaitForChild("PlayerGui")
local sg = Instance.new("ScreenGui")
sg.Name = "AutoBuyEggUI"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent = PG

local main = Instance.new("Frame")
main.Name = "MainPanel"
main.Size = UDim2.new(0, 320, 0, 450)
main.Position = UDim2.new(0.98, -330, 0.05, 0)
main.BackgroundColor3 = C.bg
main.BorderSizePixel = 0
main.Parent = sg

local header = Instance.new("TextLabel")
header.Size = UDim2.new(1, 0, 0, 50)
header.BackgroundColor3 = C.header
header.TextColor3 = C.text
header.TextSize = 16
header.Font = Enum.Font.GothamBold
header.Text = "🥚 Auto Buy Egg"
header.BorderSizePixel = 0
header.Parent = main

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, 0, 1, -50)
scroll.Position = UDim2.new(0, 0, 0, 50)
scroll.BackgroundColor3 = C.bg
scroll.ScrollBarThickness = 4
scroll.BorderSizePixel = 0
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.Parent = main

local layout = Instance.new("UIListLayout")
layout.Parent = scroll
layout.Padding = UDim.new(0, 10)
layout.FillDirection = Enum.FillDirection.Vertical
layout.SortOrder = Enum.SortOrder.LayoutOrder

scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
end)

-- DRAG
local dragging = false
local dragStart = Vector2.new(0, 0)
local startPos = main.Position

header.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = inp.Position
        startPos = main.Position
    end
end)

header.InputChanged:Connect(function(inp)
    if (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) and dragging then
        local delta = inp.Position - dragStart
        main.Position = startPos + UDim2.new(0, delta.X, 0, delta.Y)
    end
end)

header.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- ════════════════════════════════════════
--              HELPER FUNCTIONS
-- ════════════════════════════════════════
local function mkLabel(parent, text, size)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -20, 0, size or 18)
    l.BackgroundTransparency = 1
    l.TextColor3 = C.muted
    l.TextSize = 11
    l.Font = Enum.Font.Gotham
    l.Text = text
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.LayoutOrder = layout.AbsoluteContentSize.Y
    l.Parent = scroll
    return l
end

local function mkButton(parent, text, bgColor, callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -20, 0, 36)
    b.BackgroundColor3 = bgColor
    b.TextColor3 = C.text
    b.TextSize = 12
    b.Font = Enum.Font.GothamBold
    b.Text = text
    b.BorderSizePixel = 0
    b.LayoutOrder = layout.AbsoluteContentSize.Y
    b.Parent = parent
    b.MouseButton1Click:Connect(callback)
    return b
end

local function getUptime()
    local e = os.time() - StartTime
    return string.format("%dh %dm %ds", math.floor(e/3600), math.floor((e%3600)/60), e%60)
end

-- ════════════════════════════════════════
--              UI SECTIONS
-- ════════════════════════════════════════

-- Status Section
mkLabel(scroll, "STATUS", 14)
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 70)
statusLabel.BackgroundColor3 = C.card
statusLabel.TextColor3 = C.green
statusLabel.TextSize = 10
statusLabel.Font = Enum.Font.Gotham
statusLabel.Text = "Status: " .. (Enabled and "ON" or "OFF") .. "\nBought: " .. EggsBought .. "\nUptime: " .. getUptime()
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextYAlignment = Enum.TextYAlignment.Top
statusLabel.Padding = UDim.new(0, 8)
statusLabel.Parent = scroll

-- Enable/Disable Button
local enableBtn = mkButton(scroll, Enabled and "⏹  Stop" or "▶  Start", Enabled and C.red or C.green, function()
    Enabled = not Enabled
    enableBtn.Text = Enabled and "⏹  Stop" or "▶  Start"
    enableBtn.BackgroundColor3 = Enabled and C.red or C.green
    statusLabel.Text = "Status: " .. (Enabled and "ON" or "OFF") .. "\nBought: " .. EggsBought .. "\nUptime: " .. getUptime()
end)

-- Tier Priority Section
mkLabel(scroll, "TIER PRIORITY", 14)
local tierContainer = Instance.new("Frame")
tierContainer.Size = UDim2.new(1, -20, 0, 90)
tierContainer.BackgroundTransparency = 1
tierContainer.LayoutOrder = layout.AbsoluteContentSize.Y
tierContainer.Parent = scroll

local tierLayout = Instance.new("GridLayout")
tierLayout.Parent = tierContainer
tierLayout.FillDirection = Enum.FillDirection.Horizontal
tierLayout.CellSize = UDim2.new(0.5, -5, 0, 36)
tierLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
tierLayout.VerticalAlignment = Enum.VerticalAlignment.Top

for _, tier in ipairs({"Legendary", "Epic", "Rare", "Common"}) do
    local tierBtn = mkButton(tierContainer, tier, TierPriority == tier and C.blue or C.card, function()
        TierPriority = tier
        for _, t in ipairs({"Legendary", "Epic", "Rare", "Common"}) do
            tierContainer:FindFirstChildOfClass("TextButton", true).BackgroundColor3 = TierPriority == t and C.blue or C.card
        end
    end)
    tierBtn.Size = UDim2.new(0.5, -5, 0, 36)
    tierBtn.Parent = tierContainer
end

-- Delay Slider Section
mkLabel(scroll, "DELAY (" .. BuyDelay .. "s)", 14)
local delayFrame = Instance.new("Frame")
delayFrame.Size = UDim2.new(1, -20, 0, 40)
delayFrame.BackgroundColor3 = C.card
delayFrame.BorderSizePixel = 0
delayFrame.LayoutOrder = layout.AbsoluteContentSize.Y
delayFrame.Parent = scroll

local delaySlider = Instance.new("TextBox")
delaySlider.Size = UDim2.new(1, -16, 0, 28)
delaySlider.Position = UDim2.new(0, 8, 0, 6)
delaySlider.BackgroundColor3 = C.bg
delaySlider.TextColor3 = C.text
delaySlider.TextSize = 11
delaySlider.Text = tostring(BuyDelay)
delaySlider.PlaceholderText = "30"
delaySlider.Parent = delayFrame
delaySlider.FocusLost:Connect(function()
    local val = tonumber(delaySlider.Text)
    if val then BuyDelay = math.clamp(val, 0, 60) end
end)

-- ════════════════════════════════════════
--              EGG BUYING LOGIC
-- ════════════════════════════════════════
local function scanEggStock()
    local pm = workspace:FindFirstChild("PetMerchant")
    if not pm then return {} end
    local stock = {}
    for i = 1, 5 do
        local podium = pm:FindFirstChild("Podium" .. i .. "Stock")
        if podium then
            local tierText = podium.Text or ""
            for tier in pairs(TIER_ORDER) do
                if tierText:find(tier) then
                    stock[i] = tier
                    break
                end
            end
        end
    end
    return stock
end

local function buyEgg(podiumNum)
    local pm = workspace:FindFirstChild("PetMerchant")
    if not pm then return false end
    local lever = pm:FindFirstChild("Podium" .. podiumNum .. "Lever")
    if not lever then return false end
    local prompt = lever:FindFirstChildOfClass("ProximityPrompt")
    if prompt then
        fireproximityprompt(prompt)
        return true
    end
    return false
end

local function autoBuyEggs()
    local stock = scanEggStock()
    local bought = 0
    local priority = TIER_ORDER[TierPriority] or 4
    for i = 1, 5 do
        if stock[i] and TIER_ORDER[stock[i]] == priority then
            if buyEgg(i) then
                bought = bought + 1
                task.wait(0.5)
            end
        end
    end
    EggsBought = EggsBought + bought
    statusLabel.Text = "Status: " .. (Enabled and "ON" or "OFF") .. "\nBought: " .. EggsBought .. "\nUptime: " .. getUptime()
    
    if bought > 0 and Req then
        sendReport(bought, stock)
    end
end

local function sendReport(count, stock)
    local stockStr = ""
    for i, tier in pairs(stock) do
        stockStr = stockStr .. "🥚 Podium " .. i .. ": " .. tier .. "\n"
    end
    pcall(function()
        Req({
            Url = WEBHOOK,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode({
                embeds = {{
                    title = "🥚 Egg Purchased!",
                    description = "👤 " .. Player.Name .. " bought **" .. count .. "** egg(s)!",
                    fields = {
                        {name = "Tier", value = "**" .. TierPriority .. "**", inline = true},
                        {name = "Total", value = "**" .. EggsBought .. "**", inline = true},
                        {name = "Available", value = stockStr, inline = false}
                    },
                    color = 16754176,
                    footer = {text = "Auto Buy Egg • " .. getUptime()}
                }}
            })
        })
    end)
end

-- ════════════════════════════════════════
--              RESTOCK MONITORING
-- ════════════════════════════════════════
local RestockTimer = nil
local lastRestockText = ""

task.spawn(function()
    local PG = Player:WaitForChild("PlayerGui")
    local MainUI = PG:WaitForChild("MainUI")
    local Menus = MainUI:WaitForChild("Menus")
    local GearShop = Menus:WaitForChild("GearShopFrame")
    RestockTimer = GearShop:WaitForChild("RestockTimer")
    
    RestockTimer:GetPropertyChangedSignal("Text"):Connect(function()
        local currentText = RestockTimer.Text
        if currentText ~= lastRestockText then
            lastRestockText = currentText
            if Enabled and (currentText:find("00:") or currentText:find("0:")) then
                task.wait(BuyDelay)
                autoBuyEggs()
            end
        end
    end)
end)

-- Update status every second
task.spawn(function()
    while true do
        task.wait(1)
        statusLabel.Text = "Status: " .. (Enabled and "ON" or "OFF") .. "\nBought: " .. EggsBought .. "\nUptime: " .. getUptime()
    end
end)

print("✅ Auto Buy Egg v2 Loaded!")
