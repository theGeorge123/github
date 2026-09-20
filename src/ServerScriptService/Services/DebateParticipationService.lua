local Service={}
local owners={}
local generations={}
local VALID={MULTIPLAYER=true,BOSS=true}
function Service.TryClaim(player,mode)
 assert(VALID[mode],"Invalid debate mode")
 local current=owners[player]
 if current then
  if current.Mode~=mode then return false,"PLAYER_BUSY"end
  return true,current
 end
 generations[player]=(generations[player]or 0)+1
 local claim={Mode=mode,Generation=generations[player]};owners[player]=claim;return true,claim
end
function Service.Get(player)return owners[player]end
function Service.Release(player,claim)
 local current=owners[player]
 if not current or type(claim)~="table"or current.Mode~=claim.Mode or current.Generation~=claim.Generation then return false end
 owners[player]=nil;return true
end
function Service.Disconnect(player)owners[player]=nil;generations[player]=nil end
function Service.ResetForTests()table.clear(owners);table.clear(generations)end
return Service
