
--[[
License for Evl's original work

Copyright (c) 2009 Evl

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
]]

local debugf = tekDebug and tekDebug:GetFrame('MmmmonsterKill')
local debug
if debugf then
	debug = function(...) debugf:AddMessage(string.join(', ', tostringall(...))) end
else
	debug = function() end
end

local PATH = [[Interface\AddOns\MmmmonsterKill\sounds\%s.mp3]]

local spreeSounds = {
	[1] = 'First_Blood',
	[2] = 'Killing_Spree',
	[3] = 'Dominating',
	[4] = 'Mega_Kill',
	[5] = 'Unstoppable',
	[6] = 'Wicked_Sick',
	[7] = 'Monster_Kill',
	[8] = 'Ludicrous_Kill',
	[9] = 'God_Like',
	[10] = 'Holy_Shit',
}

local multiSounds = {
	[2] = 'Double_Kill',
	[3] = 'Triple_Kill',
	[4] = 'Ultra_Kill',
	[5] = 'Rampage',
}

local spreeMAX = 10
local multiMAX = 5

local MULTI_KILL_HOLD_TIME = 11.5

local killingStreak = 0
local multiKill = 0
local lastKillTime = 0
local multiSound
local spreeSound

local bit_band = bit.band

local function hasFlag(flags, flag)
	return bit_band(flags, flag) == flag
end


local addon = CreateFrame('Frame', 'MmmmonsterKill')
addon:SetScript('OnEvent', function(self, event, ...) self[event](self, event, ...) end)
addon:RegisterEvent'COMBAT_LOG_EVENT_UNFILTERED'
addon:RegisterEvent'PLAYER_DEAD'

function addon:PlaySound(file)
	PlaySoundFile(format(PATH, file))
end

local total = 0
function addon:OnUpdate(elps)
	total = total + elps
	if total >= 2 then
		self:PlaySound(spreeSound)
		total = 0
		self:SetScript('OnUpdate', nil)
	end
end

function addon:Trigger()
	local now = GetTime()
	
	multiKill = (lastKillTime + MULTI_KILL_HOLD_TIME > now) and (multiKill + 1) or 1
	lastKillTime = now
	killingStreak = killingStreak + 1
	
	multiSound = multiSounds[min(multiMAX, multiKill)]
	spreeSound = spreeSounds[min(spreeMAX, killingStreak)]
	if multiSound then
		self:PlaySound(multiSound)
		if spreeSound then
			self:SetScript('OnUpdate', self.OnUpdate)
		end
	elseif spreeSound then
		self:PlaySound(spreeSound)
	end
end


function addon:PLAYER_DEAD()
	killingStreak = 0
end

function addon:PARTY_KILL(sourceFlags, destFlags)
    if hasFlag(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) and hasFlag(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) then
        return addon:Trigger()
    end
end

function addon:COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, eventType, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlasgs)
    if(eventType=='PARTY_KILL') then
        return self:PARTY_KILL(sourceFlags, destFlags)
    end
end

