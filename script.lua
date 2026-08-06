local Arcane = loadstring(game:HttpGet("https://raw.githubusercontent.com/Da7mu/Ui-Collection/refs/heads/main/Arcane%20Ui/Library.lua"))()

local Unloaded = false
local Connections = {}

local Configs = {
    AutoReset = { Enabled = false, ResetPercentage = 10, SpawnAtDeath = false },
    DelayMod = { Enabled = false, ActionDelayMultiplier = 1.0 },
    Crouch = { Enabled = false, FastCrouchAnimation = true, CrouchAnimationMultiplier = 2.5 },
    Jump = { Enabled = false, BoostAmount = 75, KickInAt = 40 },
    Stamina = { Enabled = false },
    AntiGroundHit = { Enabled = false },

    Visuals = { 
        Enabled = false, 
        Color = Color3.fromRGB(200, 0, 0), 
        Material = Enum.Material.Neon,
        Texture = "Disabled",
        Transparency = 0.7,
        Reflectance = 0
    },

    Skybox = { Enabled = false, Name = "Default" },
    Ambience = { Enabled = false, Ambient = Color3.fromRGB(128, 128, 128), OutdoorAmbient = Color3.fromRGB(128, 128, 128) },
    Time = { Enabled = false, Value = 12 },
    Bloom = { Enabled = false, Intensity = 15, Size = 24, Threshold = 2 },
    ColorShift = { Enabled = false, Top = Color3.fromRGB(255, 0, 0), Bottom = Color3.fromRGB(0, 0, 255) },
    Atmosphere = { 
        Enabled = false, 
        Density = 0.4, 
        Color = Color3.fromRGB(199, 175, 166),
        Decay = Color3.fromRGB(92, 60, 13),
        Glare = 0, 
        Haze = 0 
    },
    Fog = { Enabled = false, Start = 0, End = 1000, Color = Color3.fromRGB(192, 192, 192) },
    SunRays = { Enabled = false, Intensity = 0.25, Spread = 1 },
    Tracers = { Enabled = false, Style = "Lightning", Color = Color3.fromRGB(255, 50, 50), Lifetime = 0.8, Width = 1.2 },

    SpawnGamepass = { Enabled = false, Location = "Random" },

    AvatarSpoofer = {
        Enabled = false,
        Target = "",
        Headless = false,
        KorbloxLeftLeg = false,
        KorbloxRightLeg = false,
        KorbloxLeftArm = false,
        KorbloxRightArm = false
    }
}

local function TrackConnection(conn)
    table.insert(Connections, conn)
    return conn
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local MarketplaceService = game:GetService("MarketplaceService")
local LocalPlayer = Players.LocalPlayer

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Traits = require(Modules:WaitForChild("Traits"))

local SkyBoxes = {
    ["Default"] = {SkyboxLf="rbxassetid://148943339",SkyboxBk="rbxassetid://148943390",SkyboxDn="rbxassetid://148943362",SkyboxFt="rbxassetid://148943404",SkyboxRt="rbxassetid://148943379",SkyboxUp="rbxassetid://148943410"},
    ["Nebula"] = {SkyboxLf="rbxassetid://159454286",SkyboxBk="rbxassetid://159454299",SkyboxDn="rbxassetid://159454296",SkyboxFt="rbxassetid://159454293",SkyboxRt="rbxassetid://159454300",SkyboxUp="rbxassetid://159454288"},
    ["Blue Nebula"] = {SkyboxBk="rbxassetid://79187608916257",SkyboxDn="rbxassetid://79187608916257",SkyboxFt="rbxassetid://135345543970829",SkyboxLf="rbxassetid://130684897818024",SkyboxRt="rbxassetid://134117814265945",SkyboxUp="rbxassetid://128019898265074"},
    ["Setting Hills"] = {SkyboxLf="rbxassetid://264909758",SkyboxBk="rbxassetid://264908339",SkyboxDn="rbxassetid://264907909",SkyboxFt="rbxassetid://264909420",SkyboxRt="rbxassetid://264908886",SkyboxUp="rbxassetid://264907379"},
    ["Blue Aurora"] = {SkyboxBk="rbxassetid://12064107",SkyboxDn="rbxassetid://12064152",SkyboxFt="rbxassetid://12064121",SkyboxLf="rbxassetid://12063984",SkyboxRt="rbxassetid://12064115",SkyboxUp="rbxassetid://12064131"},
    ["Red Aurora"] = {SkyboxBk="rbxassetid://401664839",SkyboxDn="rbxassetid://401664862",SkyboxFt="rbxassetid://401664960",SkyboxLf="rbxassetid://401664881",SkyboxRt="rbxassetid://401664901",SkyboxUp="rbxassetid://401664936"},
    ["Pink Vision"] = {SkyboxBk="rbxassetid://6593929026",SkyboxDn="rbxassetid://6593930140",SkyboxFt="rbxassetid://6593931249",SkyboxLf="rbxassetid://6593932587",SkyboxRt="rbxassetid://6593933789",SkyboxUp="rbxassetid://6593935319"},
    ["Twillight"] = {SkyboxBk="rbxassetid://570557514",SkyboxDn="rbxassetid://570557775",SkyboxFt="rbxassetid://570557559",SkyboxLf="rbxassetid://570557620",SkyboxRt="rbxassetid://570557672",SkyboxUp="rbxassetid://570557727"},
    ["Distopia"] = {SkyboxBk="rbxassetid://2240134413",SkyboxDn="rbxassetid://2240136039",SkyboxFt="rbxassetid://2240130790",SkyboxLf="rbxassetid://2240133550",SkyboxRt="rbxassetid://2240132643",SkyboxUp="rbxassetid://2240135222"},
    ["Peaceful"] = {SkyboxBk="rbxassetid://73252679982122",SkyboxDn="rbxassetid://101074061181553",SkyboxFt="rbxassetid://112572775732134",SkyboxLf="rbxassetid://126931573973019",SkyboxRt="rbxassetid://135908172504233",SkyboxUp="rbxassetid://124514468649717"}
}

