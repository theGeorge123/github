local V={}
function V.Validate(value,maxBytes)
 if type(value)~="table"then return false,"BAD_PAYLOAD","The turn payload was invalid."end
 if type(value.Id)~="number"then return false,"BAD_ID","The turn requires a submission ID."end
 if type(value.Text)~="string"then return false,"BAD_TEXT","Enter text before sending."end
 if #value.Text<2 then return false,"TOO_SHORT","Enter at least two characters."end
 if #value.Text>maxBytes then return false,"TOO_LONG",("Keep the turn under %d bytes."):format(maxBytes)end
 return true
end
return V
