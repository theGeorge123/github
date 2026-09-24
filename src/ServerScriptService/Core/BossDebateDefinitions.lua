local TopicBank=if script then require(script.Parent.DebateTopicBank)else require("./DebateTopicBank")
local Definitions={PlayerTurns=6,PlayerTurnSeconds=45,TopicChoiceSeconds=20,MaxArgumentBytes=500}
Definitions.ScriptedReplies=table.freeze({
 "SCRIPTED PRACTICE: Restate your reason and name one trade-off the other side might raise.",
 "SCRIPTED PRACTICE: Give one concrete example or consequence for your assigned position.",
 "SCRIPTED PRACTICE: Use however or but to answer the strongest objection you can imagine.",
 "SCRIPTED PRACTICE: Compare your position with one realistic alternative.",
 "SCRIPTED PRACTICE: Explain who benefits, who may not, and why that matters.",
 "SCRIPTED PRACTICE: Close by linking your reason, example, and rebuttal in two clear sentences.",
})
Definitions.Disclosure="SCRIPTED PRACTICE uses authored prompts only. It does not understand, judge, score, or choose a winner."
function Definitions.TopicOffers(seed)return TopicBank.Offers(seed)end
function Definitions.FindOfferedTopic(offers,id)return TopicBank.FindInOffers(offers,id)end
function Definitions.TopicSummaries(offers)return TopicBank.Summary(offers)end
return Definitions
