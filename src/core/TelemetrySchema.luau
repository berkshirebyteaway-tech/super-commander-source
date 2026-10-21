local M={version=1,releaseGroup='preseason',clientBatch=32,clientRate=8,clientBurst=64,rawLimit=8192,nativeLimit=2048}
local function set(words)local t={};for s in words:gmatch('%S+')do t[s]=true end;return t end
M.actions=set('attack transport cancelAttack cancelTransport moveWarship moveWarships retaliate build upgrade delete nuclear support alliance embargoAll spawn start learn practiceSolo daily setting preset menu guide pause speed watch replaySpeed comms ping emoji emote invalid other')
M.rare=set('nuclear alliance support transport build upgrade delete embargoAll ping emoji comms')
M.features=set('expansion construction navy trade railway diplomacy support signals nuclear hydrogen mirv defense')
M.enums={
 comms_kind=set('emoji signal target quickChat text other'),scope=set('all team allies player spectators lobby unknown'),
 locale=set('en ko ja zh es pt fr de ru tr vi id th pl it ar other'),
 action=M.actions,feature=M.features,
 input_mode=set('mouse touch gamepad unknown'),viewport_bucket=set('small medium large portrait unknown'),
 phase=set('boot lobby queue transfer drop playing spectate result closed unknown'),
 mode=set('lobby single training practice coop pvp custom official ranked ffa teams duel unknown'),
 result=set('ok failed rejected cancelled timeout unknown duplicate accepted unavailable active inactive ready won lost forfeit expired serverStop skipped complete opened closed shown selected intercepted detonated pending granted retry joined left loaded refused version'),
 verb=set('invite accept decline leave kick ready leader team join cancel create update play again follow attend promote war share other'),
 reason=set('none unknown invalid stale busy loading paused not_playing observer insufficient_cost territory relation cooldown capacity party teamfull private subscription_required storage_unavailable policy_restricted sales_disabled cancelled timeout disconnected completed replaced missing response_missing network failed auto manual random fallback input_limited abandoned shutdown skipped closed granted duplicate not_loaded gap host opponent rules ready automatic team full locked expired invalid_target out_of_range unreachable not_owner relation_missing refused version'),
 stage=set('client_ready lobby_ready map_ready profile ownership request seat reserved sending admitted combat command capture grow settled ready move land rally start stop shown selected opened closed accepted rejected locked unlocked warning clear outcome checkpoint load save mutate retry flush shutdown status prompt benefit queue arrived'),
 category=set('nil_index call_nil arithmetic compare bad_argument missing_member infinite_yield timeout http datastore memorystore teleport stack script_timeout cast asset deprecated game_warn other'),
 side=set('client server'),channel=set('lobby account'),device_class=set('phone tablet desktop console unknown'),
 area=set('shop cosmetics gacha solo custom queue drop input character map_ui settings social lobby result tutorial match other clan ranked commerce vip progression goals comms hud mobile perf spectate season journey ops campaign'),
 entry=set('home list quick solo custom result party station shortcut automatic unknown'),
 format=set('ffa team coop custom unknown'),spawn_style=set('selected random shifted unknown'),
 kind=set('City DefensePost Port Factory Railroad MissileSilo SAMLauncher TransportShip Warship TradeShip Train AtomBomb HydrogenBomb MIRV MIRVWarhead other'),
 sku=set('basic epic legendary mythic permanent club match checkIn recruit supply goalClaim rankedSeason exchange clanAttend other'),
 currency=set('Medals Tickets Shards basic epic legendary mythic none'),rarity=set('normal common rare epic legendary mythic other'),
 benefit=set('xp permanent_welcome daily_tickets preset_slots loadout_slots public_custom badge comms voice motion other'),
 benefit_state=set('free permanent club both unknown'),source=set('server client platform'),
 operation=set('profile_load profile_mutate profile_save queue_update reserve teleport reward_inbox career_inbox account_request asset_load native raw other'),
 bucket=set('le16 le33 le50 le100 gt100 le50ms le100ms le250ms le500ms le1000ms gt1000ms'),
 checkpoint=set('1m 5m 15m 30m 60m'),outcome=set('won lost forfeit expired serverStop unknown'),
 origin=set('shopBox shopMember benefits supply vipCard vipBubble clanStrip other'),
 journey=set('preLobby newLobby firstOp afterFirstOp firstPvp returning unknown'),marker=set('new return unknown'),
 where=set('loading boot intro lobby shop goals clan wardrobe settings play menu queue transfer drop match spectate result commander campaign unknown'),
}
local numbers=set('journey_seconds duration_ms elapsed_seconds count accepted rejected duplicate cancelled total samples sum_ms max_ms le16 le33 le50 le100 gt100 le50ms le100ms le250ms le500ms le1000ms gt1000ms human_count ai_count neutral_count seat_cap team_size team_count party_size ready_count position revision version command_id amount balance level xp base_xp paid_xp multiplier tiles troops cap gold_ratio growth_ratio units incoming outgoing tick simulation_seconds paused_seconds memory_mb dropped retry attempts bytes sequence first matches first_capture_ms render_ms movement_count dive_count rally_count altitude window_seconds')
local booleans=set('touch keyboard gamepad focused eligible active verified paused partial synthetic random fallback landed intercepted warning first_visit first_use duplicate_receipt available completed intro final correction away last_attack')
for key in ('line ping_ms fps players quality heartbeat_fps instances kbps_in kbps_out value idle_seconds frames errors warnings emitted invalid client_rejected client_gaps native_failed native_skipped native_overflow raw_failed raw_dropped retention_evictions'):gmatch('%S+')do numbers[key]=true end
local ids=set('screen control panel list gui step item module tag request')
M.ids=ids
function M.code(v)
 if type(v)~='string'or #v<2 or #v>40 or not v:match('^%a[%w_]*$')then return nil end
 return v
