--[[
    WindUI 速度修改器
    绕过点：不修改 Humanoid.WalkSpeed，直接驱动速度向量
    针对反作弊：V / d / m / i 函数（WalkSpeed 回写 + 移动完整性检测）
]]

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- ===== 创建窗口（加长边框 + 透明字体缩小） =====
local Window = WindUI:CreateWindow({
    Title = "速度修改",
    Author = "Speed Hack",
    Folder = "SpeedHack",
    Icon = "gauge",
    IconThemed = true,

    -- 边框加长（比默认 580 更宽，比默认 460 稍高）
    Size = UDim2.new(0, 780, 0, 480),
    MinSize = Vector2.new(620, 400),
    MaxSize = Vector2.new(1000, 620),

    Theme = "Dark",
    Resizable = true,

    -- 透明窗口
    Transparent = true,
    TransparencyValue = 0.15,

    -- 缩小字体通过 Window 的 Topbar 与 UI 缩放控制
    TopBarButtonIconSize = 14,
    ElementsRadius = 10,
    Radius = 14,
})

-- ===== 分区卡：名字叫“速度修改” =====
local SpeedTab = Window:Tab({
    Title = "速度修改",
    Icon = "gauge",
    Desc = "绕过反作弊的移动速度修改器",
})

-- ===== 核心逻辑 =====
local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local player      = Players.LocalPlayer

local enabled     = false
local speedValue  = 16
local mode        = "Velocity"   -- Velocity = 绕过 / WalkSpeed = 直接（会被检测）
local bypassConn  = nil

local function applySpeed()
    if bypassConn then bypassConn:Disconnect() bypassConn = nil end
    if not enabled then return end

    bypassConn = RunService.Heartbeat:Connect(function()
        local char = player.Character
        if not char then return end

        local hum = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp then return end

        if mode == "Velocity" then
            -- 关键绕过：不修改 WalkSpeed，只驱动速度向量
            -- 反作弊 i 函数检查 WalkSpeed 时永远是官方值
            local dir = hum.MoveDirection
            if dir.Magnitude > 0.05 then
                local v = dir.Unit * speedValue
                hrp.AssemblyLinearVelocity = Vector3.new(
                    v.X,
                    hrp.AssemblyLinearVelocity.Y,
                    v.Z
                )
            end
        else
            -- 直接改 WalkSpeed，仅作对照（会被反作弊秒杀）
            hum.WalkSpeed = speedValue
        end
    end)
end

-- ===== 控制器 UI =====
SpeedTab:Toggle({
    Title = "启用速度修改",
    Desc = "开启后按住方向键即可加速",
    Value = false,
    Callback = function(state)
        enabled = state
        applySpeed()
    end,
})

SpeedTab:Slider({
    Title = "速度值",
    Desc = "16 = 默认行走 | 100+ = 起飞",
    Value = { Min = 16, Max = 250, Default = 16 },
    Step = 1,
    Callback = function(value)
        speedValue = value
        -- 数值变化时无需重连，Heartbeat 里会读取新值
    end,
})

SpeedTab:Dropdown({
    Title = "模式",
    Desc = "Velocity = 绕过检测 | WalkSpeed = 直接改（会被杀）",
    Values = { "Velocity", "WalkSpeed" },
    Value = "Velocity",
    Callback = function(v)
        mode = v
        applySpeed()
    end,
})

SpeedTab:Divider()

SpeedTab:Paragraph({
    Title = "使用说明",
    Desc = "Velocity 模式不会修改 WalkSpeed，可以绕过大部分 WalkSpeed 回写型反作弊；如果目标反作弊检测速度向量大小，请把速度值控制在 60 以内。",
})

SpeedTab:Button({
    Title = "重置状态",
    Icon = "rotate-ccw",
    Callback = function()
        enabled = false
        speedValue = 16
    end,
})