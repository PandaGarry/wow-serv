--Change ID Token: 17242
--Change ID Rewars: 50818 (Invensible - Mount)
--Change ID Rewars: 20371 (Murky - Pet)
--NPC id
local hcNPC = 90000
--This is how long the character is locked for - default is 32 years.
local banTimer = 999999999

--on death function - checks if player has token and bans character if it does.
local function PlayerDeath(event, killer, killed)
--Configure ID item for enable Hardcore Mode (Token)
--  if killed:HasItem(17242,1) and killed:GetLevel() == 1 then
  if killed:HasItem(17242,1) then
    print(killed:GetName() .. " was killed by " .. killer:GetName())
    SendWorldMessage(killed:GetName() .. " was killed by " .. killer:GetName())
    Ban(1,killed:GetName(),banTimer)
  end
end

--First Gossip Screen for NPC
function OnFirstTalk(event, player, unit)
--Configure max level for rewards and ID items for rewards.
  if player:GetLevel() == 80 and player:HasItem(17242,1) then
    player:AddItem(50818, 1)
    player:AddItem(20371, 1)
	player:RemoveItem(17242, player:GetItemCount(17242))
--Configure ID item for enable Hardcore Mode (Token)
  elseif player:HasItem(17242,1) then
    player:SendBroadcastMessage("You are already in Hardcore Mode.")
    player:PlayDistanceSound(20432)
    player:GossipComplete()
--Configure level for talk NPC (Level 1)
  elseif player:GetLevel() == 1 then
    player:PlayDistanceSound(20431)
    player:GossipMenuAddItem(0, "Looking for a challenge? Click here to try hardcore mode!", 0, 1)
    player:GossipSendMenu(1, unit)
  else
    player:SendBroadcastMessage("You must be level 1 to access hardcore mode.")
    player:PlayDistanceSound(20432)
    player:GossipComplete()
  end
end

--Selection for NPC gossip
function OnSelect(event, player, unit, sender, intid, code)
  if intid == 1 then
    player:PlayDistanceSound(20433)
    player:GossipMenuAddItem(0, "Just double checking to make sure that you want to turn on hardcore mode. This will lock the character after death to be no longer playable. When you are level 80 talk to me for your reward.", 0, 2)
    player:GossipMenuAddItem(0, "NO TAKE ME BACK!", 0, 3)
    player:GossipSendMenu(2, unit)
  elseif intid == 3 then
    player:GossipComplete()
  end
end

--if player chooses to do hardcore they receive the token and have custom items and Murky removed
function OnHardCore(event, player, unit, sender, intid, code)
  if intid == 2 then
    player:PlayDistanceSound(20434)
--Configure ID item for enable Hardcore Mode (Token)
    player:AddItem(17242, 1)
    player:SetCoinage(0)
	player:GossipComplete()
  else
    player:GossipComplete()
  end
end

RegisterCreatureGossipEvent(hcNPC, 1 , OnFirstTalk)
RegisterCreatureGossipEvent(hcNPC, 2, OnSelect)
RegisterCreatureGossipEvent(hcNPC, 2, OnHardCore)
RegisterPlayerEvent(8, PlayerDeath)