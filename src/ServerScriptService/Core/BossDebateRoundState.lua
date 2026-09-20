local State={}
local LEGAL={READY={PLAYER_TURN=true},PLAYER_TURN={FILTERING_PLAYER=true,ABORTED=true},FILTERING_PLAYER={PLAYER_TURN=true,SCRIPTED_REPLY=true,LIVE_GENERATING=true,ABORTED=true},SCRIPTED_REPLY={PLAYER_TURN=true,COMPLETE=true},LIVE_GENERATING={PLAYER_TURN=true,LIVE_JUDGING=true,ABORTED=true},LIVE_JUDGING={COMPLETE=true,ABORTED=true},COMPLETE={READY=true,ENDED=true},ABORTED={READY=true,ENDED=true}}
function State.new(participationGeneration,sessionGeneration,roundGeneration)
 return {Phase="READY",ParticipationGeneration=participationGeneration,SessionGeneration=sessionGeneration,RoundGeneration=roundGeneration,TurnToken=0,OperationToken=0,Turn=0,Closed=false}
end
function State.transition(state,nextPhase)if state.Closed or not(LEGAL[state.Phase]and LEGAL[state.Phase][nextPhase])then return false end;state.Phase=nextPhase;state.OperationToken+=1;return true end
function State.startTurn(state)if not State.transition(state,"PLAYER_TURN")then return nil end;state.TurnToken+=1;return State.token(state,"PLAYER_TURN")end
function State.beginFiltering(state,turnToken)if state.Phase~="PLAYER_TURN"or state.TurnToken~=turnToken then return nil end;if not State.transition(state,"FILTERING_PLAYER")then return nil end;return State.token(state,"FILTERING_PLAYER")end
function State.filterFailed(state,token)if not State.matches(state,token)or not State.transition(state,"PLAYER_TURN")then return nil end;state.TurnToken+=1;return State.token(state,"PLAYER_TURN")end
function State.acceptFiltered(state,token)if not State.matches(state,token)or not State.transition(state,"SCRIPTED_REPLY")then return false end;state.Turn+=1;return true end
function State.finishReply(state,maxTurns)if state.Phase~="SCRIPTED_REPLY"then return nil end;if state.Turn>=maxTurns then State.transition(state,"COMPLETE");return "COMPLETE"end;return State.startTurn(state)end
function State.abort(state)return State.transition(state,"ABORTED")end
function State.close(state)if state.Phase~="COMPLETE"and state.Phase~="ABORTED"then return false end;State.transition(state,"ENDED");state.Closed=true;return true end
function State.token(s,phase)return {ParticipationGeneration=s.ParticipationGeneration,SessionGeneration=s.SessionGeneration,RoundGeneration=s.RoundGeneration,TurnToken=s.TurnToken,OperationToken=s.OperationToken,ExpectedPhase=phase}end
function State.matches(s,t)return type(t)=="table"and s.Phase==t.ExpectedPhase and s.ParticipationGeneration==t.ParticipationGeneration and s.SessionGeneration==t.SessionGeneration and s.RoundGeneration==t.RoundGeneration and s.TurnToken==t.TurnToken and s.OperationToken==t.OperationToken end
return State
