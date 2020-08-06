--[[
MIT License

Copyright (c) 2020 Martin Hassman

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
--]]

local addonName, NS = ...;
local C = NS.C;

local frame = CreateFrame("FRAME");
local events = {};

local function setDefaultSettings(setts)
	setts.debug = false;
end

-- Print only if debug is on
local function debugPrint(...)
	if NS.settings and NS.settings.debug then
		print(...);
	end
end

function events.ADDON_LOADED(...)
	local arg1 = select(1, ...);

	-- ADDON_LOADED event is raised for every running addon,
	-- 1st argument contains that addon name
	-- we response only for our addon call and ignore the others
	if arg1 ~= addonName then
		return;
	end

	print(NS.msgPrefix.."version "..GetAddOnMetadata(addonName, "version")..". Use "..NS.mainSlashCmd.." for help");

	if SQTTSharedData == nil then SQTTSharedData = {} end;
	if SQTTData       == nil then SQTTData       = {} end;
	if SQTTSettings   == nil then SQTTSettings   = {}; setDefaultSettings(SQTTSettings); end;

	NS.sharedData = SQTTSharedData;
	NS.data       = SQTTData;
	NS.settings   = SQTTSettings;
end



function events.GOSSIP_SHOW(...) -- General talking with NPC, not necessary quest giver
	-- Dialog here is not so interested, do not log. only debug print
	debugPrint(C.Yellow.."GOSSIP_SHOW", ...);

	debugPrint("NPC=", UnitName("npc"), ""); -- last "" only for omit second return parameter of UnitName in output
	debugPrint("GetGossipText=", GetGossipText());

	if GetNumActiveQuests() > 0          then debugPrint("GetNumActiveQuests=", GetNumActiveQuests()); end
	if GetNumAvailableQuests() > 0       then debugPrint("GetNumAvailableQuests=", GetNumAvailableQuests()); end
	if GetNumGossipAvailableQuests() > 0 then debugPrint("GetNumGossipAvailableQuests=", GetNumGossipAvailableQuests()); debugPrint("GetGossipAvailableQuests:", GetGossipAvailableQuests()); end
	if GetNumGossipActiveQuests() > 0    then debugPrint("GetNumGossipActiveQuests=", GetNumGossipActiveQuests()); debugPrint("GetGossipActiveQuests:", GetGossipActiveQuests()); end
	if GetNumGossipOptions() > 0         then debugPrint("GetNumGossipOptions=", GetNumGossipOptions()); debugPrint("GetGossipOptions", GetGossipOptions()); end
end


function events.GOSSIP_CLOSED(...)
	--debugPrint("GOSSIP_CLOSED", ...); -- nothing important happens here, can completelly ignore this event
end


function events.QUEST_GREETING(...) -- Talking with NPC quest giver
	debugPrint(C.Yellow.."QUEST_GREETING", ...);

	debugPrint("UnitName(npc)", UnitName("npc"));
	debugPrint("GetGreetingText", GetGreetingText());

	debugPrint("GetNumActiveQuests", GetNumActiveQuests());
	debugPrint("GetNumAvailableQuests", GetNumAvailableQuests());

	debugPrint("GetNumGossipAvailableQuests", GetNumGossipAvailableQuests());
	debugPrint("GetNumGossipActiveQuests", GetNumGossipActiveQuests());
	debugPrint("GetNumGossipOptions", GetNumGossipOptions());
	debugPrint("GetGossipOptions", GetGossipOptions());
end


function events.QUEST_DETAIL(...)  -- Talking with NPC quest giver, opened Quest detail with Accept/Decline buttons
	debugPrint(C.Yellow.."QUEST_DETAIL", ...);

	debugPrint("NPC=", UnitName("npc"), ""); -- last "" only for omit second return parameter of UnitName in output
	debugPrint("GetTitleText="..C.Green1, GetTitleText());
	debugPrint("GetQuestText=", GetQuestText());
	debugPrint("GetObjectiveText="..C.Blue1, GetObjectiveText());

	if GetNumQuestRewards() > 0 then debugPrint("GetNumQuestRewards", GetNumQuestRewards()); end -- how many rewards I get
	if GetNumQuestChoices() > 0 then debugPrint("GetNumQuestChoices", GetNumQuestChoices()); end -- probably between how many items player can choose
	if GetNumRewardSpells() > 0 then debugPrint("GetNumRewardSpells", GetNumRewardSpells()); end
	if GetRewardMoney() > 0     then debugPrint("Reward Money", GetRewardMoney()); end

	local quest = NS.getQuestDetailInfo();
	local npc = NS.getNpcUnitInfo();
	if npc == nil then npc = {} end

	NS.trackQuestDetail(NS.data, npc, quest);
end

