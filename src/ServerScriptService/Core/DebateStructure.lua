local DebateStructure={}
local ROLES={[1]="Opening",[2]="Rebuttal",[3]="Closing"}
function DebateStructure.RoleForTurn(turnNumber)local role=ROLES[turnNumber];assert(role~=nil,"Unsupported turn number");return role end
function DebateStructure.SideFor(round,playerIndex)
 assert(playerIndex==1 or playerIndex==2,"Invalid player index")
 local playerOneIsAffirmative=round%2==1
 if playerIndex==1 then return playerOneIsAffirmative and "Affirmative" or "Negative" end
 return playerOneIsAffirmative and "Negative" or "Affirmative"
end
function DebateStructure.HostPrompt(topic,role,side,previousCriteria)
 local sideDefinition=topic.Sides[side];assert(sideDefinition,"Unknown side")
 local basePrompt=role=="Opening" and sideDefinition.OpeningPrompt or topic.TurnPrompts[role];assert(basePrompt,"Unknown role")
 local detected={};for _,criterion in ipairs(previousCriteria or {})do if criterion.Earned and criterion.Id~="complete"then table.insert(detected,criterion.Label)end end
 local detectionText="No additional writing feature was detected in the previous turn."
 if #detected>0 then detectionText="The checklist detected: "..table.concat(detected,", ").."."end
 return ("SCRIPTED HOST - %s: You are %s. %s %s This does not judge whether the argument was strong, correct, or relevant."):format(string.upper(role),sideDefinition.Label,basePrompt,detectionText)
end
return DebateStructure
