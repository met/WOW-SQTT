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


-- General talking with NPC, not necessary quest giver
-- Dialog here is not so interested, don't log. only debug print
function events.GOSSIP_SHOW(...)	
	debugPrint(C.Yellow.."GOSSIP_SHOW", ...);
	debugPrint("NPC=", UnitName("npc"), ""); -- last "" only for omit second return parameter of UnitName in output
	debugPrint("GetGossipText=", GetGossipText());

	if GetNumActiveQuests() > 0          then debugPrint("GetNumActiveQuests=", GetNumActiveQuests()); end
	if GetNumAvailableQuests() > 0       then debugPrint("GetNumAvailableQuests=", GetNumAvailableQuests()); end
	if GetNumGossipAvailableQuests() > 0 then debugPrint("GetNumGossipAvailableQuests=", GetNumGossipAvailableQuests()); debugPrint("GetGossipAvailableQuests:", GetGossipAvailableQuests()); end
	-- GetNumGossipAvailableQuests should return list of [title1, level1, isLowLevel1, isDaily1, isRepeatable1] ??
	if GetNumGossipActiveQuests() > 0    then debugPrint("GetNumGossipActiveQuests=", GetNumGossipActiveQuests()); debugPrint("GetGossipActiveQuests:", GetGossipActiveQuests()); end
	-- GetGossipActiveQuests should return list of [title1, level1, isLowLevel1, isComplete1] ??
	if GetNumGossipOptions() > 0         then debugPrint("GetNumGossipOptions=", GetNumGossipOptions()); debugPrint("GetGossipOptions", GetGossipOptions()); end
end

-- nothing important happens here, can completelly ignore this event
function events.GOSSIP_CLOSED(...)
	--debugPrint("GOSSIP_CLOSED", ...);
end


-- Talking with NPC quest giver, never seen this, usually I see GOSSIP_SHOW instead
function events.QUEST_GREETING(...)
	debugPrint(C.Red.."QUEST_GREETING", ...);
	debugPrint("NPC=", UnitName("npc"), ""); -- last "" only for omit second return parameter of UnitName in output
	debugPrint("GetGreetingText=", GetGreetingText());

	if GetNumActiveQuests() > 0          then debugPrint("GetNumActiveQuests=", GetNumActiveQuests()); end
	if GetNumAvailableQuests() > 0       then debugPrint("GetNumAvailableQuests=", GetNumAvailableQuests()); end
	if GetNumGossipAvailableQuests() > 0 then debugPrint("GetNumGossipAvailableQuests=", GetNumGossipAvailableQuests()); debugPrint("GetGossipAvailableQuests:", GetGossipAvailableQuests()); end
	-- GetNumGossipAvailableQuests should return list of [title1, level1, isLowLevel1, isDaily1, isRepeatable1] ??
	if GetNumGossipActiveQuests() > 0    then debugPrint("GetNumGossipActiveQuests=", GetNumGossipActiveQuests()); debugPrint("GetGossipActiveQuests:", GetGossipActiveQuests()); end
	-- GetGossipActiveQuests should return list of [title1, level1, isLowLevel1, isComplete1] ??
	if GetNumGossipOptions() > 0         then debugPrint("GetNumGossipOptions=", GetNumGossipOptions()); debugPrint("GetGossipOptions", GetGossipOptions()); end
end


-- Talking with NPC quest giver, opened Quest detail with Accept/Decline buttons
-- track quest details
function events.QUEST_DETAIL(...) 
	debugPrint(C.Yellow.."QUEST_DETAIL", ...);
	debugPrint("NPC=", UnitName("npc"), ""); -- last "" only for omit second return parameter of UnitName in output
	debugPrint("GetTitleText="..C.Green1, GetTitleText());
	debugPrint("GetQuestText=", GetQuestText());
	debugPrint("GetObjectiveText="..C.Blue1, GetObjectiveText());

	if GetNumQuestRewards() > 0 then debugPrint("GetNumQuestRewards", GetNumQuestRewards()); end -- how many rewards I get
	if GetNumQuestChoices() > 0 then debugPrint("GetNumQuestChoices", GetNumQuestChoices()); end -- between how many items player can choose
	if GetNumRewardSpells() > 0 then debugPrint("GetNumRewardSpells", GetNumRewardSpells()); end
	if GetRewardMoney() > 0     then debugPrint("Reward Money:"..C.Copper, GetRewardMoney()); end

	local quest = NS.getQuestDetailInfo();
	local npc = NS.getNpcUnitInfo();
	if npc == nil then npc = {} end

	NS.trackQuestDetail(NS.data, npc, quest);
end

