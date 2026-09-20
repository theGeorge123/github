local W={}
local function normalize(t)t=string.lower(t);t=string.gsub(t,"%s+"," ");t=string.gsub(t,"^%s+","");t=string.gsub(t,"%s+$","");return t end
local function wordsAfter(t,p)local _,e=string.find(t,p,1,true);if not e then return 0 end;local n=0;for _ in string.gmatch(string.sub(t,e+1),"[%w\128-\255]+")do n=n+1 end;return n end
local function explained(t,phrases,n)for _,p in ipairs(phrases)do if wordsAfter(t,p)>=n then return true end end;return false end
function W.Evaluate(text)
 assert(type(text)=="string");local t=normalize(text);local complete=string.find(t,"[%w\128-\255]")~=nil and #t>=10
 local reason=complete and explained(t,{"because ","since ","so that "},3)
 local example=complete and explained(t,{"for example ","for instance ","imagine ","a scenario is "},3)
 local rebuttal=complete and (explained(t,{"however ","but ","you said ","the other side says ","that argument misses "},3)or string.find(t,"i disagree because ",1,true)~=nil or string.find(t,"that is not enough because ",1,true)~=nil)
 local criteria={{Id="complete",Label="Complete filtered turn",Points=10,Earned=complete},{Id="reason",Label="Gives a reason",Points=5,Earned=reason},{Id="example",Label="Uses an example or scenario",Points=5,Earned=example},{Id="rebuttal_attempt",Label="Attempts a rebuttal",Points=5,Earned=rebuttal}}
 local score,reasons=0,{};for _,c in ipairs(criteria)do if c.Earned then score=score+c.Points;table.insert(reasons,("%s +%d"):format(c.Label,c.Points))end end;return score,reasons,criteria
end
function W.Normalize(t)return normalize(t)end
return W