local ChamsAnimations = {
    ["Disabled"]="", ["Webbed"]="rbxassetid://2179243880", ["Pixelated"]="rbxassetid://140652787",
    ["Swirl"]="rbxassetid://8133639623", ["Shield"]="rbxassetid://361073795", ["Bubbles"]="rbxassetid://1461576423",
    ["Matrix"]="rbxassetid://10713189068", ["Honeycomb"]="rbxassetid://179898251", ["Clouds"]="rbxassetid://5176277457",
    ["Galaxy"]="rbxassetid://1120738433", ["Stars"]="rbxassetid://598201818", ["Wires"]="rbxassetid://14127933",
    ["Camo"]="rbxassetid://3280937154", ["Hexagon"]="rbxassetid://6175083785", ["Particles"]="rbxassetid://1133822388",
    ["Triangular"]="rbxassetid://4504368932", ["Wall"]="rbxassetid://4271279", ["Scanning"]="rbxassetid://5843010904"
}

local TracerProperties = {
    ["Obelus"] = {
        Texture = "rbxassetid://2382169232", Brightness = 1.5, Transparency = NumberSequence.new(0.45),
        LightEmission = 1, LightInfluence = 0, Segments = 1, TextureLength = 5,
        TextureMode = Enum.TextureMode.Stretch, TextureSpeed = 0, Width0 = 0.35, Width1 = 0.35, FaceCamera = true
    },
    ["Lightning"] = {
        Texture = "rbxassetid://7151778302", Brightness = 1.5, Transparency = NumberSequence.new(0.45),
        LightEmission = 1, LightInfluence = 0, Segments = 10, TextureLength = 1,
        TextureMode = Enum.TextureMode.Stretch, TextureSpeed = 1, Width0 = 1.3, Width1 = 1.3, FaceCamera = true
    },
    ["DNA"] = {
        Texture = "rbxassetid://7071778278", Brightness = 1.5, Transparency = NumberSequence.new(0.45),
        LightEmission = 1, LightInfluence = 0, Segments = 1, TextureLength = 12,
        TextureMode = Enum.TextureMode.Wrap, TextureSpeed = 1, Width0 = 0.7, Width1 = 0.7, FaceCamera = true
    }
}

local BundleAssets = {
    Headless = 134083940,
    KorbloxLeftLeg = 139607713,
    KorbloxRightLeg = 139607724,
    KorbloxLeftArm = 139607687,
    KorbloxRightArm = 139607697
}

local Window = Arcane:Window({
    Name = "spoofware.lol",
    User = LocalPlayer.Name,
    Logo = "97741915311873"
})

local MainPage = Window:Page({ Name = "Main", Icon = "home" })
local WorldPage = Window:Page({ Name = "World", Icon = "globe" })
local MiscPage = Window:Page({ Name = "Misc", Icon = "list" })
local SettingsPage = Window:Page({ Name = "Settings", Icon = "settings" })

local MainSub = MainPage:SubPage({ Name = "Scripts", Icon = "zap" })
local VisualsSub = WorldPage:SubPage({ Name = "Visuals", Icon = "eye" })
local MiscSub = MiscPage:SubPage({ Name = "Main", Icon = "list" })
local ConfigSub = SettingsPage:SubPage({ Name = "Configs", Icon = "save" })

local ScriptsSection = MainSub:Section({ Name = "Script Toggles", Side = 1 })
local VisualsSection = VisualsSub:Section({ Name = "Gun Visuals", Side = 1 })
local WorldVisualsSection = VisualsSub:Section({ Name = "World Visuals", Side = 1 })
local MiscSection = MiscSub:Section({ Name = "Spawn & Avatar", Side = 1 })
local MenuSection = ConfigSub:Section({ Name = "Menu Options", Side = 1 })

local AutoResetToggle = ScriptsSection:Toggle({ Name = "Auto Reset", Flag = "AutoResetToggle", Default = false, Callback = function(s) Configs.AutoReset.Enabled = s end })
local AutoResetSettings = AutoResetToggle:Settings()
AutoResetSettings:Slider({ Name = "Reset Percentage", Flag = "ResetSlider", Min = 1, Max = 99, Default = 10, Suffix = "%", Callback = function(v) Configs.AutoReset.ResetPercentage = v end })
AutoResetSettings:Toggle({ Name = "Spawn at Death Location", Flag = "SpawnAtDeathToggle", Default = false, Callback = function(s) Configs.AutoReset.SpawnAtDeath = s end })

local DelayModToggle = ScriptsSection:Toggle({ Name = "Delay Modification", Flag = "DelayModToggle", Default = false, Callback = function(s) Configs.DelayMod.Enabled = s end })
local DelayModSettings = DelayModToggle:Settings()
DelayModSettings:Slider({ Name = "Action Delay Multiplier", Flag = "ActionDelayMulti", Min = 0, Max = 2, Default = 1, Decimals = 0.01, Callback = function(v) Configs.DelayMod.ActionDelayMultiplier = v end })

