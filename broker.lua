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
local TTYPES = NS.TTYPES;

local dataBroker;

if LibStub == nil then
	print(addonName, "ERROR: LibStub not found.");
	return;
end

local ldb = LibStub:GetLibrary("LibDataBroker-1.1", true);
if ldb == nil then
	print(addonName, "ERROR: LibDataBroker not found.");
	return;
end

-- LibDataBroker documentation: https://github.com/tekkub/libdatabroker-1-1/wiki/How-to-provide-a-dataobject

dataBroker = ldb:NewDataObject(addonName, {
	type = "data source",
	text = "",
	icon = "Interface\\Icons\\INV_Misc_Book_03",
});


function dataBroker:OnTooltipShow()
	self:AddLine(addonName.." v"..GetAddOnMetadata(addonName, "version"));
	self:AddLine(" ");

	local verbose = IsShiftKeyDown();

	local line, lastLine = "", "";

	for i, item in ipairs(NS.data) do
		line = "";
		
		if item.type == TTYPES.QUEST_DETAIL then
			line = C.White.."Detail: "..C.Yellow..item.quest.title.." at "..C.White..item.npc.name;
		elseif item.type == TTYPES.QUEST_COMPLETE then
			line = C.White.."Complete "..C.Yellow..item.quest.title..C.White.." at "..item.npc.name;
		elseif item.type == TTYPES.QUEST_ACCEPTED then
			if verbose then
				line = C.Yellow.."["..tostring(item.quest[8]).."] "..item.quest[1];
			end
		elseif item.type == TTYPES.QUEST_TURNED_IN then
			if verbose then
				line = "["..tostring(item.quest.id).."] turned in";
			end
		else
			-- should not happen
			NS.logError("dataBroker:OnTooltipShow found unexpected item.type=", item.type);
			line = "";
		end

		-- Prevent printing duplicities (there are in log sometimes, we can fix them too)
		if line ~= "" and line ~= lastLine then
			self:AddLine(line);
			lastLine = line;
		end
	end
end