local M={}
function M.apply()
    local light=game:GetService("Lighting")
    light.ClockTime=0;light.GeographicLatitude=38;light.Brightness=1;light.ExposureCompensation=-.05;light.GlobalShadows=true;light.ShadowSoftness=.35
    light.Ambient=Color3.fromRGB(78,88,104);light.OutdoorAmbient=Color3.fromRGB(120,132,150)
    light.ColorShift_Top=Color3.fromRGB(0,8,16);light.ColorShift_Bottom=Color3.fromRGB(0,0,0)
    light.EnvironmentDiffuseScale=.6;light.EnvironmentSpecularScale=.4
    local tone=light:FindFirstChildOfClass("ColorGradingEffect")or Instance.new("ColorGradingEffect")
    tone.Name="ToyToneMap";tone.TonemapperPreset=Enum.TonemapperPreset.Default;tone.Parent=light
    local grade=light:FindFirstChild("ToyColorGrade")or Instance.new("ColorCorrectionEffect")
    grade.Name="ToyColorGrade";grade.Brightness=0;grade.Contrast=.12;grade.Saturation=.02;grade.TintColor=Color3.fromRGB(242,248,255);grade.Parent=light
    local sky=light:FindFirstChildOfClass('Sky')or Instance.new('Sky');
    sky.Name='AtelierSky';sky.CelestialBodiesShown=true;sky.StarCount=3000;sky.MoonAngularSize=7;sky.SunAngularSize=0;sky.Parent=light
    local air=light:FindFirstChildOfClass('Atmosphere')or Instance.new('Atmosphere');air.Name='AtelierAir';air.Density=.32;air.Offset=.05;air.Color=Color3.fromRGB(28,36,46);air.Decay=Color3.fromRGB(10,14,20);air.Glare=0;air.Haze=.6;air.Parent=light
    local bloom=light:FindFirstChild('AtelierBloom')or Instance.new('BloomEffect');bloom.Name='AtelierBloom';bloom.Intensity=.12;bloom.Size=20;bloom.Threshold=1.15;bloom.Parent=light
    local depth=light:FindFirstChild('LobbyDepth')or Instance.new('DepthOfFieldEffect');depth.Name='LobbyDepth';depth.Enabled=false
    depth.FarIntensity=.32;depth.NearIntensity=0;depth.FocusDistance=55;depth.InFocusRadius=80;depth.Parent=light
end
function M.lobby(on)
    local light=game:GetService("Lighting")
    local depth=light:FindFirstChild('LobbyDepth')
    if depth then depth.Enabled=on==true end
    light.ClockTime=0;light.Brightness=1
    light.Ambient=on and Color3.fromRGB(132,146,168) or Color3.fromRGB(136,148,168)
    light.OutdoorAmbient=on and Color3.fromRGB(168,184,206) or Color3.fromRGB(168,180,202)
    light.ExposureCompensation=on and .45 or .12
    light.EnvironmentDiffuseScale=on and .6 or .9
    light.ColorShift_Top=on and Color3.fromRGB(0,8,16) or Color3.fromRGB(40,54,72)
    local air=light:FindFirstChildOfClass('Atmosphere')
    if air then
        air.Density=on and .14 or .32;air.Haze=on and 1.4 or .6;air.Glare=on and .15 or 0
        air.Color=on and Color3.fromRGB(26,48,64) or Color3.fromRGB(28,36,46);air.Decay=on and Color3.fromRGB(6,10,16) or Color3.fromRGB(10,14,20)
    end
end
return M
