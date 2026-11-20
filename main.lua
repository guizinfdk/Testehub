local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

-- MÓDULOS
local EggState, AssetsData, PetsData
pcall(function() EggState   = require(ReplicatedStorage.Client.EggState) end)
pcall(function() AssetsData  = require(ReplicatedStorage.Data.Assets) end)
pcall(function() PetsData    = require(ReplicatedStorage.Data.Pets) end)

-- CORES
local ROXO      = Color3.fromRGB(100, 85, 120)
local ROXO_DARK = Color3.fromRGB(30, 25, 35)
local VERDE     = Color3.fromRGB(60, 200, 90)
local VERMELHO  = Color3.fromRGB(230, 50, 70)
local LARANJA   = Color3.fromRGB(230, 140, 50)
local AMARELO   = Color3.fromRGB(230, 180, 50)
local AZUL      = Color3.fromRGB(60, 150, 230)
local BG        = Color3.fromRGB(8, 8, 10)
local BG_BTN    = Color3.fromRGB(16, 16, 20)
local TXT       = Color3.fromRGB(210, 210, 220)
local TXT_DIM   = Color3.fromRGB(140, 140, 150)

local gui = Instance.new("ScreenGui")
gui.Name = "R7FLOWGui"
gui.ResetOnSpawn = false
gui.Parent = PlayerGui

-- TOAST
local toastContainer = Instance.new("Frame")
toastContainer.Name = "Toasts"
toastContainer.Size = UDim2.new(0, 300, 1, 0)
toastContainer.Position = UDim2.new(0.5, -150, 0, 0)
toastContainer.BackgroundTransparency = 1
toastContainer.ZIndex = 100
toastContainer.Parent = gui

local toastLayout = Instance.new("UIListLayout")
toastLayout.Padding = UDim.new(0, 6)
toastLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
toastLayout.SortOrder = Enum.SortOrder.LayoutOrder
toastLayout.Parent = toastContainer

local toastPad = Instance.new("UIPadding")
toastPad.PaddingTop = UDim.new(0, 20)
toastPad.Parent = toastContainer

function Toast(msg, cor)
    cor = cor or TXT
    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1, -20, 0, 30)
    t.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
    t.BackgroundTransparency = 0.1
    t.BorderSizePixel = 0
    t.Font = Enum.Font.GothamBold
    t.TextSize = 12
    t.TextColor3 = cor
    t.Text = msg
    t.ZIndex = 101
    t.Parent = toastContainer
    Instance.new("UICorner", t).CornerRadius = UDim.new(0, 6)
    local stroke = Instance.new("UIStroke")
    stroke.Color = cor
    stroke.Thickness = 1
    stroke.Transparency = 0.5
    stroke.Parent = t
    t.BackgroundTransparency = 1
    t.TextTransparency = 1
    TweenService:Create(t, TweenInfo.new(0.25), {
        BackgroundTransparency = 0.1, TextTransparency = 0,
    }):Play()
    task.delay(2, function()
        TweenService:Create(t, TweenInfo.new(0.3), {
            BackgroundTransparency = 1, TextTransparency = 1,
        }):Play()
        task.wait(0.35)
        t:Destroy()
    end)
end

-- HOLDER
local holder = Instance.new("Frame")
holder.Name = "Holder"
holder.Size = UDim2.new(0, 340, 0, 260)
holder.Position = UDim2.new(0.5, -170, 0.1, 0)
holder.BackgroundTransparency = 1
holder.Active = true
holder.Draggable = true
holder.ClipsDescendants = true
holder.Parent = gui

local bordaGradiente = Instance.new("Frame")
bordaGradiente.Size = UDim2.new(1, 4, 1, 4)
bordaGradiente.Position = UDim2.new(0, -2, 0, -2)
bordaGradiente.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
bordaGradiente.BorderSizePixel = 0
bordaGradiente.ZIndex = 1
bordaGradiente.Parent = holder
Instance.new("UICorner", bordaGradiente).CornerRadius = UDim.new(0, 14)

local gradBorda = Instance.new("UIGradient")
gradBorda.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(15, 15, 18)),
    ColorSequenceKeypoint.new(0.35, ROXO),
    ColorSequenceKeypoint.new(0.60, Color3.fromRGB(200, 200, 200)),
    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(15, 15, 18)),
})
gradBorda.Parent = bordaGradiente

local menu = Instance.new("Frame")
menu.Size = UDim2.new(1, -4, 1, -4)
menu.Position = UDim2.new(0, 2, 0, 2)
menu.BackgroundColor3 = BG
menu.BorderSizePixel = 0
menu.ZIndex = 2
menu.Parent = holder
Instance.new("UICorner", menu).CornerRadius = UDim.new(0, 12)

-- HEADER
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 36)
header.BackgroundTransparency = 1
header.ZIndex = 3
header.Parent = menu

local ledHeader = Instance.new("Frame")
ledHeader.Size = UDim2.new(0, 6, 0, 6)
ledHeader.Position = UDim2.new(0, 10, 0, 15)
ledHeader.BackgroundColor3 = VERMELHO
ledHeader.BorderSizePixel = 0
ledHeader.ZIndex = 4
ledHeader.Parent = header
Instance.new("UICorner", ledHeader).CornerRadius = UDim.new(1, 0)

local logoHeader = Instance.new("ImageLabel")
logoHeader.Name = "Logo"
logoHeader.Size = UDim2.new(0, 20, 0, 20)
logoHeader.Position = UDim2.new(0, 22, 0, 8)
logoHeader.BackgroundTransparency = 1
logoHeader.Image = "rbxassetid://82209165523926"
logoHeader.ScaleType = Enum.ScaleType.Fit
logoHeader.ZIndex = 4
logoHeader.Parent = header

local titulo = Instance.new("TextLabel")
titulo.Size = UDim2.new(1, -100, 0, 14)
titulo.Position = UDim2.new(0, 46, 0, 4)
titulo.BackgroundTransparency = 1
titulo.Font = Enum.Font.GothamBold
titulo.TextSize = 13
titulo.TextColor3 = Color3.fromRGB(255, 255, 255)
titulo.TextXAlignment = Enum.TextXAlignment.Left
titulo.Text = "R7FLOW"
titulo.ZIndex = 4
titulo.Parent = header

local subtitulo = Instance.new("TextLabel")
subtitulo.Size = UDim2.new(1, -100, 0, 10)
subtitulo.Position = UDim2.new(0, 46, 0, 19)
subtitulo.BackgroundTransparency = 1
subtitulo.Font = Enum.Font.Gotham
subtitulo.TextSize = 8
subtitulo.TextColor3 = TXT_DIM
subtitulo.TextXAlignment = Enum.TextXAlignment.Left
subtitulo.Text = "v15 | IB: @caligsc"
subtitulo.ZIndex = 4
subtitulo.Parent = header

local btnMin = Instance.new("TextButton")
btnMin.Size = UDim2.new(0, 18, 0, 18)
btnMin.Position = UDim2.new(1, -44, 0, 9)
btnMin.BackgroundTransparency = 1
btnMin.Font = Enum.Font.GothamBold
btnMin.TextSize = 14
btnMin.TextColor3 = TXT_DIM
btnMin.Text = "—"
btnMin.ZIndex = 5
btnMin.Parent = header
btnMin.MouseEnter:Connect(function() btnMin.TextColor3 = Color3.fromRGB(200, 200, 200) end)
btnMin.MouseLeave:Connect(function() btnMin.TextColor3 = TXT_DIM end)

