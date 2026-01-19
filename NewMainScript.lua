--[[
	rewritten vape lite from xylex!
	all credits to xylex for making vapelite and for me to redo
]]
local run = function(func) func() end
local cloneref = cloneref or function(obj) return obj end
local vapelite


local playersService = cloneref(game:GetService('Players'))
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local runService = cloneref(game:GetService('RunService'))
local inputService = cloneref(game:GetService('UserInputService'))
local tweenService = cloneref(game:GetService('TweenService'))
local httpService = cloneref(game:GetService('HttpService'))
local textChatService = cloneref(game:GetService('TextChatService'))
local collectionService = cloneref(game:GetService('CollectionService'))
local contextActionService = cloneref(game:GetService('ContextActionService'))
local guiService = cloneref(game:GetService('GuiService'))
local coreGui = cloneref(game:GetService('CoreGui'))
local starterGui = cloneref(game:GetService('StarterGui'))
local TeleportService = cloneref(game:GetService("TeleportService"))
local lightingService = cloneref(game:GetService("Lighting"))
local vim = cloneref(game:GetService("VirtualInputManager"))
local proximityPromptService = cloneref(game:GetService('ProximityPromptService'))
local isnetworkowner = identifyexecutor and table.find({'Nihon','Volt', 'Seliware'}, ({identifyexecutor()})[1]) and isnetworkowner or function()
	return true
end
local gameCamera = workspace.CurrentCamera
local lplr = playersService.LocalPlayer

local LiteVapeEvents = setmetatable({}, {
	__index = function(self, index)
		self[index] = Instance.new('BindableEvent')
		return self[index]
	end
})

local store = {
	attackReach = 0,
	attackReachUpdate = tick(),
	damageBlockFail = tick(),
	hand = {},
	inventory = {
		inventory = {
			items = {},
			armor = {}
		},
		hotbar = {}
	},
	inventories = {},
	matchState = 0,
	queueType = 'bedwars_test',
	tools = {}
}
local bedwars = {}


local suc, web = pcall(function() return WebSocket.connect('ws://127.0.0.1:6892/') end)
if not suc or suc and type(web) == 'boolean' then
	repeat
		suc, web = pcall(function() return WebSocket.connect('ws://127.0.0.1:6892/') end)
		if not suc or suc and type(web) == 'boolean' then
			print('websocket error:', web)
		else
			break
		end
		task.wait(1)
	until suc and type(web) ~= 'boolean'