-- Player accepted quest
-- arg1=quest log index, arg2=quest ID
-- use information from player quest log (not from NPC quest giver dialog)
function events.QUEST_ACCEPTED(...)
	debugPrint(C.Yellow.."QUEST_ACCEPTED", ...);
	local questLogIndex = select(1, ...);
	local questLogInfo = { GetQuestLogTitle(questLogIndex) };	
 	-- https://wowwiki.fandom.com/wiki/API_GetQuestLogTitle
	-- title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isStory
	debugPrint("GetQuestLogTitle", unpack(questLogInfo));
	NS.trackQuestAccepted(NS.data, questLogInfo); -- not sure if we need all all of this, can remove later
end

-- Talking with quest NPC, inside quest option, but before press continue
-- Dialog here is not so interested, do not log. only debug print
function events.QUEST_PROGRESS(...)
	debugPrint(C.Yellow.."QUEST_PROGRESS", ...);
	debugPrint("GetTitleText"..C.Green1, GetTitleText());
	debugPrint("GetProgressText", GetProgressText());
	debugPrint("IsQuestCompletable", IsQuestCompletable());
end

-- Talking with quest NPC, after player press continue (=can complete quest), but just before player press complete the quest
-- Track quest finalle text
function events.QUEST_COMPLETE(...)
	debugPrint(C.Yellow.."QUEST_COMPLETE", ...);
	debugPrint("NPC=", UnitName("npc"), ""); -- last "" only for omit second return parameter of UnitName in output
	debugPrint("GetTitleText="..C.Green1, GetTitleText());
	debugPrint("GetRewardText=", GetRewardText());

	-- Can use this here? want to try.
	if GetNumQuestRewards() > 0 then debugPrint("GetNumQuestRewards", GetNumQuestRewards()); end -- how many rewards I get
	if GetNumQuestChoices() > 0 then debugPrint("GetNumQuestChoices", GetNumQuestChoices()); end -- probably between how many items player can choose
	if GetNumRewardSpells() > 0 then debugPrint("GetNumRewardSpells", GetNumRewardSpells()); end
	if GetRewardMoney() > 0     then debugPrint("Reward Money:"..C.Copper, GetRewardMoney()); end

	local quest = NS.getQuestCompleteInfo();
	local npc = NS.getNpcUnitInfo();
	if npc == nil then npc = {} end

	NS.trackQuestComplete(NS.data, npc, quest);
end

-- player press complete = finished quest
-- args: QuestID, XP earned, Money reward
function events.QUEST_TURNED_IN(...)
	debugPrint(C.Yellow.."QUEST_TURNED_IN", C.White.."(id, xp, money) :", ...);
	local quest = {};
	quest.id = select(1, ...);
	quest.xp = select(2, ...);
	quest.money = select(3, ...);
	NS.trackQuestTurnedIn(NS.data, quest);
end

-- something like GOSSIP_CLOSED, when I close quest window, can ignore this event
function events.QUEST_FINISHED(...)
	--debugPrint("QUEST_FINISHED", ...);
end

-- quest is removed from log, either was completed and turned in or was abandon by user
function events.QUEST_REMOVED(...)
	-- arg1 = questId
	debugPrint("QUEST_REMOVED", ...);
end

-- arg1="player" ??? similar to UNIT_QUEST_LOG_CHANGED
-- can ignore
function events.UNIT_QUEST_LOG_CHANGED(...)
	--debugPrint("UNIT_QUEST_LOG_CHANGED", ...); 
end

 -- call very often, even for small changes in quest log window, event for headings collapse/expand
 -- can ignore
function events.QUEST_LOG_UPDATE(...)
	--debugPrint("QUEST_LOG_UPDATE", ...);
end


 --??
function events.QUEST_ITEM_UPDATE(...)
	debugPrint(C.Red.."QUEST_ITEM_UPDATE", ...); -- never seen this one yet
end


-- during quest progressing, when player kill quest mod or get quest item (usually from killed mob), arg1= player quest log index
function events.QUEST_WATCH_UPDATE(...) 
	debugPrint("QUEST_WATCH_UPDATE", ...);
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

frame:RegisterEvent("QUEST_GREETING");
frame:RegisterEvent("QUEST_DETAIL");
frame:RegisterEvent("QUEST_ACCEPTED");


frame:RegisterEvent("QUEST_PROGRESS");
frame:RegisterEvent("QUEST_COMPLETE");
frame:RegisterEvent("QUEST_TURNED_IN");
frame:RegisterEvent("QUEST_FINISHED");

frame:RegisterEvent("QUEST_REMOVED");

frame:RegisterEvent("UNIT_QUEST_LOG_CHANGED");
frame:RegisterEvent("QUEST_LOG_UPDATE");
frame:RegisterEvent("QUEST_ITEM_UPDATE");
frame:RegisterEvent("QUEST_WATCH_UPDATE");
