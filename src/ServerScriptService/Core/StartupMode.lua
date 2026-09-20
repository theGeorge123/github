local StartupMode={}
function StartupMode.Resolve(config)
 assert(type(config)=="table","Config must be a table")
 if config.DebateEnabled==true then return {Mode="debate",InitDebate=true,InitLegacy=false,BuildEmergencyWorld=false,RunLegacyRefresh=false}end
 return {Mode="legacy",InitDebate=false,InitLegacy=true,BuildEmergencyWorld=true,RunLegacyRefresh=true}
end
return StartupMode