end
run(function()
	vapelite = {
		Connections = {},
		Loaded = false,
		Modules = {}
	}

	local function getTableSize(tab)
		local ind = 0
		for _ in tab do ind += 1 end
		return ind
	end

	function vapelite:UpdateTextGUI() end

	function vapelite:CreateModule(modulesettings)
		local moduleapi = {Enabled = false, Options = {}, Connections = {}, Name = modulesettings.Name, Tooltip = modulesettings.Tooltip}

		function moduleapi:CreateToggle(optionsettings)
			local optionapi = {Type = 'Toggle', Enabled = false, Index = getTableSize(moduleapi.Options)}
			optionsettings.Function = optionsettings.Function or function() end

			function optionapi:Toggle()
				optionapi.Enabled = not optionapi.Enabled
				optionsettings.Function(optionapi.Enabled)
			end
			if optionsettings.Default then
				optionapi:Toggle()
			end

			moduleapi.Options[optionsettings.Name] = optionapi

			return optionapi
		end

		function moduleapi:CreateSlider(optionsettings)
			local optionapi = {Type = 'Slider', Value = optionsettings.Default or optionsettings.Min, Min = optionsettings.Min, Max = optionsettings.Max, Index = getTableSize(moduleapi.Options)}
			optionsettings.Function = optionsettings.Function or function() end

			function optionapi:SetValue(value)
				if tonumber(value) == math.huge or value ~= value then return end
				optionapi.Value = value
				optionsettings.Function(value)
			end

			moduleapi.Options[optionsettings.Name] = optionapi

			return optionapi
		end

		function moduleapi:Clean(obj) table.insert(moduleapi.Connections, obj) end

		function moduleapi:Toggle()
			moduleapi.Enabled = not moduleapi.Enabled
			if not moduleapi.Enabled then
				for _, v in moduleapi.Connections do
					if typeof(v) == 'Instance' then
						v:ClearAllChildren()
						v:Destroy()
					else
						v:Disconnect()
					end
				end
				table.clear(moduleapi.Connections)
			end
			task.spawn(modulesettings.Function, moduleapi.Enabled)
			vapelite:UpdateTextGUI()
		end

		vapelite.Modules[modulesettings.Name] = moduleapi

		return moduleapi
	end

	function vapelite:Save()
		if not vapelite.Loaded then return end
		vapelite:Send({
			msg = 'writesettings',
			id = (game.PlaceId == 6872265039 and 'bedwarslobbynew' or 'bedwarsmainnew'),
			content = httpService:JSONEncode(vapelite.Modules)
		})
	end

	function vapelite:Load()
		vapelite.read = Instance.new('BindableEvent')
		vapelite:Send({
			msg = 'readsettings',
			id = (game.PlaceId == 6872265039 and 'bedwarslobbynew' or 'bedwarsmainnew')
		})

		local got, data = pcall(function() return httpService:JSONDecode(vapelite.read.Event:Wait()) end)
		if type(data) == 'table' then
			for i, v in data do
				local object = vapelite.Modules[i]
				if object then
					for i2, v2 in v.Options do
						local optionobject = object.Options[i2]
						if optionobject then
							if v2.Type == 'Toggle' then
								if v2.Enabled ~= optionobject.Enabled then optionobject:Toggle() end
							else
								optionobject:SetValue(v2.Value)
							end
						end
					end

					if v.Enabled then object:Toggle() end
				end
			end
		end

		local replicatedmodules = {}
		for i, v in vapelite.Modules do
			local newmodule = {name = i, desc = v.Tooltip, options = {}, toggled = v.Enabled}
			for i2, v2 in v.Options do
				if v2.Type == 'Slider' then
					table.insert(newmodule.options, {name = i2, type = 'Slider', state = v2.Value, min = v2.Min, max = v2.Max, index = v2.Index})
				else
					table.insert(newmodule.options, {name = i2, type = 'Toggle', toggled = v2.Enabled, index = v2.Index})
				end
			end
			table.sort(newmodule.options, function(a, b) return a.index < b.index end)
			table.insert(replicatedmodules, newmodule)
		end
		table.sort(replicatedmodules, function(a, b) return a.name < b.name end)

		vapelite.Loaded = true
		vapelite:Send({
			msg = 'connectrequest',
			modules = replicatedmodules
		})
	end

	function vapelite:Send(data)
		if suc and web then
			web:Send(httpService:JSONEncode(data))
		end
	end

	function vapelite.Receive(data)
		data = httpService:JSONDecode(data)
		local write = false
		if data.msg == 'togglemodule' then
			local module = vapelite.Modules[data.module]
			if module and data.state ~= module.Enabled then module:Toggle() end
		elseif data.msg == 'togglebuttontoggle' or data.msg == 'togglebuttonslider' then
			local option = vapelite.Modules[data.module] and vapelite.Modules[data.module].Options[data.setting]
			if option then
				if option.Type == 'Toggle' then
					option:Toggle(data.state)
				else
					option:SetValue(data.state)
				end
			end
		elseif data.msg == 'readsettings' then
			if vapelite.read then
				vapelite.read:Fire(data.result)
				vapelite.read:Destroy()
			end
		end

		if data.msg ~= 'readsettings' then vapelite:Save() end
	end

	function vapelite.Uninject(tp)
		if web then pcall(function() web:Disconnect() end) end
		vapelite:Save()
		vapelite.Loaded = nil
		for _, v in vapelite.Modules do if v.Enabled then v:Toggle() end end
		for _, v in vapelite.Connections do pcall(function() v:Disconnect() end) end

		shared.vapelite = nil
		if tp then return end
		task.spawn(function()
			repeat task.wait() until game:IsLoaded()
			repeat task.wait(5) until isfile('vapelite.injectable.txt')
			delfile('vapelite.injectable.txt')
			loadstring(readfile('vapelite.lua'))()
		end)
	end

	shared.vapelite = vapelite.Uninject
end)


