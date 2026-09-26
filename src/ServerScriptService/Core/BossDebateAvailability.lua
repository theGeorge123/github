local Availability={}
Availability.LOCKED_DISCLOSURE="Boss Debate is locked. No live AI, judging, score, winner, or rewards are available."
Availability.LIVE_DISCLOSURE="LIVE AI BETA uses Roblox TextGenerator for opponent replies. It does not judge, score, choose a winner, or award rewards."
Availability.SCRIPTED_DISCLOSURE="Scripted practice uses authored replies only. It does not judge argument meaning."

function Availability.Resolve(config,context)
 local boss=config.BossDebate or {}
 context=type(context)=="table"and context or{}
 if boss.Enabled~=true then return "LOCKED","BOSS_DISABLED",Availability.LOCKED_DISCLOSURE end
 local liveAllowed=config.DebateLiveEnabled==true and boss.LiveBetaEnabled==true and(context.IsStudio==true or(context.IsTester==true and context.IsPrivateServer==true))
 if liveAllowed then return "LIVE_AI_BETA","LIVE_PRIVATE_BETA",Availability.LIVE_DISCLOSURE end
 if boss.ScriptedPracticeEnabled==true then return "SCRIPTED_PRACTICE","AUTHORED_PRACTICE",Availability.SCRIPTED_DISCLOSURE end
 return "LOCKED","PRACTICE_DISABLED",Availability.LOCKED_DISCLOSURE
end

return Availability