local CrouchToggle = ScriptsSection:Toggle({ Name = "Crouch Modification", Flag = "CrouchToggle", Default = false, Callback = function(s) Configs.Crouch.Enabled = s end })
local CrouchSettings = CrouchToggle:Settings()
CrouchSettings:Toggle({ Name = "Fast Crouch Animation", Flag = "CrouchAnimToggle", Default = true, Callback = function(s) Configs.Crouch.FastCrouchAnimation = s end })
CrouchSettings:Slider({ Name = "Animation Speed Multiplier", Flag = "CrouchAnimMulti", Min = 1, Max = 5, Default = 2.5, Decimals = 0.1, Callback = function(v) Configs.Crouch.CrouchAnimationMultiplier = v end })

local JumpToggle = ScriptsSection:Toggle({ Name = "Glock Launch Boost", Flag = "JumpToggle", Default = false, Callback = function(s) Configs.Jump.Enabled = s end })
local JumpSettings = JumpToggle:Settings()
JumpSettings:Slider({ Name = "Boost Amount", Flag = "JumpAmt", Min = 0, Max = 200, Default = 75, Callback = function(v) Configs.Jump.BoostAmount = v end })
JumpSettings:Slider({ Name = "Kick-In Velocity", Flag = "JumpKick", Min = 0, Max = 100, Default = 40, Callback = function(v) Configs.Jump.KickInAt = v end })

ScriptsSection:Toggle({ Name = "Infinite Stamina", Flag = "StaminaToggle", Default = false, Callback = function(s) Configs.Stamina.Enabled = s end })
ScriptsSection:Toggle({ Name = "Anti GroundHit", Flag = "AntiGroundHitToggle", Default = false, Callback = function(s) Configs.AntiGroundHit.Enabled = s end })

local GunVisualsToggle = VisualsSection:Toggle({
    Name = "Gun Chams", Flag = "GunVisualsToggle", Default = false,
    Callback = function(s) Configs.Visuals.Enabled = s end
})
local GunSettings = GunVisualsToggle:Settings()
GunSettings:Colorpicker({ Name = "Gun Color", Default = Color3.fromRGB(200,0,0), Flag = "GunColor", Callback = function(c) Configs.Visuals.Color = c end })
GunSettings:Dropdown({
    Name = "Material",
    Items = {"Neon","ForceField","Plastic","SmoothPlastic","Glass","Foil","Ice","Metal"},
    Default = "Neon", Flag = "GunMaterial",
    Callback = function(n) Configs.Visuals.Material = Enum.Material[n] or Enum.Material.Neon end
})
GunSettings:Dropdown({
    Name = "ForceField Animation",
    Items = {"Disabled","Webbed","Pixelated","Swirl","Shield","Bubbles","Matrix","Honeycomb","Clouds","Galaxy","Stars","Wires","Camo","Hexagon","Particles","Triangular","Wall","Scanning"},
    Default = "Disabled", Flag = "GunTexture",
    Callback = function(n) Configs.Visuals.Texture = n end
})
GunSettings:Slider({ Name = "Transparency", Min = 0, Max = 1, Default = 0.7, Decimals = 0.05, Flag = "GunTransparency", Callback = function(v) Configs.Visuals.Transparency = v end })
GunSettings:Slider({ Name = "Reflectance", Min = 0, Max = 1, Default = 0, Decimals = 0.05, Flag = "GunReflectance", Callback = function(v) Configs.Visuals.Reflectance = v end })

local function makeToggle(section, name, flag, default, cb)
    return section:Toggle({ Name = name, Flag = flag, Default = default, Callback = cb })
end

local SkyboxToggle = makeToggle(WorldVisualsSection, "Custom Skybox", "SkyboxToggle", false, function(s)
    Configs.Skybox.Enabled = s
    ApplySkybox()
end)
local SkySettings = SkyboxToggle:Settings()
SkySettings:Dropdown({
    Name = "Skybox",
    Items = {"Default","Nebula","Blue Nebula","Setting Hills","Blue Aurora","Red Aurora","Pink Vision","Twillight","Distopia","Peaceful"},
    Default = "Default", Flag = "SkyboxName",
    Callback = function(n) Configs.Skybox.Name = n if Configs.Skybox.Enabled then ApplySkybox() end end
})

local AmbToggle = makeToggle(WorldVisualsSection, "Ambience Colors", "AmbienceToggle", false, function(s) Configs.Ambience.Enabled = s end)
local AmbSettings = AmbToggle:Settings()
AmbSettings:Colorpicker({ Name = "Ambient", Default = Color3.fromRGB(128,128,128), Flag = "AmbColor", Callback = function(c) Configs.Ambience.Ambient = c end })
AmbSettings:Colorpicker({ Name = "Outdoor Ambient", Default = Color3.fromRGB(128,128,128), Flag = "OutAmbColor", Callback = function(c) Configs.Ambience.OutdoorAmbient = c end })

local TimeToggle = makeToggle(WorldVisualsSection, "Custom Time", "TimeToggle", false, function(s) Configs.Time.Enabled = s end)
local TimeSettings = TimeToggle:Settings()
TimeSettings:Slider({ Name = "Clock Time", Min = 0, Max = 24, Default = 12, Decimals = 0.1, Flag = "TimeValue", Callback = function(v) Configs.Time.Value = v end })

local BloomToggle = makeToggle(WorldVisualsSection, "Bloom", "BloomToggle", false, function(s) Configs.Bloom.Enabled = s end)
local BloomSettings = BloomToggle:Settings()
BloomSettings:Slider({ Name = "Intensity", Min = 0, Max = 100, Default = 15, Decimals = 0.5, Flag = "BloomInt", Callback = function(v) Configs.Bloom.Intensity = v end })
BloomSettings:Slider({ Name = "Size", Min = 0, Max = 56, Default = 24, Decimals = 0.5, Flag = "BloomSize", Callback = function(v) Configs.Bloom.Size = v end })
BloomSettings:Slider({ Name = "Threshold", Min = 0, Max = 10, Default = 2, Decimals = 0.1, Flag = "BloomThresh", Callback = function(v) Configs.Bloom.Threshold = v end })

