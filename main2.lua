--[[
    Explorer Viewer v2 (standalone) - Roblox / Luau

    - Painel arrastavel com um botao por servico (Workspace, ReplicatedStorage, etc).
    - Clique num servico -> arvore estilo Explorer: tudo fechado, clique na pasta
      pra abrir/fechar (▸ fechada, ▾ aberta). 📂 abre tudo, 📁 fecha tudo.
    - Linhas de Script / LocalScript / ModuleScript tem 🔍 e sao clicaveis:
      abre OUTRA janela arrastavel (e redimensionavel) com o codigo.
        * usa decompile() do executor (ou script.Source se o executor deixar)
        * se nao der, mostra um DUMP da funcao: constantes, upvalues, protos,
          funcoes vivas (getgc) e ambiente (getsenv)
        * botoes: 📜 codigo | 🧬 dump | 📋 copiar | 💾 salvar | ✕ fechar
    - Botao 💾 do painel principal -> pede nome + extensao e salva a arvore inteira.

    NOVO v2.1:
    - SELECAO: clique numa linha pra selecionar (fica destacada). A caixinha ☐/☑ a
      esquerda soma/tira itens (multi-selecao).
    - CONTORNO NO MAPA: item selecionado que esta no Workspace ganha um contorno
      quadrado (SelectionBox) no jogo real. Azul = principal, roxo = os outros.
      Pasta/afins contorna o que tem dentro (limite de 80 caixas).
    - 🔗 Deps: janela de dependencias do item selecionado (nome, classe, relacao,
      caminho): filhos, propriedades (Part0/Value/...), o que o script usa em runtime
      (upvalues / require / getsenv), nomes citados no codigo e QUEM usa o item.
      Clique numa linha pra navegar; 📌 trava, ⬅ volta, 🔄 recalcula, 📋 copia.
    - 🖱️ Mapa: liga a selecao clicando direto no jogo (Ctrl soma). Abre o item na arvore.
    - ⬆ Pai | 📋 Path (copia caminhos) | 👁 Contorno on/off | ✖ limpa selecao.

    Obs: Script (de servidor) nao envia codigo pro cliente, so aparece se RunContext = Client.
]]

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TextService = game:GetService("TextService")

local GUI_NAME = "ExplorerViewerPanel"
local MAX_NODES = 5000000000        -- limite de itens lidos por servico
local MAX_DEPTH = 4000           -- profundidade maxima da arvore
local ROW_H = 18               -- altura de cada linha
local TEXT_SIZE = 13
local MAX_LINE_CHARS = 400     -- corte VISUAL por linha (copiar/salvar leva tudo)
local POOL = 48                -- linhas reaproveitadas por lista (virtualizacao)
local MAX_DUMP_LINES = 40000
local MAX_GC_FUNCS = 150
local MAX_PROTO_DEPTH = 4

