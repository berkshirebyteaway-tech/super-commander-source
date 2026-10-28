local M={}
local function humans(d)local n=d.human_count;return not n and 'unknown'or n<=1 and '1'or n==2 and '2'or n<=5 and '3_5'or n<=10 and '6_10'or n<=20 and '11_20'or '21p'end
local function matches(d)local n=d.matches or 0;return n==0 and '0'or n==1 and '1'or n==2 and '2'or n<=5 and '3_5'or '6p'end
local function gap(d)local t=d.elapsed_seconds;return d.first_visit and 'new'or not t and 'unknown'or t<3600 and 'lt1h'or t<86400 and 'lt1d'or t<259200 and 'lt3d'or t<604800 and 'lt7d'or 'gt7d'end
local function outcome(d)return d.result=='accepted'and 'ok'or d.reason or d.result or 'unknown'end
local function fps(d)local n=d.fps;return not n and 'unknown'or n>=55 and 'ge55'or n>=40 and 'ge40'or n>=25 and 'ge25'or n>=15 and 'ge15'or 'lt15'end
local function ping(d)local n=d.ping_ms;return not n and 'unknown'or n<=80 and 'le80'or n<=150 and 'le150'or n<=250 and 'le250'or n<=500 and 'le500'or 'gt500'end
local function memory(d)local n=d.memory_mb;return not n and 'unknown'or n<=800 and 'le800'or n<=1200 and 'le1200'or n<=1800 and 'le1800'or n<=2500 and 'le2500'or 'gt2500'end
local function seconds(d)return (d.duration_ms or 0)/1000 end
local function party(d)return tostring(math.clamp(math.floor(d.party_size or 1),1,6))end
local function request(d)return (d.channel or 'unknown')..'.'..(d.request or 'other')end
local function areaStep(d)return (d.area or 'other')..'.'..(d.step or 'other')end
local function hasResult(d)return d.result~=nil and 1 or -1 end
local function hasValue(d)return type(d.value)=='number'and d.value>=0 and d.value or -1 end
local function outcomeReason(d)local bad=d.result=='rejected'or d.result=='failed';return bad and d.reason and d.reason~='none'and d.result..'_'..d.reason or d.result or 'unknown'end
local function pay(d)if d.area~='commerce'or not d.sku then return nil end;local r=d.result or 'unknown'
 local bad=r=='rejected'or r=='failed'or r=='unavailable';return d.step..'.'..(bad and d.reason and d.reason~='none'and r..'_'..d.reason or r)end
local function payRow(d)return pay(d)and 1 or -1 end
local function payWhere(d)return d.area=='commerce'and d.sku and d.origin and d.step..'.'..d.sku or nil end
local function payWhereRow(d)return payWhere(d)and 1 or -1 end
local function waitBucket(d)local t=d.elapsed_seconds;return not t and 'unknown'or t<10 and 'lt10s'or t<30 and 'lt30s'or t<60 and 'lt60s'or t<120 and 'lt2m'or t<300 and 'lt5m'or 'ge5m'end
local function minutes(d)local t=d.journey_seconds or d.elapsed_seconds;return not t and 'unknown'or t<60 and 'lt1m'or t<180 and 'lt3m'or t<300 and 'lt5m'or t<600 and 'lt10m'or t<1200 and 'lt20m'or t<2400 and 'lt40m'or 'ge40m'end
local function firstMinutes(d)local t=d.elapsed_seconds;return not t and 'unknown'or t<60 and 'lt1m'or t<180 and 'lt3m'or t<300 and 'lt5m'or t<600 and 'lt10m'or t<900 and 'lt15m'or t<1200 and 'lt20m'or t<1800 and 'lt30m'or 'ge30m'end
local function firstRow(d)return d.marker=='new'and (d.elapsed_seconds or 0)/60 or -1 end
local function elimCause(d)return d.area=='match'and d.step=='eliminated'and d.item or nil end
local function elimRow(d)return elimCause(d)and 1 or -1 end
local function campaignOut(d)if d.area~='campaign'then return nil end;if d.step=='campaignEnd'then return d.result end;if d.step=='quit'then return 'quit_'..(d.phase or 'unknown')end end
local function campaignRow(d)return campaignOut(d)and 1 or -1 end
local function standing(d)if d.area~='campaign'or d.step~='quit'then return nil end
 local r,g=d.position,d.growth_ratio
 return (not r and 'rx'or r==1 and 'r1'or r==2 and 'r2'or r<=5 and 'r3_5'or 'r6p')..'_'..(not g and 'gx'or g<.15 and 'low'or g>=.85 and 'full'or 'mid')end