local CSToggle = makeToggle(WorldVisualsSection, "ColorShift", "ColorShiftToggle", false, function(s) Configs.ColorShift.Enabled = s end)
local CSSettings = CSToggle:Settings()
CSSettings:Colorpicker({ Name = "Top", Default = Color3.fromRGB(255,0,0), Flag = "CSTop", Callback = function(c) Configs.ColorShift.Top = c end })
CSSettings:Colorpicker({ Name = "Bottom", Default = Color3.fromRGB(0,0,255), Flag = "CSBottom", Callback = function(c) Configs.ColorShift.Bottom = c end })

local AtmoToggle = makeToggle(WorldVisualsSection, "Atmosphere", "AtmosphereToggle", false, function(s) Configs.Atmosphere.Enabled = s end)
local AtmoSettings = AtmoToggle:Settings()
AtmoSettings:Slider({ Name = "Density", Min = 0, Max = 1, Default = 0.4, Decimals = 0.01, Flag = "AtmoDens", Callback = function(v) Configs.Atmosphere.Density = v end })
AtmoSettings:Colorpicker({ Name = "Color", Default = Color3.fromRGB(199,175,166), Flag = "AtmoColor", Callback = function(c) Configs.Atmosphere.Color = c end })
AtmoSettings:Colorpicker({ Name = "Decay Color", Default = Color3.fromRGB(92,60,13), Flag = "AtmoDecay", Callback = function(c) Configs.Atmosphere.Decay = c end })
AtmoSettings:Slider({ Name = "Glare", Min = 0, Max = 10, Default = 0, Decimals = 0.1, Flag = "AtmoGlare", Callback = function(v) Configs.Atmosphere.Glare = v end })
AtmoSettings:Slider({ Name = "Haze", Min = 0, Max = 10, Default = 0, Decimals = 0.1, Flag = "AtmoHaze", Callback = function(v) Configs.Atmosphere.Haze = v end })

local FogToggle = makeToggle(WorldVisualsSection, "Fog", "FogToggle", false, function(s) Configs.Fog.Enabled = s end)
local FogSettings = FogToggle:Settings()
FogSettings:Slider({ Name = "Start", Min = 0, Max = 2000, Default = 0, Flag = "FogStart", Callback = function(v) Configs.Fog.Start = v end })
FogSettings:Slider({ Name = "End", Min = 0, Max = 5000, Default = 1000, Flag = "FogEnd", Callback = function(v) Configs.Fog.End = v end })
FogSettings:Colorpicker({ Name = "Color", Default = Color3.fromRGB(192,192,192), Flag = "FogColor", Callback = function(c) Configs.Fog.Color = c end })

local SRToggle = makeToggle(WorldVisualsSection, "Sun Rays", "SunRaysToggle", false, function(s) Configs.SunRays.Enabled = s end)
local SRSettings = SRToggle:Settings()
SRSettings:Slider({ Name = "Intensity", Min = 0, Max = 1, Default = 0.25, Decimals = 0.01, Flag = "SRInt", Callback = function(v) Configs.SunRays.Intensity = v end })
SRSettings:Slider({ Name = "Spread", Min = 0, Max = 1, Default = 1, Decimals = 0.01, Flag = "SRSpread", Callback = function(v) Configs.SunRays.Spread = v end })

local TracerToggle = makeToggle(WorldVisualsSection, "Bullet Tracers", "TracersToggle", false, function(s) Configs.Tracers.Enabled = s end)
local TracerSettings = TracerToggle:Settings()
TracerSettings:Dropdown({
    Name = "Style",
    Items = {"Obelus","Lightning","DNA"},
    Default = "Lightning", Flag = "TracerStyle",
    Callback = function(s) Configs.Tracers.Style = s end
})
TracerSettings:Colorpicker({
    Name = "Color",
    Default = Color3.fromRGB(255,50,50), Flag = "TracerColor",
    Callback = function(c) Configs.Tracers.Color = c end
})
TracerSettings:Slider({
    Name = "Width / Thickness",
    Min = 0.3, Max = 4, Default = 1.2, Decimals = 0.05, Flag = "TracerWidth",
    Callback = function(v) Configs.Tracers.Width = v end
})
TracerSettings:Slider({
    Name = "Lifetime",
    Min = 0.1, Max = 3, Default = 0.8, Decimals = 0.05, Flag = "TracerLife",
    Callback = function(v) Configs.Tracers.Lifetime = v end
})

local SpawnGPToggle = MiscSection:Toggle({
    Name = "Spawn Gamepass",
    Flag = "SpawnGamepassToggle",
    Default = false,
    Callback = function(state)
        Configs.SpawnGamepass.Enabled = state
        if state then
            ApplySpawnLocation(Configs.SpawnGamepass.Location)
        end
    end
})
local SpawnGPSettings = SpawnGPToggle:Settings()
SpawnGPSettings:Dropdown({
    Name = "Location",
    Items = {"Front", "Back", "Visit", "Random"},
    Default = "Random",
    Flag = "SpawnLocationChoice",
    Callback = function(loc)
        Configs.SpawnGamepass.Location = loc
        if Configs.SpawnGamepass.Enabled then
            ApplySpawnLocation(loc)
        end
    end
})

