local HttpService=game:GetService("HttpService");local Adapter={}
local forbidden={"http://","https://","citation","winner","score","reward","elo"}
function Adapter.Parse(text,expected,maxOutput,maxText)
 if type(text)~="string"or text==""then return nil,"EMPTY_RESPONSE"end;if #text>maxOutput then return nil,"OUTPUT_TOO_LARGE"end;if utf8.len(text)==nil then return nil,"INVALID_UTF8"end
 local ok,payload=pcall(HttpService.JSONDecode,HttpService,text);if not ok or type(payload)~="table"then return nil,"BAD_SCHEMA"end
 local count=0;for key in pairs(payload)do if key~="text"and key~="addresses"then return nil,"BAD_SCHEMA"end;count+=1 end
 if count~=2 or type(payload.text)~="string"or payload.text==""or#payload.text>maxText or utf8.len(payload.text)==nil then return nil,"BAD_SCHEMA"end
 if type(payload.addresses)~="table"or#payload.addresses~=1 or payload.addresses[1]~=expected then return nil,"BAD_SCHEMA"end
 local lower=string.lower(payload.text);for _,word in ipairs(forbidden)do if string.find(lower,word,1,true)then return nil,"BAD_SCHEMA"end end
 return payload
end
return Adapter
