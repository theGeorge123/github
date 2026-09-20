local Definitions={PlayerTurns=3,PlayerTurnSeconds=45,MaxArgumentBytes=500}
Definitions.Topic={Id="optional_hints",Question="Should building games make hints optional?",PlayerPosition="Hints should be available but optional.",BossPosition="Building games should use one consistent hint system."}
Definitions.ScriptedReplies={
 "SCRIPTED PRACTICE: Restate your reason and name one trade-off the other side might raise.",
 "SCRIPTED PRACTICE: Give one concrete example or consequence for your assigned position.",
 "SCRIPTED PRACTICE: Summarize your assigned position. This authored prompt does not evaluate it.",
}
Definitions.Disclosure="SCRIPTED PRACTICE uses authored prompts only. It does not understand, judge, score, or choose a winner."
return Definitions
