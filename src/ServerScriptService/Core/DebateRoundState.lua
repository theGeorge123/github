local R={}
function R.new(generation,turnsEach,openingIndex)
 assert(type(generation)=="number");assert(type(turnsEach)=="number"and turnsEach>=1);assert(openingIndex==1 or openingIndex==2)
 return {RoundGeneration=generation,TurnsEach=turnsEach,Turns={0,0},PlayerIndex=openingIndex,TurnToken=0,Closed=false}
end
function R.beginTurn(s)assert(not s.Closed);s.TurnToken=s.TurnToken+1;return {RoundGeneration=s.RoundGeneration,TurnToken=s.TurnToken,PlayerIndex=s.PlayerIndex,TurnNumber=s.Turns[s.PlayerIndex]+1}end
function R.matches(s,g,t,i)return not s.Closed and s.RoundGeneration==g and s.TurnToken==t and s.PlayerIndex==i end
function R.completeTurn(s,g,t,i)
 if not R.matches(s,g,t,i)then return {Applied=false,Complete=s.Closed}end;s.Turns[i]=s.Turns[i]+1
 if s.Turns[1]>=s.TurnsEach and s.Turns[2]>=s.TurnsEach then s.Closed=true;return {Applied=true,Complete=true,CompletedPlayerIndex=i}end
 s.PlayerIndex=i==1 and 2 or 1;return {Applied=true,Complete=false,CompletedPlayerIndex=i,NextPlayerIndex=s.PlayerIndex}
end
function R.close(s)s.Closed=true;s.TurnToken=s.TurnToken+1 end
return R
