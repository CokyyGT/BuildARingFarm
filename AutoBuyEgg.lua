local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local Player = Players.LocalPlayer
local WEBHOOK = "https://discord.com/api/webhooks/1514898766040137779/WqgxA1O9VZX7qxtmY3hfMsbHCjCZuVKmWuiBND2DZzup8S84ZfpvcMqeMP1VlA0PhXtW"
local Req = (syn and syn.request) or http_request or request

-- ═══════════════════════════════════
--        VARIABLES
-- ═══════════════════════════════════
local Enabled = false
local TierPriority = "Legendary"  -- Legendary, Epic, Rare, Common
local BuyDelay = 30
local EggsBought = 0
local StartTime = os.time()

local TIER_ORDER = {
    ["Legendary"] = 1,
    ["Epic"] = 2,
    ["Rare"] = 3,
    ["Common"] = 4
}

-- ═══════════════════════════════════
--        UI SETUP
-- ═══════════════════════════════════
local PG = Player:WaitForChild("PlayerGui")
local SG = Instance.new("ScreenGui")
SG.Name = "AutoBuyEggUI"
SG.ResetOnSpawn = false
SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SG.Parent = PG

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 300, 0, 350)
MainFrame.Position = UDim2.new(0.02, 0, 0.5, -175)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = SG

local Header = Instance.new("TextLabel")
Header.Size = UDim2.new(1, 0, 0, 40)
Header.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
Header.TextColor3 = Color3.fromRGB(255, 255, 255)
Header.TextSize = 14
Header.Font = Enum.Font.GothamBold
Header.Text = "🥚 Auto Buy Egg"
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, 0, 1, -40)
ScrollFrame.Position = UDim2.new(0, 0, 0, 40)
ScrollFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
ScrollFrame.ScrollBarThickness = 6
ScrollFrame.BorderSizePixel = 0
ScrollFrame.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = ScrollFrame
UIListLayout.Padding = UDim.new(0, 8)

local function mkLabel(parent, text, size)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -16, 0, size or 20)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.TextSize = 12
    label.Font = Enum.Font.Gotham
    label.Text = text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = parent
    return label
end

local function mkButton(parent, text, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -16, 0, 32)
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamBold
    btn.Text = text
    btn.BorderSizePixel = 0
    btn.Parent = parent
    return btn
end

-- Enable Toggle
mkLabel(ScrollFrame, "Status: " .. (Enabled and "ON" or "OFF"), 20)
local EnableBtn = mkButton(ScrollFrame, Enabled and "⏹ Disable" or "▶ Enable", Enabled and Color3.fromRGB(220, 50, 50) or Color3.fromRGB(50, 200, 50))
EnableBtn.MouseButton1Click:Connect(function()
    Enabled = not Enabled
    EnableBtn.Text = Enabled and "⏹ Disable" or "▶ Enable"
    EnableBtn.BackgroundColor3 = Enabled and Color3.fromRGB(220, 50, 50) or Color3.fromRGB(50, 200, 50)
end)

-- Tier Priority
mkLabel(ScrollFrame, "Tier Priority", 16)
local TierFrame = Instance.new("Frame")
TierFrame.Size = UDim2.new(1, -16, 0, 90)
TierFrame.BackgroundTransparency = 1
TierFrame.Parent = ScrollFrame

for i, tier in ipairs({"Legendary", "Epic", "Rare", "Common"}) do
    local tierBtn = mkButton(TierFrame, tier, TierPriority == tier and Color3.fromRGB(100, 150, 255) or Color3.fromRGB(60, 60, 70))
    tierBtn.Size = UDim2.new(0.5, -6, 0, 36)
    tierBtn.Position = UDim2.new(((i-1) % 2) * 0.5, (i-1) % 2 == 0 and 0 or 8, 0, math.floor((i-1)/2) * 40)
    tierBtn.Parent = TierFrame
    tierBtn.MouseButton1Click:Connect(function()
        TierPriority = tier
        for j, t in ipairs({"Legendary", "Epic", "Rare", "Common"}) do
            TierFrame:FindFirstChild(t .. "Btn").BackgroundColor3 = tier == t and Color3.fromRGB(100, 150, 255) or Color3.fromRGB(60, 60, 70)
        end
    end)
    tierBtn.Name = tier .. "Btn"