local btnFechar = Instance.new("TextButton")
btnFechar.Size = UDim2.new(0, 18, 0, 18)
btnFechar.Position = UDim2.new(1, -22, 0, 9)
btnFechar.BackgroundTransparency = 1
btnFechar.Font = Enum.Font.GothamBold
btnFechar.TextSize = 12
btnFechar.TextColor3 = TXT_DIM
btnFechar.Text = "✕"
btnFechar.ZIndex = 5
btnFechar.Parent = header
btnFechar.MouseEnter:Connect(function() btnFechar.TextColor3 = VERMELHO end)
btnFechar.MouseLeave:Connect(function() btnFechar.TextColor3 = TXT_DIM end)
btnFechar.MouseButton1Click:Connect(function() holder.Visible = false end)

local faixaTopo = Instance.new("Frame")
faixaTopo.Size = UDim2.new(1, -16, 0, 2)
faixaTopo.Position = UDim2.new(0, 8, 0, 36)
faixaTopo.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
faixaTopo.BorderSizePixel = 0
faixaTopo.ZIndex = 3
faixaTopo.Parent = menu
local gradTopo = Instance.new("UIGradient")
gradTopo.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0.00, 1),
    NumberSequenceKeypoint.new(0.20, 0),
    NumberSequenceKeypoint.new(0.80, 0),
    NumberSequenceKeypoint.new(1.00, 1),
})
gradTopo.Color = ColorSequence.new(ROXO, Color3.fromRGB(200, 200, 200))
gradTopo.Parent = faixaTopo

-- CONTAINER STEAL (único, ocupa o espaço todo)
local containerSteal = Instance.new("Frame")
containerSteal.Size = UDim2.new(1, -16, 0, 188)
containerSteal.Position = UDim2.new(0, 8, 0, 42)
containerSteal.BackgroundTransparency = 1
containerSteal.ZIndex = 3
containerSteal.Parent = menu

-- FAIXA BASE + RODAPÉ
local faixaBase = Instance.new("Frame")
faixaBase.Size = UDim2.new(1, -16, 0, 2)
faixaBase.Position = UDim2.new(0, 8, 1, -26)
faixaBase.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
faixaBase.BorderSizePixel = 0
faixaBase.ZIndex = 3
faixaBase.Parent = menu
local gradBase = Instance.new("UIGradient")
gradBase.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0.00, 1),
    NumberSequenceKeypoint.new(0.20, 0),
    NumberSequenceKeypoint.new(0.80, 0),
    NumberSequenceKeypoint.new(1.00, 1),
})
gradBase.Color = ColorSequence.new(ROXO, Color3.fromRGB(200, 200, 200))
gradBase.Parent = faixaBase

local rodape = Instance.new("Frame")
rodape.Size = UDim2.new(1, 0, 0, 20)
rodape.Position = UDim2.new(0, 0, 1, -23)
rodape.BackgroundTransparency = 1
rodape.ZIndex = 3
rodape.Parent = menu

local ledRodape = Instance.new("Frame")
ledRodape.Size = UDim2.new(0, 6, 0, 6)
ledRodape.Position = UDim2.new(0, 10, 0, 7)
ledRodape.BackgroundColor3 = VERDE
ledRodape.BorderSizePixel = 0
ledRodape.ZIndex = 4
ledRodape.Parent = rodape
Instance.new("UICorner", ledRodape).CornerRadius = UDim.new(1, 0)

local labelStatus = Instance.new("TextLabel")
labelStatus.Size = UDim2.new(1, -26, 1, 0)
labelStatus.Position = UDim2.new(0, 22, 0, 0)
labelStatus.BackgroundTransparency = 1
labelStatus.Font = Enum.Font.GothamBold
labelStatus.TextSize = 9
labelStatus.TextColor3 = VERDE
labelStatus.TextXAlignment = Enum.TextXAlignment.Left
labelStatus.Text = "STATUS: STEAL MODE"
labelStatus.ZIndex = 4
labelStatus.Parent = rodape

-- MINIMIZAR
local corpoPainel = { faixaTopo, containerSteal, faixaBase, rodape }
local minimizado = false
local tamanhoNormal = UDim2.new(0, 340, 0, 260)
local tamanhoMin    = UDim2.new(0, 200, 0, 36)

btnMin.MouseButton1Click:Connect(function()
    minimizado = not minimizado
    if minimizado then
        for _, obj in ipairs(corpoPainel) do obj.Visible = false end
        btnMin.Text = "□"
    else
        for _, obj in ipairs(corpoPainel) do obj.Visible = true end
        btnMin.Text = "—"
    end

    local posAtual = holder.AbsolutePosition
    local tamAtual = holder.AbsoluteSize
    local centroX  = posAtual.X + tamAtual.X / 2

    local novoTam = minimizado and tamanhoMin or tamanhoNormal
    local novoX   = centroX - novoTam.X.Offset / 2

    TweenService:Create(holder, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
        Size = novoTam,
        Position = UDim2.new(0, novoX, holder.Position.Y.Scale, holder.Position.Y.Offset),
    }):Play()
end)

