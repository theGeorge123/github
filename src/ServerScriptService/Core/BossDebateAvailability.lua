local Availability={}
Availability.LOCKED_DISCLOSURE="Boss Debate is locked. No live AI, judging, score, winner, or rewards are available."
function Availability.Resolve(config)
 local boss=config.BossDebate or {}
 if boss.Enabled~=true then return "LOCKED","BOSS_DISABLED",Availability.LOCKED_DISCLOSURE end
 if boss.ScriptedPracticeEnabled==true then return "SCRIPTED_PRACTICE","AUTHORED_PRACTICE","Scripted practice uses authored replies only. It does not judge argument meaning."end
 return "LOCKED","PRACTICE_DISABLED",Availability.LOCKED_DISCLOSURE
end
return Availability