local AvatarToggle = MiscSection:Toggle({
    Name = "Avatar Spoofer",
    Flag = "AvatarSpooferToggle",
    Default = false,
    Callback = function(s) Configs.AvatarSpoofer.Enabled = s end
})
local AvatarSettings = AvatarToggle:Settings()

AvatarSettings:Textbox({
    Name = "Username / ID",
    Placeholder = "username or userid",
    Flag = "AvatarTarget",
    Callback = function(text)
        Configs.AvatarSpoofer.Target = text
    end
})

AvatarSettings:Toggle({
    Name = "Headless",
    Flag = "AvatarHeadless",
    Default = false,
    Callback = function(s) Configs.AvatarSpoofer.Headless = s end
})
AvatarSettings:Toggle({
    Name = "Korblox Left Leg",
    Flag = "AvatarKorbloxLL",
    Default = false,
    Callback = function(s) Configs.AvatarSpoofer.KorbloxLeftLeg = s end
})
AvatarSettings:Toggle({
    Name = "Korblox Right Leg",
    Flag = "AvatarKorbloxRL",
    Default = false,
    Callback = function(s) Configs.AvatarSpoofer.KorbloxRightLeg = s end
})
AvatarSettings:Toggle({
    Name = "Korblox Left Arm",
    Flag = "AvatarKorbloxLA",
    Default = false,
    Callback = function(s) Configs.AvatarSpoofer.KorbloxLeftArm = s end
})
AvatarSettings:Toggle({
    Name = "Korblox Right Arm",
    Flag = "AvatarKorbloxRA",
    Default = false,
    Callback = function(s) Configs.AvatarSpoofer.KorbloxRightArm = s end
})

AvatarSettings:Button({
    Name = "Apply Avatar",
    Callback = function()
        ApplyAvatarSpoof()
    end
})

AvatarSettings:Button({
    Name = "Reset to Own",
    Callback = function()
        ResetAvatar()
    end
})

local function UnloadUI()
    if Unloaded then return end
    Unloaded = true
    for _, t in pairs(Configs) do if type(t) == "table" then t.Enabled = false end end
    for _, c in ipairs(Connections) do
        if c and typeof(c) == "RBXScriptConnection" and c.Connected then c:Disconnect() end
    end
    table.clear(Connections)
    pcall(function() if Arcane.Unload then Arcane:Unload() end end)
    pcall(function()
        for _, g in ipairs(CoreGui:GetChildren()) do
            if g:IsA("ScreenGui") and g.Name:lower():find("arcane") then g:Destroy() end
        end
        for _, g in ipairs(LocalPlayer.PlayerGui:GetChildren()) do
            if g:IsA("ScreenGui") and g.Name:lower():find("arcane") then g:Destroy() end
        end
    end)
end

MenuSection:Button({ Name = "Unload UI", Callback = UnloadUI })
ConfigSub:Config()

Arcane:Notification({
    Name = "spoofware.lol",
    Description = "Loaded successfully.",
    Duration = 5,
    Icon = "check",
    Color = Color3.fromRGB(126, 192, 255)
})
Window:Watermark({ Title = "spoofware.lol | v1.7" })

if hookfunction then
    pcall(function()
        local oldOwns
        oldOwns = hookfunction(MarketplaceService.UserOwnsGamePassAsync, function(self, userId, passId)
            if passId == 683649849 then
                return true
            end
            return oldOwns(self, userId, passId)
        end)
    end)
end

function ApplySpawnLocation(location)
    Configs.SpawnGamepass.Location = location
    pcall(function()
        local DataClient = require(Modules:WaitForChild("DataClient", 2))
        if DataClient and DataClient.Set then
            DataClient:Set("SpawnLocation", location)
        end
    end)
end

local OriginalDescription = nil

function ApplyAvatarSpoof()
    local target = Configs.AvatarSpoofer.Target
    if not target or target == "" then
        Arcane:Notification({ Name = "Avatar Spoofer", Description = "Enter a username or ID first.", Duration = 3, Icon = "x", Color = Color3.fromRGB(255,80,80) })
        return
    end

    task.spawn(function()
        local userId
        if tonumber(target) then
            userId = tonumber(target)
        else
            local success, result = pcall(function()
                return Players:GetUserIdFromNameAsync(target)
            end)
            if not success then
                Arcane:Notification({ Name = "Avatar Spoofer", Description = "Invalid username.", Duration = 3, Icon = "x", Color = Color3.fromRGB(255,80,80) })
                return
            end
            userId = result
        end

        local success, description = pcall(function()
            return Players:GetHumanoidDescriptionFromUserId(userId)
        end)

        if not success or not description then
            Arcane:Notification({ Name = "Avatar Spoofer", Description = "Failed to load avatar.", Duration = 3, Icon = "x", Color = Color3.fromRGB(255,80,80) })
            return
        end

        description.BodyTypeScale = 0
        description.ProportionScale = 0
        description.HeightScale = 1
        description.WidthScale = 1
        description.DepthScale = 1
        description.HeadScale = 1

        if Configs.AvatarSpoofer.Headless then
            description.Head = BundleAssets.Headless
        end
        if Configs.AvatarSpoofer.KorbloxLeftLeg then
            description.LeftLeg = BundleAssets.KorbloxLeftLeg
        end
        if Configs.AvatarSpoofer.KorbloxRightLeg then
            description.RightLeg = BundleAssets.KorbloxRightLeg
        end
        if Configs.AvatarSpoofer.KorbloxLeftArm then
            description.LeftArm = BundleAssets.KorbloxLeftArm
        end
        if Configs.AvatarSpoofer.KorbloxRightArm then
            description.RightArm = BundleAssets.KorbloxRightArm
        end

        local char = LocalPlayer.Character
        if char then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid then
                if not OriginalDescription then
                    pcall(function()
                        OriginalDescription = humanoid:GetAppliedDescription()
                    end)
                end

                pcall(function()
                    humanoid:ApplyDescription(description)
                end)

                Arcane:Notification({ Name = "Avatar Spoofer", Description = "Avatar applied (client-sided).", Duration = 3, Icon = "check", Color = Color3.fromRGB(80,255,120) })
            end
        end
    end)