if game.PlaceId == 6872265039 then
	run(function()
		local function dumpRemote(tab)
			local ind = table.find(tab, 'Client')
			return ind and tab[ind + 1] or ''
		end
		local KnitInit, Knit
		repeat
			KnitInit, Knit = pcall(function()
				return debug.getupvalue(require(lplr.PlayerScripts.TS.knit).setup, 9)
			end)
			if KnitInit then break end
			task.wait(0.1)
		until KnitInit

		if not debug.getupvalue(Knit.Start, 1) then
			repeat task.wait(0.1) until debug.getupvalue(Knit.Start, 1)
		end

		local Flamework = require(replicatedStorage['rbxts_include']['node_modules']['@flamework'].core.out).Flamework
		local InventoryUtil = require(replicatedStorage.TS.inventory['inventory-util']).InventoryUtil
		local Client = require(replicatedStorage.TS.remotes).default.Client
		local OldGet, OldBreak = Client.Get
		local function safeGetProto(func, index)
			if not func then return nil end
			local success, proto = pcall(safeGetProto, func, index)
			if success then
				return proto
			else
				warn("function:", func, "index:", index) 
				return nil
			end
		end

		bedwars = setmetatable({
			MatchHistroyApp = require(lplr.PlayerScripts.TS.controllers.global["match-history"].ui["match-history-moderation-app"]).MatchHistoryModerationApp,
			MatchHistroyController = Knit.Controllers.MatchHistoryController,
			AbilityController = Flamework.resolveDependency('@easy-games/game-core:client/controllers/ability/ability-controller@AbilityController'),
			AnimationType = require(replicatedStorage.TS.animation['animation-type']).AnimationType,
			AnimationUtil = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['game-core'].out['shared'].util['animation-util']).AnimationUtil,
			AppController = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['game-core'].out.client.controllers['app-controller']).AppController,
			BedBreakEffectMeta = require(replicatedStorage.TS.locker['bed-break-effect']['bed-break-effect-meta']).BedBreakEffectMeta,
			BedwarsKitMeta = require(replicatedStorage.TS.games.bedwars.kit['bedwars-kit-meta']).BedwarsKitMeta,
			ClickHold = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['game-core'].out.client.ui.lib.util['click-hold']).ClickHold,
			Client = Client,
			ClientConstructor = require(replicatedStorage['rbxts_include']['node_modules']['@rbxts'].net.out.client),
			MatchHistoryController = require(lplr.PlayerScripts.TS.controllers.global['match-history']['match-history-controller']),
			PlayerProfileUIController = require(lplr.PlayerScripts.TS.controllers.global['player-profile']['player-profile-ui-controller']),
			TitleTypes = require(game.ReplicatedStorage.TS.locker.title['title-type']).TitleType,
			TitleTypesMeta =  require(game.ReplicatedStorage.TS.locker.title['title-meta']).TitleMeta,
			EmoteType = require(replicatedStorage.TS.locker.emote['emote-type']).EmoteType,
			GameAnimationUtil = require(replicatedStorage.TS.animation['animation-util']).GameAnimationUtil,
			NotificationController = Flamework.resolveDependency('@easy-games/game-core:client/controllers/notification-controller@NotificationController'),
			getIcon = function(item, showinv)
				local itemmeta = bedwars.ItemMeta[item.itemType]
				return itemmeta and showinv and itemmeta.image or ''
			end,
			getInventory = function(plr)
				local suc, res = pcall(function()
					return InventoryUtil.getInventory(plr)
				end)
				return suc and res or {
					items = {},
					armor = {}
				}
			end,
			HudAliveCount = require(lplr.PlayerScripts.TS.controllers.global['top-bar'].ui.game['hud-alive-player-counts']).HudAlivePlayerCounts,
			ItemMeta = debug.getupvalue(require(replicatedStorage.TS.item['item-meta']).getItemMeta, 1),
			--KillEffectMeta = require(replicatedStorage.TS.locker['kill-effect']['kill-effect-meta']).KillEffectMeta,
			Knit = Knit,
			KnockbackUtil = require(replicatedStorage.TS.damage['knockback-util']).KnockbackUtil,
			MageKitUtil = require(replicatedStorage.TS.games.bedwars.kit.kits.mage['mage-kit-util']).MageKitUtil,
			NametagController = Knit.Controllers.NametagController,
			PartyController = Flamework.resolveDependency('@easy-games/lobby:client/controllers/party-controller@PartyController'),
			ProjectileMeta = require(replicatedStorage.TS.projectile['projectile-meta']).ProjectileMeta,
			QueryUtil = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['game-core'].out).GameQueryUtil,
			QueueCard = require(lplr.PlayerScripts.TS.controllers.global.queue.ui['queue-card']).QueueCard,
			QueueMeta = require(replicatedStorage.TS.game['queue-meta']).QueueMeta,
			Roact = require(replicatedStorage['rbxts_include']['node_modules']['@rbxts']['roact'].src),
			RuntimeLib = require(replicatedStorage['rbxts_include'].RuntimeLib),
			SoundList = require(replicatedStorage.TS.sound['game-sound']).GameSound,
			--SoundManager = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['game-core'].out).SoundManager,
			Store = require(lplr.PlayerScripts.TS.ui.store).ClientStore,
			TeamUpgradeMeta = debug.getupvalue(require(replicatedStorage.TS.games.bedwars['team-upgrade']['team-upgrade-meta']).getTeamUpgradeMetaForQueue, 6),
			UILayers = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['game-core'].out).UILayers,
			VisualizerUtils = require(lplr.PlayerScripts.TS.lib.visualizer['visualizer-utils']).VisualizerUtils,
			WeldTable = require(replicatedStorage.TS.util['weld-util']).WeldUtil,
			WinEffectMeta = require(replicatedStorage.TS.locker['win-effect']['win-effect-meta']).WinEffectMeta,
			ZapNetworking = require(lplr.PlayerScripts.TS.lib.network),
		}, {
			__index = function(self, ind)
				rawset(self, ind, Knit.Controllers[ind])
				return rawget(self, ind)
			end
		})
	end)
	run(function()
		local Sprint
		local old
		
		Sprint = vapelite:CreateModule({
			Name = 'Sprint',
			Function = function(callback)
				if callback then
					if inputService.TouchEnabled then pcall(function() lplr.PlayerGui.MobileUI['2'].Visible = false end) end
					old = bedwars.SprintController.stopSprinting
					bedwars.SprintController.stopSprinting = function(...)
						local call = old(...)
						bedwars.SprintController:startSprinting()
						return call
					end
					Sprint:Clean(entitylib.Events.LocalAdded:Connect(function() bedwars.SprintController:stopSprinting() end))
					bedwars.SprintController:stopSprinting()
				else
					if inputService.TouchEnabled then pcall(function() lplr.PlayerGui.MobileUI['2'].Visible = true end) end
					bedwars.SprintController.stopSprinting = old
					bedwars.SprintController:stopSprinting()
				end
			end,
			Tooltip = 'Sets your sprinting to true.'
		})
	end)	
	run(function()
		local MHA
		MHA = vapelite:CreateModule({
			Name = "ViewHistory",
			Function = function(callback)
				if callback then
					bedwars.MatchHistroyController:requestMatchHistory(lplr.Name):andThen(function(Data)
						if Data then
							bedwars.AppController:openApp({
								app = bedwars.MatchHistroyApp,
								appId = "MatchHistoryApp",
							}, Data)
						end
					end)
					MHA:Toggle(false)
				else
					return
				end
			end,
			Tooltip = "allows you to see peoples history without being in the same game with you"
		})																								
	end)	
end

table.insert(vapelite.Connections, web.OnMessage:Connect(vapelite.Receive))
table.insert(vapelite.Connections, web.OnClose:Connect(vapelite.Uninject))
table.insert(vapelite.Connections, lplr.OnTeleport:Connect(function() vapelite.Uninject(true) end))
vapelite:Load()