---------------------------------------------------------------------
-- Utilidades
---------------------------------------------------------------------
local function new(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do
        inst[k] = v
    end
    if parent then inst.Parent = parent end
    return inst
end

local function getGuiParent()
    local ok, ui = pcall(function() return gethui and gethui() end)
    if ok and ui then return ui end
    ok, ui = pcall(function() return game:GetService("CoreGui") end)
    if ok and ui then return ui end
    return Players.LocalPlayer:WaitForChild("PlayerGui")
end

-- remove versao antiga
do
    local okP, parent = pcall(getGuiParent)
    if okP and parent then
        local old = parent:FindFirstChild(GUI_NAME)
        if old then old:Destroy() end
        local oldAdorn = parent:FindFirstChild(GUI_NAME .. "Adorn")
        if oldAdorn then oldAdorn:Destroy() end
    end
end

local function safeChildren(inst)
    local ok, kids = pcall(function() return inst:GetChildren() end)
    return ok and kids or {}
end

local function safeName(inst)
    local ok, n = pcall(function() return inst.Name end)
    return ok and tostring(n) or "?"
end

local function safeClass(inst)
    local ok, c = pcall(function() return inst.ClassName end)
    return ok and c or "?"
end

local function isA(inst, cls)
    local ok, r = pcall(function() return inst:IsA(cls) end)
    return ok and r == true
end

local function getPath(inst)
    local parts = {}
    local cur = inst
    local guard = 0
    while cur and cur ~= game and guard < 100 do
        parts[#parts + 1] = safeName(cur)
        local ok, p = pcall(function() return cur.Parent end)
        if ok then cur = p else cur = nil end
        guard = guard + 1
    end
    local out = {}
    for i = #parts, 1, -1 do out[#out + 1] = parts[i] end
    return "game." .. table.concat(out, ".")
end

-- corta string sem quebrar caractere UTF-8
local function clip(s, n)
    if #s <= n then return s end
    local cut = n
    while cut > 0 do
        local b = string.byte(s, cut + 1)
        if b and b >= 128 and b < 192 then cut = cut - 1 else break end
    end
    return string.sub(s, 1, cut) .. " …"
end

local function cleanFileName(name, fallback)
    name = tostring(name or "")
    name = name:gsub("[\\/:*?\"<>|%c]", "_")
    name = name:gsub("^%s+", "")
    name = name:gsub("%s+$", "")
    if name == "" then name = fallback end
    return name
end

local function copyToClipboard(text)
    local fn = setclipboard or toclipboard
    if typeof(fn) == "function" then
        return (pcall(fn, text))
    end
    return false
end

---------------------------------------------------------------------
-- Icones
---------------------------------------------------------------------
local SERVICE_ICONS = {
    Workspace = "🌍", Players = "👥", Lighting = "💡", ReplicatedFirst = "⚡",
    ReplicatedStorage = "📦", ServerScriptService = "📜", ServerStorage = "🗄️",
    StarterGui = "🖥️", StarterPack = "🎒", StarterPlayer = "🧑",
    Teams = "🏳️", SoundService = "🔊", Chat = "💬", TextChatService = "💬",
    MaterialService = "🎨", CoreGui = "🛡️", Nil = "🕳️",
}

local CLASS_ICONS = {
    Folder = "📁", Model = "🧊", Part = "🧱", MeshPart = "🔷", UnionOperation = "🔶",
    WedgePart = "🔺", SpawnLocation = "🏁", Terrain = "🏔️", Camera = "🎥",
    Script = "📜", LocalScript = "📄", ModuleScript = "🧩",
    RemoteEvent = "📡", RemoteFunction = "📞", BindableEvent = "🔔", BindableFunction = "🔕",
    Humanoid = "🧍", Tool = "🔧", Accessory = "🎩", Sound = "🔊",
    Decal = "🖼️", Texture = "🖼️", Animation = "🎞️", Animator = "🎞️",
    PointLight = "💡", SpotLight = "💡", SurfaceLight = "💡", ParticleEmitter = "✨",
    Attachment = "📎", Weld = "🔗", WeldConstraint = "🔗", Motor6D = "⚙️",
    ScreenGui = "🖥️", Frame = "▫️", TextLabel = "🔤", TextButton = "🔘", TextBox = "⌨️",
    ImageLabel = "🏞️", ImageButton = "🏞️", ScrollingFrame = "🧾",
    Player = "👤", Team = "🏳️", Configuration = "⚙️", Sky = "🌌", Atmosphere = "🌫️",
    ProximityPrompt = "🖐️", ClickDetector = "👆", Seat = "💺", Shirt = "👕", Pants = "👖",
    BoolValue = "✅", ObjectValue = "🎯", StringValue = "🔠",
    IntValue = "🔢", NumberValue = "🔢", Color3Value = "🎨", Vector3Value = "📍",
}

local CONTAINER = { Folder = true, Model = true, Configuration = true }
local SCRIPT_CLASSES = { Script = true, LocalScript = true, ModuleScript = true }

local function iconFor(inst)
    local c = safeClass(inst)
    if CLASS_ICONS[c] then return CLASS_ICONS[c] end
    if isA(inst, "BasePart") then return "🧱" end
    if isA(inst, "GuiObject") then return "▫️" end
    if isA(inst, "ValueBase") then return "🔢" end
    if isA(inst, "LuaSourceContainer") then return "📜" end
    return "▪️"
end

local function isScriptInstance(inst)
    if SCRIPT_CLASSES[safeClass(inst)] then return true end
    return isA(inst, "LuaSourceContainer")
end

---------------------------------------------------------------------
-- Cores / GUI raiz / janelas
---------------------------------------------------------------------
local C = {
    bg = Color3.fromRGB(16, 16, 22),
    panel = Color3.fromRGB(26, 26, 36),
    panel2 = Color3.fromRGB(34, 34, 48),
    accent = Color3.fromRGB(150, 110, 255),
    script = Color3.fromRGB(196, 170, 255),
    match = Color3.fromRGB(255, 214, 102),
    text = Color3.fromRGB(235, 235, 245),
    dim = Color3.fromRGB(140, 140, 165),
    ok = Color3.fromRGB(110, 220, 150),
    bad = Color3.fromRGB(255, 110, 120),
}

local gui = new("ScreenGui", {
    Name = GUI_NAME, ResetOnSpawn = false, IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999,
})
pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
local okParent = pcall(function() gui.Parent = getGuiParent() end)
if not okParent then gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui") end

local function getViewport()
    local cam = workspace.CurrentCamera
    if cam then return cam.ViewportSize end
    return Vector2.new(800, 400)
end

local cleanups = {}   -- funcoes chamadas ao fechar o painel principal
local zCounter = 10

local function bringToFront(frame)
    zCounter = zCounter + 1
    frame.ZIndex = zCounter
end

-- arrastar generico: begin() devolve um estado, move(delta, estado) aplica
local function makeDrag(handle, begin, move)
    local dragging, startPos, state = false, nil, nil
    local c1 = handle.InputBegan:Connect(function(input)
        local t = input.UserInputType
        if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
            dragging = true
            startPos = input.Position
            state = begin()
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    local c2 = UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            move(input.Position - startPos, state)
        end
    end)
    local function cleanup()
        c1:Disconnect()
        c2:Disconnect()
    end
    cleanups[#cleanups + 1] = cleanup
    return cleanup
end

local function headerButton(parent, text, xFromRight, color)
    local b = new("TextButton", {
        BackgroundColor3 = color or C.panel2, BorderSizePixel = 0,
        Size = UDim2.fromOffset(30, 24),
        Position = UDim2.new(1, -xFromRight, 0.5, -12),
        Text = text, TextColor3 = C.text, Font = Enum.Font.GothamBold, TextSize = 14,
        AutoButtonColor = true,
    }, parent)
    new("UICorner", { CornerRadius = UDim.new(0, 6) }, b)
    return b
end

---------------------------------------------------------------------
-- Selecao + contorno 3D no mapa (SelectionBox)
---------------------------------------------------------------------
local adornFolder = new("Folder", { Name = GUI_NAME .. "Adorn" })
do
    local okA = pcall(function() adornFolder.Parent = getGuiParent() end)
    if not okA then adornFolder.Parent = gui end
end

local selection = {}      -- conjunto: instancia -> true
local selOrder = {}       -- lista na ordem em que foi selecionado
local primary = nil       -- ultimo item selecionado (o "principal")
local selHooks = {}       -- funcoes chamadas quando a selecao muda
local outlineEnabled = true
local outlineBoxes = {}
local MAX_BOXES = 80
local OUT_PRIMARY = Color3.fromRGB(80, 210, 255)
local OUT_OTHER = Color3.fromRGB(170, 130, 255)

local function clearBoxes()
    for _, b in ipairs(outlineBoxes) do
        pcall(function() b:Destroy() end)
    end
    outlineBoxes = {}
end

cleanups[#cleanups + 1] = function()
    clearBoxes()
    pcall(function() adornFolder:Destroy() end)
end

-- Parte/Model recebe o contorno direto. Pasta e afins: contorna o que tem dentro.
local function collectTargets(inst, out, depth)
    if #out >= MAX_BOXES then return end
    if isA(inst, "BasePart") or isA(inst, "Model") then
        out[#out + 1] = inst
        return
    end
    if depth >= 4 then return end
    for _, ch in ipairs(safeChildren(inst)) do
        if #out >= MAX_BOXES then return end
        collectTargets(ch, out, depth + 1)
    end
end

local function inWorkspace(inst)
    local ok, r = pcall(function() return inst:IsDescendantOf(workspace) end)
    return ok and r == true
end

local function updateOutlines()
    clearBoxes()
    if not outlineEnabled then return end
    local total = 0
    for _, inst in ipairs(selOrder) do
        if total >= MAX_BOXES then break end
        if inWorkspace(inst) then
            local targets = {}
            collectTargets(inst, targets, 0)
            local col = (inst == primary) and OUT_PRIMARY or OUT_OTHER
            for _, t in ipairs(targets) do
                if total >= MAX_BOXES then break end
                total = total + 1
                local ok, box = pcall(new, "SelectionBox", {
                    Adornee = t, Color3 = col, SurfaceColor3 = col,
                    LineThickness = 0.04, SurfaceTransparency = 0.85, Transparency = 0,
                }, adornFolder)
                if ok and box then outlineBoxes[#outlineBoxes + 1] = box end
            end
        end
    end
end

local function fireSelection()
    updateOutlines()
    for _, fn in ipairs(selHooks) do pcall(fn) end
end

local function selectOnly(inst)
    selection = { [inst] = true }
    selOrder = { inst }
    primary = inst
    fireSelection()
end

local function toggleSelect(inst)
    if selection[inst] then
        selection[inst] = nil
        for i = #selOrder, 1, -1 do
            if selOrder[i] == inst then table.remove(selOrder, i) end
        end
    else
        selection[inst] = true
        selOrder[#selOrder + 1] = inst
    end
    primary = selOrder[#selOrder]
    fireSelection()
end

local function clearSelection()
    selection = {}
    selOrder = {}
    primary = nil
    fireSelection()
end

---------------------------------------------------------------------
-- Lista virtualizada (so desenha as linhas visiveis => aguenta 50k linhas)
---------------------------------------------------------------------
local function plainRow(text, color)
    return { text = text, display = text, click = false, color = color }
end

local function createVirtualList(parent, props)
    local list = {}
    local rows = {}
    local canvasW = 200
    local canvasH = 12
    local cbW = props.checkbox and 20 or 0

    local scroll = new("ScrollingFrame", {
        BackgroundColor3 = C.panel, BorderSizePixel = 0,
        Size = props.Size, Position = props.Position or UDim2.new(),
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.None,
        ScrollingDirection = Enum.ScrollingDirection.XY,
        ScrollBarThickness = 5, ScrollBarImageColor3 = C.accent,
    }, parent)
    new("UICorner", { CornerRadius = UDim.new(0, 8) }, scroll)

    local pool, btnIndex = {}, {}
    for i = 1, POOL do
        local hl = new("Frame", {
            BackgroundColor3 = C.accent, BackgroundTransparency = 0.6, BorderSizePixel = 0,
            Size = UDim2.fromOffset(200, ROW_H), Visible = false, ZIndex = 1,
        }, scroll)
        local b = new("TextButton", {
            BackgroundTransparency = 1, BorderSizePixel = 0, AutoButtonColor = false,
            Size = UDim2.fromOffset(200, ROW_H), Position = UDim2.fromOffset(6 + cbW, 0),
            Text = "", TextColor3 = C.text, Font = Enum.Font.Code, TextSize = TEXT_SIZE,
            TextXAlignment = Enum.TextXAlignment.Left, RichText = false,
            Visible = false, Active = false, ZIndex = 2,
        }, scroll)
        b.MouseButton1Click:Connect(function()
            local idx = btnIndex[b]
            local row = idx and rows[idx]
            if row and row.click and props.onClick then
                props.onClick(row, idx)
            end
        end)
        local cb = nil
        if props.checkbox then
            cb = new("TextButton", {
                BackgroundTransparency = 1, BorderSizePixel = 0, AutoButtonColor = false,
                Size = UDim2.fromOffset(cbW - 2, ROW_H), Position = UDim2.fromOffset(4, 0),
                Text = "☐", TextColor3 = C.dim, Font = Enum.Font.Gotham, TextSize = 14,
                Visible = false, ZIndex = 3,
            }, scroll)
            cb.MouseButton1Click:Connect(function()
                local idx = btnIndex[b]
                local row = idx and rows[idx]
                if row and props.onCheck then props.onCheck(row, idx) end
            end)
        end
        pool[i] = { b = b, hl = hl, cb = cb }
    end

    local function refresh()
        local y = scroll.CanvasPosition.Y
        local first = math.max(1, math.floor(y / ROW_H) + 1)
        for i = 1, POOL do
            local idx = first + i - 1
            local p = pool[i]
            local b = p.b
            local row = rows[idx]
            if row then
                local ry = (idx - 1) * ROW_H + 4
                b.Visible = true
                btnIndex[b] = idx
                b.Position = UDim2.fromOffset(6 + cbW, ry)
                b.Size = UDim2.fromOffset(canvasW, ROW_H)
                b.Text = row.display
                b.TextColor3 = row.color or C.text
                b.Active = (row.click == true)

                local sel = props.isSelected and props.isSelected(row) or false
                if sel then
                    p.hl.Visible = true
                    p.hl.Position = UDim2.fromOffset(0, ry)
                    p.hl.Size = UDim2.fromOffset(canvasW + cbW + 12, ROW_H)
                    p.hl.BackgroundTransparency = (sel == "primary") and 0.45 or 0.72
                else
                    p.hl.Visible = false
                end

                if p.cb then
                    local has = props.hasCheck and props.hasCheck(row) or false
                    p.cb.Visible = has and true or false
                    if has then
                        p.cb.Position = UDim2.fromOffset(4, ry)
                        p.cb.Text = sel and "☑" or "☐"
                        p.cb.TextColor3 = sel and C.ok or C.dim
                    end
                end
            else
                b.Visible = false
                btnIndex[b] = nil
                p.hl.Visible = false
                if p.cb then p.cb.Visible = false end
            end
        end
    end
    scroll:GetPropertyChangedSignal("CanvasPosition"):Connect(refresh)

    function list.setRows(newRows, keepScroll)
        local prevPos = scroll.CanvasPosition
        rows = newRows
        local longest, longestLen = "", 0
        for i = 1, #rows do
            local d = rows[i].display
            if #d > longestLen then longest, longestLen = d, #d end
        end
        local w = 200
        if longestLen > 0 then
            local ok, size = pcall(function()
                return TextService:GetTextSize(longest, TEXT_SIZE, Enum.Font.Code, Vector2.new(100000, ROW_H))
            end)
            if ok and size then w = size.X + 24 else w = longestLen * 8 + 24 end
        end
        canvasW = math.min(math.max(w, 200), 8000)
        canvasH = #rows * ROW_H + 12
        scroll.CanvasSize = UDim2.fromOffset(canvasW + 12 + cbW, canvasH)
        if keepScroll then
            scroll.CanvasPosition = Vector2.new(prevPos.X, prevPos.Y)
        else
            scroll.CanvasPosition = Vector2.new(0, 0)
        end
        refresh()
    end

    -- rola ate a linha i ficar mais ou menos no meio da lista
    function list.scrollTo(i)
        local viewH = scroll.AbsoluteSize.Y
        local y = (i - 1) * ROW_H - math.floor(viewH / 2) + ROW_H
        local maxY = math.max(0, canvasH - viewH)
        scroll.CanvasPosition = Vector2.new(0, math.clamp(y, 0, maxY))
        refresh()
    end

    function list.getRows() return rows end
    list.refresh = refresh
    list.scroll = scroll
    return list
end

---------------------------------------------------------------------
-- Codigo do script: decompile / Source / dump
---------------------------------------------------------------------
local function getSource(inst)
    local reasons = {}

    if typeof(decompile) == "function" then
        local ok, res = pcall(decompile, inst)
        if ok and type(res) == "string" and res ~= "" then
            return res, "decompile"
        end
        reasons[#reasons + 1] = "decompile: " .. tostring(ok and "retornou vazio" or res)
    else
        reasons[#reasons + 1] = "decompile não existe nesse executor"
    end

    local ok, src = pcall(function() return inst.Source end)
    if ok and type(src) == "string" and src ~= "" then
        return src, "script.Source"
    end
    reasons[#reasons + 1] = "script.Source bloqueado"

    return nil, table.concat(reasons, " | ")
end

local function short(v)
    local t = typeof(v)
    if t == "string" then
        local s = v:gsub("%c", " ")
        return "\"" .. clip(s, 100) .. "\""
    elseif t == "number" or t == "boolean" or t == "nil" then
        return tostring(v)
    elseif t == "function" then
        local nm = "?"
        if debug and debug.getinfo then
            local ok, info = pcall(debug.getinfo, v)
            if ok and type(info) == "table" and info.name and info.name ~= "" then nm = info.name end
        end
        return "function " .. nm
    elseif t == "table" then
        local c = 0
        pcall(function()
            for _ in pairs(v) do
                c = c + 1
                if c > 999 then break end
            end
        end)
        return "table (" .. c .. (c > 999 and "+" or "") .. " itens)"
    elseif t == "Instance" then
        return "Instance<" .. safeClass(v) .. "> " .. safeName(v)
    end
    return t .. " " .. tostring(v)
end

local function sortedNumericKeys(tbl)
    local keys = {}
    for k in pairs(tbl) do
        if type(k) == "number" then keys[#keys + 1] = k end
    end
    table.sort(keys)
    return keys
end

local function dumpFunction(f, depth, P, seen, withProtos)
    local pad = string.rep("  ", depth)

    if seen[f] then
        P(pad .. "(já listada acima)")
        return
    end
    seen[f] = true

    if debug and debug.getinfo then
        local ok, info = pcall(debug.getinfo, f)
        if ok and type(info) == "table" then
            P(pad .. "-- info: nome=" .. tostring(info.name or "?")
                .. " | linha=" .. tostring(info.linedefined or info.currentline or "?")
                .. " | params=" .. tostring(info.numparams or "?")
                .. " | upvalues=" .. tostring(info.nups or "?"))
        end
    end

    if debug and debug.getconstants then
        local ok, consts = pcall(debug.getconstants, f)
        if ok and type(consts) == "table" then
            local keys = sortedNumericKeys(consts)
            if #keys > 0 then
                P(pad .. "constants (" .. #keys .. "):")
                for n = 1, #keys do
                    if n > 300 then
                        P(pad .. "  … +" .. (#keys - 300) .. " constantes")
                        break
                    end
                    local v = consts[keys[n]]
                    if v ~= nil then
                        P(pad .. "  [" .. keys[n] .. "] " .. short(v))
                    end
                end
            end
        end
    end

    if debug and debug.getupvalues then
        local ok, ups = pcall(debug.getupvalues, f)
        if ok and type(ups) == "table" then
            local keys = sortedNumericKeys(ups)
            if #keys > 0 then
                P(pad .. "upvalues (" .. #keys .. "):")
                for n = 1, #keys do
                    if n > 100 then
                        P(pad .. "  … +" .. (#keys - 100) .. " upvalues")
                        break
                    end
                    P(pad .. "  [" .. keys[n] .. "] " .. short(ups[keys[n]]))
                end
            end
        end
    end

    if withProtos and debug and debug.getprotos then
        local ok, protos = pcall(debug.getprotos, f)
        if ok and type(protos) == "table" and #protos > 0 then
            P(pad .. "protos (" .. #protos .. "):")
            for i = 1, #protos do
                if i > 200 then
                    P(pad .. "  … +" .. (#protos - 200) .. " protos")
                    break
                end
                P(pad .. "  ▸ proto #" .. i)
                local p = protos[i]
                if type(p) == "function" then
                    if depth < MAX_PROTO_DEPTH then
                        dumpFunction(p, depth + 2, P, seen, true)
                    else
                        P(pad .. "    (profundidade máxima)")
                    end
                end
            end
        end
    end
end

-- roda dentro de task.spawn (usa task.wait). aborted() => true cancela.
local function dumpScript(inst, reason, aborted)
    local out, n, capped = {}, 0, false
    local function P(s)
        if n >= MAX_DUMP_LINES then
            if not capped then
                capped = true
                out[#out + 1] = "-- … dump cortado (limite de linhas)"
            end
            return
        end
        n = n + 1
        out[n] = s
    end

    local class = safeClass(inst)
    P("-- 🧬 DUMP de " .. getPath(inst))
    P("-- Classe: " .. class)
    if reason and reason ~= "" then P("-- Motivo: " .. reason) end
    if class == "Script" then
        P("-- Obs: Script de servidor não envia o código pro cliente (só com RunContext = Client).")
    end
    P("")

    if typeof(getscriptbytecode) == "function" then
        local ok, bc = pcall(getscriptbytecode, inst)
        if ok and type(bc) == "string" then
            P("-- bytecode: " .. #bc .. " bytes")
        else
            P("-- bytecode: indisponível")
        end
    end
    if typeof(getscripthash) == "function" then
        local ok, h = pcall(getscripthash, inst)
        if ok then P("-- hash: " .. tostring(h)) end
    end
    P("")

    local seen = {}

    -- 1) funcao principal do script + protos aninhados
    if typeof(getscriptclosure) == "function" then
        local ok, f = pcall(getscriptclosure, inst)
        if ok and type(f) == "function" then
            P("== 📦 Função principal (getscriptclosure) ==")
            dumpFunction(f, 0, P, seen, true)
        else
            P("== getscriptclosure falhou (script sem bytecode acessível) ==")
        end
    else
        P("== getscriptclosure não existe nesse executor ==")
    end

    -- 2) ambiente do script
    if typeof(getsenv) == "function" then
        P("")
        local ok, env = pcall(getsenv, inst)
        if ok and type(env) == "table" then
            P("== 🌐 Ambiente do script (getsenv) ==")
            local entries = {}
            pcall(function()
                for k, v in pairs(env) do
                    entries[#entries + 1] = { key = tostring(k), val = v }
                end
            end)
            table.sort(entries, function(a, b) return a.key < b.key end)
            for i = 1, #entries do
                if i > 500 then
                    P("  … +" .. (#entries - 500) .. " entradas")
                    break
                end
                P(string.format("  %-28s %s", entries[i].key, short(entries[i].val)))
            end
            if #entries == 0 then P("  (vazio)") end
        else
            P("== getsenv falhou (script/módulo não está rodando) ==")
        end
    end

    -- 3) funcoes vivas que pertencem ao script
    if typeof(getgc) == "function" then
        P("")
        P("== ⚙️ Funções vivas deste script (getgc) ==")
        local okGc, gc = pcall(getgc)
        if okGc and type(gc) == "table" then
            local found = 0
            for i = 1, #gc do
                if aborted() then
                    P("-- (cancelado)")
                    return table.concat(out, "\n")
                end
                local f = gc[i]
                if type(f) == "function" then
                    local skip = false
                    if typeof(isexecutorclosure) == "function" then
                        local okx, isx = pcall(isexecutorclosure, f)
                        if okx and isx then skip = true end
                    end
                    if not skip then
                        local okE, fenv = pcall(getfenv, f)
                        if okE and type(fenv) == "table" then
                            local okS, sc = pcall(function() return fenv.script end)
                            if okS and sc == inst then
                                found = found + 1
                                if found > MAX_GC_FUNCS then
                                    P("  … limite de " .. MAX_GC_FUNCS .. " funções")
                                    break
                                end
                                P("")
                                P("▸ função #" .. found)
                                dumpFunction(f, 1, P, seen, false)
                            end
                        end
                    end
                end
                if i % 3000 == 0 then task.wait() end
            end
            if found == 0 then
                P("  (nenhuma função viva encontrada — o script pode não estar rodando)")
            end
        else
            P("  getgc falhou")
        end
    end

    return table.concat(out, "\n")
end

---------------------------------------------------------------------
-- Linhas de texto -> linhas da lista
---------------------------------------------------------------------
local function splitLines(src)
    src = tostring(src)
    src = src:gsub("\r\n", "\n")
    src = src:gsub("\r", "\n")
    local lines = {}
    for line in (src .. "\n"):gmatch("(.-)\n") do
        lines[#lines + 1] = line
    end
    if #lines > 1 and lines[#lines] == "" then lines[#lines] = nil end
    return lines
end

local function codeRows(lines)
    local rows = {}
    local width = #tostring(#lines)
    local fmt = "%" .. width .. "d │ %s"
    for i = 1, #lines do
        local s = lines[i]
        s = s:gsub("\t", "    ")
        s = s:gsub("%c", " ")
        s = clip(s, MAX_LINE_CHARS)
        local isComment = s:match("^%s*%-%-") ~= nil
        rows[i] = {
            text = lines[i],
            display = string.format(fmt, i, s),
            click = false,
            color = isComment and C.dim or nil,
        }
    end
    return rows
end

---------------------------------------------------------------------
-- Janela do codigo (uma por script)
---------------------------------------------------------------------
local viewers = {}
local viewerSpawnCount = 0

local function openScriptViewer(inst)
    local existing = viewers[inst]
    if existing and existing.win.Parent then
        bringToFront(existing.win)
        existing.reload()
        return
    end

    local name = safeName(inst)
    local class = safeClass(inst)
    local vpSize = getViewport()
    local Wc = math.min(580, vpSize.X - 20)
    local Hc = math.min(380, vpSize.Y - 20)
    viewerSpawnCount = viewerSpawnCount + 1
    local off = (viewerSpawnCount % 6) * 26

    local win = new("Frame", {
        Name = "ScriptViewer", BackgroundColor3 = C.bg, BorderSizePixel = 0, Active = true,
        Size = UDim2.fromOffset(Wc, Hc),
        Position = UDim2.new(0.5, -Wc / 2 + off, 0.5, -Hc / 2 + off),
        ClipsDescendants = true,
    }, gui)
    new("UICorner", { CornerRadius = UDim.new(0, 12) }, win)
    new("UIStroke", { Color = C.accent, Thickness = 1.5, Transparency = 0.3 }, win)
    bringToFront(win)

    local bar = new("Frame", {
        BackgroundColor3 = C.panel, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 34),
    }, win)

    new("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(1, -196, 1, 0),
        Text = iconFor(inst) .. " " .. name .. "  ‹" .. class .. "›",
        TextColor3 = C.text, Font = Enum.Font.GothamBold, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
    }, bar)

    local closeB = headerButton(bar, "✕", 36, Color3.fromRGB(90, 40, 50))
    local saveB = headerButton(bar, "💾", 72)
    local copyB = headerButton(bar, "📋", 108)
    local dumpB = headerButton(bar, "🧬", 144)
    local codeB = headerButton(bar, "📜", 180)

    local status = new("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 8, 1, -22),
        Size = UDim2.new(1, -40, 0, 18),
        Text = "", TextColor3 = C.dim, Font = Enum.Font.Gotham, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
    }, win)

    local function vStatus(msg, color)
        status.Text = msg
        status.TextColor3 = color or C.dim
    end

    local list = createVirtualList(win, {
        Position = UDim2.fromOffset(6, 38),
        Size = UDim2.new(1, -12, 1, -64),
    })

    -- alca pra redimensionar
    local grip = new("TextButton", {
        BackgroundTransparency = 1, Text = "◢", TextColor3 = C.accent,
        Font = Enum.Font.GothamBold, TextSize = 16,
        Size = UDim2.fromOffset(24, 24), Position = UDim2.new(1, -24, 1, -24),
        ZIndex = 5,
    }, win)

    local content = ""
    local mode = "code"
    local loadToken = 0

    local function aborted(tk)
        return tk ~= loadToken or not win.Parent
    end

    local function showText(text, label, color)
        content = text
        local lines = splitLines(text)
        list.setRows(codeRows(lines))
        vStatus(label .. " — " .. #lines .. " linhas", color)
    end

    local function loadDump(reason)
        loadToken = loadToken + 1
        local tk = loadToken
        mode = "dump"
        list.setRows({ plainRow("⏳ Gerando dump de " .. name .. "... (pode demorar)") })
        vStatus("⏳ Gerando dump...")
        task.spawn(function()
            local ok, res = pcall(dumpScript, inst, reason, function() return aborted(tk) end)
            if aborted(tk) then return end
            if ok then
                showText(res, "🧬 dump", C.ok)
            else
                showText("-- erro ao gerar dump: " .. tostring(res), "❌ erro no dump", C.bad)
            end
        end)
    end

    local function loadCode()
        loadToken = loadToken + 1
        local tk = loadToken
        mode = "code"
        list.setRows({ plainRow("⏳ Decompilando " .. name .. "...") })
        vStatus("⏳ Decompilando...")
        task.spawn(function()
            local src, how = getSource(inst)
            if aborted(tk) then return end
            if src then
                showText(src, "✅ " .. how, C.ok)
            else
                -- fallback: dump da funcao
                loadDump(how)
            end
        end)
    end

    codeB.MouseButton1Click:Connect(loadCode)
    dumpB.MouseButton1Click:Connect(function() loadDump("pedido manual (botão 🧬)") end)

    copyB.MouseButton1Click:Connect(function()
        if content == "" then vStatus("❌ Nada pra copiar", C.bad) return end
        if copyToClipboard(content) then
            vStatus("📋 Copiado pro clipboard", C.ok)
        else
            vStatus("❌ Executor sem setclipboard", C.bad)
        end
    end)

    saveB.MouseButton1Click:Connect(function()
        if content == "" then vStatus("❌ Nada pra salvar", C.bad) return end
        local ext = (mode == "dump") and ".dump.txt" or ".lua"
        local fname = cleanFileName(name, "script") .. ext
        if typeof(writefile) == "function" then
            local ok, err = pcall(writefile, fname, content)
            if ok then
                vStatus("💾 Salvo como " .. fname, C.ok)
            else
                vStatus("❌ Erro: " .. tostring(err), C.bad)
            end
        else
            vStatus("❌ Executor sem writefile", C.bad)
        end
    end)

    local cleanDrag = makeDrag(bar,
        function() bringToFront(win) return win.Position end,
        function(d, sp)
            win.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
        end)

    local cleanResize = makeDrag(grip,
        function()
            bringToFront(win)
            return Vector2.new(win.AbsoluteSize.X, win.AbsoluteSize.Y)
        end,
        function(d, s)
            local vsz = getViewport()
            local w = math.clamp(s.X + d.X, 300, vsz.X)
            local h = math.clamp(s.Y + d.Y, 200, vsz.Y)
            win.Size = UDim2.fromOffset(w, h)
        end)

    list.scroll.InputBegan:Connect(function() bringToFront(win) end)

    closeB.MouseButton1Click:Connect(function()
        loadToken = loadToken + 1
        cleanDrag()
        cleanResize()
        viewers[inst] = nil
        win:Destroy()
    end)

    viewers[inst] = { win = win, reload = loadCode }
    loadCode()
end

---------------------------------------------------------------------
-- Dependencias dos itens (o que ele usa / quem usa ele)
---------------------------------------------------------------------
local revealInTree   -- definido la embaixo (precisa do estado da arvore)
local analyzeDeps, resetDepsCache

do
    local NAME_CLASSES = {
        ModuleScript = true, Script = true, LocalScript = true,
        RemoteEvent = true, RemoteFunction = true, UnreliableRemoteEvent = true,
        BindableEvent = true, BindableFunction = true, Folder = true,
        BoolValue = true, IntValue = true, NumberValue = true, StringValue = true,
        ObjectValue = true, Color3Value = true, Vector3Value = true, CFrameValue = true,
    }
    local ATT = { "Attachment0", "Attachment1" }
    local P01 = { "Part0", "Part1" }
    -- classes que "apontam" pra outras instancias (usado pra achar quem referencia quem)
    local REF_PROPS = {
        Weld = P01, ManualWeld = P01, WeldConstraint = P01, Motor6D = P01, Motor = P01,
        Snap = P01, Glue = P01, NoCollisionConstraint = P01,
        ObjectValue = { "Value" }, Model = { "PrimaryPart" },
        BallSocketConstraint = ATT, HingeConstraint = ATT, RopeConstraint = ATT,
        RodConstraint = ATT, SpringConstraint = ATT, PrismaticConstraint = ATT,
        CylindricalConstraint = ATT, UniversalConstraint = ATT, AlignPosition = ATT,
        AlignOrientation = ATT, Beam = ATT, Trail = ATT, LineForce = ATT,
        LinearVelocity = { "Attachment0" }, VectorForce = { "Attachment0" },
        Torque = { "Attachment0" },
        Highlight = { "Adornee" }, BillboardGui = { "Adornee" }, SurfaceGui = { "Adornee" },
    }
    local GENERIC_REF_PROPS = {
        "Part0", "Part1", "Value", "PrimaryPart", "Adornee",
        "Attachment0", "Attachment1", "RootPart", "SeatPart", "CameraSubject",
    }
    local MAX_LIST = 120

    local worldCache, gcCache = nil, nil
    local strCache = setmetatable({}, { __mode = "k" })

    resetDepsCache = function()
        worldCache, gcCache = nil, nil
    end

    local function sortedByName(list)
        table.sort(list, function(a, b)
            return safeName(a):lower() < safeName(b):lower()
        end)
        return list
    end

    -- strings (constantes) de um script, incluindo as funcoes internas
    local function scriptStrings(sc)
        local cached = strCache[sc]
        if cached ~= nil then return cached or nil end
        if typeof(getscriptclosure) ~= "function" or not (debug and debug.getconstants) then
            return nil
        end
        local okf, f = pcall(getscriptclosure, sc)
        if not okf or type(f) ~= "function" then
            strCache[sc] = false
            return nil
        end
        local set, n, seen = {}, 0, {}
        local function visit(fn, depth)
            if seen[fn] or depth > 8 or n > 5000 then return end
            seen[fn] = true
            local okc, consts = pcall(debug.getconstants, fn)
            if okc and type(consts) == "table" then
                for _, v in pairs(consts) do
                    if type(v) == "string" and #v >= 3 and #v <= 80 then
                        set[v] = true
                        n = n + 1
                    end
                end
            end
            if debug.getprotos then
                local okp, protos = pcall(debug.getprotos, fn)
                if okp and type(protos) == "table" then
                    for _, p in ipairs(protos) do
                        if type(p) == "function" then visit(p, depth + 1) end
                    end
                end
            end
        end
        visit(f, 0)
        strCache[sc] = set
        return set
    end

    -- varre o jogo: indice de nomes + quem aponta pra quem (propriedades)
    local function scanWorld(aborted)
        if worldCache and os.clock() - worldCache.t < 30 then return worldCache end
        local w = { nameIndex = {}, refBy = {}, scripts = {}, t = 0 }
        local ok, all = pcall(function() return game:GetDescendants() end)
        if not ok or type(all) ~= "table" then all = {} end
        for i = 1, #all do
            if i % 4000 == 0 then
                task.wait()
                if aborted() then return nil end
            end
            local d = all[i]
            local cls = safeClass(d)
            if NAME_CLASSES[cls] then
                local nm = safeName(d)
                if #nm >= 3 and d ~= adornFolder then
                    local l = w.nameIndex[nm]
                    if not l then
                        l = { n = 0 }
                        w.nameIndex[nm] = l
                    end
                    l.n = l.n + 1
                    if #l < 6 then l[#l + 1] = d end
                end
                if SCRIPT_CLASSES[cls] then w.scripts[#w.scripts + 1] = d end
            end
            local props = REF_PROPS[cls]
            if props then
                for _, p in ipairs(props) do
                    local okv, v = pcall(function() return d[p] end)
                    if okv and typeof(v) == "Instance" then
                        local l = w.refBy[v]
                        if not l then
                            l = {}
                            w.refBy[v] = l
                        end
                        l[#l + 1] = { inst = d, prop = p }
                    end
                end
            end
        end
        w.t = os.clock()
        worldCache = w
        return w
    end

    -- nome -> lista de scripts que citam esse nome nas constantes (lazy, so quando precisa)
    local function ensureMentions(w, aborted)
        if w.mentions then return w.mentions end
        local m = {}
        for i, sc in ipairs(w.scripts) do
            if i % 25 == 0 then
                task.wait()
                if aborted() then return nil end
            end
            local strs = scriptStrings(sc)
            if strs then
                for s in pairs(strs) do
                    if w.nameIndex[s] then
                        local l = m[s]
                        if not l then
                            l = {}
                            m[s] = l
                        end
                        l[#l + 1] = sc
                    end
                end
            end
        end
        w.mentions = m
        return m
    end

    local function recordDep(r, sc, tgt, kind)
        local d = r.deps[sc]
        if not d then
            d = {}
            r.deps[sc] = d
        end
        if d[tgt] ~= "require" then d[tgt] = kind end
        local u = r.usedBy[tgt]
        if not u then
            u = {}
            r.usedBy[tgt] = u
        end
        u[sc] = true
    end

    -- funcoes vivas (getgc): upvalues que sao Instances ou resultado de require()
    local function scanRuntime(aborted)
        if gcCache and os.clock() - gcCache.t < 30 then return gcCache end
        local r = { deps = {}, usedBy = {}, moduleOf = {}, t = 0 }
        local function finish()
            r.t = os.clock()
            gcCache = r
            return r
        end

        if typeof(getgc) ~= "function" or not (debug and debug.getupvalues) then
            r.unsupported = true
            return finish()
        end

        if typeof(getloadedmodules) == "function" then
            local okm, mods = pcall(getloadedmodules)
            if okm and type(mods) == "table" then
                for i = 1, #mods do
                    if i % 40 == 0 then
                        task.wait()
                        if aborted() then return nil end
                    end
                    local okr, res = pcall(require, mods[i])
                    if okr and (type(res) == "table" or type(res) == "function") then
                        r.moduleOf[res] = mods[i]
                    end
                end
            end
        end

        local okGc, gc = pcall(getgc)
        if not okGc or type(gc) ~= "table" then
            r.unsupported = true
            return finish()
        end

        for i = 1, #gc do
            if i % 3000 == 0 then
                task.wait()
                if aborted() then return nil end
            end
            local f = gc[i]
            if type(f) == "function" then
                local okE, fenv = pcall(getfenv, f)
                if okE and type(fenv) == "table" then
                    local okS, sc = pcall(function() return fenv.script end)
                    if okS and typeof(sc) == "Instance" then
                        local skip = false
                        if typeof(isexecutorclosure) == "function" then
                            local okx, isx = pcall(isexecutorclosure, f)
                            if okx and isx then skip = true end
                        end
                        if not skip then
                            local okU, ups = pcall(debug.getupvalues, f)
                            if okU and type(ups) == "table" then
                                for _, v in pairs(ups) do
                                    local t = typeof(v)
                                    if t == "Instance" then
                                        if v ~= sc and v ~= game then recordDep(r, sc, v, "upvalue") end
                                    elseif t == "table" or t == "function" then
                                        local m = r.moduleOf[v]
                                        if m and m ~= sc then recordDep(r, sc, m, "require") end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        return finish()
    end

    -- Devolve (rows, lines) ou nil se foi cancelado.
    analyzeDeps = function(inst, aborted, progress)
        local rows, lines = {}, {}
        local function add(row)
            rows[#rows + 1] = row
            lines[#lines + 1] = row.text
        end
        local function line(text, color)
            add({ text = text, display = text, click = false, color = color })
        end
        local function header(title)
            if #rows > 0 then line("") end
            add({ text = title, display = title, click = false, color = C.accent })
        end
        -- linha clicavel: nome, classe, relacao e caminho
        local function entry(target, note)
            local label = iconFor(target) .. " " .. safeName(target) .. "  ‹" .. safeClass(target) .. "›"
            local disp = "  ↳ " .. label .. (note and ("   [" .. note .. "]") or "") .. "   " .. getPath(target)
            add({
                text = disp, display = disp, click = true, inst = target,
                color = isScriptInstance(target) and C.script or nil,
            })
        end

        local class = safeClass(inst)
        local isScript = isScriptInstance(inst)
        local name = safeName(inst)

        -- 1) o proprio item
        header("📍 " .. name .. "  ‹" .. class .. "›")
        line("  Caminho : " .. getPath(inst))
        local okp, parent = pcall(function() return inst.Parent end)
        if okp and parent and parent ~= game then entry(parent, "pai") end
        local kids = safeChildren(inst)
        line("  Filhos  : " .. #kids)
        if isA(inst, "BasePart") then
            local okv, pos = pcall(function() return inst.Position end)
            local oks, size = pcall(function() return inst.Size end)
            if okv and typeof(pos) == "Vector3" then
                line(string.format("  Posição : %.1f, %.1f, %.1f", pos.X, pos.Y, pos.Z))
            end
            if oks and typeof(size) == "Vector3" then
                line(string.format("  Tamanho : %.1f, %.1f, %.1f", size.X, size.Y, size.Z))
            end
        end
        if inWorkspace(inst) then
            line("  No mapa : sim (Workspace) — contorno " .. (outlineEnabled and "ligado" or "desligado"))
        else
            line("  No mapa : não (fora do Workspace)")
        end

        -- 2) filhos
        if #kids > 0 then
            header("👶 Filhos (" .. #kids .. ")")
            for i = 1, math.min(#kids, MAX_LIST) do entry(kids[i]) end
            if #kids > MAX_LIST then line("  … +" .. (#kids - MAX_LIST) .. " filhos") end
        end

        -- 3) propriedades que apontam pra outras instancias
        local propHeader = false
        for _, p in ipairs(GENERIC_REF_PROPS) do
            local okv, v = pcall(function() return inst[p] end)
            if okv and typeof(v) == "Instance" then
                if not propHeader then
                    header("➡️ Aponta pra (propriedades)")
                    propHeader = true
                end
                entry(v, "." .. p)
            end
        end

        -- varreduras (cache de 30s)
        progress("⏳ Varrendo o jogo...")
        local w = scanWorld(aborted)
        if not w then return nil end
        progress("⏳ Lendo funções vivas (getgc)...")
        local rt = scanRuntime(aborted)
        if not rt then return nil end

        -- 4) dependencias de script
        if isScript then
            header("⚙️ Usa em runtime (upvalues das funções vivas)")
            if rt.unsupported then
                line("  (executor sem getgc / debug.getupvalues)", C.dim)
            else
                local list, kinds = {}, rt.deps[inst]
                if kinds then
                    for tgt in pairs(kinds) do list[#list + 1] = tgt end
                end
                sortedByName(list)
                if #list == 0 then
                    line("  (nenhuma — o script pode não estar rodando)", C.dim)
                else
                    for i = 1, math.min(#list, MAX_LIST) do
                        local k = kinds[list[i]]
                        entry(list[i], k == "require" and "require" or "upvalue")
                    end
                    if #list > MAX_LIST then line("  … +" .. (#list - MAX_LIST) .. " itens") end
                end
            end

            if typeof(getsenv) == "function" then
                local oke, env = pcall(getsenv, inst)
                if oke and type(env) == "table" then
                    local globals = {}
                    pcall(function()
                        for k, v in pairs(env) do
                            if typeof(v) == "Instance" then
                                globals[#globals + 1] = { key = tostring(k), inst = v }
                            elseif (type(v) == "table" or type(v) == "function") and rt.moduleOf[v] then
                                globals[#globals + 1] = { key = tostring(k), inst = rt.moduleOf[v], req = true }
                            end
                        end
                    end)
                    if #globals > 0 then
                        table.sort(globals, function(a, b) return a.key < b.key end)
                        header("🌐 Variáveis globais do script (getsenv)")
                        for i = 1, math.min(#globals, MAX_LIST) do
                            entry(globals[i].inst, (globals[i].req and "require " or "global ") .. globals[i].key)
                        end
                    end
                end
            end

            header("📛 Nomes citados no código (constantes — provável)")
            local strs = scriptStrings(inst)
            if not strs then
                line("  (sem getscriptclosure / debug.getconstants, ou script sem bytecode)", C.dim)
            else
                local names = {}
                for s in pairs(strs) do
                    if w.nameIndex[s] then names[#names + 1] = s end
                end
                table.sort(names)
                local shown = 0
                for _, s in ipairs(names) do
                    local cands = w.nameIndex[s]
                    local usable = {}
                    for _, c in ipairs(cands) do
                        if c ~= inst then usable[#usable + 1] = c end
                    end
                    if #usable > 0 then
                        shown = shown + 1
                        if shown > 60 then
                            line("  … limite de 60 nomes")
                            break
                        end
                        local extra = (cands.n > #cands) and ("  (+" .. (cands.n - #cands) .. " com o mesmo nome)") or ""
                        line("  \"" .. s .. "\"" .. extra, C.dim)
                        for _, c in ipairs(usable) do entry(c, "pelo nome") end
                    end
                end
                if shown == 0 then line("  (nenhum nome de módulo/remote/pasta encontrado)", C.dim) end
            end
        end

        -- 5) quem usa esse item
        header("⬅️ Usado / referenciado por")
        local any = false
        local listed = {}

        local rb = w.refBy[inst]
        if rb then
            for i = 1, math.min(#rb, MAX_LIST) do
                entry(rb[i].inst, "propriedade " .. rb[i].prop)
                any = true
            end
        end

        if not rt.unsupported then
            local ub = rt.usedBy[inst]
            if ub then
                local list = {}
                for sc in pairs(ub) do list[#list + 1] = sc end
                sortedByName(list)
                for i = 1, math.min(#list, MAX_LIST) do
                    entry(list[i], "usa em runtime")
                    listed[list[i]] = true
                    any = true
                end
            end
        end

        if NAME_CLASSES[class] and #name >= 3
            and typeof(getscriptclosure) == "function" and debug and debug.getconstants then
            progress("⏳ Procurando scripts que citam \"" .. name .. "\"...")
            local m = ensureMentions(w, aborted)
            if not m then return nil end
            local lst = m[name]
            if lst then
                local count = 0
                for _, sc in ipairs(lst) do
                    if sc ~= inst and not listed[sc] then
                        count = count + 1
                        if count > MAX_LIST then
                            line("  … mais scripts citam esse nome")
                            break
                        end
                        entry(sc, "cita o nome (provável)")
                        any = true
                    end
                end
            end
        end

        if not any then line("  (nada encontrado)", C.dim) end
        return rows, lines
    end
end

local depsWin = nil

local function openDepsViewer(target)
    if depsWin and depsWin.win.Parent then
        bringToFront(depsWin.win)
        if target then depsWin.setTarget(target) end
        return
    end

    local vpSize = getViewport()
    local Wc = math.min(640, vpSize.X - 20)
    local Hc = math.min(400, vpSize.Y - 20)

    local win = new("Frame", {
        Name = "DepsViewer", BackgroundColor3 = C.bg, BorderSizePixel = 0, Active = true,
        Size = UDim2.fromOffset(Wc, Hc),
        Position = UDim2.new(0.5, -Wc / 2 + 36, 0.5, -Hc / 2 + 36),
        ClipsDescendants = true,
    }, gui)
    new("UICorner", { CornerRadius = UDim.new(0, 12) }, win)
    new("UIStroke", { Color = C.accent, Thickness = 1.5, Transparency = 0.3 }, win)
    bringToFront(win)

    local bar = new("Frame", {
        BackgroundColor3 = C.panel, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 34),
    }, win)

    local titleLbl = new("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(1, -232, 1, 0), Text = "🔗 Dependências",
        TextColor3 = C.text, Font = Enum.Font.GothamBold, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
    }, bar)

    local closeB = headerButton(bar, "✕", 36, Color3.fromRGB(90, 40, 50))
    local pinB = headerButton(bar, "📌", 72)
    local copyB = headerButton(bar, "📋", 108)
    local refB = headerButton(bar, "🔄", 144)
    local backB = headerButton(bar, "⬅", 180)

    local status = new("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 8, 1, -22),
        Size = UDim2.new(1, -40, 0, 18),
        Text = "", TextColor3 = C.dim, Font = Enum.Font.Gotham, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
    }, win)

    local function vStatus(msg, color)
        status.Text = msg
        status.TextColor3 = color or C.dim
    end

    local cur, content, pinned = nil, "", false
    local history = {}
    local loadToken = 0
    local render

    local list = createVirtualList(win, {
        Position = UDim2.fromOffset(6, 38),
        Size = UDim2.new(1, -12, 1, -64),
        onClick = function(row)
            local t = row.inst
            if not t then return end
            if cur then history[#history + 1] = cur end
            render(t)
            selectOnly(t)
            if revealInTree then revealInTree(t) end
        end,
    })

    local grip = new("TextButton", {
        BackgroundTransparency = 1, Text = "◢", TextColor3 = C.accent,
        Font = Enum.Font.GothamBold, TextSize = 16,
        Size = UDim2.fromOffset(24, 24), Position = UDim2.new(1, -24, 1, -24),
        ZIndex = 5,
    }, win)

    local function setTitle()
        if cur then
            titleLbl.Text = "🔗 " .. safeName(cur) .. "  ‹" .. safeClass(cur) .. "›" .. (pinned and "  📌" or "")
        else
            titleLbl.Text = "🔗 Dependências"
        end
    end

    render = function(t)
        loadToken = loadToken + 1
        local tk = loadToken
        cur = t
        content = ""
        setTitle()
        if not t then
            list.setRows({ plainRow("Selecione um item na árvore pra ver as dependências dele.", C.dim) })
            vStatus("Nada selecionado")
            return
        end
        list.setRows({ plainRow("⏳ Analisando " .. safeName(t) .. "...", C.dim) })
        vStatus("⏳ Analisando...")
        task.spawn(function()
            local function dead() return tk ~= loadToken or not win.Parent end
            local ok, rows, lines = pcall(analyzeDeps, t, dead, function(msg)
                if not dead() then vStatus(msg) end
            end)
            if dead() then return end
            if ok and rows then
                content = table.concat(lines, "\n")
                list.setRows(rows)
                vStatus("✅ " .. #rows .. " linhas • clique num item pra navegar até ele", C.ok)
            elseif ok then
                vStatus("Cancelado")
            else
                list.setRows({ plainRow("❌ Erro na análise: " .. tostring(rows), C.bad) })
                vStatus("❌ Erro na análise", C.bad)
            end
        end)
    end

    pinB.MouseButton1Click:Connect(function()
        pinned = not pinned
        pinB.BackgroundColor3 = pinned and C.accent or C.panel2
        setTitle()
        if not pinned and primary and primary ~= cur then
            history = {}
            render(primary)
        end
    end)

    refB.MouseButton1Click:Connect(function()
        resetDepsCache()
        render(cur)
    end)

    backB.MouseButton1Click:Connect(function()
        local prev = table.remove(history)
        if prev then
            render(prev)
            selectOnly(prev)
            if revealInTree then revealInTree(prev) end
        else
            vStatus("Sem histórico pra voltar")
        end
    end)

    copyB.MouseButton1Click:Connect(function()
        if content == "" then vStatus("❌ Nada pra copiar", C.bad) return end
        if copyToClipboard(content) then
            vStatus("📋 Copiado pro clipboard", C.ok)
        else
            vStatus("❌ Executor sem setclipboard", C.bad)
        end
    end)

    -- acompanha a selecao da arvore (a nao ser que esteja com o 📌)
    local function hook()
        if not win.Parent or pinned then return end
        if primary and primary ~= cur then
            history = {}
            render(primary)
        end
    end
    selHooks[#selHooks + 1] = hook

    local cleanDrag = makeDrag(bar,
        function() bringToFront(win) return win.Position end,
        function(d, sp)
            win.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
        end)

    local cleanResize = makeDrag(grip,
        function()
            bringToFront(win)
            return Vector2.new(win.AbsoluteSize.X, win.AbsoluteSize.Y)
        end,
        function(d, s)
            local vsz = getViewport()
            local w = math.clamp(s.X + d.X, 320, vsz.X)
            local h = math.clamp(s.Y + d.Y, 200, vsz.Y)
            win.Size = UDim2.fromOffset(w, h)
        end)

    list.scroll.InputBegan:Connect(function() bringToFront(win) end)

    closeB.MouseButton1Click:Connect(function()
        loadToken = loadToken + 1
        cleanDrag()
        cleanResize()
        for i = #selHooks, 1, -1 do
            if selHooks[i] == hook then table.remove(selHooks, i) end
        end
        depsWin = nil
        win:Destroy()
    end)

    depsWin = {
        win = win,
        setTarget = function(t)
            history = {}
            render(t)
        end,
    }
    render(target or primary)
end

---------------------------------------------------------------------
-- Painel principal
---------------------------------------------------------------------
local vp = getViewport()
local W = math.min(580, vp.X - 20)
local H = math.min(390, vp.Y - 20)

local main = new("Frame", {
    Name = "Main", BackgroundColor3 = C.bg, BorderSizePixel = 0, Active = true,
    Size = UDim2.fromOffset(W, H),
    Position = UDim2.new(0.5, -W / 2 - 20, 0.5, -H / 2 - 20),
    ClipsDescendants = true,
}, gui)
new("UICorner", { CornerRadius = UDim.new(0, 12) }, main)
new("UIStroke", { Color = C.accent, Thickness = 1.5, Transparency = 0.3 }, main)
bringToFront(main)

local top = new("Frame", {
    Name = "Top", BackgroundColor3 = C.panel, BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 0, 34),
}, main)

new("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 0),
    Size = UDim2.new(1, -140, 1, 0), Text = "🗂️ Explorer Viewer",
    TextColor3 = C.text, Font = Enum.Font.GothamBold, TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left,
}, top)

local closeBtn = headerButton(top, "✕", 36, Color3.fromRGB(90, 40, 50))
local minBtn = headerButton(top, "—", 72)
local saveBtn = headerButton(top, "💾", 108)

local body = new("Frame", {
    Name = "Body", BackgroundTransparency = 1,
    Position = UDim2.fromOffset(0, 34), Size = UDim2.new(1, 0, 1, -34),
}, main)

local side = new("ScrollingFrame", {
    BackgroundColor3 = C.panel, BorderSizePixel = 0,
    Size = UDim2.new(0, 142, 1, 0),
    CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollBarThickness = 3, ScrollBarImageColor3 = C.accent,
}, body)
new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, side)
new("UIPadding", {
    PaddingTop = UDim.new(0, 6), PaddingLeft = UDim.new(0, 6),
    PaddingRight = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6),
}, side)

local outWrap = new("Frame", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(148, 4), Size = UDim2.new(1, -154, 1, -8),
}, body)

local status = new("TextLabel", {
    BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18),
    Position = UDim2.new(0, 0, 1, -18),
    Text = "Selecione um serviço ao lado", TextColor3 = C.dim,
    Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
}, outWrap)

local function setStatus(msg, color)
    status.Text = msg
    status.TextColor3 = color or C.dim
end

local onTreeClick   -- definido mais abaixo (precisa do estado da arvore)

local treeList = createVirtualList(outWrap, {
    Position = UDim2.fromOffset(0, 58),
    Size = UDim2.new(1, 0, 1, -80),
    checkbox = true,
    onClick = function(row, idx)
        if onTreeClick then onTreeClick(row, idx) end
    end,
    onCheck = function(row)
        local n = row.node
        if n and n.inst then toggleSelect(n.inst) end
    end,
    hasCheck = function(row)
        local n = row.node
        return n ~= nil and n.inst ~= nil
    end,
    isSelected = function(row)
        local n = row.node
        local inst = n and n.inst
        if inst and selection[inst] then
            return (inst == primary) and "primary" or true
        end
        return false
    end,
})
treeList.setRows({ plainRow("Escolha um serviço ao lado.  ▸ toque na pasta pra abrir  •  🔍 abre o código.", C.dim) })

---------------------------------------------------------------------
-- Construcao da arvore
---------------------------------------------------------------------
local currentToken = 0
local fullText = ""

local function buildTree(serviceName, rootKids, setStat, token)
    local rows = {}
    local byInst = {}
    local count, scripts = 0, 0
    local truncated, aborted = false, false

    local head = (SERVICE_ICONS[serviceName] or "🌐") .. " " .. serviceName
    rows[1] = { text = head, display = head, click = false, color = C.accent }

    -- No da arvore. "lead" = prefixo + conector (│  ├─ └─), "label" = emoji + nome.
    -- text = o que vai pro arquivo salvo; a tela desenha lead + seta + label.
    local function addNode(lead, label, inst, parentIdx, lname, isScript, hasKids)
        rows[#rows + 1] = {
            text = lead .. label, lead = lead, label = label, lname = lname,
            inst = inst, parent = parentIdx, isScript = isScript,
            hasKids = hasKids, expanded = false,
        }
        return #rows
    end

    -- Linha so de aviso (vazio, limite...). Nao entra na pesquisa.
    local function addInfo(text, parentIdx)
        rows[#rows + 1] = { text = text, info = true, parent = parentIdx }
        return #rows
    end

    local function walk(kids, prefix, depth, parentIdx)
        if aborted or truncated then return end
        for i, child in ipairs(kids) do
            if token ~= currentToken then aborted = true return end
            if count >= MAX_NODES then truncated = true return end

            local grand = safeChildren(child)
            local last = (i == #kids)
            local class = safeClass(child)
            local isScript = isScriptInstance(child)
            local extra = ""
            if not CONTAINER[class] then extra = "  ‹" .. class .. "›" end
            if #grand > 0 then extra = extra .. "  (" .. #grand .. ")" end
            if isScript then scripts = scripts + 1 end

            local cname = safeName(child)
            local label = iconFor(child) .. " " .. cname .. extra
            local idx = addNode(prefix .. (last and "└─ " or "├─ "), label,
                child, parentIdx, cname:lower(), isScript, #grand > 0)
            byInst[child] = idx

            count = count + 1
            if count % 250 == 0 then
                setStat("⏳ Lendo... " .. count .. " itens")
                task.wait()
            end

            if #grand > 0 then
                local nextPrefix = prefix .. (last and "   " or "│  ")
                if depth >= MAX_DEPTH then
                    addInfo(nextPrefix .. "└─ … (profundidade máxima)", idx)
                else
                    walk(grand, nextPrefix, depth + 1, idx)
                end
            end
        end
    end

    if #rootKids == 0 then
        addInfo("└─ (vazio ou inacessível pelo cliente)", 1)
    else
        walk(rootKids, "", 1, 1)
    end

    if truncated then
        addInfo("", 1)
        addInfo("⚠️ Limite de " .. MAX_NODES .. " itens atingido, o resto foi omitido.", 1)
    end

    if aborted then return nil end
    return rows, count, scripts, byInst
end

---------------------------------------------------------------------
-- Pesquisa (filtra a arvore pelo nome, sem diferenciar maiusculas)
---------------------------------------------------------------------
local allRows, curService, curCount, curScripts = nil, "", 0, 0
local allText = ""   -- arvore COMPLETA (tudo aberto) em texto, usada no 💾
local searchRaw, searchTerm = "", ""

local searchBox = new("TextBox", {
    BackgroundColor3 = C.panel, BorderSizePixel = 0,
    Position = UDim2.fromOffset(0, 0), Size = UDim2.new(1, -92, 0, 26),
    Text = "", PlaceholderText = "🔎 Pesquisar nome (ex: Egg)", PlaceholderColor3 = C.dim,
    TextColor3 = C.text, Font = Enum.Font.Code, TextSize = 13,
    ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left,
}, outWrap)
new("UICorner", { CornerRadius = UDim.new(0, 8) }, searchBox)
new("UIPadding", { PaddingLeft = UDim.new(0, 8) }, searchBox)

local clearSearchBtn = new("TextButton", {
    BackgroundColor3 = C.panel2, BorderSizePixel = 0,
    Position = UDim2.new(1, -86, 0, 0), Size = UDim2.fromOffset(26, 26),
    Text = "✕", TextColor3 = C.text, Font = Enum.Font.GothamBold, TextSize = 12,
}, outWrap)
new("UICorner", { CornerRadius = UDim.new(0, 8) }, clearSearchBtn)

local expandAllBtn = new("TextButton", {
    BackgroundColor3 = C.panel2, BorderSizePixel = 0,
    Position = UDim2.new(1, -56, 0, 0), Size = UDim2.fromOffset(26, 26),
    Text = "📂", TextColor3 = C.text, Font = Enum.Font.GothamBold, TextSize = 13,
}, outWrap)
new("UICorner", { CornerRadius = UDim.new(0, 8) }, expandAllBtn)

local collapseAllBtn = new("TextButton", {
    BackgroundColor3 = C.panel2, BorderSizePixel = 0,
    Position = UDim2.new(1, -26, 0, 0), Size = UDim2.fromOffset(26, 26),
    Text = "📁", TextColor3 = C.text, Font = Enum.Font.GothamBold, TextSize = 13,
}, outWrap)
new("UICorner", { CornerRadius = UDim.new(0, 8) }, collapseAllBtn)

-- Mantem so os itens que casam + os pais deles (pra nao perder o caminho)
-- e refaz os conectores ├─ └─ │ da arvore filtrada.
local function buildFilteredRows(rows, term)
    local marked, isMatch, hasMarkedKid = {}, {}, {}
    local matches = 0

    for i = 2, #rows do
        local r = rows[i]
        if r.lname and string.find(r.lname, term, 1, true) then
            matches = matches + 1
            isMatch[i] = true
            local j = i
            while j and j > 1 and not marked[j] do
                marked[j] = true
                local pj = rows[j].parent
                if pj then hasMarkedKid[pj] = true end
                j = pj
            end
        end
    end

    local lastChild = {}
    for i = 2, #rows do
        if marked[i] then lastChild[rows[i].parent] = i end
    end

    local out = { rows[1] }
    local childPrefix = { [1] = "" }
    for i = 2, #rows do
        if marked[i] then
            local r = rows[i]
            local p = r.parent
            local isLast = (lastChild[p] == i)
            local prefix = childPrefix[p] or ""
            local lead = prefix .. (isLast and "└─ " or "├─ ")
            childPrefix[i] = prefix .. (isLast and "   " or "│  ")
            -- na pesquisa as pastas dos resultados ficam abertas (▾), sem clique
            local disp = lead .. (hasMarkedKid[i] and "▾ " or "  ") .. r.label
            if r.isScript then disp = disp .. "   🔍" end
            local color = r.isScript and C.script or nil
            if isMatch[i] and not r.isScript then color = C.match end
            out[#out + 1] = {
                text = lead .. r.label,
                display = disp,
                node = r,
                click = true,
                color = color,
            }
        end
    end
    return out, matches
end

-- Linha desenhada na tela a partir de um no (seta ▸ fechada / ▾ aberta)
local function viewRow(n)
    if n.info then
        return { text = n.text, display = n.text, click = false, color = C.dim }
    end
    local arrow = n.hasKids and (n.expanded and "▾ " or "▸ ") or "  "
    local disp = n.lead .. arrow .. n.label
    if n.isScript then disp = disp .. "   🔍" end
    return {
        text = n.text,
        display = disp,
        node = n,
        click = true,
        color = n.isScript and C.script or nil,
    }
end

-- Estilo Explorer: um no so aparece se o pai esta aberto (e o pai tambem visivel).
local function buildVisibleRows(nodes)
    local out = { nodes[1] }
    local open = { [1] = true }
    for i = 2, #nodes do
        local n = nodes[i]
        if n.parent and open[n.parent] then
            out[#out + 1] = viewRow(n)
            open[i] = (n.hasKids and n.expanded) and true or false
        end
    end
    return out
end

-- Mostra a arvore (filtrada ou aberta/fechada).
-- fullText = o que o 💾 salva: a arvore COMPLETA, ou so os resultados se tiver filtro.
local function updateView(keepScroll)
    if not allRows then return end

    local rows, matches
    if searchTerm ~= "" then
        rows, matches = buildFilteredRows(allRows, searchTerm)
        if matches == 0 then
            rows[#rows + 1] = plainRow("└─ (nenhum resultado para \"" .. searchRaw .. "\")", C.dim)
        end
        local texts = {}
        for i = 1, #rows do texts[i] = rows[i].text end
        fullText = table.concat(texts, "\n")
    else
        rows = buildVisibleRows(allRows)
        fullText = allText
    end

    treeList.setRows(rows, keepScroll)

    if matches == nil then
        setStatus("✅ " .. curService .. " — " .. curCount .. " itens • " .. curScripts .. " scripts (🔍)", C.ok)
    else
        setStatus("🔎 \"" .. searchRaw .. "\" — " .. matches .. " resultado(s) em " .. curService,
            matches > 0 and C.ok or C.bad)
    end
end

-- Clique numa linha: pasta abre/fecha, script abre a janela do codigo.
-- (script que tem filhos faz as duas coisas)
onTreeClick = function(row)
    local n = row.node
    if not n or not n.inst then return end
    if n.hasKids and searchTerm == "" then
        n.expanded = not n.expanded
        updateView(true)   -- true = mantem a rolagem onde estava
    end
    selectOnly(n.inst)
    if n.isScript then openScriptViewer(n.inst) end
end

local function setAllExpanded(state)
    if not allRows then return end
    for i = 2, #allRows do
        local n = allRows[i]
        if n.hasKids then n.expanded = state end
    end
    updateView()
end

expandAllBtn.MouseButton1Click:Connect(function() setAllExpanded(true) end)
collapseAllBtn.MouseButton1Click:Connect(function() setAllExpanded(false) end)

local searchToken = 0
searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    searchToken = searchToken + 1
    local tk = searchToken
    task.delay(0.25, function()   -- espera parar de digitar
        if tk ~= searchToken then return end
        local raw = searchBox.Text
        raw = raw:gsub("^%s+", "")
        raw = raw:gsub("%s+$", "")
        if raw:lower() == searchTerm then
            searchRaw = raw
            return
        end
        searchRaw = raw
        searchTerm = raw:lower()
        updateView()
    end)
end)

clearSearchBtn.MouseButton1Click:Connect(function()
    searchBox.Text = ""
end)

---------------------------------------------------------------------
-- Carregar servico
---------------------------------------------------------------------
local serviceButtons = {}
local serviceLoaders = {}
local doReveal   -- definido mais abaixo

local function showService(serviceName, getRoot, revealInst)
    currentToken = currentToken + 1
    local token = currentToken
    allRows = nil   -- enquanto carrega, a pesquisa nao mexe na tela

    for n, b in pairs(serviceButtons) do
        b.BackgroundColor3 = (n == serviceName) and C.accent or C.panel2
    end

    treeList.setRows({ plainRow("⏳ Carregando " .. serviceName .. "...", C.dim) })
    setStatus("⏳ Lendo...")

    task.spawn(function()
        local rootInst, kids = getRoot()
        if token ~= currentToken then return end
        if rootInst == false then
            fullText = ""
            treeList.setRows({ plainRow("❌ " .. serviceName .. " não está disponível.", C.bad) })
            setStatus("❌ Indisponível", C.bad)
            return
        end

        local rows, count, scripts, byInst = buildTree(serviceName, kids, setStatus, token)
        if not rows or token ~= currentToken then return end
        rows.byInst = byInst

        local texts = {}
        for i = 1, #rows do texts[i] = rows[i].text end
        allText = table.concat(texts, "\n")

        allRows, curService, curCount, curScripts = rows, serviceName, count, scripts
        updateView()   -- comeca tudo fechado; aplica a pesquisa se ja tiver texto
        if revealInst and doReveal then doReveal(revealInst) end
    end)
end

local function addService(name, icon, getRoot)
    local btn = new("TextButton", {
        BackgroundColor3 = C.panel2, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 30),
        Text = icon .. " " .. name, TextColor3 = C.text,
        Font = Enum.Font.GothamMedium, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
        AutoButtonColor = true,
    }, side)
    new("UICorner", { CornerRadius = UDim.new(0, 6) }, btn)
    new("UIPadding", { PaddingLeft = UDim.new(0, 8) }, btn)
    serviceButtons[name] = btn
    serviceLoaders[name] = getRoot
    btn.MouseButton1Click:Connect(function()
        showService(name, getRoot)
    end)
end

local SERVICES = {
    "Workspace", "Players", "Lighting", "ReplicatedFirst", "ReplicatedStorage",
    "ServerScriptService", "ServerStorage", "StarterGui", "StarterPack",
    "StarterPlayer", "Teams", "SoundService", "Chat", "TextChatService",
    "MaterialService",
}

for _, name in ipairs(SERVICES) do
    local ok, svc = pcall(function() return game:GetService(name) end)
    if ok and svc then
        addService(name, SERVICE_ICONS[name] or "🌐", function()
            return svc, safeChildren(svc)
        end)
    end
end

do
    local ok, svc = pcall(function() return game:GetService("CoreGui") end)
    if ok and svc then
        addService("CoreGui", SERVICE_ICONS.CoreGui, function()
            return svc, safeChildren(svc)
        end)
    end
end

if typeof(getnilinstances) == "function" then
    addService("Nil", SERVICE_ICONS.Nil, function()
        local ok, list = pcall(getnilinstances)
        if not ok then return false end
        return game, list
    end)
end

---------------------------------------------------------------------
-- Selecao: revelar na arvore, barra de acoes, pegar do mapa
---------------------------------------------------------------------
-- nome do servico (aba) onde a instancia mora
local function serviceOf(inst)
    local cur, guard = inst, 0
    while cur and guard < 200 do
        local ok, p = pcall(function() return cur.Parent end)
        if not ok or p == nil then return nil end
        if p == game then return safeClass(cur) end
        cur = p
        guard = guard + 1
    end
    return nil
end

-- abre as pastas ate o item e rola a lista ate ele
doReveal = function(inst)
    if not allRows or not allRows.byInst then return end
    local idx = allRows.byInst[inst]
    if not idx then
        setStatus("⚠️ " .. safeName(inst) .. " não está na árvore carregada (limite/profundidade)", C.bad)
        return
    end
    if searchTerm ~= "" then
        searchRaw, searchTerm = "", ""
        searchBox.Text = ""
    end
    local p = allRows[idx].parent
    local guard = 0
    while p and p > 1 and guard < 200 do
        allRows[p].expanded = true
        p = allRows[p].parent
        guard = guard + 1
    end
    updateView()
    local vis = treeList.getRows()
    for i = 1, #vis do
        local nd = vis[i].node
        if nd and nd == allRows[idx] then
            treeList.scrollTo(i)
            break
        end
    end
end

revealInTree = function(inst)
    local svc = serviceOf(inst)
    if not svc or not serviceLoaders[svc] then
        setStatus("ℹ️ " .. safeName(inst) .. " fica fora dos serviços do painel (selecionado mesmo assim)", C.dim)
        return
    end
    if allRows and curService == svc then
        doReveal(inst)
    else
        showService(svc, serviceLoaders[svc], inst)
    end
end

-- barra de acoes (rola de lado se a janela for estreita)
local actions = new("ScrollingFrame", {
    BackgroundTransparency = 1, BorderSizePixel = 0,
    Position = UDim2.fromOffset(0, 30), Size = UDim2.new(1, 0, 0, 24),
    CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.X,
    ScrollingDirection = Enum.ScrollingDirection.X, ScrollBarThickness = 0,
}, outWrap)
new("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, actions)

local function actionBtn(text, width, order)
    local b = new("TextButton", {
        BackgroundColor3 = C.panel2, BorderSizePixel = 0,
        Size = UDim2.new(0, width, 1, 0), LayoutOrder = order,
        Text = text, TextColor3 = C.text, Font = Enum.Font.GothamMedium, TextSize = 12,
        AutoButtonColor = true,
    }, actions)
    new("UICorner", { CornerRadius = UDim.new(0, 6) }, b)
    return b
end

local depsBtn = actionBtn("🔗 Deps", 62, 1)
local pickBtn = actionBtn("🖱️ Mapa", 72, 2)
local parentBtn = actionBtn("⬆ Pai", 52, 3)
local pathBtn = actionBtn("📋 Path", 64, 4)
local outlineBtn = actionBtn("👁 Contorno", 90, 5)
local clearBtn = actionBtn("✖", 34, 6)
outlineBtn.BackgroundColor3 = C.accent

depsBtn.MouseButton1Click:Connect(function()
    openDepsViewer(primary)
    if not primary then setStatus("Selecione um item (clique na linha ou na caixinha ☐)", C.dim) end
end)

parentBtn.MouseButton1Click:Connect(function()
    if not primary then setStatus("Nada selecionado", C.dim) return end
    local ok, p = pcall(function() return primary.Parent end)
    if ok and p and p ~= game then
        selectOnly(p)
        revealInTree(p)
    else
        setStatus("Esse item não tem pai selecionável", C.dim)
    end
end)

pathBtn.MouseButton1Click:Connect(function()
    if #selOrder == 0 then setStatus("Nada selecionado", C.dim) return end
    local paths = {}
    for i, inst in ipairs(selOrder) do paths[i] = getPath(inst) end
    if copyToClipboard(table.concat(paths, "\n")) then
        setStatus("📋 " .. #paths .. " caminho(s) copiado(s)", C.ok)
    else
        setStatus("❌ Executor sem setclipboard", C.bad)
    end
end)

outlineBtn.MouseButton1Click:Connect(function()
    outlineEnabled = not outlineEnabled
    outlineBtn.BackgroundColor3 = outlineEnabled and C.accent or C.panel2
    updateOutlines()
    setStatus(outlineEnabled and "👁 Contorno no mapa ligado" or "👁 Contorno no mapa desligado", C.dim)
end)

clearBtn.MouseButton1Click:Connect(clearSelection)

-- atualiza destaque das linhas + status quando a selecao muda
selHooks[#selHooks + 1] = function()
    treeList.refresh()
    if #selOrder == 0 then
        setStatus("Seleção limpa", C.dim)
    elseif #selOrder == 1 then
        local i = selOrder[1]
        local note
        if inWorkspace(i) then
            note = outlineEnabled and "  •  contorno no mapa" or "  •  contorno desligado"
        else
            note = "  •  fora do Workspace (sem contorno)"
        end
        setStatus("✔ " .. safeName(i) .. " ‹" .. safeClass(i) .. "›" .. note, C.ok)
    else
        setStatus("✔ " .. #selOrder .. " itens selecionados (principal: " .. safeName(primary) .. ")", C.ok)
    end
end

-- pegar do mapa: clique (sem arrastar) em algo do jogo -> seleciona + abre na arvore
local pickMode = false

local function doPick(pos, additive)
    local cam = workspace.CurrentCamera
    if not cam then return end
    local ray = cam:ScreenPointToRay(pos.X, pos.Y)
    local okR, res = pcall(function()
        return workspace:Raycast(ray.Origin, ray.Direction * 3000)
    end)
    if not okR or not res or not res.Instance then
        setStatus("🖱️ Nada embaixo do clique", C.dim)
        return
    end
    local hit = res.Instance
    if additive then toggleSelect(hit) else selectOnly(hit) end
    revealInTree(hit)
end

pickBtn.MouseButton1Click:Connect(function()
    pickMode = not pickMode
    pickBtn.BackgroundColor3 = pickMode and C.accent or C.panel2
    pickBtn.Text = pickMode and "🖱️ Mapa ON" or "🖱️ Mapa"
    setStatus(pickMode and "🖱️ Clique em algo no mapa pra selecionar (Ctrl = somar à seleção)"
        or "🖱️ Seleção pelo mapa desligada", C.dim)
end)

do
    local conn = UIS.InputBegan:Connect(function(input, gpe)
        if gpe or not pickMode then return end
        local t = input.UserInputType
        if t ~= Enum.UserInputType.MouseButton1 and t ~= Enum.UserInputType.Touch then return end
        local start = input.Position
        local c
        c = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                c:Disconnect()
                if pickMode and (input.Position - start).Magnitude < 8 then
                    local additive = UIS:IsKeyDown(Enum.KeyCode.LeftControl)
                        or UIS:IsKeyDown(Enum.KeyCode.RightControl)
                    doPick(Vector2.new(input.Position.X, input.Position.Y), additive)
                end
            end
        end)
    end)
    cleanups[#cleanups + 1] = function() conn:Disconnect() end
end

---------------------------------------------------------------------
-- Janela de salvar a arvore (💾)
---------------------------------------------------------------------
local modalW = math.min(300, W - 24)
local modal = new("Frame", {
    Name = "SaveModal", Visible = false, ZIndex = 20,
    BackgroundColor3 = C.panel, BorderSizePixel = 0,
    Size = UDim2.fromOffset(modalW, 150),
    Position = UDim2.new(0.5, -modalW / 2, 0.5, -75),
}, main)
new("UICorner", { CornerRadius = UDim.new(0, 10) }, modal)
new("UIStroke", { Color = C.accent, Thickness = 1.5 }, modal)

new("TextLabel", {
    ZIndex = 21, BackgroundTransparency = 1,
    Position = UDim2.fromOffset(12, 8), Size = UDim2.new(1, -24, 0, 20),
    Text = "💾 Salvar Output em arquivo", TextColor3 = C.text,
    Font = Enum.Font.GothamBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
}, modal)

local nameBox = new("TextBox", {
    ZIndex = 21, BackgroundColor3 = C.panel2, BorderSizePixel = 0,
    Position = UDim2.fromOffset(12, 36), Size = UDim2.new(1, -24, 0, 32),
    Text = "", PlaceholderText = "ArquivoSs.txt", PlaceholderColor3 = C.dim,
    TextColor3 = C.text, Font = Enum.Font.Code, TextSize = 14,
    ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left,
}, modal)
new("UICorner", { CornerRadius = UDim.new(0, 6) }, nameBox)
new("UIPadding", { PaddingLeft = UDim.new(0, 8) }, nameBox)

local modalStatus = new("TextLabel", {
    ZIndex = 21, BackgroundTransparency = 1,
    Position = UDim2.fromOffset(12, 72), Size = UDim2.new(1, -24, 0, 18),
    Text = "Nome + extensão (ex: ArquivoSs.txt)", TextColor3 = C.dim,
    Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
}, modal)

local confirmBtn = new("TextButton", {
    ZIndex = 21, BackgroundColor3 = C.accent, BorderSizePixel = 0,
    Position = UDim2.fromOffset(12, 100), Size = UDim2.new(0.5, -16, 0, 32),
    Text = "Salvar", TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamBold, TextSize = 13,
}, modal)
local cancelBtn = new("TextButton", {
    ZIndex = 21, BackgroundColor3 = C.panel2, BorderSizePixel = 0,
    Position = UDim2.new(0.5, 4, 0, 100), Size = UDim2.new(0.5, -16, 0, 32),
    Text = "Cancelar", TextColor3 = C.text,
    Font = Enum.Font.GothamBold, TextSize = 13,
}, modal)
new("UICorner", { CornerRadius = UDim.new(0, 6) }, confirmBtn)
new("UICorner", { CornerRadius = UDim.new(0, 6) }, cancelBtn)

local function modalMsg(msg, color)
    modalStatus.Text = msg
    modalStatus.TextColor3 = color or C.dim
end

saveBtn.MouseButton1Click:Connect(function()
    modal.Visible = not modal.Visible
    if modal.Visible then
        modalMsg("Nome + extensão (ex: ArquivoSs.txt)")
    end
end)
cancelBtn.MouseButton1Click:Connect(function() modal.Visible = false end)

confirmBtn.MouseButton1Click:Connect(function()
    if fullText == "" then
        modalMsg("❌ Nada no Output pra salvar. Abra um serviço antes.", C.bad)
        return
    end

    local fname = cleanFileName(nameBox.Text, "ArquivoSs.txt")
    if not fname:match("%.%w+$") then fname = fname .. ".txt" end

    if typeof(writefile) == "function" then
        local ok, err = pcall(writefile, fname, fullText)
        if ok then
            modalMsg("✅ Salvo: " .. fname .. " (pasta workspace do executor)", C.ok)
            setStatus("💾 Salvo como " .. fname, C.ok)
        else
            modalMsg("❌ Erro: " .. tostring(err), C.bad)
        end
    elseif copyToClipboard(fullText) then
        modalMsg("⚠️ Sem writefile — copiei o texto pro clipboard.", C.bad)
    else
        modalMsg("❌ Seu executor não tem writefile.", C.bad)
    end
end)

---------------------------------------------------------------------
-- Arrastar, minimizar, fechar (painel principal)
---------------------------------------------------------------------
makeDrag(top,
    function() bringToFront(main) return main.Position end,
    function(d, sp)
        main.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
    end)

treeList.scroll.InputBegan:Connect(function() bringToFront(main) end)

local minimized = false
minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    body.Visible = not minimized
    modal.Visible = false
    main.Size = minimized and UDim2.fromOffset(W, 34) or UDim2.fromOffset(W, H)
end)

closeBtn.MouseButton1Click:Connect(function()
    currentToken = currentToken + 1
    for _, fn in ipairs(cleanups) do pcall(fn) end
    gui:Destroy()
end)
