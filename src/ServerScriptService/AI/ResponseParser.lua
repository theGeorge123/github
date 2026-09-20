local P={}
local intents={requirements=true,permit=true,verify=true,escort=true,flattery=true,authority=true,urgency=true,joke=true,bribe=true,threat=true,irrelevant=true}
local strengths={weak=true,normal=true,strong=true}
local keys={TACTIC=true,STRENGTH=true,REPLY=true}
local forbidden={"show me your permit","show me your papers","show me your document","show me your badge","show me your inventory","show your permit","show your papers","show your document","show your badge","show your inventory","hand me ","hand over ","give me the item","click the ","equip ","upload ","open your inventory","play a minigame","play a mini game","complete a minigame","complete a mini game"}
local function trim(v)return(v:match("^%s*(.-)%s*$"))end
function P.Parse(text,limits)
 if type(text)~="string"or text==""then return nil,"EMPTY_RESPONSE"end
 limits=type(limits)=="table"and limits or{};local maxOutput=limits.MaxOutputBytes or 2048;local maxReply=limits.MaxReplyBytes or 320
 if #text>maxOutput then return nil,"OUTPUT_TOO_LARGE"end;if utf8.len(text)==nil then return nil,"INVALID_UTF8"end
 local lines={};for line in string.gmatch(text.."\n","([^\r\n]*)\r?\n")do table.insert(lines,line)end
 if #lines~=3 then return nil,"BAD_SCHEMA"end
 local fields={};for _,line in ipairs(lines)do local key,value=line:match("^([A-Z]+)=(.+)$");if not key or not keys[key]or fields[key]then return nil,"BAD_SCHEMA"end;value=trim(value);if value==""then return nil,"BAD_SCHEMA"end;fields[key]=value end
 local intent=string.lower(fields.TACTIC);local strength=string.lower(fields.STRENGTH);local reply=fields.REPLY
 if not intents[intent]or not strengths[strength]then return nil,"BAD_SCHEMA"end
 if #reply>maxReply then return nil,"OUTPUT_TOO_LARGE"end
 local normalized=string.lower(reply);for _,pattern in ipairs(forbidden)do if string.find(normalized,pattern,1,true)then return nil,"BAD_SCHEMA"end end
 return {Intent=intent,Strength=strength,Reply=reply}
end
return P