local function standingRow(d)if not standing(d)then return -1 end;return type(d.value)=='number'and d.value>=0 and d.value or 0 end
local function idleBucket(d)local t=d.idle_seconds;return not t and 'unknown'or t<10 and 'lt10s'or t<20 and 'lt20s'or t<30 and 'lt30s'or t<60 and 'lt60s'or t<180 and 'lt3m'or 'ge3m'end
M.buckets={humans=humans,matches=matches,gap=gap,fps=fps,ping=ping,memory=memory,party=party,wait=waitBucket,minutes=minutes,pay=pay}
M.views={
 ui_click={{'SC_UiClick','panel','control'}},
 screen_viewed={{'SC_ScreenView','screen','phase'}},
 screen_dwell={{'SC_ScreenSeconds','screen','phase',seconds}},
 idle_window={{'SC_IdleSeconds','phase','screen','idle_seconds'}},
 client_error={{'SC_ClientError','module','category','count'}},
 client_warning_window={{'SC_ClientWarning','category','phase','count'}},
 device_profile={{'SC_Device','device_class','viewport_bucket'},{'SC_Locale','locale','device_class'}},
 client_health_window={{'SC_ClientFps','phase',fps},{'SC_FpsDevice','device_class',fps},{'SC_PingBucket','input_mode',ping},{'SC_ClientMemory','phase',memory}},
 request_result={{'SC_Request',request,outcome}},
 visit_closed={{'SC_ExitPhase','phase',matches},{'SC_SessionSeconds','phase',matches,'elapsed_seconds'},{'SC_ExitStage','journey','where'},{'SC_ExitMinutes','journey',minutes},{'SC_FirstSession',firstMinutes,'journey',firstRow}},
 queue_exit={{'SC_QueueWait','result',waitBucket}},
 capture_observed={{'SC_FirstCaptureSeconds','mode','input_mode','elapsed_seconds'}},
 tutorial_step={{'SC_TutorialStep','stage','result'}},
 party_ready_changed={{'SC_PartyReady','result','reason'}},
 team_change={{'SC_TeamChange','verb','result'}},
 queue_entered={{'SC_QueueEntered','mode',party}},
 drop_started={{'SC_DropStarted','spawn_style',humans}},
 drop_ended={{'SC_DropEnded','result',humans}},
 result_viewed={{'SC_ResultViewed','result','mode'}},
 match_admission_result={{'SC_MatchHumans','mode',humans}},
 cosmetic_equipped={{'SC_CosmeticEquip','result','stage'}},
 preset_action={{'SC_PresetAction','stage','result'}},
 xp_awarded={{'SC_XpAwarded','sku','mode','xp'}},
 daily_reward_claimed={{'SC_DailyReward','sku','result'}},
 daily_op={{'SC_DailyOp','stage','outcome'}},
 clan_action={{'SC_Clan','verb','result'}},
 communication_window={{'SC_Comms','comms_kind','scope','count'}},
 nuclear_aim_started={{'SC_AimStart','kind','input_mode'}},
 structure_range_viewed={{'SC_RangeViewed','kind','input_mode'}},
 supply_reveal={{'SC_SupplyReveal','stage','rarity'}},
 flow_step={{'SC_Elim',elimCause,'journey',elimRow},{'SC_ElimIdle',elimCause,idleBucket,elimRow},{'SC_Flow','area','step'},{'SC_FlowItem',areaStep,'item',function(d)return d.item and 1 or -1 end},{'SC_FlowResult',areaStep,outcomeReason,hasResult},{'SC_FlowValue',areaStep,'item',hasValue},{'SC_Pay','sku',pay,payRow},{'SC_PayWhere',payWhere,'origin',payWhereRow},
  {'SC_CampaignStage','item',campaignOut,campaignRow},{'SC_CampaignQuit','item',standing,standingRow}},
 commerce_grant_result={{'SC_CommerceGrant','sku','result'}},
 return_observed={{'SC_Return',gap,'result'}},
 profile_load_result={{'SC_ProfileLoadMs','result','operation','duration_ms'}},
 action_flow={{'SC_ActionFlow','stage','action'}},
 command_feedback_seen={{'SC_CommandFeedback','action','result'}},
}
local places={queue=true,transfer=true,drop=true,spectate=true,result=true}
local screens={shop='shop',supply='shop',benefits='shop',gacha='shop',goals='goals',season='goals',clan='clan',wardrobe='wardrobe',motion='wardrobe',cosmetics='wardrobe',
 collection='wardrobe',settings='settings',single='play',custom='play',deployment='play',play='play',ranked='play',spectate='play',lobby='lobby',intro='intro',
 commander='commander',campaign='campaign'}
