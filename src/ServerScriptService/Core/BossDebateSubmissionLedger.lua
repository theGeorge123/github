local Ledger={};local MAX_ID=2147483647;local MAX_TERMINAL=8
function Ledger.new()return {HighestSubmissionId=0,Records={},Order={}}end
function Ledger.begin(s,id,text)
 if type(id)~="number"or id%1~=0 or id<1 or id>MAX_ID or type(text)~="string"then return "REJECT","INVALID_SUBMISSION_ID"end
 local old=s.Records[id]
 if old then if old.Text~=text then return "REJECT","SUBMISSION_ID_REUSED"end;if old.Status=="FILTERING"then return "IGNORE"end;return "REPLAY",old.Ack end
 if id<=s.HighestSubmissionId then return "REJECT","STALE_SUBMISSION_ID"end
 s.HighestSubmissionId=id;s.Records[id]={Id=id,Text=text,Status="FILTERING"};return "START",s.Records[id]
end
function Ledger.finish(s,id,status,ack)
 local record=s.Records[id];if not record or record.Status~="FILTERING"or(status~="ACCEPTED"and status~="REJECTED")then return false end
 record.Status=status;record.Ack=ack;table.insert(s.Order,id)
 while #s.Order>MAX_TERMINAL do local expired=table.remove(s.Order,1);s.Records[expired]=nil end
 return true
end
return Ledger
