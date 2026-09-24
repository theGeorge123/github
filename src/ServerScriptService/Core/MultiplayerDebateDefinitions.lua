local WritingChecklist=if script then require(script.Parent.WritingChecklist)else require("./WritingChecklist")
local TopicBank=if script then require(script.Parent.DebateTopicBank)else require("./DebateTopicBank")
local Definitions={PlayerTurnsEach=3,TurnSeconds=45,TopicChoiceSeconds=20,MaxArgumentBytes=500,Topics=TopicBank.Topics}
Definitions.Unlocks=table.freeze({{Points=0,Id="starter-chair",Label="Starter Chair",Kind="chair"},{Points=30,Id="blue-chair",Label="Blue Chair",Kind="chair"},{Points=60,Id="clear-thinker",Label="Clear Thinker title",Kind="title"},{Points=100,Id="gold-chair",Label="Gold Chair",Kind="chair"}})
function Definitions.TopicOffers(seed)return TopicBank.Offers(seed)end
function Definitions.FindOfferedTopic(offers,id)return TopicBank.FindInOffers(offers,id)end
function Definitions.TopicSummaries(offers)return TopicBank.Summary(offers)end
function Definitions.Score(text)return WritingChecklist.Evaluate(text)end
return Definitions