end

function ResetAvatar()
    local char = LocalPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    if OriginalDescription then
        pcall(function()
            humanoid:ApplyDescription(OriginalDescription)
        end)
        Arcane:Notification({ Name = "Avatar Spoofer", Description = "Reset to original.", Duration = 3, Icon = "check", Color = Color3.fromRGB(80,255,120) })
    else
        pcall(function()
            local desc = Players:GetHumanoidDescriptionFromUserId(LocalPlayer.UserId)
            humanoid:ApplyDescription(desc)
        end)
    end
end

local SkyInstance, BloomEffect, AtmosphereEffect, SunRaysEffect

function ApplySkybox()
    if not Configs.Skybox.Enabled then
        if SkyInstance then SkyInstance:Destroy() SkyInstance = nil end
        return
    end
    local data = SkyBoxes[Configs.Skybox.Name]
    if not data then return end
    if not SkyInstance or not SkyInstance.Parent then
        for _, v in ipairs(Lighting:GetChildren()) do if v:IsA("Sky") then v:Destroy() end end
        SkyInstance = Instance.new("Sky")
        SkyInstance.Parent = Lighting
    end
    for k, v in pairs(data) do pcall(function() SkyInstance[k] = v end) end
end

local function StyleTrail(trail)
    if not trail or not trail:IsA("Trail") then return end
    if not Configs.Tracers.Enabled then return end
    if trail:GetAttribute("SpoofReplaced") then return end

    local props = TracerProperties[Configs.Tracers.Style]
    if not props then return end

    local widthMult = Configs.Tracers.Width or 1.2
    local att0 = trail.Attachment0
    local att1 = trail.Attachment1
    local parent = trail.Parent

    if not (att0 and att1 and parent) then return end

    local newTrail = Instance.new("Trail")
    newTrail.Attachment0 = att0
    newTrail.Attachment1 = att1
    newTrail.Parent = parent
    newTrail:SetAttribute("SpoofReplaced", true)

    for k, v in pairs(props) do
        pcall(function() newTrail[k] = v end)
    end

    pcall(function()
        newTrail.Width0 = (props.Width0 or 0.5) * widthMult
        newTrail.Width1 = (props.Width1 or 0.5) * widthMult
    end)

    newTrail.Color = ColorSequence.new(Configs.Tracers.Color)
    newTrail.Lifetime = Configs.Tracers.Lifetime
    newTrail.Enabled = true

    trail.Enabled = false
    trail:SetAttribute("SpoofReplaced", true)
end

local function HookTrails(container)
    if not container then return end
    TrackConnection(container.DescendantAdded:Connect(function(obj)
        if obj:IsA("Trail") then
            task.defer(StyleTrail, obj)
        end
    end))
end

HookTrails(Workspace)
local Temp = Workspace:FindFirstChild("Temp")
if Temp then HookTrails(Temp) end

task.defer(function()
    local bullet = ReplicatedStorage:FindFirstChild("Effects")
        and ReplicatedStorage.Effects:FindFirstChild("DefaultGun")
        and ReplicatedStorage.Effects.DefaultGun:FindFirstChild("Bullet")
    if bullet then
        local trail = bullet:FindFirstChildOfClass("Trail")
        if trail then StyleTrail(trail) end
    end
end)

task.spawn(function()
    while not Unloaded do
        if Configs.Ambience.Enabled then
            Lighting.Ambient = Configs.Ambience.Ambient
            Lighting.OutdoorAmbient = Configs.Ambience.OutdoorAmbient
        end
        if Configs.Time.Enabled then
            Lighting.ClockTime = Configs.Time.Value
        end
        if Configs.ColorShift.Enabled then
            Lighting.ColorShift_Top = Configs.ColorShift.Top
            Lighting.ColorShift_Bottom = Configs.ColorShift.Bottom
        end
        if Configs.Fog.Enabled then
            Lighting.FogStart = Configs.Fog.Start
            Lighting.FogEnd = Configs.Fog.End
            Lighting.FogColor = Configs.Fog.Color
        end
        if Configs.Bloom.Enabled then
            if not BloomEffect or not BloomEffect.Parent then
                BloomEffect = Instance.new("BloomEffect")
                BloomEffect.Parent = Lighting
            end
            BloomEffect.Enabled = true
            BloomEffect.Intensity = Configs.Bloom.Intensity * 0.01
            BloomEffect.Size = Configs.Bloom.Size
            BloomEffect.Threshold = Configs.Bloom.Threshold * 0.1
        elseif BloomEffect then
            BloomEffect.Enabled = false
        end
        if Configs.Atmosphere.Enabled then
            if not AtmosphereEffect or not AtmosphereEffect.Parent then
                AtmosphereEffect = Lighting:FindFirstChildOfClass("Atmosphere")
                if not AtmosphereEffect then
                    AtmosphereEffect = Instance.new("Atmosphere")
                    AtmosphereEffect.Parent = Lighting
                end
            end
            AtmosphereEffect.Density = Configs.Atmosphere.Density
            AtmosphereEffect.Color = Configs.Atmosphere.Color
            AtmosphereEffect.Decay = Configs.Atmosphere.Decay
            AtmosphereEffect.Glare = Configs.Atmosphere.Glare
            AtmosphereEffect.Haze = Configs.Atmosphere.Haze
        elseif AtmosphereEffect then
            AtmosphereEffect:Destroy()
            AtmosphereEffect = nil
        end
        if Configs.SunRays.Enabled then
            if not SunRaysEffect or not SunRaysEffect.Parent then
                SunRaysEffect = Instance.new("SunRaysEffect")
                SunRaysEffect.Parent = Lighting
            end
            SunRaysEffect.Enabled = true
            SunRaysEffect.Intensity = Configs.SunRays.Intensity
            SunRaysEffect.Spread = Configs.SunRays.Spread
        elseif SunRaysEffect then
            SunRaysEffect.Enabled = false
        end
        task.wait(0.1)
    end
end)

