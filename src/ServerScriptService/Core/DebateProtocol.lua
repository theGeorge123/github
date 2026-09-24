local Protocol = {}
local VALID_KINDS = {Lobby=true,Profile=true,TopicOffer=true,Start=true,Turn=true,PlayerTurn=true,AIReply=true,ArgumentRejected=true,Complete=true,RematchStatus=true,Ended=true}
function Protocol.Lobby(status,profile,queueSize)
 assert(status=="READY" or status=="QUEUED","Invalid lobby status");assert(type(queueSize)=="number","Queue size must be a number")
 return {Kind="Lobby",Status=status,Profile=profile,QueueSize=queueSize}
end
function Protocol.Profile(profile)assert(type(profile)=="table","Profile must be a table");return {Kind="Profile",Profile=profile}end
function Protocol.Start(round,topic,playerOne,playerTwo,opening,rules)
 assert(type(round)=="number","Round must be a number");assert(type(topic)=="table","Topic must be a table");assert(type(playerOne)=="table" and type(playerOne.Name)=="string","Player one requires Name");assert(type(playerTwo)=="table" and type(playerTwo.Name)=="string","Player two requires Name")
 return {Kind="Start",Round=round,Topic=topic,Players={playerOne,playerTwo},Opening=opening,Rules=rules}
end
function Protocol.Validate(m)
 if type(m)~="table"then return false,"Message must be a table"end;if not VALID_KINDS[m.Kind]then return false,"Unknown message kind"end
 if m.Kind=="Lobby"and m.Status~="READY"and m.Status~="QUEUED"then return false,"Invalid lobby status"end
 if m.Kind=="TopicOffer"and(type(m.Topics)~="table"or#m.Topics~=3 or type(m.PickerUserId)~="number")then return false,"TopicOffer requires three topics and a picker"end
 if m.Kind=="Start"then if type(m.Topic)~="table"then return false,"Start requires Topic"end;if type(m.Players)~="table"or #m.Players~=2 then return false,"Start requires two players"end;for _,p in ipairs(m.Players)do if type(p)~="table"or type(p.Name)~="string"then return false,"Start player requires Name"end end end
 return true
end
return Protocol
