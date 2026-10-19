local M={seconds=2}
local function smooth(a,b,t)
    local x=math.clamp((t-a)/(b-a),0,1)
    return x*x*x*(x*(x*6-15)+10)
end
function M.sample(elapsed,reduced)
    local t=math.clamp(elapsed/M.seconds,0,1)
    local reveal=smooth(.48,1,t)
    local settle=smooth(0,.24,t)
    return {
        active=elapsed>=0 and elapsed<M.seconds,
        reveal=reveal,
        lift=24*(1-t)^2,
        drift=5*(1-t)^2,
        pitch=-.24-.86*settle,
        roll=reduced and 0 or -.18*(1-reveal)+.5*math.sin(t*13)*math.exp(-t*5),
        pose=1-reveal,
        bars=(reduced and .025 or .075)*(1-reveal),
        streaks=reduced and 0 or smooth(.02,.16,t)*(1-smooth(.55,.9,t)),
        fov=50+(reduced and 0 or 6*math.sin(math.pi*t))*(1-reveal),
    }
end
return M
