local Policy={}
function Policy.CanBackgroundSearch(claim)return type(claim)=="table"and claim.Mode=="BOSS"end
function Policy.NewOffer(id,bossPlayer,queuedPlayer,expiresAt)return {Id=id,BossPlayer=bossPlayer,QueuedPlayer=queuedPlayer,ExpiresAt=expiresAt,Status="OFFERED"}end
function Policy.CanAccept(offer,offerId,currentClaim)
 if type(offer)~="table"or offer.Status~="OFFERED"or offer.Id~=offerId then return false,"STALE_OFFER"end
 if currentClaim~=nil then return false,"FINISH_CURRENT_TURN"end
 return true
end
function Policy.Resolve(offer,status)if type(offer)~="table"or offer.Status~="OFFERED"then return false end;offer.Status=status;return true end
return Policy
