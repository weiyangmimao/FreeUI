local F, C, L = unpack(select(2, ...))
local module = F:GetModule("chat")



--[[
	修改自NoGoldSeller，强迫症患者只能接受这个低占用的。
]]

-- Filter Chat symbols
local msgSymbols = {"`", "～", "＠", "＃", "^", "＊", "！", "？", "。", "|", " ", "—", "——", "￥", "’", "‘", "“", "”", "【", "】", "『", "』", "《", "》", "〈", "〉", "（", "）", "〔", "〕", "、", "，", "：", ",", "_", "/", "~", "-"}

local FilterList = {}
local function genFilterList()
	FilterList = {string.split(" ", C.chat.filterList or "")}
end
F.genFilterList = genFilterList

F.FriendsList = {}
local function updateFriends()
	wipe(F.FriendsList)

	for i = 1, GetNumFriends() do
		local name = GetFriendInfo(i)
		if name then
			F.FriendsList[Ambiguate(name, "none")] = true
		end
	end

	for i = 1, select(2, BNGetNumFriends()) do
		for j = 1, BNGetNumFriendGameAccounts(i) do
			local _, characterName, client, realmName = BNGetFriendGameAccountInfo(i, j)
			if client == BNET_CLIENT_WOW then
				F.FriendsList[Ambiguate(characterName.."-"..realmName, "none")] = true
			end
		end
	end
end
F:RegisterEvent("FRIENDLIST_UPDATE", updateFriends)
F:RegisterEvent("BN_FRIEND_INFO_CHANGED", updateFriends)

local function genChatFilter(_, event, msg, author, _, _, _, flag)
	--if not C.chat.enableFilter then return end

	local name = Ambiguate(author, "none")
	if UnitIsUnit(name, "player") or (event == "CHAT_MSG_WHISPER" and flag == "GM") or flag == "DEV" then
		return
	elseif F.UnitInGuild(author) or UnitInRaid(name) or UnitInParty(name) or F.FriendsList[name] then
		return
	end

	for _, symbol in ipairs(msgSymbols) do
		msg = gsub(msg, symbol, "")
	end

	local match = 0
	for _, keyword in pairs(FilterList) do
		if keyword ~= "" then
			local _, count = gsub(msg, keyword, "")
			if count > 0 then
				match = match + 1
			end
		end
	end

	if match >= C.chat.match then
		return true
	end
end

local addonBlockList = {
	"任务进度提示%s?[:：]", "%[接受任务%]", "%(任务完成%)", "<大脚组队提示>", "<大脚团队提示>", "【爱不易】", "EUI:", "EUI_RaidCD", "打断:.+|Hspell", "PS 死亡: .+>", "%*%*.+%*%*",
	"<iLvl>", ("%-"):rep(30), "<小队物品等级:.+>", "<LFG>", "wowcdk", "进度:", "属性通报", "%[World Quest Tracker%]", "wowcn%.vip"
}

local function genAddonBlock(_, _, msg, author)
	--if not C.chat.blockAddonAlert then return end

	local name = Ambiguate(author, "none")
	if UnitIsUnit(name, "player") then return end

	for _, word in ipairs(addonBlockList) do
		if msg:find(word) then
			return true
		end
	end
end




function module:ChatFilter()
	genFilterList()

	ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", genChatFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", genChatFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", genChatFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", genChatFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_EMOTE", genChatFilter)

	ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", genAddonBlock)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", genAddonBlock)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY", genAddonBlock)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY_LEADER", genAddonBlock)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID", genAddonBlock)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_LEADER", genAddonBlock)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_INSTANCE_CHAT", genAddonBlock)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_INSTANCE_CHAT_LEADER", genAddonBlock)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", genAddonBlock)

end