-- ============================================================
-- SISTEMA STEAL (inalterado)
-- ============================================================
local function iniciarSistemaSteal()
    local StealCfg = {
        SpeedCap = 1.15, HopRatio = 1.515, HopMin = 40, HopGap = 0.06, HopGapMin = 0.06,
        HopGapMax = 0.2, HopRetries = 6, HopLift = 42, LandOffset = 14, LandSettle = 0.08,
        DropDelay = 0.05, GrabInterval = 0.03, RegrabFar = 40, Height = 70,
        ClimbShare = 0.5, CarryRatio = 0.9, EasyRatio = 1.3,
    }
    local FpsSeq = { 60, 30, 0.15 }
    local FlightHeight = 10

    local S = {
        Carrying = false, Uid = nil, Delivered = 0, Busy = false, Cancel = false,
        Paused = false, Mult = 1, PulledAt = 0, HeldSeen = 0, GuessedDrop = false,
    }

    local statusSteal = nil

    local function status(msg)
        if statusSteal then statusSteal(tostring(msg)) end
    end

    local function root()
        local c = LocalPlayer.Character
        return c and c:FindFirstChild("HumanoidRootPart")
    end

    -- ---------- SHIELD ----------
    local shield = { Active = false, Original = nil, Clone = nil, Links = {}, HB = nil, Added = nil }

    local function walkSpeed()
        local ch = LocalPlayer.Character
        local h = ch and ch:FindFirstChildOfClass("Humanoid")
        local speed = h and h.WalkSpeed or 16
        if shield.Original and shield.Original.Health > 0 then
            speed = math.min(speed, shield.Original.WalkSpeed)
        end
        pcall(function()
            local stat = LocalPlayer:FindFirstChild("leaderstats")
            stat = stat and stat:FindFirstChild("Speed")
            if stat then
                local util = require(ReplicatedStorage.Shared.Util.TreadmillUtil)
                local v = util.SpeedPowerToWalkSpeed(stat.Value)
                if type(v) == "number" and v > 0 then speed = math.min(speed, v) end
            end
        end)
        return speed
    end

    local function shieldControls(h)
        pcall(function()
            local s = LocalPlayer:FindFirstChild("PlayerScripts")
            local m = s and s:FindFirstChild("PlayerModule")
            if m then
                local c = require(m):GetControls()
                if type(c) == "table" then c.humanoid = h end
            end
        end)
    end

    local function shieldAnimate(ch)
        local a = ch and ch:FindFirstChild("Animate")
        if a and a:IsA("LocalScript") then
            task.spawn(function() a.Enabled = false task.wait() a.Enabled = true end)
        end
    end

    local function shieldUnlink()
        for _, l in ipairs(shield.Links) do pcall(function() l:Disconnect() end) end
        table.clear(shield.Links)
    end

    local groundedStates = {
        [Enum.HumanoidStateType.Running] = true,
        [Enum.HumanoidStateType.RunningNoPhysics] = true,
        [Enum.HumanoidStateType.Landed] = true,
    }
    local function grounded(h)
        if not h or h.Health <= 0 or h.FloorMaterial == Enum.Material.Air then return false end
        return groundedStates[h:GetState()] == true
    end

    local function shieldSwap()
        if not shield.Active then return end
        local ch = LocalPlayer.Character
        local h = ch and ch:FindFirstChildOfClass("Humanoid")
        if not h or h.Health <= 0 then return end
        if shield.Clone and shield.Clone.Parent == ch then return end
        if not grounded(h) then return end
        local clone = h:Clone()
        h.Parent = nil
        clone.Parent = ch
        workspace.CurrentCamera.CameraSubject = clone
        shieldControls(clone)
        shieldAnimate(ch)
        shield.Original = h
        shield.Clone = clone
        table.insert(shield.Links, h:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
            if clone.Parent ~= nil then clone.WalkSpeed = h.WalkSpeed end
        end))
        local a1 = h:FindFirstChildOfClass("Animator")
        local a2 = clone:FindFirstChildOfClass("Animator")
        if a1 and a2 then
            table.insert(shield.Links, a1.AnimationPlayed:Connect(function(played)
                local anim = played.Animation
                if not anim or clone.Parent == nil then return end
                local ok, track = pcall(function() return a2:LoadAnimation(anim) end)
                if not ok or not track then return end
                pcall(function()
                    track.Priority = played.Priority
                    track.Looped = played.Looped
                    track:Play(0.05, math.max(played.WeightTarget, 0.01), played.Speed)
                end)
                played.Stopped:Connect(function() pcall(function() track:Stop(0.1) end) end)
            end))
        end
        table.insert(shield.Links, clone.Died:Connect(function()
            shieldUnlink()
            shield.Original, shield.Clone = nil, nil
            local c = LocalPlayer.Character
            if c and h.Parent == nil then
                h.Parent = c
                workspace.CurrentCamera.CameraSubject = h
                shieldControls(h)
            end
            pcall(function() clone:Destroy() end)
            h.Health = 0
        end))
    end

    local function shieldStart()
        if shield.Active then return end
        shield.Active = true
        shieldSwap()
        local n = 0
        shield.HB = RunService.Heartbeat:Connect(function(dt)
            if not shield.Active then return end
            n += dt
            local ch = LocalPlayer.Character
            local miss = not (shield.Clone and ch and shield.Clone.Parent == ch)
            if (miss and 0.25 or 3) <= n then n = 0 shieldSwap() end
        end)
        shield.Added = LocalPlayer.CharacterAdded:Connect(function(ch)
            if not shield.Active then return end
            shieldUnlink()
            shield.Original, shield.Clone = nil, nil
            task.spawn(function()
                ch:WaitForChild("Humanoid", 10)
                task.wait(1)
                if shield.Active then shieldSwap() end
            end)
        end)
    end

    local function shieldStop()
        if not shield.Active then return end
        shield.Active = false
        if shield.HB then shield.HB:Disconnect() shield.HB = nil end
        if shield.Added then shield.Added:Disconnect() shield.Added = nil end
        shieldUnlink()
        if shield.Original and shield.Clone then
            local ch = LocalPlayer.Character
            if ch and shield.Clone.Parent == ch then
                pcall(function() shield.Clone:Destroy() end)
                pcall(function()
                    shield.Original.Parent = ch
                    workspace.CurrentCamera.CameraSubject = shield.Original
                    shieldControls(shield.Original)
                end)
            end
        end
        shield.Original, shield.Clone = nil, nil
    end

    -- ---------- RARITY ----------
    local RarityScore = {
        ["Light & Dark"]=1300,["Titan"]=1100,["Divine"]=1000,["Transcendent"]=1000,
        ["Superior"]=1000,["Eternal"]=900,["Limited"]=900,["Secret"]=800,["Exotic"]=800,
        ["Cosmic"]=700,["Exclusive"]=700,["Admin"]=700,["Mythic"]=600,["Mythical"]=600,
        ["Prismatic"]=600,["Rainbow"]=600,["Squishy God"]=600,["BrainrotGod"]=600,
        ["Legendary"]=500,["Epic"]=400,["Rare"]=300,["SuperRare"]=200,["Celestial"]=200,
        ["Uncommon"]=200,["Basic"]=100,["Common"]=100,
    }

    local rarityFilterEnabled = false
    local targetRarity = "Todos"
    local rarityOptions = { "Todos","Common","Uncommon","Rare","Epic","Legendary","Mythic","Cosmic","Secret","Eternal","Divine" }
    local rarityIdx = 1

    local iconCacheSteal = {}
    local function getPetIconSteal(record)
        if not record then return nil end
        local targetName = record.Pet or record.PetId or record.PetName
            or record.AssetCategory or record.Category
        if targetName and iconCacheSteal[targetName] then
            return iconCacheSteal[targetName]
        end
        local rawIcon = record.Icon or record.PetIcon or record.ImageAsset or record.TextureId
        local result
        local function normalizeIcon(value)
            if value == nil or value == "" then return nil end
            local valueStr = tostring(value)
            if valueStr:match("^rbxassetid://") or valueStr:match("://") then
                return valueStr
            end
            if valueStr:match("^%d+$") then return "rbxassetid://" .. valueStr end
            return nil
        end
        result = normalizeIcon(rawIcon)
        if not result and targetName and PetsData then
            local info = (PetsData.Directory or PetsData)[targetName]
            if type(info) == "table" then
                result = normalizeIcon(info.Icon or info.Image or info.AssetId)
            end
        end
        if not result and targetName and AssetsData then
            local info = (AssetsData.Directory or AssetsData)[targetName]
            if type(info) == "table" then
                result = normalizeIcon(info.Icon or info.Image or info.AssetId)
            end
        end
        if targetName and result then iconCacheSteal[targetName] = result end
        return result
    end

    -- ---------- SNAPSHOT ----------
    local function snapshot()
        if type(EggState) ~= "table" then return {} end
        local list = {}
        if type(EggState.ReadFieldEggs) == "function" then
            local ok, snap = pcall(EggState.ReadFieldEggs)
            if ok and snap and snap.Records then
                for _, r in ipairs(snap.Records) do
                    if r and r.BoundsCFrame and (r.State == "Slot" or r.State == "Dropped") then
                        list[#list + 1] = r
                    end
                end
            end
        end
        return list
    end

    local function eggPosition(uid)
        for _, r in ipairs(snapshot()) do
            if r.Uid == uid then return r.BoundsCFrame.Position end
        end
        return nil
    end

    local function getRarityName(record)
        if not record then return "Common" end
        local name
        if record.Rarity then
            local r = record.Rarity
            name = type(r) == "table" and (r.DisplayName or r._id or r.Name) or tostring(r)
        end
        if not name then
            local info = AssetsData and (AssetsData.Directory or AssetsData)
            info = info and info[tostring(record.AssetCategory or record.Category or record.Name or "")]
            if info and info.Rarity then
                local r = info.Rarity
                name = type(r) == "table" and (r.DisplayName or r._id or r.Name) or tostring(r)
            end
        end
        return name or "Common"
    end

    local function getEggValue(record)
        local cat = tostring(record.AssetCategory or record.Category or record.Name or "Egg")
        local info = AssetsData and (AssetsData.Directory or AssetsData)
        info = info and info[cat]
        local raw = tonumber(
            record.Income or record.EarningRate or record.MoneyPerSecond or
            record.Money or record.Cash or record.Value or record.Price or 0
        ) or 0
        if raw <= 0 and type(info) == "table" then
            raw = tonumber(info.Income or info.EarningRate or info.MoneyPerSecond or
                info.Money or info.Cash or info.SalePrice or info.Price or 0) or 0
        end
        local scale = tonumber(record.AssetScale or record.Scale or record.NestScale) or 1
        local val = raw * scale
        if val <= 0 then
            local score = RarityScore[getRarityName(record)] or 100
            local area = tonumber(tostring(record.AreaId or ""):match("%d+")) or 50
            val = score * math.max(area, 50) * math.max(scale, 1)
        end
        return val
    end

    local function money(v)
        v = tonumber(v) or 0
        if v >= 1e15 then return string.format("%.1fQ", v/1e15)
        elseif v >= 1e12 then return string.format("%.1fT", v/1e12)
        elseif v >= 1e9 then return string.format("%.1fB", v/1e9)
        elseif v >= 1e6 then return string.format("%.1fM", v/1e6)
        elseif v >= 1e3 then return string.format("%.1fK", v/1e3)
        else return string.format("%d", math.floor(v + 0.5)) end
    end

    -- ---------- TAKE / DROP ----------
    local function takeEgg(uid)
        if type(uid) == "string" and type(EggState) == "table" and type(EggState.CarryFieldEgg) == "function" then
            pcall(EggState.CarryFieldEgg, uid)
        end
    end
    local function dropEgg()
        if type(EggState) == "table" and type(EggState.DropFieldEgg) == "function" then
            pcall(EggState.DropFieldEgg, "PlayerRequest")
        end
    end
    local function promptNear(pos, radius)
        local best, bd = nil, radius
        for _, child in ipairs(workspace:GetChildren()) do
            if child.Name == "SmartPromptPart" and child:IsA("BasePart") then
                local p = child:FindFirstChild("CarryAreaEgg")
                if p and p:IsA("ProximityPrompt") then
                    local d = (child.Position - pos).Magnitude
                    if d < bd then best, bd = p, d end
                end
            end
        end
        return best
    end
    local function heldByMe(uid)
        local ch = LocalPlayer.Character
        if type(uid) ~= "string" or not ch then return false end
        local egg = workspace:FindFirstChild(uid)
        if not egg then return false end
        for _, d in ipairs(egg:GetDescendants()) do
            if d:IsA("WeldConstraint") or d:IsA("JointInstance") then
                local ok, a, b = pcall(function() return d.Part0, d.Part1 end)
                if ok and ((a and a:IsDescendantOf(ch)) or (b and b:IsDescendantOf(ch))) then return true end
            end
        end
        return false
    end

    -- ---------- LISTENER ----------
    if type(EggState) == "table" and type(EggState.CarryChanged) == "table"
        and type(EggState.CarryChanged.Connect) == "function" then
        EggState.CarryChanged:Connect(function(arg)
            local c = type(arg) == "table" and arg.IsCarrying == true
            if c and arg.GuardDisabled == true then c = false end
            S.GuessedDrop = false
            if c then S.HeldSeen = os.clock() end
            if c and type(arg.Uid) == "string" then
                S.Uid = arg.Uid
                local m = tonumber(arg.SpeedMultiplier)
                if m and m > 0 then S.Mult = m end
            end
            S.Carrying = c
        end)
    end

    pcall(function()
        local pkg = ReplicatedStorage:FindFirstChild("Packages")
        local net = pkg and pkg:FindFirstChild("Networking")
        local r = net and net:FindFirstChild("RE/EggWorld/FieldEggRedeemVerdict")
        if r then r.OnClientEvent:Connect(function() S.Delivered = os.clock() end) end
    end)
    pcall(function()
        local pkg = ReplicatedStorage:FindFirstChild("Packages")
        local net = pkg and pkg:FindFirstChild("Networking")
        local r = net and net:FindFirstChild("RE/RigSync/Refresh")
        if r then r.OnClientEvent:Connect(function(arg)
            if type(arg) == "table" and arg.Action == "Relocate" then S.PulledAt = os.clock() end
        end) end
    end)

    task.spawn(function()
        while true do
            task.wait(0.2)
            if not S.Carrying then
                if S.GuessedDrop and heldByMe(S.Uid) then
                    S.GuessedDrop, S.Carrying, S.HeldSeen = false, true, os.clock()
                end
            elseif heldByMe(S.Uid) then
                S.HeldSeen = os.clock()
            elseif os.clock() - S.HeldSeen > 0.8 then
                S.Carrying, S.GuessedDrop = false, true
            end
        end
    end)

    -- ---------- MOVIMENTO ----------
    local function frozenCamera()
        local cam = workspace.CurrentCamera
        if not cam then return function() end end
        local ot = cam.CameraType
        local fr = cam.CFrame
        pcall(function() cam.CameraType = Enum.CameraType.Scriptable cam.CFrame = fr end)
        return function() pcall(function() cam.CameraType = ot end) end
    end

    local fpsGen = 0
    local function fpsOn()
        if typeof(setfpscap) ~= "function" then return end
        fpsGen += 1
        local mine = fpsGen
        task.spawn(function()
            local high = true
            local st = os.clock()
            while fpsGen == mine and os.clock() - st < 60 do
                pcall(setfpscap, high and FpsSeq[1] or FpsSeq[2])
                high = not high
                task.wait(FpsSeq[3])
            end
        end)
    end
    local function fpsOff()
        fpsGen += 1
        if typeof(setfpscap) == "function" then pcall(setfpscap, 240) end
    end

    local stealClone = nil
    local function dropClone()
        if stealClone then pcall(function() stealClone:Destroy() end) stealClone = nil end
    end
    local function postClone()
        dropClone()
        local ch = LocalPlayer.Character
        if not ch then return end
        local was = ch.Archivable
        ch.Archivable = true
        local copy = ch:Clone()
        ch.Archivable = was
        if copy then
            for _, d in ipairs(copy:GetDescendants()) do
                if d:IsA("LuaSourceContainer") or d:IsA("Humanoid") then
                    pcall(function() d:Destroy() end)
                elseif d:IsA("BasePart") then
                    d.Anchored = true d.CanCollide = false d.CanTouch = false d.CanQuery = false
                end
            end
            copy.Name = "PHZClone"
            copy.Parent = workspace
            stealClone = copy
        end
    end

    local function lineInfo()
        local w = workspace:FindFirstChild("World") or workspace:FindFirstChild("__OBJECTS")
        w = w and w:FindFirstChild("Areas")
        w = w and w:FindFirstChild("SeparationLine")
        local ok = w and w:IsA("BasePart")
        return ok and w.Position.X or 552.2, ok and w.Position.Y or 67.67
    end
    local function homePoint()
        for _, def in ipairs({
            { { "GearGiver_Slap", "Podium" }, Vector3.new(-16.415, 21.072, -6.106) },
            { { "World", "Machines", "RiftMachine", "Rift", "Meshes/VoidPortal_Cube.003" }, Vector3.new(-26.776, 1.75, 18.665) },
            { { "__OBJECTS", "Machines", "RiftMachine", "Rift", "Meshes/VoidPortal_Cube.003" }, Vector3.new(-26.776, 1.75, 18.665) },
        }) do
            local n = workspace
            for _, name in ipairs(def[1]) do n = n and n:FindFirstChild(name) or nil end
            if n and n:IsA("BasePart") then return n.CFrame:PointToWorldSpace(def[2]) end
        end
        return Vector3.new(528.7, 70.57, -364.11)
    end
    local function place(pos)
        local r = root()
        if not r then return end
        pcall(function()
            r.CFrame = CFrame.new(pos) * CFrame.Angles(0, math.rad(90), 0)
            r.AssemblyLinearVelocity = Vector3.zero
            r.AssemblyAngularVelocity = Vector3.zero
        end)
    end

    local dangerCache, dangerAt = {}, 0
    local function dangers()
        if os.clock() - dangerAt < 1 then return dangerCache end
        dangerAt = os.clock()
        local list = {}
        local function add(inst)
            local ok, cf, size = pcall(function()
                if inst:IsA("Model") then return inst:GetBoundingBox()
                elseif inst:IsA("BasePart") then return inst.CFrame, inst.Size end
            end)
            if ok and cf and size then
                local half = Vector3.new(math.abs(size.X), 0, math.abs(size.Z)) * 0.5
                local rot = (cf - cf.Position):VectorToWorldSpace(half)
                local rx = math.max(math.abs(rot.X), half.X, half.Z)
                local rz = math.max(math.abs(rot.Z), half.X, half.Z)
                list[#list + 1] = { MinX = cf.Position.X - rx, MaxX = cf.Position.X + rx,
                    MinZ = cf.Position.Z - rz, MaxZ = cf.Position.Z + rz }
            end
        end
        local function bad(name)
            if name == "ScrambleLocalVisuals" or name == "DrScrambleEvent" then return false end
            name = string.lower(name)
            return string.find(name, "portal", 1, true) or string.find(name, "teleport", 1, true)
                or string.find(name, "mech", 1, true) or string.find(name, "arena", 1, true)
                or string.find(name, "scramble", 1, true)
        end
        for _, child in ipairs(workspace:GetChildren()) do
            if (child:IsA("Model") or child:IsA("BasePart") or child:IsA("Folder")) and bad(child.Name) then
                if child:IsA("Folder") then
                    for _, inner in ipairs(child:GetChildren()) do add(inner) end
                else add(child) end
            end
        end
        local build = workspace:FindFirstChild("World")
        build = build and build:FindFirstChild("Build")
        if build then
            for _, child in ipairs(build:GetChildren()) do
                if bad(child.Name) then
                    for _, inner in ipairs(child:GetChildren()) do add(inner) end
                end
            end
        end
        dangerCache = list
        return list
    end

    local function avoid(from, to)
        for _, d in ipairs(dangers()) do
            local x0, x1, z0, z1 = d.MinX - 12, d.MaxX + 12, d.MinZ - 12, d.MaxZ + 12
            local inside = from.X >= x0 and from.X <= x1 and from.Z >= z0 and from.Z <= z1
            if not inside then
                local t0, t1, hit = 0, 1, true
                for _, axis in ipairs({ { from.X, to.X - from.X, x0, x1 }, { from.Z, to.Z - from.Z, z0, z1 } }) do
                    local pos, delta, lo, hi = axis[1], axis[2], axis[3], axis[4]
                    if math.abs(delta) < 1e-6 then
                        if pos < lo or pos > hi then hit = false end
                    else
                        local ta, tb = (lo - pos) / delta, (hi - pos) / delta
                        if ta > tb then ta, tb = tb, ta end
                        t0, t1 = math.max(t0, ta), math.min(t1, tb)
                        if t0 > t1 then hit = false end
                    end
                end
                if hit then
                    local zLow, zHigh = z0 - 2, z1 + 2
                    local z = math.abs(from.Z - zLow) <= math.abs(from.Z - zHigh) and zLow or zHigh
                    if z < -440 or z > -290 then z = z == zLow and zHigh or zLow end
                    local x = math.abs(from.X - x0) <= math.abs(from.X - x1) and x0 or x1
                    if math.abs(from.Z - z) < 3 then
                        x = math.abs(to.X - x0) <= math.abs(to.X - x1) and x0 or x1
                    end
                    return Vector3.new(x, to.Y, z)
                end
            end
        end
        return to
    end

    local function waitIfPaused()
        while S.Paused and not S.Cancel do RunService.Heartbeat:Wait() end
    end

    -- ---------- RUN TO EGG ----------
    local function runToEgg(uid, egg)
        local lineX = lineInfo()
        local home = homePoint()
        local ch = LocalPlayer.Character
        local hum = ch and ch:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.PlatformStand = false
            if ch:FindFirstChildWhichIsA("Tool") then pcall(function() hum:UnequipTools() end) end
        end
        local r = root()
        if not r then return false end
        local stage = "field"
        if r.Position.X < lineX - 2 and Vector3.new(r.Position.X - home.X, 0, r.Position.Z - home.Z).Magnitude > 20 then
            stage = "safe"
        end
        local started    = os.clock()
        local lastCheck  = os.clock()
        local lastPos    = r.Position
        local lastTake   = 0
        local stuckCount = 0

        while os.clock() - started < 120 and not S.Cancel do
            waitIfPaused()
            r = root()
            if not r then return false end

            local fe_dist = Vector3.new(egg.X - r.Position.X, 0, egg.Z - r.Position.Z)
            -- Chegada precisa: corta o movimento antes de atravessar o alvo.
            if stage == "field" and fe_dist.Magnitude <= 1.8 then
                pcall(function()
                    r.AssemblyLinearVelocity = Vector3.zero
                    r.AssemblyAngularVelocity = Vector3.zero
                    if hum then hum:Move(Vector3.zero, false) end
                end)
                break
            end

            local target = egg
            if stage == "safe" then
                if Vector3.new(home.X - r.Position.X, 0, home.Z - r.Position.Z).Magnitude <= 6 then
                    stage = "field"
                else
                    target = home
                end
            end

            local wp    = avoid(r.Position, target)
            local flat  = Vector3.new(wp.X - r.Position.X, 0, wp.Z - r.Position.Z)
            local unit  = flat.Magnitude > 0.01 and flat.Unit or Vector3.zero
            local speed = math.max(walkSpeed() * StealCfg.SpeedCap, 8)
            -- Desacelera progressivamente conforme se aproxima do Egg.
            local moveSpeed = math.min(speed, flat.Magnitude * 3)
            local v = unit * moveSpeed

            pcall(function()
                r.AssemblyLinearVelocity  = Vector3.new(v.X, r.AssemblyLinearVelocity.Y, v.Z)
                r.AssemblyAngularVelocity = Vector3.zero
                if hum then
                    if stage ~= "field" or fe_dist.Magnitude > 1.8 then
                        hum:Move(unit, false)
                    else
                        hum:Move(Vector3.zero, false)
                    end
                end
            end)

            if os.clock() - lastCheck >= 1.2 then
                local moved = (r.Position - lastPos).Magnitude
                if moved < 3 and fe_dist.Magnitude > 8 then
                    stuckCount += 1
                    if stuckCount >= 2 then
                        if flat.Magnitude > 0.5 then
                            local step = math.min(6, flat.Magnitude)
                            local dir  = flat.Unit
                            local newPos = r.Position + dir * step + Vector3.new(0, 2, 0)
                            pcall(function()
                                r.CFrame = CFrame.lookAt(newPos, newPos + dir)
                                r.AssemblyLinearVelocity  = Vector3.zero
                                r.AssemblyAngularVelocity = Vector3.zero
                            end)
                        end
                        stuckCount = 0
                    else
                        pcall(function()
                            if hum then hum.Jump = true end
                            r.AssemblyLinearVelocity = Vector3.new(
                                v.X,
                                math.max(r.AssemblyLinearVelocity.Y, 60),
                                v.Z
                            )
                        end)
                    end
                else
                    stuckCount = 0
                end
                lastPos, lastCheck = r.Position, os.clock()
            end

            if stage == "field" and fe_dist.Magnitude <= 9 and os.clock() - lastTake > 0.1 then
                lastTake = os.clock()
                takeEgg(uid)
            end

            RunService.Heartbeat:Wait()
        end

        r = root()
        if r then
            pcall(function()
                r.AssemblyLinearVelocity  = Vector3.zero
                r.AssemblyAngularVelocity = Vector3.zero
                if hum then hum:Move(Vector3.zero, false) end
            end)
        end
        return S.Carrying or (r ~= nil and Vector3.new(egg.X - r.Position.X, 0, egg.Z - r.Position.Z).Magnitude <= 6)
    end

    local function eggNow(uid, cache)
        local node = workspace:FindFirstChild(uid)
        local slots = workspace:FindFirstChild("AreaEggSlotsClient")
        node = node or (slots and slots:FindFirstChild(uid))
        if node then
            local ok, pos = pcall(function() return node:GetPivot().Position end)
            if ok and pos then
                cache.Pos, cache.At = pos, os.clock()
                return pos
            end
        end
        if os.clock() - cache.At >= 0.5 then
            cache.At = os.clock()
            cache.Pos = eggPosition(uid) or cache.Pos
        end
        return cache.Pos
    end

    local function grab(uid, timeout)
        local cache = { At = 0 }
        local waited, since = 0, 1
        while not S.Carrying and waited < timeout and not S.Cancel do
            waitIfPaused()
            local r = root()
            local egg = eggNow(uid, cache)
            local dt = math.max(RunService.Heartbeat:Wait(), 1 / 240)
            waited += dt
            since += dt
            if r and egg then
                local delta = egg - r.Position
                local dist = delta.Magnitude
                local hum = r.Parent and r.Parent:FindFirstChildOfClass("Humanoid")
                if dist > 4 then
                    local pace = math.max(walkSpeed() * StealCfg.SpeedCap, 16)
                    local v = delta / math.max(0.08, dt)
                    if v.Magnitude > pace then v = v.Unit * pace end
                    pcall(function()
                        r.AssemblyLinearVelocity = Vector3.new(v.X, r.AssemblyLinearVelocity.Y, v.Z)
                        r.AssemblyAngularVelocity = Vector3.zero
                    end)
                    if hum then
                        local flat = Vector3.new(delta.X, 0, delta.Z)
                        if flat.Magnitude > 0.5 then pcall(function() hum:Move(flat.Unit, false) end)
                        else pcall(function() hum:Move(Vector3.zero, false) end) end
                    end
                else
                    pcall(function()
                        r.AssemblyLinearVelocity = Vector3.new(0, r.AssemblyLinearVelocity.Y, 0)
                        r.AssemblyAngularVelocity = Vector3.zero
                    end)
                    if hum then pcall(function() hum:Move(Vector3.zero, false) end) end
                end
                if since >= StealCfg.GrabInterval then
                    since = 0
                    local pr = promptNear(egg - Vector3.new(0, 3, 0), 12)
                    if pr and typeof(fireproximityprompt) == "function" then
                        pcall(function() pr.HoldDuration = 0 end)
                        pcall(fireproximityprompt, pr)
                    end
                    task.spawn(takeEgg, uid)
                end
            elseif since >= StealCfg.GrabInterval then
                since = 0
                task.spawn(takeEgg, uid)
            end
        end
        local r = root()
        if r then
            pcall(function()
                r.AssemblyLinearVelocity = Vector3.zero
                r.AssemblyAngularVelocity = Vector3.zero
            end)
            local hum = r.Parent and r.Parent:FindFirstChildOfClass("Humanoid")
            if hum then pcall(function() hum:Move(Vector3.zero, false) end) end
        end
        return S.Carrying and S.Uid == uid
    end

    local function regrab(uid)
        if S.Carrying then return true end
        local r = root()
        local egg = eggPosition(uid)
        if r and egg and Vector3.new(r.Position.X - egg.X, 0, r.Position.Z - egg.Z).Magnitude > StealCfg.RegrabFar then
            place(egg + Vector3.new(0, 3, 0))
        end
        return grab(uid, 3)
    end

    local function groundY(pos, fb)
        local y = fb
        pcall(function()
            local p = RaycastParams.new()
            p.FilterType = Enum.RaycastFilterType.Exclude
            p.FilterDescendantsInstances = { LocalPlayer.Character }
            p.IgnoreWater = true
            local hit = workspace:Raycast(pos + Vector3.new(0, 60, 0), Vector3.new(0, -140, 0), p)
            if hit and hit.Material ~= Enum.Material.Water and math.abs(hit.Position.Y - fb) < 40 then
                y = hit.Position.Y + 3.5
            end
        end)
        return y
    end

    local function carrySpeed(dist)
        local ws = walkSpeed()
        local base = ws * math.min(StealCfg.CarryRatio, StealCfg.SpeedCap) * S.Mult
        local fast = base * 1.5
        local excess = 5.5 * base
        local limit = fast
        if dist and dist > excess then
            limit = math.min(fast, base * dist / (dist - excess))
        end
        return math.min(math.max(math.min(base * StealCfg.EasyRatio, limit), base), math.max(ws * StealCfg.SpeedCap, base))
    end

    -- ---------- RUN HOME ----------
    local function runHome(lineX, laneZ)
        local started = os.clock()
        local home = homePoint()
        local checkpoint = lineX - 7
        local height = StealCfg.Height
        local share = math.clamp(StealCfg.ClimbShare, 0.1, 0.9)
        local descent = height * math.sqrt(1 - share * share) / share
        local ch = LocalPlayer.Character
        local hum = ch and ch:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
        local r = root()
        if r and ch and height > 0.5 and home.Y + height - 2 > r.Position.Y then
            pcall(function()
                ch:PivotTo(CFrame.new(Vector3.new(r.Position.X, home.Y + height, r.Position.Z)) * r.CFrame.Rotation)
                r.AssemblyLinearVelocity = Vector3.zero
                r.AssemblyAngularVelocity = Vector3.zero
            end)
        end
        local start = root()
        local speed = carrySpeed(start and (Vector3.new(start.Position.X - home.X, 0, start.Position.Z - home.Z).Magnitude + math.max(0, height) * 2) or nil)
        local last = os.clock()
        local timeout = 0
        while S.Carrying and S.Delivered < started and not S.Cancel and timeout < 25 do
            waitIfPaused()
            r = root()
            if not r then return false end
            local now = os.clock()
            local dt = math.max(now - last, 1 / 240)
            last = now
            timeout += dt
            local toHome = r.Position.X <= checkpoint + 2
            local target = toHome and home or Vector3.new(checkpoint, home.Y, laneZ)
            if toHome and Vector3.new(home.X - r.Position.X, 0, home.Z - r.Position.Z).Magnitude < 2 then break end
            local aim = avoid(r.Position, target)
            local flat = Vector3.new(aim.X - r.Position.X, 0, aim.Z - r.Position.Z)
            local remaining = toHome and 0 or math.max(0, r.Position.X - checkpoint)
            local wantY = home.Y + height
            if toHome or remaining <= descent then
                wantY = home.Y + height * math.clamp(remaining / math.max(descent, 1), 0, 1)
            end
            local vy = math.clamp((wantY - r.Position.Y) / 0.12, -speed * share, speed * share)
            local horizontal = math.sqrt(math.max(speed * speed - vy * vy, 0))
            local v = flat.Magnitude > 0.01 and flat.Unit * math.min(horizontal, flat.Magnitude / 0.05) or Vector3.zero
            pcall(function() r.AssemblyLinearVelocity = Vector3.new(v.X, vy, v.Z) end)
            RunService.Heartbeat:Wait()
        end
        if hum then pcall(function() hum:Move(Vector3.zero, false) end) end
        local settle = 0
        while settle < 2 and S.Delivered < started and S.Carrying and not S.Cancel do
            settle += RunService.Heartbeat:Wait()
        end
        if S.Carrying and S.Delivered < started and not S.Cancel then
            task.wait(0.2)
            dropEgg()
            local waited = 0
            while S.Delivered < started and waited < 1 do
                waited += RunService.Heartbeat:Wait()
            end
        end
        return S.Delivered >= started
    end

    -- ---------- INSTANT TP ----------
    local function instantTP(uid)
        if S.Cancel then return false end
        local started = os.clock()
        local lineX, lineY = lineInfo()
        local r = root()
        if not r then return false end
        local laneZ = math.clamp(r.Position.Z, -425, -300)
        local landing = Vector3.new(lineX + StealCfg.LandOffset, lineY + 3.35, laneZ)
        local hopStep = math.max(walkSpeed() * StealCfg.HopRatio, StealCfg.HopMin)
        local hopY = r.Position.Y + StealCfg.HopLift
        local x = r.Position.X
        local retries = 0
        local releaseCamera = frozenCamera()
        pcall(postClone)
        fpsOn()
        while x - hopStep > landing.X and not S.Cancel do
            waitIfPaused()
            if not S.Carrying then
                if not regrab(uid) then break end
                local cur = root()
                if cur then x = math.min(x, cur.Position.X) end
                continue
            end
            local nextX = x - hopStep
            local pulledBefore = S.PulledAt
            local held = 0
            while held < StealCfg.HopGap do
                place(Vector3.new(nextX, hopY, laneZ))
                held += RunService.Heartbeat:Wait()
            end
            local check = root()
            local pulled = S.PulledAt > pulledBefore
                or (check ~= nil and (check.Position.X - nextX > 10 or check.AssemblyLinearVelocity.Magnitude > 150))
            if pulled and S.Carrying and not S.Cancel then
                retries += 1
                StealCfg.HopGap = math.min(StealCfg.HopGapMax, StealCfg.HopGap + 0.02)
                if retries > StealCfg.HopRetries then break end
                local settle = 0
                while settle < 0.12 and not S.Cancel do
                    place(Vector3.new(x, hopY, laneZ))
                    settle += RunService.Heartbeat:Wait()
                end
            else
                x = nextX
                StealCfg.HopGap = math.max(StealCfg.HopGapMin, StealCfg.HopGap - 0.01)
            end
        end
        landing = Vector3.new(landing.X, groundY(landing, landing.Y), landing.Z)
        local function land()
            local cur = root()
            if cur and cur.Position.X <= landing.X + 1 and cur.Position.Y > landing.Y - 25 then
                pcall(function() cur.AssemblyLinearVelocity = Vector3.zero end)
                return
            end
            place(landing)
        end
        land()
        for _ = 1, 3 do
            local settle = 0
            while settle < StealCfg.LandSettle and not S.Cancel do
                settle += RunService.Heartbeat:Wait()
            end
            local landed = root()
            if S.Carrying and landed and (landed.Position.X - landing.X > 12 or landed.Position.Y < landing.Y - 25) then
                land()
            else break end
        end
        dropClone()
        if S.Carrying and not S.Cancel then
            local delay = 0
            while delay < StealCfg.DropDelay do
                delay += RunService.Heartbeat:Wait()
            end
            dropEgg()
            local waited = 0
            while S.Carrying and waited < 1 and not S.Cancel do
                waited += RunService.Heartbeat:Wait()
            end
            local cur = root()
            if cur then
                pcall(function()
                    cur.AssemblyLinearVelocity = Vector3.zero
                    cur.AssemblyAngularVelocity = Vector3.zero
                end)
            end
            releaseCamera()
            dropClone()
            if not grab(uid, 3) and not regrab(uid) then
                fpsOff()
                return false
            end
            dropClone()
        end
        releaseCamera()
        local ok = false
        if S.Carrying and not S.Cancel then
            ok = runHome(lineX, laneZ)
        end
        fpsOff()
        return ok or S.Delivered >= started
    end

    -- ---------- PIPELINE ----------
    local function stealAndDeliver(uid)
        if S.Busy then return end
        S.Busy = true
        S.Cancel = false
        S.Paused = false
        shieldStart()
        task.spawn(function()
            local ok, err = pcall(function()
                status("Procurando ovo...")
                local egg = eggPosition(uid)
                if not egg then status("Ovo sumiu") return end
                if S.Carrying and S.Uid ~= uid then
                    dropEgg()
                    local waited = 0
                    while S.Carrying and waited < 1 and not S.Cancel do
                        waited += RunService.Heartbeat:Wait()
                    end
                end
                if S.Cancel then return end
                fpsOn()
                status("Indo até o ovo...")
                if not runToEgg(uid, egg) then
                    fpsOff() status("Não alcancei") return
                end
                if S.Cancel then return end
                status("Pegando ovo...")
                if not grab(uid, 4) then
                    fpsOff() status("Ovo não soltou") return
                end
                if S.Cancel then return end
                local delivered = instantTP(uid)
                status(delivered and "Entregue!" or "Falha na entrega")
            end)
            fpsOff()
            dropClone()
            if not ok and err then status("Erro: " .. tostring(err)) end
            shieldStop()
            S.Busy = false
        end)
    end

    -- ---------- AUTO LOOP ----------
    local Auto = { Active = false, Thread = nil }

    local function pickBest()
        local best, bestVal, bestInfo = nil, 0, nil
        for _, r in ipairs(snapshot()) do
            local rar = getRarityName(r)
            if (not rarityFilterEnabled) or targetRarity == "Todos" or rar:lower() == targetRarity:lower() then
                local v = getEggValue(r)
                if v > bestVal then best, bestVal, bestInfo = r.Uid, v, r end
            end
        end
        return best, bestInfo
    end

    local function autoEnable()
        if Auto.Active then return end
        Auto.Active = true
        Auto.Thread = task.spawn(function()
            while Auto.Active do
                local uid, info = pickBest()
                if not uid then
                    status("Nenhum ovo disponível")
                    task.wait(1.5)
                else
                    status("AUTO: " .. tostring(info and (info.AssetCategory or info.Name) or "ovo"))
                    stealAndDeliver(uid)
                    local t0 = os.clock()
                    while S.Busy and Auto.Active and os.clock() - t0 < 90 do
                        task.wait(0.2)
                    end
                    task.wait(0.4)
                end
            end
        end)
    end

    local function autoDisable()
        if not Auto.Active then return end
        Auto.Active = false
        S.Cancel = true
        if Auto.Thread then pcall(task.cancel, Auto.Thread) Auto.Thread = nil end
        task.spawn(function()
            local t0 = os.clock()
            while S.Busy and os.clock() - t0 < 4 do task.wait(0.1) end
            S.Cancel = false
        end)
    end

    -- ---------- UI ----------
    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 2)
    pad.Parent = containerSteal

    local row1 = Instance.new("Frame")
    row1.Size = UDim2.new(1, -4, 0, 22)
    row1.Position = UDim2.new(0, 2, 0, 0)
    row1.BackgroundTransparency = 1
    row1.Parent = containerSteal

    local btnFiltro = Instance.new("TextButton")
    btnFiltro.Size = UDim2.new(0.5, -2, 1, 0)
    btnFiltro.Position = UDim2.new(0, 0, 0, 0)
    btnFiltro.BackgroundColor3 = BG_BTN
    btnFiltro.BorderSizePixel = 0
    btnFiltro.Font = Enum.Font.GothamBold
    btnFiltro.TextSize = 9
    btnFiltro.TextColor3 = TXT
    btnFiltro.Text = "Filtro: Todos"
    btnFiltro.ZIndex = 4
    btnFiltro.Parent = row1
    Instance.new("UICorner", btnFiltro).CornerRadius = UDim.new(0, 5)

    local btnAuto = Instance.new("TextButton")
    btnAuto.Size = UDim2.new(0.5, -2, 1, 0)
    btnAuto.Position = UDim2.new(0.5, 2, 0, 0)
    btnAuto.BackgroundColor3 = BG_BTN
    btnAuto.BorderSizePixel = 0
    btnAuto.Font = Enum.Font.GothamBold
    btnAuto.TextSize = 9
    btnAuto.TextColor3 = TXT
    btnAuto.Text = "AUTO: OFF"
    btnAuto.ZIndex = 4
    btnAuto.Parent = row1
    Instance.new("UICorner", btnAuto).CornerRadius = UDim.new(0, 5)

    local lblStatus = Instance.new("TextLabel")
    lblStatus.Size = UDim2.new(1, -4, 0, 12)
    lblStatus.Position = UDim2.new(0, 2, 0, 24)
    lblStatus.BackgroundTransparency = 1
    lblStatus.Font = Enum.Font.Gotham
    lblStatus.TextSize = 9
    lblStatus.TextColor3 = TXT_DIM
    lblStatus.TextXAlignment = Enum.TextXAlignment.Left
    lblStatus.TextTruncate = Enum.TextTruncate.AtEnd
    lblStatus.Text = "Pronto."
    lblStatus.ZIndex = 4
    lblStatus.Parent = containerSteal

    statusSteal = function(msg)
        lblStatus.Text = tostring(msg)
    end

    local scrollEggs = Instance.new("ScrollingFrame")
    scrollEggs.Size = UDim2.new(1, -4, 0, 88)
    scrollEggs.Position = UDim2.new(0, 2, 0, 38)
    scrollEggs.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
    scrollEggs.BorderSizePixel = 0
    scrollEggs.ScrollBarThickness = 3
    scrollEggs.ScrollBarImageColor3 = ROXO
    scrollEggs.ScrollBarImageTransparency = 0.3
    scrollEggs.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollEggs.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scrollEggs.ScrollingDirection = Enum.ScrollingDirection.Y
    scrollEggs.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
    scrollEggs.ZIndex = 3
    scrollEggs.Parent = containerSteal
    Instance.new("UICorner", scrollEggs).CornerRadius = UDim.new(0, 5)

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 2)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = scrollEggs

    local listPad = Instance.new("UIPadding")
    listPad.PaddingTop = UDim.new(0, 2)
    listPad.PaddingBottom = UDim.new(0, 2)
    listPad.Parent = scrollEggs

    local btnStop = Instance.new("TextButton")
    btnStop.Size = UDim2.new(1, -4, 0, 20)
    btnStop.Position = UDim2.new(0, 2, 1, -22)
    btnStop.BackgroundColor3 = Color3.fromRGB(60, 15, 25)
    btnStop.BorderSizePixel = 0
    btnStop.Font = Enum.Font.GothamBold
    btnStop.TextSize = 10
    btnStop.TextColor3 = Color3.fromRGB(255, 190, 200)
    btnStop.Text = "PARAR / CANCELAR"
    btnStop.ZIndex = 4
    btnStop.Parent = containerSteal
    Instance.new("UICorner", btnStop).CornerRadius = UDim.new(0, 5)

    btnStop.MouseButton1Click:Connect(function()
        if Auto.Active then
            autoDisable()
            btnAuto.Text = "AUTO: OFF"
            btnAuto.BackgroundColor3 = BG_BTN
            btnAuto.TextColor3 = TXT
            Toast("AUTO desligado", AMARELO)
        end
        S.Cancel = true
        S.Paused = false
        status("Cancelado")
    end)

    local listCache = {}
    local function refreshList()
        for _, it in ipairs(listCache) do it:Destroy() end
        listCache = {}
        local rows = {}
        for _, r in ipairs(snapshot()) do
            rows[#rows + 1] = { r = r, v = getEggValue(r) }
        end
        table.sort(rows, function(a, b) return a.v > b.v end)
        for i = 1, math.min(8, #rows) do
            local item = rows[i]
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -2, 0, 40)
            btn.BackgroundColor3 = BG_BTN
            btn.BorderSizePixel = 0
            btn.Text = ""
            btn.LayoutOrder = i
            btn.ZIndex = 4
            btn.Parent = scrollEggs
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

            local petIcon = Instance.new("ImageLabel")
            petIcon.Name = "PetIcon"
            petIcon.Size = UDim2.new(0, 32, 0, 32)
            petIcon.Position = UDim2.new(0, 5, 0.5, -16)
            petIcon.BackgroundTransparency = 1
            petIcon.ScaleType = Enum.ScaleType.Fit
            petIcon.ZIndex = 5
            petIcon.Image = getPetIconSteal(item.r) or ""
            petIcon.Visible = petIcon.Image ~= ""
            petIcon.Parent = btn

            local nm = Instance.new("TextLabel")
            nm.Size = UDim2.new(1, -125, 1, 0)
            nm.Position = UDim2.new(0, 43, 0, 0)
            nm.BackgroundTransparency = 1
            nm.Font = Enum.Font.GothamBold
            nm.TextSize = 9
            nm.TextColor3 = TXT
            nm.TextXAlignment = Enum.TextXAlignment.Left
            nm.TextTruncate = Enum.TextTruncate.AtEnd
            nm.Text = tostring(item.r.AssetCategory or item.r.Category or item.r.Name or "Ovo")
            nm.ZIndex = 5
            nm.Parent = btn

            local val = Instance.new("TextLabel")
            val.Size = UDim2.new(0, 75, 1, 0)
            val.Position = UDim2.new(1, -80, 0, 0)
            val.BackgroundTransparency = 1
            val.Font = Enum.Font.GothamBold
            val.TextSize = 9
            val.TextColor3 = AMARELO
            val.TextXAlignment = Enum.TextXAlignment.Right
            val.Text = "$" .. money(item.v)
            val.ZIndex = 5
            val.Parent = btn

            local uid = item.r.Uid
            btn.MouseButton1Click:Connect(function()
                if not uid then return end
                if Auto.Active then
                    autoDisable()
                    btnAuto.Text = "AUTO: OFF"
                    btnAuto.BackgroundColor3 = BG_BTN
                    btnAuto.TextColor3 = TXT
                end
                status("Roubando: " .. nm.Text)
                stealAndDeliver(uid)
            end)

            table.insert(listCache, btn)
        end
    end

    btnFiltro.MouseButton1Click:Connect(function()
        rarityIdx += 1
        if rarityIdx > #rarityOptions then rarityIdx = 1 end
        targetRarity = rarityOptions[rarityIdx]
        rarityFilterEnabled = (targetRarity ~= "Todos")
        btnFiltro.Text = "Filtro: " .. targetRarity
    end)

    btnAuto.MouseButton1Click:Connect(function()
        if Auto.Active then
            autoDisable()
            btnAuto.Text = "AUTO: OFF"
            btnAuto.BackgroundColor3 = BG_BTN
            btnAuto.TextColor3 = TXT
            Toast("AUTO-STEAL OFF", AMARELO)
        else
            autoEnable()
            btnAuto.Text = "AUTO: ON"
            btnAuto.BackgroundColor3 = Color3.fromRGB(15, 40, 20)
            btnAuto.TextColor3 = VERDE
            Toast("AUTO-STEAL ON", VERDE)
        end
    end)

    task.spawn(function()
        while gui.Parent do
            task.wait(2)
            pcall(refreshList)
        end
    end)

    pcall(refreshList)
end

iniciarSistemaSteal()

-- ============================================================
-- LOOPS VISUAIS
-- ============================================================
task.spawn(function()
    while gui.Parent do
        for rot = 0, 360, 6 do
            if not gui.Parent then break end
            gradBorda.Rotation = rot
            task.wait(0.03)
        end
    end
end)

task.spawn(function()
    while gui.Parent do
        TweenService:Create(ledHeader, TweenInfo.new(0.6, Enum.EasingStyle.Sine), {
            BackgroundTransparency = 0.4,
            Size = UDim2.new(0, 5, 0, 5),
            Position = UDim2.new(0, 10, 0, 15),
        }):Play()
        task.wait(0.6)
        if not gui.Parent then break end
        TweenService:Create(ledHeader, TweenInfo.new(0.6, Enum.EasingStyle.Sine), {
            BackgroundTransparency = 0,
            Size = UDim2.new(0, 6, 0, 6),
            Position = UDim2.new(0, 10, 0, 15),
        }):Play()
        task.wait(0.6)
    end
end)
