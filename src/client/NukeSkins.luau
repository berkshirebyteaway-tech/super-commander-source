local M={}
local rgb=Color3.fromRGB
local function classic(w,t,i)
    return {warhead=w,trail=t,impact=i}
end
M.skins={
    classic=classic(
        {body=rgb(214,222,230),nose=rgb(236,240,244),fins=rgb(70,82,98),glow=rgb(255,190,90),light=rgb(255,176,84)},
        {core=rgb(255,236,170),hot=rgb(255,140,52),smoke=rgb(168,172,180),width=.8,smokeWidth=1.8,coreLife=.45,smokeLife=2.8},
        {flash=rgb(255,252,236),core=rgb(255,238,186),fire=rgb(255,138,46),ember=rgb(150,48,22),smoke=rgb(96,90,88),cap=rgb(128,116,108),shock=rgb(255,236,204),dust=rgb(150,140,128),scorch=rgb(24,20,18)}),
    arctic=classic(
        {body=rgb(226,238,248),nose=rgb(244,250,255),fins=rgb(80,96,116),glow=rgb(125,211,252),light=rgb(125,211,252)},
        {core=rgb(214,244,255),hot=rgb(125,211,252),smoke=rgb(196,214,230),width=.8,smokeWidth=1.8,coreLife=.45,smokeLife=2.8},
        {flash=rgb(240,250,255),core=rgb(214,244,255),fire=rgb(125,211,252),ember=rgb(56,120,190),smoke=rgb(120,138,158),cap=rgb(160,182,204),shock=rgb(214,244,255),dust=rgb(170,186,204),scorch=rgb(20,28,38)}),
    copper=classic(
        {body=rgb(214,190,160),nose=rgb(236,214,186),fins=rgb(92,74,60),glow=rgb(251,146,60),light=rgb(251,146,60)},
        {core=rgb(255,214,160),hot=rgb(251,146,60),smoke=rgb(150,132,118),width=.9,smokeWidth=2,coreLife=.5,smokeLife=2.8},
        {flash=rgb(255,244,226),core=rgb(255,214,160),fire=rgb(251,120,40),ember=rgb(140,60,20),smoke=rgb(98,82,72),cap=rgb(134,108,90),shock=rgb(255,214,160),dust=rgb(160,136,112),scorch=rgb(30,20,14)}),
}
M.themes={
    steel={
        warhead={body=rgb(128,136,146),nose=rgb(96,104,114),fins=rgb(84,92,102),trim=rgb(52,58,66),stripe=rgb(236,178,64),glow=rgb(255,170,80),light=rgb(255,166,74)},
        trail={core=rgb(255,226,160),hot=rgb(255,146,56),smoke=rgb(84,86,92),haze=rgb(140,142,148),width=.9,smokeWidth=2.3,coreLife=.5,smokeLife=3.2},
        impact={flash=rgb(255,250,236),core=rgb(255,236,180),fire=rgb(255,128,40),ember=rgb(140,44,20),smoke=rgb(66,62,62),cap=rgb(100,92,88),shock=rgb(255,232,200),dust=rgb(122,114,106),scorch=rgb(18,16,14),debris=rgb(46,44,44),ring=rgb(255,190,110)},
    },
    cryo={
        warhead={body=rgb(188,226,248),nose=rgb(236,250,255),fins=rgb(160,210,242),trim=rgb(60,110,170),core=rgb(110,200,255),glow=rgb(150,220,255),light=rgb(110,200,255)},
        trail={core=rgb(236,250,255),hot=rgb(110,200,255),smoke=rgb(206,230,248),haze=rgb(236,248,255),width=.85,smokeWidth=2,coreLife=.55,smokeLife=3,snow=rgb(244,252,255)},
        impact={flash=rgb(240,252,255),core=rgb(214,244,255),fire=rgb(110,200,255),ember=rgb(60,110,170),smoke=rgb(168,196,222),cap=rgb(204,226,246),shock=rgb(200,240,255),dust=rgb(186,214,236),scorch=rgb(140,190,226),ice=rgb(176,224,250),ring=rgb(150,226,255)},
    },
    plasma={
        warhead={body=rgb(38,24,66),nose=rgb(220,190,255),fins=rgb(70,44,120),trim=rgb(220,190,255),core=rgb(214,150,255),glow=rgb(190,110,255),light=rgb(190,110,255)},
        trail={core=rgb(246,230,255),hot=rgb(190,110,255),smoke=rgb(104,76,156),haze=rgb(150,110,210),width=.8,smokeWidth=1.7,coreLife=.6,smokeLife=2.8,ribbon=rgb(206,140,255),arc=rgb(236,210,255)},
        impact={flash=rgb(250,240,255),core=rgb(236,210,255),fire=rgb(190,110,255),ember=rgb(80,36,140),smoke=rgb(70,52,100),cap=rgb(104,78,144),shock=rgb(220,180,255),dust=rgb(110,96,140),scorch=rgb(28,16,44),dome=rgb(168,100,255),arc=rgb(240,220,255),ring=rgb(200,130,255)},
    },
    sun={
        warhead={body=rgb(226,172,62),nose=rgb(255,230,160),fins=rgb(120,84,26),trim=rgb(255,236,180),core=rgb(255,244,200),glow=rgb(255,200,80),light=rgb(255,190,60)},
        trail={core=rgb(255,250,214),hot=rgb(255,168,40),smoke=rgb(200,156,96),haze=rgb(255,214,140),width=1.1,smokeWidth=2.1,coreLife=.85,smokeLife=3,ribbon=rgb(255,206,80),ember=rgb(255,186,64)},
        impact={flash=rgb(255,252,230),core=rgb(255,244,190),fire=rgb(255,182,50),ember=rgb(190,92,20),smoke=rgb(122,94,62),cap=rgb(176,136,84),shock=rgb(255,228,150),dust=rgb(172,142,100),scorch=rgb(40,26,10),ring=rgb(255,204,72),pillar=rgb(255,236,170)},
    },
    singularity={
        warhead={body=rgb(8,8,14),nose=rgb(200,240,255),fins=rgb(40,30,70),trim=rgb(200,240,255),core=rgb(160,250,240),glow=rgb(170,130,255),light=rgb(160,140,255)},
        trail={core=rgb(232,250,255),hot=rgb(160,120,255),smoke=rgb(44,26,78),haze=rgb(90,60,150),width=.9,smokeWidth=2.5,coreLife=.6,smokeLife=3.4,ribbon=rgb(160,250,240)},
        impact={flash=rgb(255,255,255),core=rgb(210,244,255),fire=rgb(150,104,255),ember=rgb(50,20,90),smoke=rgb(40,28,64),cap=rgb(72,52,112),shock=rgb(200,240,255),dust=rgb(92,80,122),scorch=rgb(8,6,16),void=rgb(4,4,8),ring=rgb(160,250,240)},
    },
    toxin={
        warhead={body=rgb(44,62,44),nose=rgb(70,92,62),fins=rgb(30,42,30),trim=rgb(150,160,140),stripe=rgb(232,212,60),glass=rgb(170,240,140),core=rgb(140,250,100),bubble=rgb(210,255,180),glow=rgb(120,230,90),light=rgb(120,230,90)},
        trail={core=rgb(220,255,190),hot=rgb(120,230,90),smoke=rgb(64,88,54),haze=rgb(120,180,84),width=.85,smokeWidth=2.4,coreLife=.55,smokeLife=3.4,drip=rgb(170,240,140)},
        impact={flash=rgb(240,255,226),core=rgb(210,255,170),fire=rgb(120,230,90),ember=rgb(50,90,30),smoke=rgb(58,78,46),cap=rgb(90,124,64),shock=rgb(200,255,170),dust=rgb(96,116,80),scorch=rgb(24,34,18),gas=rgb(110,200,80),bubble=rgb(170,240,140),ring=rgb(140,240,100)},
    },
    tsunami={
        warhead={body=rgb(20,60,90),nose=rgb(170,236,250),fins=rgb(14,42,66),trim=rgb(236,250,255),water=rgb(90,190,230),core=rgb(60,200,230),glow=rgb(60,200,230),light=rgb(90,210,240)},
        trail={core=rgb(230,250,255),hot=rgb(60,200,230),smoke=rgb(150,200,222),haze=rgb(210,240,250),width=.8,smokeWidth=2.2,coreLife=.55,smokeLife=3,foam=rgb(240,252,255),ribbon=rgb(110,220,245)},
        impact={flash=rgb(235,250,255),core=rgb(200,244,255),fire=rgb(60,200,230),ember=rgb(20,80,120),smoke=rgb(110,160,190),cap=rgb(176,218,236),shock=rgb(230,250,255),dust=rgb(130,180,204),scorch=rgb(16,44,64),water=rgb(50,160,210),foam=rgb(236,250,255),ring=rgb(90,220,245)},
    },
    lava={
        warhead={body=rgb(78,54,42),nose=rgb(84,58,44),fins=rgb(52,36,30),crust=rgb(50,36,30),trim=rgb(255,200,120),core=rgb(255,150,50),glow=rgb(255,170,60),light=rgb(255,140,50)},
        trail={core=rgb(255,226,150),hot=rgb(255,140,50),smoke=rgb(56,44,40),haze=rgb(104,78,60),width=1,smokeWidth=2.4,coreLife=.7,smokeLife=3.2,ember=rgb(255,180,70)},
        impact={flash=rgb(255,248,226),core=rgb(255,220,140),fire=rgb(255,140,50),ember=rgb(150,72,24),smoke=rgb(56,42,38),cap=rgb(88,64,54),shock=rgb(255,210,150),dust=rgb(100,80,66),scorch=rgb(26,16,12),magma=rgb(255,140,40),rock=rgb(52,34,28),ring=rgb(255,160,60)},
    },
    thunder={
        warhead={body=rgb(64,74,104),nose=rgb(200,214,240),fins=rgb(40,46,68),trim=rgb(170,180,200),core=rgb(190,215,255),bolt=rgb(225,236,255),glow=rgb(140,180,255),light=rgb(150,190,255)},
        trail={core=rgb(240,246,255),hot=rgb(140,180,255),smoke=rgb(52,58,80),haze=rgb(88,98,128),width=.8,smokeWidth=2.6,coreLife=.5,smokeLife=3.2,bolt=rgb(225,236,255),spark=rgb(170,200,255)},
        impact={flash=rgb(250,252,255),core=rgb(220,232,255),fire=rgb(140,180,255),ember=rgb(40,60,120),smoke=rgb(50,56,76),cap=rgb(70,78,104),shock=rgb(210,226,255),dust=rgb(90,98,120),scorch=rgb(14,16,26),cloud=rgb(46,52,72),bolt=rgb(230,240,255),ring=rgb(150,190,255)},
    },
    regal={
        warhead={body=rgb(44,58,150),nose=rgb(255,226,150),fins=rgb(34,44,110),trim=rgb(255,206,90),core=rgb(255,244,200),jewel=rgb(110,170,255),glow=rgb(255,204,70),light=rgb(255,210,110)},
        trail={core=rgb(255,248,220),hot=rgb(255,204,70),smoke=rgb(54,60,116),haze=rgb(116,124,196),width=.95,smokeWidth=2,coreLife=.8,smokeLife=3,ribbon=rgb(255,206,90),star=rgb(255,244,200),jewel=rgb(130,184,255)},
        impact={flash=rgb(255,252,236),core=rgb(255,244,200),fire=rgb(255,204,70),ember=rgb(150,100,30),smoke=rgb(50,56,100),cap=rgb(72,78,140),shock=rgb(255,236,170),dust=rgb(110,110,140),scorch=rgb(20,22,44),gold=rgb(255,200,80),jewel=rgb(110,170,255),ring=rgb(255,214,100)},
    },
    firebird={
        warhead={body=rgb(255,150,46),nose=rgb(255,220,140),fins=rgb(190,96,30),feather=rgb(255,206,90),trim=rgb(255,232,160),core=rgb(255,240,190),glow=rgb(255,170,40),light=rgb(255,170,60)},
        trail={core=rgb(255,248,210),hot=rgb(255,160,40),smoke=rgb(120,74,44),haze=rgb(255,190,110),width=1.1,smokeWidth=2,coreLife=.9,smokeLife=2.8,ribbon=rgb(255,196,70),ember=rgb(255,200,90)},
        impact={flash=rgb(255,252,232),core=rgb(255,240,190),fire=rgb(255,166,40),ember=rgb(170,84,24),smoke=rgb(110,72,46),cap=rgb(170,112,60),shock=rgb(255,226,160),dust=rgb(160,120,90),scorch=rgb(36,18,8),wing=rgb(255,150,40),feather=rgb(255,210,100),ring=rgb(255,190,60)},
    },
    eclipse={
        warhead={body=rgb(10,10,18),nose=rgb(235,230,255),fins=rgb(24,22,40),trim=rgb(245,242,255),corona=rgb(235,230,255),core=rgb(170,240,255),glow=rgb(200,120,255),light=rgb(190,150,255)},
        trail={core=rgb(240,236,255),hot=rgb(200,120,255),smoke=rgb(20,18,34),haze=rgb(70,56,110),width=.9,smokeWidth=2.6,coreLife=.6,smokeLife=3.4,ribbon=rgb(235,230,255)},
        impact={flash=rgb(255,255,255),core=rgb(240,236,255),fire=rgb(200,120,255),ember=rgb(40,20,70),smoke=rgb(22,20,36),cap=rgb(46,40,74),shock=rgb(235,230,255),dust=rgb(70,64,96),scorch=rgb(6,6,12),void=rgb(4,4,8),corona=rgb(235,230,255),ring=rgb(200,120,255)},
    },
    dragonbreath={
        warhead={body=rgb(30,96,90),nose=rgb(170,240,215),fins=rgb(18,58,60),trim=rgb(255,206,90),core=rgb(210,255,234),eye=rgb(255,214,100),mane=rgb(140,240,200),glow=rgb(90,230,180),light=rgb(110,240,190)},
        trail={core=rgb(220,255,236),hot=rgb(90,230,180),smoke=rgb(24,70,66),haze=rgb(90,170,150),width=1,smokeWidth=2.2,coreLife=.8,smokeLife=3,ribbon=rgb(120,236,196),scale=rgb(170,240,215),gold=rgb(255,206,90)},
        impact={flash=rgb(236,255,246),core=rgb(210,255,234),fire=rgb(80,226,176),ember=rgb(20,90,76),smoke=rgb(26,64,60),cap=rgb(40,96,88),shock=rgb(190,250,226),dust=rgb(70,110,100),scorch=rgb(10,28,26),flame=rgb(150,250,210),jade=rgb(30,96,90),gold=rgb(255,206,90),ring=rgb(120,240,200)},
    },
    gem={
        warhead={body=rgb(226,236,246),nose=rgb(244,250,255),fins=rgb(190,206,224),trim=rgb(255,214,120),core=rgb(200,235,255),gem=rgb(214,236,255),spark=rgb(250,252,255),glow=rgb(170,215,255),light=rgb(190,225,255)},
        trail={core=rgb(250,252,255),hot=rgb(170,215,255),smoke=rgb(150,170,196),haze=rgb(226,236,246),width=.9,smokeWidth=1.8,coreLife=.8,smokeLife=2.8,ribbon=rgb(214,236,255),spark=rgb(255,255,255),gold=rgb(255,214,120)},
        impact={flash=rgb(255,255,255),core=rgb(236,246,255),fire=rgb(170,215,255),ember=rgb(90,120,170),smoke=rgb(120,136,160),cap=rgb(170,186,210),shock=rgb(236,246,255),dust=rgb(170,180,196),scorch=rgb(60,74,96),gem=rgb(214,236,255),gold=rgb(255,214,120),ring=rgb(170,215,255)},
    },
    judgment={
        warhead={body=rgb(244,244,252),nose=rgb(255,250,236),fins=rgb(232,226,214),trim=rgb(255,224,150),core=rgb(255,252,240),blade=rgb(255,246,214),feather=rgb(246,244,250),halo=rgb(255,143,216),glow=rgb(255,232,170),light=rgb(255,236,190)},
        trail={core=rgb(255,252,240),hot=rgb(255,226,160),smoke=rgb(214,210,222),haze=rgb(250,246,236),width=1,smokeWidth=1.9,coreLife=.9,smokeLife=3,ribbon=rgb(255,232,170),feather=rgb(250,248,255),halo=rgb(255,143,216)},
        impact={flash=rgb(255,255,255),core=rgb(255,252,240),fire=rgb(255,226,160),ember=rgb(170,140,180),smoke=rgb(200,196,214),cap=rgb(232,226,240),shock=rgb(255,246,226),dust=rgb(210,204,214),scorch=rgb(130,120,140),pillar=rgb(255,250,230),feather=rgb(248,246,255),gold=rgb(255,224,150),halo=rgb(255,143,216),ring=rgb(255,232,170)},
    },
    delete={
        warhead={body=rgb(8,10,16),nose=rgb(80,240,255),fins=rgb(20,24,36),trim=rgb(80,240,255),core=rgb(255,90,220),pixel=rgb(255,90,220),code=rgb(150,250,255),glow=rgb(80,240,255),light=rgb(120,220,255)},
        trail={core=rgb(220,252,255),hot=rgb(80,240,255),smoke=rgb(14,18,28),haze=rgb(40,60,90),width=.8,smokeWidth=2,coreLife=.6,smokeLife=3,ribbon=rgb(80,240,255),pixel=rgb(255,90,220)},
        impact={flash=rgb(230,252,255),core=rgb(200,250,255),fire=rgb(80,240,255),ember=rgb(110,40,140),smoke=rgb(14,18,28),cap=rgb(30,36,56),shock=rgb(160,250,255),dust=rgb(40,50,70),scorch=rgb(4,6,10),void=rgb(4,6,10),pixel=rgb(255,90,220),ring=rgb(80,240,255)},
    },
    maw={
        warhead={body=rgb(10,30,52),nose=rgb(60,240,220),fins=rgb(6,20,36),trim=rgb(220,236,240),core=rgb(60,240,220),water=rgb(40,140,170),eye=rgb(160,255,240),maw=rgb(190,130,255),halo=rgb(200,120,255),glow=rgb(60,240,220),light=rgb(80,230,220)},
        trail={core=rgb(210,255,248),hot=rgb(60,240,220),smoke=rgb(8,26,44),haze=rgb(30,80,100),width=.9,smokeWidth=2.4,coreLife=.7,smokeLife=3.2,ribbon=rgb(60,240,220),violet=rgb(200,120,255),bubble=rgb(170,250,240)},
        impact={flash=rgb(220,255,250),core=rgb(190,255,244),fire=rgb(60,240,220),ember=rgb(30,70,110),smoke=rgb(10,30,48),cap=rgb(20,54,76),shock=rgb(170,250,240),dust=rgb(40,70,90),scorch=rgb(4,14,24),water=rgb(30,120,150),foam=rgb(200,255,248),abyss=rgb(6,20,36),flesh=rgb(14,40,64),eye=rgb(160,255,240),violet=rgb(200,120,255),teeth=rgb(220,236,240),ring=rgb(170,120,255)},
    },
}
M.default='classic'
for id,s in pairs(require(script.Parent.Parent.Core.CosmeticCatalog).styles)do if s.category=='nuclear'then
    local base=M.themes[s.theme]or M.themes.steel
    local skin={}
    for slot,colors in pairs(base)do local t=table.clone(colors);t.theme=s.theme or 'steel';t.tier=s.tier;t.collection=s;skin[slot]=t end
    M.skins[id]=skin
end end
for _,skin in pairs(M.skins)do for _,t in pairs(skin)do t.theme=t.theme or 'classic';t.tier=t.tier or 0 end end
local part={projectile='warhead',trail='trail',impact='impact'}
function M.get(loadout,slot)
    local skin=M.skins[loadout and loadout[slot]]or M.skins[M.default]
    return skin[part[slot]]
end
return M