end
local common='duration_ms elapsed_seconds count result reason stage action feature input_mode viewport_bucket phase mode screen entry format spawn_style kind sku currency rarity benefit benefit_state operation bucket checkpoint outcome partial verb map_key field_id locale'
local events={}
local function add(names,origin,priority,extra)
 for name in names:gmatch('%S+')do local fields=set(common..' '..(extra or ''));events[name]={origin=origin,priority=priority or 1,fields=fields}end
end
add('visit_entered visit_relinked visit_checkpoint visit_phase_window visit_closed connection_closed return_observed profile_load_result','server',3,'first_visit matches checkpoint journey where marker journey_seconds')
add('boot_stage screen_viewed tutorial_started tutorial_step tutorial_exit battlefield_impression battlefield_selected action_flow command_feedback_seen nuclear_aim_started nuclear_aim_warning_changed nuclear_aim_ended structure_range_viewed result_viewed result_action offer_impression offer_selected purchase_prompt_result asset_load_summary ui_layout_anomaly','client',1,'version command_id position eligible available warning intro completed memory_mb samples')
add('room_created room_status_changed party_action party_ready_changed party_entry_check team_change party_match_summary queue_entered queue_state_changed queue_exit transfer_started transfer_stage transfer_result match_admission_result drop_started drop_landed drop_ended first_operation_outcome player_outcome match_outcome spectate_state','server',2,'human_count ai_count neutral_count seat_cap team_size team_count party_size ready_count version simulation_seconds paused_seconds fallback random landed intro final correction revision')
add('drop_render_ready drop_input_window drop_rally','client',1,'version render_ms movement_count dive_count rally_count window_seconds')
add('command_result command_window feature_available feature_use capture_observed match_player_window match_room_window nuclear_launched nuclear_resolved','server',1,'version command_id accepted rejected duplicate cancelled total first first_use eligible human_count ai_count neutral_count seat_cap team_size team_count party_size tiles troops cap gold gold_ratio growth_ratio growth_per_second units incoming outgoing tick simulation_seconds paused_seconds window_seconds intercepted')
add('reward_commit_result xp_awarded level_reached unlock_granted cosmetic_equipped preset_action daily_reward_claimed goal_progress ownership_verified commerce_grant_result purchase_attempt benefit_used subscription_lifecycle draw_result economy_transaction','server',3,'amount balance level xp base_xp paid_xp multiplier active verified duplicate_receipt first_use')
add('client_performance_window','client',0,'samples sum_ms max_ms le16 le33 le50 le100 gt100 memory_mb window_seconds version')
add('communication communication_window','server',1,'comms_kind scope window_seconds')
add('server_performance_window service_operation telemetry_health','server',0,'samples sum_ms max_ms le16 le33 le50 le100 gt100 dropped retry attempts bytes window_seconds emitted invalid client_rejected client_gaps native_failed native_skipped native_overflow raw_failed raw_dropped retention_evictions')
add('lobby_choice_blocked','either',2,'party_size eligible')
add('supply_reveal','client',1,'completed')
add('ui_click screen_dwell idle_window client_error client_warning_window device_profile client_health_window','client',1,'control panel list gui module line category sig detail tag count side device_class quality touch keyboard gamepad focused ping_ms fps frames memory_mb window_seconds idle_seconds version')
add('flow_step','either',1,'area step item value rarity version level amount first_use eligible active position total tiles troops units idle_seconds human_count ai_count simulation_seconds growth_ratio party_size balance origin marker last_attack away')
add('request_result','server',1,'channel request item sig')
add('script_error server_warning_window server_health_window','server',0,'side module line category sig detail tag count players memory_mb heartbeat_fps instances kbps_in kbps_out window_seconds errors warnings')
add('daily_op clan_action','server',2,'')
M.events=events
function M.clean(name,data,client)
 local spec=events[name];if not spec or client and spec.origin~='client'and spec.origin~='either'then return nil end
 if type(data)~='table'then return nil end
 local out={};local size=0
 for key,v in pairs(data)do
  size+=1;if size>48 then return nil end
  if spec.fields[key]then
   if key=='gold'and type(v)=='string'and #v<=100 and v:match('^%d+$')then out[key]=v
   elseif key=='growth_per_second'and type(v)=='number'and v==v and math.abs(v)<=1e15 then out[key]=v
   elseif key=='map_key'and type(v)=='string'and M.maps and M.maps[v]then out[key]=v
   elseif ids[key]then out[key]=M.code(v)
   elseif key=='detail'and type(v)=='string'and #v<=200 and not v:find('[%c]')then out[key]=v
   elseif key=='sig'and type(v)=='string'and #v<=16 and v:match('^%x+$')then out[key]=v
   elseif key=='field_id'and type(v)=='string'and #v<=128 and v:match('^[%w~%-_]+$')then out[key]=v
   elseif M.enums[key]and type(v)=='string'and M.enums[key][v]then out[key]=v
   elseif numbers[key]and type(v)=='number'and v==v and math.abs(v)<=1e15 and (v>=0 or key=='amount')then out[key]=v
   elseif booleans[key]and type(v)=='boolean'then out[key]=v end
  end
 end
 return out
