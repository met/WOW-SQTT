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


-- return information about player location
-- {x, y, zone, subzone}
function NS.getPlayerLocation()
	local position = {};
	local px, py = C_Map.GetPlayerMapPosition(C_Map.GetBestMapForUnit("player"), "player"):GetXY();

	position.x = tonumber(string.format("%.2f", px*100)); -- round to 2 decimal places
	position.y = tonumber(string.format("%.2f", py*100));
	position.zone = GetZoneText();
	position.subzone = GetSubZoneText();

	return position;
end


-- get info about NPC the player is talking to now
-- return nil if there is no NPC available
function NS.getNpcUnitInfo()
	local unit = {};

	if not UnitExists("npc") then
		logDebug("getNpcUnitInfo() - no NPC unit found");
		return nil;
	end		

	unit.name         = UnitName("npc");
	unit.level        = tonumber(UnitLevel("npc"));
	unit.faction      = UnitFactionGroup("npc"); -- Alliance/Horde/nil
	_, unit.class     = UnitClass("npc"); -- need 2nd returned parameter
	unit.creatureType = UnitCreatureType("npc"); -- eg. Humanoid
	unit.location     = NS.getPlayerLocation(); -- cannot locate NPC via API, use location of player instead

	return unit;
end


-- get info about quest that playr may just start
-- info is from opened NPC window, where player may accept or decline quest
function NS.getQuestDetailInfo()
	local quest = {};
	quest.title = GetTitleText();

	if quest.title == nil or quest.title == "" then
		logDebug("getQuestStartInfo() - no quest information found");
		return nil;
	end

	quest.text = GetQuestText();
	quest.objective = GetObjectiveText();
	quest.reward = {};
	quest.reward.numRewards = GetNumQuestRewards();  -- how many rewards I get
	quest.reward.numChoices = GetNumQuestChoices();  -- not sure, probably between how many reward items player can choose
	quest.reward.spells =  GetNumRewardSpells();
	quest.reward.money = GetRewardMoney();

	return quest;
end


-- Track quest detail info to log
function NS.trackQuestDetail(log, npc, questInfo)
	assert(log, "trackQuestDetail - log is nil");
	assert(npc, "trackQuestDetail - npc is nil");
	assert(questInfo, "trackQuestDetail - questInfo is nil");

	NS.writeTrackMessage(log, {type = "quest detail", npc = npc, quest = questInfo});
end


function NS.trackQuestAccepted(log, questInfo)
	assert(log, "trackQuestAccepted - log is nil");
	assert(questInfo, "trackQuestAccepted - questInfo is nil");

	NS.writeTrackMessage(log, {type = "quest accepted", quest = questInfo});
end

-- General call for storing track messages
-- Added time and write message
function NS.writeTrackMessage(log, msg)
	assert(log, "writeTrackMessage - log is nil");	
	assert(msg, "writeTrackMessage - msg is nil");

	local timestamp = time();
	local readableDate = date(nil, timestamp); -- human readable string for this unixtime

	msg.timestamp = timestamp;
	msg.date = readableDate;

	table.insert(log, msg);
end