end

-- Delay Slider
mkLabel(ScrollFrame, "Delay: " .. BuyDelay .. "s", 16)
local DelaySlider = Instance.new("TextBox")
DelaySlider.Size = UDim2.new(1, -16, 0, 28)
DelaySlider.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
DelaySlider.TextColor3 = Color3.fromRGB(255, 255, 255)
DelaySlider.TextSize = 12
DelaySlider.Text = tostring(BuyDelay)
DelaySlider.Parent = ScrollFrame
DelaySlider.FocusLost:Connect(function()
    local val = tonumber(DelaySlider.Text)
    if val then BuyDelay = math.clamp(val, 0, 60) end
end)

-- Status Display
mkLabel(ScrollFrame, "Status", 16)
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -16, 0, 60)
StatusLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
StatusLabel.TextColor3 = Color3.fromRGB(100, 200, 100)
StatusLabel.TextSize = 11
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.Text = "Waiting Restock\nBought: 0\nUptime: 0s"
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.TextYAlignment = Enum.TextYAlignment.Top
StatusLabel.Parent = ScrollFrame

-- ═══════════════════════════════════
--        RESTOCK DETECTION
-- ═══════════════════════════════════
local function getUptime()
    local e = os.time() - StartTime
    return string.format("%dh %dm %ds", math.floor(e/3600), math.floor((e%3600)/60), e%60)
end

local function scanEggStock()
    local PetMerchant = workspace:FindFirstChild("PetMerchant")
    if not PetMerchant then return {} end
    
    local stock = {}
    for i = 1, 5 do
        local podium = PetMerchant:FindFirstChild("Podium" .. i .. "Stock")
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
    local PetMerchant = workspace:FindFirstChild("PetMerchant")
    if not PetMerchant then return false end
    
    local lever = PetMerchant:FindFirstChild("Podium" .. podiumNum .. "Lever")
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
    
    -- Sort by tier priority
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
    StatusLabel.Text = "Bought: " .. bought .. "\nTotal: " .. EggsBought .. "\nUptime: " .. getUptime()
    
    -- Webhook report
    if bought > 0 then
        sendReport(bought, stock)
    end
end

local function sendReport(count, stock)
    if not Req then return end
    
    local stockStr = ""
    for i, tier in pairs(stock) do
        stockStr = stockStr .. "Podium " .. i .. ": " .. tier .. "\n"
    end
    
    pcall(function()
        Req({
            Url = WEBHOOK,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode({
                embeds = {{
                    title = "🥚 Egg Purchase Report",
                    description = "👤 " .. Player.Name .. " bought " .. count .. " egg(s)!",
                    fields = {
                        {name = "Count", value = "**" .. count .. "**", inline = true},
                        {name = "Tier", value = "**" .. TierPriority .. "**", inline = true},
                        {name = "Stock Available", value = stockStr, inline = false}
                    },
                    color = 16754176,
                    footer = {text = "Auto Buy Egg • " .. getUptime()}
                }}
            })
        })
    end)
end

-- ═══════════════════════════════════
--        RESTOCK MONITORING
-- ═══════════════════════════════════
local RestockTimer = nil
local lastRestockText = ""

local function waitForRestockTimer()
    local PG = Player:WaitForChild("PlayerGui")
    local MainUI = PG:WaitForChild("MainUI")
    local Menus = MainUI:WaitForChild("Menus")
    local GearShop = Menus:WaitForChild("GearShopFrame")
    RestockTimer = GearShop:WaitForChild("RestockTimer")
end

task.spawn(waitForRestockTimer)

local function onRestockDetected()
    if not Enabled then return end
    
    StatusLabel.Text = "Waiting " .. BuyDelay .. "s...\nBought: " .. EggsBought .. "\nUptime: " .. getUptime()
    
    task.wait(BuyDelay)
    autoBuyEggs()
end

if RestockTimer then
    RestockTimer:GetPropertyChangedSignal("Text"):Connect(function()
        local currentText = RestockTimer.Text
        if currentText ~= lastRestockText then
            lastRestockText = currentText
            if currentText:find("00:") or currentText:find("0:") then
                onRestockDetected()
            end
        end
    end)
end

print("✅ Auto Buy Egg Script Loaded!")
