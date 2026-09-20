local D={Schema=1}
D.Stage={CREATE=true,CONFIGURE=true,GENERATE=true,RESPONSE=true,PARSE=true,FILTER_INPUT=true,FILTER_OUTPUT=true,APPLY=true}
D.Category={OK=true,CLASS_UNAVAILABLE=true,CONFIGURE_FAILED=true,GENERATION_FAILED=true,EMPTY_RESPONSE=true,INVALID_RESPONSE_SHAPE=true,OUTPUT_TOO_LARGE=true,INVALID_UTF8=true,BAD_SCHEMA=true,FILTER_FAILED=true,STALE=true,CANCELLED=true,UNAVAILABLE=true,UNKNOWN_FAILURE=true}
local function allowed(value,set,fallback)return set[value]and value or fallback end
local function bounded(value)local n=math.floor(tonumber(value)or 0);return math.clamp(n,0,2147483647)end
function D.Success(stage,elapsed,inputBytes,outputBytes,source)return table.freeze({Ok=true,Stage=allowed(stage,D.Stage,"PARSE"),Category="OK",Source=source=="LIVE"and"LIVE"or source=="SCRIPTED"and"SCRIPTED"or"NONE",ElapsedMs=bounded(elapsed),InputBytes=bounded(inputBytes),OutputBytes=bounded(outputBytes)})end
function D.Failure(stage,category,elapsed,inputBytes,outputBytes)return table.freeze({Ok=false,Stage=allowed(stage,D.Stage,"GENERATE"),Category=allowed(category,D.Category,"UNKNOWN_FAILURE"),Source="NONE",ElapsedMs=bounded(elapsed),InputBytes=bounded(inputBytes),OutputBytes=bounded(outputBytes)})end
function D.LogFields(result,build)return table.freeze({Schema=1,Build=string.sub(tostring(build or""),1,32),Stage=allowed(result and result.Stage,D.Stage,"GENERATE"),Category=allowed(result and result.Category,D.Category,"UNKNOWN_FAILURE"),Source=result and(result.Source=="LIVE"and"LIVE"or result.Source=="SCRIPTED"and"SCRIPTED"or"NONE")or"NONE",ElapsedMs=bounded(result and result.ElapsedMs),InputBytes=bounded(result and result.InputBytes),OutputBytes=bounded(result and result.OutputBytes)})end
return D