local TARGET_PARTS = {["Union"]=true, ["Handle"]=true, ["Heh"]=true}

local function ApplyGunVisuals(tool)
    if not tool or not tool:IsA("Tool") then return end
    local tex = ChamsAnimations[Configs.Visuals.Texture] or ""

    for _, v in ipairs(tool:GetDescendants()) do
        if TARGET_PARTS[v.Name] and v:IsA("BasePart") then
            v.UsePartColor = true
            v.Material = Configs.Visuals.Material
            v.Color = Configs.Visuals.Color
            v.Transparency = Configs.Visuals.Transparency
            v.Reflectance = Configs.Visuals.Reflectance

            if v:IsA("MeshPart") then pcall(function() v.TextureID = tex end) end
            local sm = v:FindFirstChildOfClass("SpecialMesh")
            if sm then pcall(function() sm.TextureId = tex end) end
            for _, d in ipairs(v:GetChildren()) do
                if d:IsA("Decal") or d:IsA("Texture") then
                    pcall(function() d.Texture = tex end)
                end
            end
        end
    end
end

task.spawn(function()
    while not Unloaded do
        if Configs.Visuals.Enabled then
            pcall(function()
                for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
                    if tool:IsA("Tool") and (tool.Name == "Shotty" or tool.Name == "Glock" or tool.Name == "HeartGun") then
                        ApplyGunVisuals(tool)
                    end
                end
                local char = LocalPlayer.Character
                if char then
                    for _, tool in ipairs(char:GetChildren()) do
                        if tool:IsA("Tool") and (tool.Name == "Shotty" or tool.Name == "Glock" or tool.Name == "HeartGun") then
                            ApplyGunVisuals(tool)
                        end
                    end
                end
            end)
        end
        task.wait(0.05)
    end
end)

local DeathLocation = nil
local IsTracking = true

local function onCharacterAdded(character)
    if Unloaded then return end

    local humanoid = character:WaitForChild("Humanoid", 5)
    local root = character:WaitForChild("HumanoidRootPart", 5)
    if not humanoid or not root then return end

    if Configs.AutoReset.SpawnAtDeath and DeathLocation then
        local targetCF = DeathLocation
        task.spawn(function()
            local startTime = tick()
            while tick() - startTime < 4.0 do
                if not character.Parent or humanoid.Health <= 0 then break end
                root.CFrame = targetCF
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
                RunService.Heartbeat:Wait()
            end
        end)
    end

    IsTracking = true

    TrackConnection(RunService.Heartbeat:Connect(function()
        if Unloaded then return end
        if IsTracking and humanoid.Health > 0 and root and root.Parent then
            DeathLocation = root.CFrame
        end
    end))

    local function lockDeath()
        if root and root.Parent then
            DeathLocation = root.CFrame
        end
        IsTracking = false
    end

    TrackConnection(humanoid.Died:Connect(lockDeath))

    TrackConnection(humanoid.HealthChanged:Connect(function(currentHealth)
        if Unloaded or not Configs.AutoReset.Enabled then return end
        local threshold = humanoid.MaxHealth * (Configs.AutoReset.ResetPercentage / 100)
        if currentHealth <= threshold and currentHealth > 0 then
            lockDeath()
            humanoid.Health = 0
        end
    end))

    local function checkKO()
        if Unloaded or not Configs.AutoReset.Enabled then return end
        local ko = character:GetAttribute("KO")
        if typeof(ko) == "number" and ko <= Configs.AutoReset.ResetPercentage then
            if humanoid and humanoid.Health > 0 then
                lockDeath()
                humanoid.Health = 0
            end
        end
    end
    TrackConnection(character:GetAttributeChangedSignal("KO"):Connect(checkKO))
    checkKO()
end

TrackConnection(LocalPlayer.CharacterAdded:Connect(onCharacterAdded))
if LocalPlayer.Character then onCharacterAdded(LocalPlayer.Character) end

local function isAntiGroundHitActive(character, humanoid)
    if Unloaded or not Configs.AntiGroundHit.Enabled then return false end
    if not character or not character.Parent or not humanoid or humanoid.Health <= 0 then return false end
    local ko = character:GetAttribute("KO")
    if typeof(ko) == "number" and ko <= 0 then return false end
    if character:GetAttribute("Ragdoll") then return false end
    return true
end