function M.realMatch(mode)return mode~=nil and mode~='training'and mode~='practice'and mode~='single'and mode~='lobby'and mode~='unknown'end
function M.exitStage(s,now)
 local inMatch=s.matchAt and (s.phase=='drop'or s.phase=='playing'or s.phase=='spectate'or s.phase=='result')
 local mode=s.context.mode;local games=s.pvpGames or 0
 local real=inMatch and not s.intro and M.realMatch(mode)and (games==0 or games==1 and s.counted)
 local before=not s.lobbyReadyAt and not s.matchAt
 local journey=before and ((s.phase=='drop'or s.phase=='playing'or s.phase=='spectate'or s.phase=='result')and 'rejoin'or s.matchServer and 'arrival'or 'preLobby')or inMatch and s.intro and s.phase~='result'and 'firstOp'or not s.profileKnown and 'unknown'
  or not s.basics and 'newLobby'or real and 'firstPvp'or games==0 and 'afterFirstOp'or 'returning'
 local phase=s.phase;if phase=='queue'and not s.queueAt then phase='lobby'end
 local where=s.introOpen and 'intro'or phase=='boot'and (s.clientReady and 'boot'or 'loading')or phase=='lobby'and (screens[s.lastScreen or 'lobby']or 'menu')
  or phase=='playing'and 'match'or places[phase]and phase or 'unknown'
 return journey,where,journey=='firstOp'and now-s.matchAt or now-s.at
end
function M.offerState(billing,sku,available)
 if type(billing)~='table'then return available and 'shown'or 'unavailable',available and 'none'or 'unknown'end
 if billing.benefits and billing.benefits[sku]then return 'active','none'end
 if available then return 'shown','none'end
 if billing.salesOpen==false then return 'unavailable','sales_disabled'end
 if billing.policyKnown==false then return 'unavailable','unknown'end
 if billing.paidRandomAllowed==false then return 'unavailable','policy_restricted'end
 return 'unavailable',sku=='club'and 'policy_restricted'or 'sales_disabled'
end
M.legacy={'SC_LoadResult','SC_LoadMs','SC_VisitCheckpoint','SC_TutorialExit','SC_CardShown','SC_CardSelected','SC_JoinBlocked','SC_QueueExit','SC_PartyAction','SC_PartyArrival',
 'SC_TransferResult','SC_DropResult','SC_DropReadyMs','SC_AimExit','SC_NuclearOutcome','SC_FeatureAvailable','SC_FeatureUsed','SC_PlayerOutcome','SC_ResultAction','SC_RewardResult',
 'SC_OfferShown','SC_OfferSelected','SC_PromptResult','SC_OwnershipVerified','SC_BenefitUsed','SC_DrawResult','SC_UnlockUsed','SC_ServiceResult',
 'SC_QueueSeconds','SC_TransferMs','SC_CommandCount','SC_CommandRejected','SC_MatchSeconds','SC_InputLatencyBucket','SC_ClientFrameBucket',
 'SC_TelemetryHealth'}
function M.names()
 local set,list={},{}
 for _,n in ipairs(M.legacy)do if not set[n]then set[n]=true;table.insert(list,n)end end
 for _,rows in pairs(M.views)do for _,row in ipairs(rows)do if not set[row[1]]then set[row[1]]=true;table.insert(list,row[1])end end end
 table.sort(list);return list
end
local function field(v)return type(v)=='boolean'and (v and 'yes'or 'no')or tostring(v or 'unknown')end
function M.project(name,clean,context,base)
 local out={};context=context or {}
 local rows={};if base then table.insert(rows,base)end
 for _,row in ipairs(M.views[name]or {})do table.insert(rows,row)end
 for _,row in ipairs(rows)do
  local function pick(f)if type(f)=='function'then return f(clean)end;if f==nil then return nil end;local v=clean[f];if v==nil then v=context[f]end;return v end
  local value=tonumber(row[4]and pick(row[4])or 1)
  if value and value==value and value>=0 then table.insert(out,{row[1],value,field(pick(row[2])),field(pick(row[3]))})end
 end
 return out
end
return M