end
function M.action(a)return type(a)=='string'and M.actions[a]and a or 'other'end
function M.enum(key,v,default)return M.enums[key]and M.enums[key][v]and v or default or 'unknown'end
function M.reason(message)
 if message==nil then return 'unknown'end
 local s=tostring(message)
 for _,v in ipairs({{'\u{B9CC}\u{B8CC}','expired'},{'\u{BAA8}\u{C9D1}\u{C774} \u{AC00}\u{B4DD}','capacity'},{'\u{D300}\u{C774} \u{AC00}\u{B4DD}','teamfull'},{'\u{C790}\u{B3D9} \u{BC30}\u{C815}','automatic'},{'\u{D300}\u{C744} \u{B2E4}\u{C2DC}','team'},{'\u{C124}\u{C815} \u{BC94}\u{C704}','rules'},{'\u{CD9C}\u{ACA9} \u{C900}\u{BE44}','locked'},{'\u{C774}\u{B3D9} \u{C911}','busy'},{'\u{ADDC}\u{CE59}\u{C774} \u{BC14}\u{B00C}','stale'},{'\u{C790}\u{B9AC}\u{AC00} \u{BD80}\u{C871}','full'},{'\u{C810}\u{C218} \u{CC28}\u{C774}','gap'},{'\u{BC29}\u{C7A5}\u{B9CC}','host'},{'\u{C0C1}\u{B300} \u{D300}\u{C774} \u{D544}\u{C694}','opponent'},{'\u{BAA8}\u{B450} \u{C900}\u{BE44}\u{D558}\u{BA74}','ready'},{'\u{C5F0}\u{ACB0}\u{B418}\u{C9C0} \u{C54A}\u{C740} \u{BC14}\u{B2E4}','unreachable'},{'\u{BC1C}\u{C0AC}\u{D560} \u{C218} \u{C5C6}\u{B294}','out_of_range'},{'\u{C721}\u{C9C0}','territory'},{'\u{C815}\u{CC29}','territory'},{'\u{CD08}\u{B9C8}\u{B2E4}','cooldown'},{'경기를 준비','loading'},{'불러오','loading'},{'갱신','stale'},{'잠시','busy'},{'일시정지','paused'},{'관전','observer'},{'골드','insufficient_cost'},{'병력','insufficient_cost'},{'부족','insufficient_cost'},{'가득','capacity'},{'파티','party'},{'친구','party'},{'진영','teamfull'},{'팀','teamfull'},{'동맹','relation'},{'쿨','cooldown'},{'저장','storage_unavailable'},{'연결','network'},{'VIP','subscription_required'},{'구독','subscription_required'},{'진행 중','not_playing'},{'먼저 참가','not_playing'},{'초대','private'},{'판매','sales_disabled'},{'\u{C120}\u{D0DD}\u{D558}\u{C138}\u{C694}','invalid_target'}})do if s:find(v[1],1,true)then return v[2]end end
 local aliases={['storage-unavailable']='storage_unavailable',['profile-not-loaded']='not_loaded',['subscription-required']='subscription_required',['paid-random-restricted']='policy_restricted',['sales-disabled']='sales_disabled',['insufficient-medals']='insufficient_cost',['insufficient-tickets']='insufficient_cost',['sale-closed']='sales_disabled',['free-draw-used']='duplicate'}
 return aliases[s]or (M.enums.reason[s]and s)or 'unknown'
end
function M.frameBucket(ms)return ms<=16.7 and 'le16'or ms<=33.4 and 'le33'or ms<=50 and 'le50'or ms<=100 and 'le100'or 'gt100'end
function M.latencyBucket(ms)return ms<=50 and 'le50ms'or ms<=100 and 'le100ms'or ms<=250 and 'le250ms'or ms<=500 and 'le500ms'or ms<=1000 and 'le1000ms'or 'gt1000ms'end
M.funnels={Entry={'visit','interactive','requested','admitted','combat','command'},
 Onboarding={'join','lobby','opStart','opEnd','queue','seated','drop','result','claim'},Learning={'shown','command','capture','grow'},PlayJoin={'requested','seat','admitted','combat'},Replay={'shown','requested','admitted','combat'},Checkout={'selected','ready','opened','ownership','benefit'}}
function M.step(funnel,last,label)
 local list=M.funnels[funnel];if not list or list[(last or 0)+1]~=label then return nil end
 return (last or 0)+1
end
return M