local function setupAntiGroundHit(character)
    local humanoid = character:WaitForChild("Humanoid", 8)
    if not humanoid then return end
    TrackConnection(humanoid.StateChanged:Connect(function(_, new)
        if not isAntiGroundHitActive(character, humanoid) then return end
        if new == Enum.HumanoidStateType.FallingDown or new == Enum.HumanoidStateType.PlatformStanding then
            humanoid.PlatformStand = false
            humanoid.Sit = false
            humanoid:ChangeState(Enum.HumanoidStateType.Running)
        end
    end))
    TrackConnection(RunService.Heartbeat:Connect(function()
        if not isAntiGroundHitActive(character, humanoid) then return end
        if humanoid.PlatformStand or humanoid:GetState() == Enum.HumanoidStateType.PlatformStanding or humanoid:GetState() == Enum.HumanoidStateType.FallingDown then
            humanoid.PlatformStand = false
            humanoid.Sit = false
            humanoid:ChangeState(Enum.HumanoidStateType.Running)
        end
    end))
end

TrackConnection(LocalPlayer.CharacterAdded:Connect(setupAntiGroundHit))
if LocalPlayer.Character then setupAntiGroundHit(LocalPlayer.Character) end

if setreadonly then setreadonly(Traits, false) end

local originalSubtract = Traits.SubtractFrom
Traits.SubtractFrom = function(self, instance, traitName, amount)
    if not Unloaded and Configs.DelayMod.Enabled and (traitName == "SlowFor" or traitName == "StunFor") then
        if Configs.DelayMod.ActionDelayMultiplier > 0 then
            amount = amount * (1 / Configs.DelayMod.ActionDelayMultiplier)
        end
    end
    return originalSubtract(self, instance, traitName, amount)
end

local originalGet = Traits.Get
Traits.Get = function(self, instance, traitName)
    if not Unloaded and Configs.Stamina.Enabled and traitName == "Stamina" then return 100 end
    return originalGet(self, instance, traitName)
end

if hookmetamethod then
    local oldNewIndex
    oldNewIndex = hookmetamethod(game, "__newindex", function(self, index, value)
        if not Unloaded and Configs.Crouch.Enabled and not checkcaller() and typeof(self) == "Instance" and self.ClassName == "Humanoid" and index == "WalkSpeed" then
            local char = LocalPlayer.Character
            if char and self == char:FindFirstChild("Humanoid") then
                local slowFor = Traits:Get(char, "SlowFor") or 0
                local stunFor = Traits:Get(char, "StunFor") or 0
                if slowFor > 0 then value = 2 elseif stunFor > 0 then value = 0 end
            end
        end
        return oldNewIndex(self, index, value)
    end)

    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        if not Unloaded and not checkcaller() then
            if Configs.Stamina.Enabled and method == "GetAttribute" and args[1] == "Stamina" and self == LocalPlayer.Character then
                return 100
            end
            if Configs.Crouch.Enabled and typeof(self) == "Instance" and self.ClassName == "AnimationTrack" and Configs.Crouch.FastCrouchAnimation then
                local anim = self.Animation
                if anim and anim.Parent and anim.Parent.Name == "Crouch" then
                    if method == "Play" then
                        return oldNamecall(self, 0, args[2] or 1, (args[3] or 1) * Configs.Crouch.CrouchAnimationMultiplier)
                    elseif method == "AdjustSpeed" then
                        return oldNamecall(self, (args[1] or 0) * Configs.Crouch.CrouchAnimationMultiplier)
                    end
                end
            end
        end
        return oldNamecall(self, ...)
    end)
end

task.spawn(function()
    while not Unloaded do
        local char = LocalPlayer.Character
        if char then
            local humanoid = char:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local conn
                conn = RunService.Heartbeat:Connect(function()
                    if Unloaded or not Configs.Crouch.Enabled then return end
                    pcall(function()
                        if not char.Parent or humanoid.Health <= 0 then if conn then conn:Disconnect() end return end
                        local slow = Traits:Get(char, "SlowFor") or 0
                        local stun = Traits:Get(char, "StunFor") or 0
                        if slow > 0 then humanoid.WalkSpeed = 2
                        elseif stun > 0 then humanoid.WalkSpeed = 0 end
                    end)
                end)
                TrackConnection(conn)
                repeat task.wait(0.5) until Unloaded or not char.Parent or humanoid.Health <= 0
                if conn then conn:Disconnect() end
            end
        end
        task.wait(0.2)
    end
end)

local isBoosted, lastCharacter = false, nil
TrackConnection(RunService.Stepped:Connect(function()
    if Unloaded or not Configs.Jump.Enabled then return end
    local char = LocalPlayer.Character
    if not char then return end
    if char ~= lastCharacter then isBoosted = false lastCharacter = char end
    local hum = char:FindFirstChild("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then isBoosted = false return end
    local hasTool = char:FindFirstChild("Glock") or char:FindFirstChild("HeartGun")
    if not hasTool or hum.Health <= 0 or char:GetAttribute("GroundHit") or char:GetAttribute("Ragdoll") then
        isBoosted = false return
    end
    local vel = root.AssemblyLinearVelocity
    if vel.Y > Configs.Jump.KickInAt and hum.FloorMaterial == Enum.Material.Air then
        if not isBoosted then
            isBoosted = true
            root.AssemblyLinearVelocity = Vector3.new(vel.X, vel.Y + Configs.Jump.BoostAmount, vel.Z)
        end
    else
        isBoosted = false
    end
end))

TrackConnection(RunService.RenderStepped:Connect(function()
    if Unloaded or not Configs.Stamina.Enabled then return end
    pcall(function()
        local HUD = LocalPlayer.PlayerGui:FindFirstChild("HUD")
        if HUD and HUD:FindFirstChild("Stam") then
            HUD.Stam.Bar.Size = UDim2.new(1, 0, 1, 0)
        end
    end)
end))