function events.QUEST_ACCEPTED(...) -- Player accepted quest arg1=quest log index, arg2=quest ID
	--here we can use information from player quest log (not from NPC quest giver dialog)
	debugPrint(C.Yellow.."QUEST_ACCEPTED", ...);

	local questLogIndex = select(1, ...);

 	-- https://wowwiki.fandom.com/wiki/API_GetQuestLogTitle
	-- title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isStory
	local questLogInfo = { GetQuestLogTitle(questLogIndex) };

	debugPrint("GetQuestLogTitle", unpack(questLogInfo));
	NS.trackQuestAccepted(NS.data, questLogInfo); -- not sure if we need all all of this, can remove later
end


function events.QUEST_PROGRESS(...) -- Talking with quest NPC, before press continue
	-- Dialog here is not so interested, do not log. only debug print
	debugPrint(C.Yellow.."QUEST_PROGRESS", ...);

	debugPrint("GetTitleText"..C.Green1, GetTitleText());
	debugPrint("GetProgressText", GetProgressText());
	debugPrint("IsQuestCompletable", IsQuestCompletable());
end

function events.QUEST_COMPLETE(...) -- Talking with quest NPC, after player press continue (=can complete quest) but just before player press complete the quest
	debugPrint(C.Yellow.."QUEST_COMPLETE", ...);


	-- plus logovat opet detaily NPC osoby

	debugPrint("GetTitleText", GetTitleText());
	debugPrint("GetRewardText", GetRewardText()); -- TODO musim jeste odzkouset

end

function events.QUEST_TURNED_IN(...) -- player press complete = finished quest
	-- args: QuestID, XP earned, Money reward
	debugPrint(C.Yellow.."QUEST_TURNED_IN", ...);
end

function events.QUEST_FINISHED(...) -- something like GOSSIP_CLOSED, when I close quest window, can ignore this event
	--debugPrint("QUEST_FINISHED", ...);
end


function events.UNIT_QUEST_LOG_CHANGED(...) -- arg1="player" ??? similar to UNIT_QUEST_LOG_CHANGED
	debugPrint("UNIT_QUEST_LOG_CHANGED", ...); 
end

function events.QUEST_LOG_UPDATE(...) -- ???? do I not need this?
	debugPrint("QUEST_LOG_UPDATE", ...);   -- call often, even for changes in quest log window, event for headings collapse/expand
end


function events.QUEST_ITEM_UPDATE(...) -- ????
	debugPrint(C.Yellow.."QUEST_ITEM_UPDATE", ...);
end


function events.QUEST_WATCH_UPDATE(...) -- ????
	debugPrint(C.Yellow.."QUEST_ITEM_UPDATE", ...);
end

-- Call event handlers or log error for unknow events
function frame:OnEvent(event, ...)
	if events[event] ~= nil then
		events[event](...);
	else
		NS.logError("Received unhandled event:", event, ...);
	end
end

frame:SetScript("OnEvent", frame.OnEvent);

frame:RegisterEvent("ADDON_LOADED");

frame:RegisterEvent("GOSSIP_SHOW");
frame:RegisterEvent("GOSSIP_CLOSED");

frame:RegisterEvent("QUEST_GREETING");	-- !! nekdy ma trochu zajimavy text, chci logovat?, a ma senzam questu k dispozici
frame:RegisterEvent("QUEST_DETAIL");	-- !!!!! to hlavni pro logovani, quest texty a odmeny
frame:RegisterEvent("QUEST_ACCEPTED");	-- potvrzeni prijeti (muzeme zalogovat zacatek questu)


frame:RegisterEvent("QUEST_PROGRESS");	-- !! nekdy ma trochu zajimavy text, chci logovat?
frame:RegisterEvent("QUEST_COMPLETE");	-- !!!!! dalsi hodne zajimavy text
frame:RegisterEvent("QUEST_TURNED_IN");
frame:RegisterEvent("QUEST_FINISHED");


frame:RegisterEvent("UNIT_QUEST_LOG_CHANGED");
frame:RegisterEvent("QUEST_LOG_UPDATE");
frame:RegisterEvent("QUEST_ITEM_UPDATE");  -- ?? neni to kdyz plnim quest, ze mi roste pocet predmetu?? - zajimave
frame:RegisterEvent("QUEST_WATCH_UPDATE"); -- ?? tesne pred splnenim cile questu?? - nepotrebuji


--[[
-- Mám dost informací k zadávání questu a dokončení
-- Nemám informace k průběžnému plnění (asi nepotřebuju, jen pro zajímavost)
-- Nemám informace k selhání questu (např. u transport questů), ale asi nepotřebuji
-- A nemám informace k abandon questu - jak to poznám? jen sledováním změn quest logu a zmizením položky?
-- To by se hodilo časem do Wow diary volá se UNIT_QUEST_LOG_CHANGED, ale poznám detaily?
-- mohl bych odchytavat jako hook tu API funkci AbandonQuest(), kdyz neni event. a po ni zkontrolovat, ktery zmizel
-- (pokud to nejde zjistit behem, GetAbandonQuestName(), )
--]]
