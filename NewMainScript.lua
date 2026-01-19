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
local entitylib = {
	isAlive = false,
	character = {},
	List = {},
	Events = setmetatable({}, {
		__index = function(self, index)
			self[index] = {
				Connections = {},
				Connect = function(self, func)
					table.insert(self.Connections, func)
					return {
						Disconnect = function()
							local ind = table.find(self.Connections, func)
							if ind then
								table.remove(self.Connections, ind)
								end
							end
						}
					end,
					Fire = function(self, ...)
						for _, v in self.Connections do
							task.spawn(v, ...)
						end
					end,
					Destroy = function(self)
						table.clear(self.Connections)
						table.clear(self)
					end
					}
				return self[index]
		end
	})
}

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

local function addEntity(char)
					repeat task.wait() until char.PrimaryPart
					local humrootpart = char.PrimaryPart
					local head = char:WaitForChild('Head')
					local hum = char:WaitForChild('Humanoid', 5)
					if vapelite.Loaded == nil or not hum or not head then return end
					local plr = playersService:GetPlayerFromCharacter(char)

					if plr then
						local entity = {
							Connections = {},
							Character = char,
							Health = hum.Health,
							Head = head,
							Humanoid = hum,
							HumanoidRootPart = humrootpart,
							HipHeight = hum.HipHeight + (humrootpart.Size.Y / 2) + (hum.RigType == Enum.HumanoidRigType.R6 and 2 or 0),
							MaxHealth = hum.MaxHealth,
							Player = plr,
							RootPart = humrootpart,
							Targetable = true
						}

						if plr == lplr then
							entitylib.character = entity
							entitylib.isAlive = true
							entitylib.Events.LocalAdded:Fire(entity)
						else
							table.insert(entitylib.List, entity)
							for _, v in {'Health', 'MaxHealth'} do
								table.insert(entity.Connections, char:GetAttributeChangedSignal(v):Connect(function()
									entity.Health = (char:GetAttribute('Health') or 100)
									entity.MaxHealth = char:GetAttribute('MaxHealth') or 100
									entitylib.Events.EntityUpdated:Fire(entity)
								end))
							end
							entitylib.Events.EntityAdded:Fire(entity)
							if not plr.Team then
								task.spawn(function()
									repeat task.wait() until plr.Team
									entitylib.Events.EntityRemoved:Fire(entity)
									entitylib.Events.EntityAdded:Fire(entity)
								end)
							end
						end
					end
end

table.insert(vapelite.Connections, collectionService:GetInstanceAddedSignal('inventory-entity'):Connect(addEntity))
table.insert(vapelite.Connections, collectionService:GetInstanceRemovedSignal('inventory-entity'):Connect(function(v)
	local plr = playersService:GetPlayerFromCharacter(v)
	if plr == lplr then
	entitylib.isAlive = false
	entitylib.Events.LocalRemoved:Fire()
	else
						for i, v in entitylib.List do
							if v.Player == plr then
								for _, v in v.Connections do v:Disconnect() end
								table.clear(v.Connections)
								table.remove(entitylib.List, i)
								entitylib.Events.EntityRemoved:Fire(v)
								break
							end
						end
					end
end))
for _, v in collectionService:GetTagged('inventory-entity') do
	task.spawn(addEntity, v)
end

			local function getEntitiesNear(range)
				if entitylib.isAlive then
					local localpos, lteam = entitylib.character.RootPart.Position, lplr:GetAttribute('Team')
					local returned, mag = nil, range
					for _, v in entitylib.List do
						if v.Player:GetAttribute('Team') ~= lteam and v.Health > 0 then
							local newmag = (v.RootPart.Position - localpos).Magnitude
							if newmag <= mag then
								returned, mag = v, newmag
							end
						end
					end
					return returned
				end
			end
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
		local SetFPS
		local FPS
		SetFPS = vapelite:CreateModule({
			Name = "SetFPS",
			Function = function(callback)
				if callback then
					setfpscap(FPS.Value)
				else
					setfpscap(0)
				end
			end,
			Tooltip = "Removes or customizes the Frame-Per-Second limit",
		})
		FPS = SetFPS:CreateSlider({
			Name = "Frames Per Second",
			Min = 0,
			Max = 420,
			Default = 240,
			Function = function(value)
				setfpscap(value)
			end
		})
	end)
elseif game.PlaceId == 6872274481 then
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
			AttackRemote = Knit.Controllers.SwordController.sendServerRequest.instance,
			BalanceFile = require(replicatedStorage.TS.balance["balance-file"]).BalanceFile,
			ClientSyncEvents = require(lplr.PlayerScripts.TS['client-sync-events']).ClientSyncEvents,
			SyncEventPriority = require(replicatedStorage.rbxts_include.node_modules['@easy-games']['sync-event'].out),
			AbilityId = require(replicatedStorage.TS.ability['ability-id']).AbilityId,
			IdUtil = require(replicatedStorage.TS.util['id-util']).IdUtil,
			BlockSelector = require(game:GetService("ReplicatedStorage").rbxts_include.node_modules["@easy-games"]["block-engine"].out.client.select["block-selector"]).BlockSelector,
			KnockbackUtilInstance = replicatedStorage.TS.damage['knockback-util'],
			BedwarsKitSkin = require(replicatedStorage.TS.games.bedwars['kit-skin']['bedwars-kit-skin-meta']).BedwarsKitSkinMeta,
			KitController = Knit.Controllers.KitController,
			FishermanUtil = require(replicatedStorage.TS.games.bedwars.kit.kits.fisherman['fisherman-util']).FishermanUtil,
			FishMeta = require(replicatedStorage.TS.games.bedwars.kit.kits.fisherman['fish-meta']),
			MatchHistroyApp = require(lplr.PlayerScripts.TS.controllers.global["match-history"].ui["match-history-moderation-app"]).MatchHistoryModerationApp,
			MatchHistroyController = Knit.Controllers.MatchHistoryController,
			BlockEngine = require(game:GetService("ReplicatedStorage").rbxts_include.node_modules["@easy-games"]["block-engine"].out).BlockEngine,
			BlockSelectorMode = require(game:GetService("ReplicatedStorage").rbxts_include.node_modules["@easy-games"]["block-engine"].out.client.select["block-selector"]).BlockSelectorMode,
			EntityUtil = require(game:GetService("ReplicatedStorage").TS.entity["entity-util"]).EntityUtil,
			GamePlayer = require(replicatedStorage.TS.player['game-player']),
			OfflinePlayerUtil = require(replicatedStorage.TS.player['offline-player-util']),
			PlayerUtil = require(replicatedStorage.TS.player['player-util']),
			KKKnitController = require(lplr.PlayerScripts.TS.lib.knit['knit-controller']),
			AbilityController = Flamework.resolveDependency('@easy-games/game-core:client/controllers/ability/ability-controller@AbilityController'),
			AnimationType = require(replicatedStorage.TS.animation['animation-type']).AnimationType,
			AnimationUtil = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['game-core'].out['shared'].util['animation-util']).AnimationUtil,
			AppController = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['game-core'].out.client.controllers['app-controller']).AppController,
			BedBreakEffectMeta = require(replicatedStorage.TS.locker['bed-break-effect']['bed-break-effect-meta']).BedBreakEffectMeta,
			BedwarsKitMeta = require(replicatedStorage.TS.games.bedwars.kit['bedwars-kit-meta']).BedwarsKitMeta,
			BlockBreaker = Knit.Controllers.BlockBreakController.blockBreaker,
			BlockController = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['block-engine'].out).BlockEngine,
			BlockEngine = require(lplr.PlayerScripts.TS.lib['block-engine']['client-block-engine']).ClientBlockEngine,
			BlockPlacer = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['block-engine'].out.client.placement['block-placer']).BlockPlacer,
			BowConstantsTable = debug.getupvalue(Knit.Controllers.ProjectileController.enableBeam, 8),
			ClickHold = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['game-core'].out.client.ui.lib.util['click-hold']).ClickHold,
			Client = Client,
			ClientConstructor = require(replicatedStorage['rbxts_include']['node_modules']['@rbxts'].net.out.client),
			ClientDamageBlock = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['block-engine'].out.shared.remotes).BlockEngineRemotes.Client,
			CombatConstant = require(replicatedStorage.TS.combat['combat-constant']).CombatConstant,
			SharedConstants = require(replicatedStorage.TS['shared-constants']),
			DamageIndicator = Knit.Controllers.DamageIndicatorController.spawnDamageIndicator,
			DefaultKillEffect = require(lplr.PlayerScripts.TS.controllers.global.locker['kill-effect'].effects['default-kill-effect']),
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
			MatchHistoryController = require(lplr.PlayerScripts.TS.controllers.global['match-history']['match-history-controller']),
			PlayerProfileUIController = require(lplr.PlayerScripts.TS.controllers.global['player-profile']['player-profile-ui-controller']),
			HudAliveCount = require(lplr.PlayerScripts.TS.controllers.global['top-bar'].ui.game['hud-alive-player-counts']).HudAlivePlayerCounts,
			ItemMeta = debug.getupvalue(require(replicatedStorage.TS.item['item-meta']).getItemMeta, 1),
			KillEffectMeta = require(replicatedStorage.TS.locker['kill-effect']['kill-effect-meta']).KillEffectMeta,
			KillFeedController = Flamework.resolveDependency('client/controllers/game/kill-feed/kill-feed-controller@KillFeedController'),
			Knit = Knit,
			KnockbackUtil = require(replicatedStorage.TS.damage['knockback-util']).KnockbackUtil,
			MageKitUtil = require(replicatedStorage.TS.games.bedwars.kit.kits.mage['mage-kit-util']).MageKitUtil,
			NametagController = Knit.Controllers.NametagController,
			PartyController = Flamework.resolveDependency("@easy-games/lobby:client/controllers/party-controller@PartyController"),
			ProjectileMeta = require(replicatedStorage.TS.projectile['projectile-meta']).ProjectileMeta,
			QueryUtil = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['game-core'].out).GameQueryUtil,
			QueueCard = require(lplr.PlayerScripts.TS.controllers.global.queue.ui['queue-card']).QueueCard,
			QueueMeta = require(replicatedStorage.TS.game['queue-meta']).QueueMeta,
			Roact = require(replicatedStorage['rbxts_include']['node_modules']['@rbxts']['roact'].src),
			RuntimeLib = require(replicatedStorage['rbxts_include'].RuntimeLib),
			SoundList = require(replicatedStorage.TS.sound['game-sound']).GameSound,
			SoundManager = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['game-core'].out.shared.sound['sound-manager']).SoundManager,
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

		local function updateStore(new, old)
			if new.Bedwars ~= old.Bedwars then
				store.equippedKit = new.Bedwars.kit ~= 'none' and new.Bedwars.kit or ''
			end

			if new.Game ~= old.Game then
				store.matchState = new.Game.matchState
				store.queueType = new.Game.queueType or 'bedwars_test'
			end

			if new.Inventory ~= old.Inventory then
				local newinv = (new.Inventory and new.Inventory.observedInventory or {inventory = {}})
				local oldinv = (old.Inventory and old.Inventory.observedInventory or {inventory = {}})
				store.inventory = newinv

				if newinv ~= oldinv then
					LiteVapeEvents.InventoryChanged:Fire()
				end

				if newinv.inventory.items ~= oldinv.inventory.items then
					LiteVapeEvents.InventoryAmountChanged:Fire()
					store.tools.sword = getSword()
					for _, v in {'stone', 'wood', 'wool'} do
						store.tools[v] = getTool(v)
					end
				end

				if newinv.inventory.hand ~= oldinv.inventory.hand then
					local currentHand, toolType = new.Inventory.observedInventory.inventory.hand, ''
					if currentHand then
						local handData = bedwars.ItemMeta[currentHand.itemType]
						toolType = handData.sword and 'sword' or handData.block and 'block' or currentHand.itemType:find('bow') and 'bow'
					end

					store.hand = {
						tool = currentHand and currentHand.tool,
						amount = currentHand and currentHand.amount or 0,
						toolType = toolType
					}
				end
			end
		end

		local swingHook = nil
		local storeChanged = bedwars.Store.changed:connect(updateStore)
		updateStore(bedwars.Store:getState(), {})
			swingHook = bedwars.SwordController.swingSwordAtMouse
				bedwars.SwordController.swingSwordAtMouse = function(...)
					LiteVapeEvents.swingPreEvent:Fire(select(2, ...))
					LiteVapeEvents.swingEvent:Fire(select(2, ...))
					return swingHook(...)
				end	

		table.insert(vapelite.Connections, {Disconnect = function()
					table.clear(bedwars)
					table.clear(store)
					for _, v in entitylib.List do
						for _, v in v.Connections do v:Disconnect() end
						table.clear(v.Connections)
					end
					table.clear(entitylib.List)
					table.clear(entitylib.character)
					table.clear(entitylib)
					bedwars.SwordController.swingSwordAtMouse = swingHook
					table.clear(LiteVapeEvents)
					storeChanged = nil
		end})				
	end)
	run(function()
		local Value
		Reach = vapelite:CreateModule({
			Name = 'Reach',
			Function = function(callback)
				bedwars.CombatConstant.RAYCAST_SWORD_CHARACTER_DISTANCE = callback and Value.Value + 2 or 14.4
			end,
			Tooltip = 'Extends attack reach'
		})
		Value = Reach:CreateSlider({
			Name = 'Range',
			Min = 0,
			Max = 18,
			Default = 18,
			Function = function(val)
				if Reach.Enabled then
					bedwars.CombatConstant.RAYCAST_SWORD_CHARACTER_DISTANCE = val + 2
				end
			end,
			Suffix = function(val)
				return val == 1 and 'stud' or 'studs'
			end
		})
	end)
	run(function()
		local Velocity
		local Horizontal
		local Vertical
		local Chance
		local TargetCheck
		local rand, old = Random.new()
		
		Velocity = vapelite:CreateModule({
			Name = 'Velocity',
			Function = function(callback)
				if callback then
					old = bedwars.KnockbackUtil.applyKnockback
					bedwars.KnockbackUtil.applyKnockback = function(root, mass, dir, knockback, ...)
						if rand:NextNumber(0, 100) > Chance.Value then return end
						knockback = knockback or {}
						if Horizontal.Value == 0 and Vertical.Value == 0 then return end
						knockback.horizontal = (knockback.horizontal or 1) * (Horizontal.Value / 100)
						knockback.vertical = (knockback.vertical or 1) * (Vertical.Value / 100)						
						return old(root, mass, dir, knockback, ...)
					end
				else
					bedwars.KnockbackUtil.applyKnockback = old
				end
			end,
			Tooltip = 'Reduces knockback taken'
		})
		Horizontal = Velocity:CreateSlider({
			Name = 'Horizontal',
			Min = 0,
			Max = 100,
			Default = 0,
			Suffix = '%'
		})
		Vertical = Velocity:CreateSlider({
			Name = 'Vertical',
			Min = 0,
			Max = 100,
			Default = 0,
			Suffix = '%'
		})
		Chance = Velocity:CreateSlider({
			Name = 'Chance',
			Min = 0,
			Max = 100,
			Default = 100,
			Suffix = '%'
		})
	end)
	run(function()
		local AimAssist
		local Range
		local Smoothness
		local Active
		local Vertical
		AimAssist = vapelite:CreateModule({
			Name = 'AimAssist',
			Function = function(callback)
				if callback then
					AimAssist:Clean(runService.RenderStepped:Connect(function(delta)
						if store.hand.Type == 'sword' and (Active.Enabled or (tick() - bedwars.SwordController.lastSwing) < 0.2) then
							local plr = getEntitiesNear(Range.Value)
							if plr and not bedwars.AppController:isLayerOpen(bedwars.UILayers.MAIN) then
								local pos, vis = gameCamera:WorldToViewportPoint(plr.RootPart.Position)
								if vis and isrbxactive() then
									pos = (Vector2.new(pos.X, pos.Y) - inputService:GetMouseLocation()) * ((100 - Smoothness.Value) * delta / 3)
									mousemoverel(pos.X, Vertical.Enabled and pos.Y or 0)
								end
							end
						end
					end))
				end
			end,
			Tooltip = 'Helps you aim at the enemy'
		})
		Range = AimAssist:CreateSlider({
			Name = 'Range',
			Min = 1,
			Max = 30,
			Default = 30
		})
		Smoothness = AimAssist:CreateSlider({
			Name = 'Smoothness',
			Min = 1,
			Max = 100,
			Default = 70
		})
		Active = AimAssist:CreateToggle({Name = 'Always active'})
		Vertical = AimAssist:CreateToggle({Name = 'Vertical aim'})
	end)
	run(function()
		local HitFix
		local PingBased
		local Options = {Value='Blatant'}
		HitFix = vapelite:CreateModule({
			Name = 'HitFix',
			Function = function(callback)
				local function getPing()
					local stats = cloneref(game:GetService("Stats"))
					local ping = stats.Network.ServerStatsItem["Data Ping"]:GetValueString()
					return tonumber(ping:match("%d+")) or 10
				end

				local function getDelay()
					local ping = getPing()

					if PingBased.Enabled then
						if Options.Value == "Blatant" then
							return math.clamp(0.08 + (ping / 1000), 0.08, 0.14)
						else
							return math.clamp(0.11 + (ping / 1200), 0.11, 0.15)
						end
					end

					return Options.Value == "Blatant" and 0.1 or 0.13
				end

				if callback then
					pcall(function()
						if bedwars.SwordController and bedwars.SwordController.swingSwordAtMouse then
							local func = bedwars.SwordController.swingSwordAtMouse

							if Options.Value == "Blatant" then
								debug.setconstant(func, 23, "raycast" or "Raycast")
								debug.setupvalue(func, 4, bedwars.QueryUtil)
							end

							for i, v in ipairs(debug.getconstants(func)) do
								if typeof(v) == "number" and (v == 0.15 or v == 0.1) then
									debug.setconstant(func, i, getDelay())
								end
							end
						end
					end)
				else
					pcall(function()
						if bedwars.SwordController and bedwars.SwordController.swingSwordAtMouse then
							local func = bedwars.SwordController.swingSwordAtMouse

							debug.setconstant(func, 23, "Raycast")
							debug.setupvalue(func, 4, workspace)

							for i, v in ipairs(debug.getconstants(func)) do
								if typeof(v) == "number" then
									if v < 0.15 then
										debug.setconstant(func, i, 0.15)
									end
								end
							end
						end
					end)
				end
			end,
			Tooltip = 'Improves hit registration and decreases the chances of a ghost hit'
		})

		PingBased = HitFix:CreateToggle({
			Name = "Ping Based",
			Default = false,
		})
	end)
	run(function()
				local ESP
				local ESPMethod
				local ESPBoundingBox = {Enabled = true}
				local ESPHealthBar = {Enabled = false}
				local ESPName = {Enabled = true}
				local ESPDisplay = {Enabled = true}
				local ESPBackground = {Enabled = false}
				local ESPFilled = {Enabled = false}
				local ESPTeammates = {Enabled = true}
				local ESPModes = {'2D', '3D', 'Skeleton'}
				local ESPFolder = {}
				local methodused

				local function floorESPPosition(pos)
					return pos // 1
				end

				local function ESPWorldToViewport(pos)
					local newpos = gameCamera:WorldToViewportPoint(gameCamera.CFrame:pointToWorldSpace(gameCamera.CFrame:pointToObjectSpace(pos)))
					return Vector2.new(newpos.X, newpos.Y)
				end

				local ESPAdded = {
					Drawing2D = function(ent)
						if ESPTeammates.Enabled and (not ent.Targetable) and (not ent.Friend) then return end
						local EntityESP = {}
						EntityESP.Main = Drawing.new('Square')
						EntityESP.Main.Transparency = ESPBoundingBox.Enabled and 1 or 0
						EntityESP.Main.ZIndex = 2
						EntityESP.Main.Filled = false
						EntityESP.Main.Thickness = 1
						EntityESP.Main.Color = ent.Player.TeamColor.Color
						EntityESP.Border = Drawing.new('Square')
						EntityESP.Border.Transparency = ESPBoundingBox.Enabled and 0.35 or 0
						EntityESP.Border.ZIndex = 1
						EntityESP.Border.Thickness = 1
						EntityESP.Border.Filled = false
						EntityESP.Border.Color = Color3.new()
						EntityESP.Border2 = Drawing.new('Square')
						EntityESP.Border2.Transparency = ESPBoundingBox.Enabled and 0.35 or 0
						EntityESP.Border2.ZIndex = 1
						EntityESP.Border2.Thickness = 1
						EntityESP.Border2.Filled = ESPFilled.Enabled
						EntityESP.Border2.Color = Color3.new()
						if ESPHealthBar.Enabled then
							EntityESP.HealthLine = Drawing.new('Line')
							EntityESP.HealthLine.Thickness = 1
							EntityESP.HealthLine.ZIndex = 2
							EntityESP.HealthLine.Color = Color3.fromHSV(math.clamp(ent.Health / ent.MaxHealth, 0, 1) / 2.5, 0.89, 0.75)
							EntityESP.HealthBorder = Drawing.new('Line')
							EntityESP.HealthBorder.Thickness = 3
							EntityESP.HealthBorder.Transparency = 0.35
							EntityESP.HealthBorder.ZIndex = 1
							EntityESP.HealthBorder.Color = Color3.new()
						end
						if ESPName.Enabled then
							if ESPBackground.Enabled then
								EntityESP.TextBKG = Drawing.new('Square')
								EntityESP.TextBKG.Transparency = 0.35
								EntityESP.TextBKG.ZIndex = 0
								EntityESP.TextBKG.Thickness = 1
								EntityESP.TextBKG.Filled = true
								EntityESP.TextBKG.Color = Color3.new()
							end
							EntityESP.Drop = Drawing.new('Text')
							EntityESP.Drop.Color = Color3.new()
							EntityESP.Drop.Text = ent.Player and (ESPDisplay.Enabled and ent.Player.DisplayName or ent.Player.Name) or ent.Character.Name
							EntityESP.Drop.ZIndex = 1
							EntityESP.Drop.Center = true
							EntityESP.Drop.Size = 20
							EntityESP.Text = Drawing.new('Text')
							EntityESP.Text.Text = EntityESP.Drop.Text
							EntityESP.Text.ZIndex = 2
							EntityESP.Text.Color = EntityESP.Main.Color
							EntityESP.Text.Center = true
							EntityESP.Text.Size = 20
						end
						ESPFolder[ent] = EntityESP
					end,
					Drawing3D = function(ent)
						if ESPTeammates.Enabled and (not ent.Targetable) and (not ent.Friend) then return end
						local EntityESP = {}
						EntityESP.Line1 = Drawing.new('Line')
						EntityESP.Line2 = Drawing.new('Line')
						EntityESP.Line3 = Drawing.new('Line')
						EntityESP.Line4 = Drawing.new('Line')
						EntityESP.Line5 = Drawing.new('Line')
						EntityESP.Line6 = Drawing.new('Line')
						EntityESP.Line7 = Drawing.new('Line')
						EntityESP.Line8 = Drawing.new('Line')
						EntityESP.Line9 = Drawing.new('Line')
						EntityESP.Line10 = Drawing.new('Line')
						EntityESP.Line11 = Drawing.new('Line')
						EntityESP.Line12 = Drawing.new('Line')
						local color = ent.Player.TeamColor.Color
						for _, v in EntityESP do v.Thickness = 1 v.Color = color end
						ESPFolder[ent] = EntityESP
					end,
					DrawingSkeleton = function(ent)
						if ESPTeammates.Enabled and (not ent.Targetable) and (not ent.Friend) then return end
						local EntityESP = {}
						EntityESP.Head = Drawing.new('Line')
						EntityESP.HeadFacing = Drawing.new('Line')
						EntityESP.Torso = Drawing.new('Line')
						EntityESP.UpperTorso = Drawing.new('Line')
						EntityESP.LowerTorso = Drawing.new('Line')
						EntityESP.LeftArm = Drawing.new('Line')
						EntityESP.RightArm = Drawing.new('Line')
						EntityESP.LeftLeg = Drawing.new('Line')
						EntityESP.RightLeg = Drawing.new('Line')
						local color = ent.Player.TeamColor.Color
						for _, v in EntityESP do v.Thickness = 2 v.Color = color end
						ESPFolder[ent] = EntityESP
					end
				}

				local ESPRemoved = {
					Drawing2D = function(ent)
						local EntityESP = ESPFolder[ent]
						if EntityESP then
							ESPFolder[ent] = nil
							for _, v in EntityESP do
								pcall(function()
									v.Visible = false
									v:Remove()
								end)
							end
						end
					end
				}
				ESPRemoved.Drawing3D = ESPRemoved.Drawing2D
				ESPRemoved.DrawingSkeleton = ESPRemoved.Drawing2D

				local ESPUpdated = {
					Drawing2D = function(ent)
						local EntityESP = ESPFolder[ent]
						if EntityESP then
							if EntityESP.HealthLine then
								EntityESP.HealthLine.Color = Color3.fromHSV(math.clamp(ent.Health / ent.MaxHealth, 0, 1) / 2.5, 0.89, 0.75)
							end
							if EntityESP.Text then
								EntityESP.Text.Text = ent.Player and (ESPDisplay.Enabled and ent.Player.DisplayName or ent.Player.Name) or ent.Character.Name
								EntityESP.Drop.Text = EntityESP.Text.Text
							end
						end
					end
				}

				local ESPLoop = {
					Drawing2D = function()
						for ent, EntityESP in ESPFolder do
							local rootPos, rootVis = gameCamera:WorldToViewportPoint(ent.RootPart.Position)
							for _, obj in EntityESP do obj.Visible = rootVis end
							if not rootVis then continue end
							local topPos, topVis = gameCamera:WorldToViewportPoint((CFrame.new(ent.RootPart.Position, ent.RootPart.Position + gameCamera.CFrame.LookVector) * CFrame.new(2, ent.HipHeight, 0)).p)
							local bottomPos, bottomVis = gameCamera:WorldToViewportPoint((CFrame.new(ent.RootPart.Position, ent.RootPart.Position + gameCamera.CFrame.LookVector) * CFrame.new(-2, -ent.HipHeight - 1, 0)).p)
							local sizex, sizey = topPos.X - bottomPos.X, topPos.Y - bottomPos.Y
							local posx, posy = (rootPos.X - sizex / 2),  ((rootPos.Y - sizey / 2))
							EntityESP.Main.Position = floorESPPosition(Vector2.new(posx, posy))
							EntityESP.Main.Size = floorESPPosition(Vector2.new(sizex, sizey))
							EntityESP.Border.Position = floorESPPosition(Vector2.new(posx - 1, posy + 1))
							EntityESP.Border.Size = floorESPPosition(Vector2.new(sizex + 2, sizey - 2))
							EntityESP.Border2.Position = floorESPPosition(Vector2.new(posx + 1, posy - 1))
							EntityESP.Border2.Size = floorESPPosition(Vector2.new(sizex - 2, sizey + 2))
							if EntityESP.HealthLine then
								local healthposy = sizey * math.clamp(ent.Health / ent.MaxHealth, 0, 1)
								EntityESP.HealthLine.Visible = ent.Health > 0
								EntityESP.HealthLine.From = floorESPPosition(Vector2.new(posx - 6, posy + (sizey - (sizey - healthposy))))
								EntityESP.HealthLine.To = floorESPPosition(Vector2.new(posx - 6, posy))
								EntityESP.HealthBorder.From = floorESPPosition(Vector2.new(posx - 6, posy + 1))
								EntityESP.HealthBorder.To = floorESPPosition(Vector2.new(posx - 6, (posy + sizey) - 1))
							end
							if EntityESP.Text then
								EntityESP.Text.Position = floorESPPosition(Vector2.new(posx + (sizex / 2), posy + (sizey - 28)))
								EntityESP.Drop.Position = EntityESP.Text.Position + Vector2.new(1, 1)
								if EntityESP.TextBKG then
									EntityESP.TextBKG.Size = EntityESP.Text.TextBounds + Vector2.new(8, 4)
									EntityESP.TextBKG.Position = EntityESP.Text.Position - Vector2.new(4 + (EntityESP.Text.TextBounds.X / 2), 0)
								end
							end
						end
					end,
					Drawing3D = function()
						for ent, EntityESP in ESPFolder do
							local rootPos, rootVis = gameCamera:WorldToViewportPoint(ent.RootPart.Position)
							for _, obj in EntityESP do obj.Visible = rootVis end
							if not rootVis then continue end
							local point1 = ESPWorldToViewport(ent.RootPart.Position + Vector3.new(1.5, ent.HipHeight, 1.5))
							local point2 = ESPWorldToViewport(ent.RootPart.Position + Vector3.new(1.5, -ent.HipHeight, 1.5))
							local point3 = ESPWorldToViewport(ent.RootPart.Position + Vector3.new(-1.5, ent.HipHeight, 1.5))
							local point4 = ESPWorldToViewport(ent.RootPart.Position + Vector3.new(-1.5, -ent.HipHeight, 1.5))
							local point5 = ESPWorldToViewport(ent.RootPart.Position + Vector3.new(1.5, ent.HipHeight, -1.5))
							local point6 = ESPWorldToViewport(ent.RootPart.Position + Vector3.new(1.5, -ent.HipHeight, -1.5))
							local point7 = ESPWorldToViewport(ent.RootPart.Position + Vector3.new(-1.5, ent.HipHeight, -1.5))
							local point8 = ESPWorldToViewport(ent.RootPart.Position + Vector3.new(-1.5, -ent.HipHeight, -1.5))
							EntityESP.Line1.From = point1
							EntityESP.Line1.To = point2
							EntityESP.Line2.From = point3
							EntityESP.Line2.To = point4
							EntityESP.Line3.From = point5
							EntityESP.Line3.To = point6
							EntityESP.Line4.From = point7
							EntityESP.Line4.To = point8
							EntityESP.Line5.From = point1
							EntityESP.Line5.To = point3
							EntityESP.Line6.From = point1
							EntityESP.Line6.To = point5
							EntityESP.Line7.From = point5
							EntityESP.Line7.To = point7
							EntityESP.Line8.From = point7
							EntityESP.Line8.To = point3
							EntityESP.Line9.From = point2
							EntityESP.Line9.To = point4
							EntityESP.Line10.From = point2
							EntityESP.Line10.To = point6
							EntityESP.Line11.From = point6
							EntityESP.Line11.To = point8
							EntityESP.Line12.From = point8
							EntityESP.Line12.To = point4
						end
					end,
					DrawingSkeleton = function()
						for ent, EntityESP in ESPFolder do
							local rootPos, rootVis = gameCamera:WorldToViewportPoint(ent.RootPart.Position)
							for _, obj in EntityESP do obj.Visible = rootVis end
							if not rootVis then continue end
							local rigcheck = ent.Humanoid.RigType == Enum.HumanoidRigType.R6
							pcall(function() -- kill me
								local offset = rigcheck and CFrame.new(0, -0.8, 0) or CFrame.new()
								local head = ESPWorldToViewport((ent.Head.CFrame).p)
								local headfront = ESPWorldToViewport((ent.Head.CFrame * CFrame.new(0, 0, -0.5)).p)
								local toplefttorso = ESPWorldToViewport((ent.Character[(rigcheck and 'Torso' or 'UpperTorso')].CFrame * CFrame.new(-1.5, 0.8, 0)).p)
								local toprighttorso = ESPWorldToViewport((ent.Character[(rigcheck and 'Torso' or 'UpperTorso')].CFrame * CFrame.new(1.5, 0.8, 0)).p)
								local toptorso = ESPWorldToViewport((ent.Character[(rigcheck and 'Torso' or 'UpperTorso')].CFrame * CFrame.new(0, 0.8, 0)).p)
								local bottomtorso = ESPWorldToViewport((ent.Character[(rigcheck and 'Torso' or 'UpperTorso')].CFrame * CFrame.new(0, -0.8, 0)).p)
								local bottomlefttorso = ESPWorldToViewport((ent.Character[(rigcheck and 'Torso' or 'UpperTorso')].CFrame * CFrame.new(-0.5, -0.8, 0)).p)
								local bottomrighttorso = ESPWorldToViewport((ent.Character[(rigcheck and 'Torso' or 'UpperTorso')].CFrame * CFrame.new(0.5, -0.8, 0)).p)
								local leftarm = ESPWorldToViewport((ent.Character[(rigcheck and 'Left Arm' or 'LeftHand')].CFrame * offset).p)
								local rightarm = ESPWorldToViewport((ent.Character[(rigcheck and 'Right Arm' or 'RightHand')].CFrame * offset).p)
								local leftleg = ESPWorldToViewport((ent.Character[(rigcheck and 'Left Leg' or 'LeftFoot')].CFrame * offset).p)
								local rightleg = ESPWorldToViewport((ent.Character[(rigcheck and 'Right Leg' or 'RightFoot')].CFrame * offset).p)
								EntityESP.Head.From = toptorso
								EntityESP.Head.To = head
								EntityESP.HeadFacing.From = head
								EntityESP.HeadFacing.To = headfront
								EntityESP.UpperTorso.From = toplefttorso
								EntityESP.UpperTorso.To = toprighttorso
								EntityESP.Torso.From = toptorso
								EntityESP.Torso.To = bottomtorso
								EntityESP.LowerTorso.From = bottomlefttorso
								EntityESP.LowerTorso.To = bottomrighttorso
								EntityESP.LeftArm.From = toplefttorso
								EntityESP.LeftArm.To = leftarm
								EntityESP.RightArm.From = toprighttorso
								EntityESP.RightArm.To = rightarm
								EntityESP.LeftLeg.From = bottomlefttorso
								EntityESP.LeftLeg.To = leftleg
								EntityESP.RightLeg.From = bottomrighttorso
								EntityESP.RightLeg.To = rightleg
							end)
						end
					end
				}

				ESP = vapelite:CreateModule({
					Name = 'ESP',
					Function = function(callback)
						if callback then
							methodused = 'Drawing'..ESPModes[ESPMethod.Value]
							if ESPRemoved[methodused] then
								ESP:Clean(entitylib.Events.EntityRemoved:Connect(ESPRemoved[methodused]))
							end
							if ESPAdded[methodused] then
								for _, v in entitylib.List do
									if ESPFolder[v] then ESPRemoved[methodused](v) end
									ESPAdded[methodused](v)
								end
								ESP:Clean(entitylib.Events.EntityAdded:Connect(function(ent)
									if ESPFolder[ent] then ESPRemoved[methodused](ent) end
									ESPAdded[methodused](ent)
								end))
							end
							if ESPUpdated[methodused] then
								ESP:Clean(entitylib.Events.EntityUpdated:Connect(ESPUpdated[methodused]))
								for _, v in entitylib.List do ESPUpdated[methodused](v) end
							end
							if ESPLoop[methodused] then
								ESP:Clean(runService.RenderStepped:Connect(ESPLoop[methodused]))
							end
						else
							if ESPRemoved[methodused] then
								for i in ESPFolder do ESPRemoved[methodused](i) end
							end
						end
					end,
					Tooltip = 'Renders an ESP on players.'
				})
				ESPMethod = ESP:CreateSlider({
					Name = 'Mode',
					Min = 1,
					Max = #ESPModes,
					Function = function() if ESP.Enabled then ESP:Toggle() ESP:Toggle() end end
				})
				ESPBoundingBox = ESP:CreateToggle({
					Name = 'Bounding Box',
					Function = function() if ESP.Enabled then ESP:Toggle() ESP:Toggle() end end,
					Default = true
				})
				ESPHealthBar = ESP:CreateToggle({
					Name = 'Health Bar',
					Function = function() if ESP.Enabled then ESP:Toggle() ESP:Toggle() end end
				})
				ESPName = ESP:CreateToggle({
					Name = 'Name',
					Function = function() if ESP.Enabled then ESP:Toggle() ESP:Toggle() end end
				})
				ESPDisplay = ESP:CreateToggle({
					Name = 'Use Displayname',
					Function = function() if ESP.Enabled then ESP:Toggle() ESP:Toggle() end end,
					Default = true
				})
				ESPBackground = ESP:CreateToggle({
					Name = 'Show Background',
					Function = function() if ESP.Enabled then ESP:Toggle() ESP:Toggle() end end
				})
				ESPFilled = ESP:CreateToggle({
					Name = 'Filled',
					Function = function() if ESP.Enabled then ESP:Toggle() ESP:Toggle() end end
				})
				ESPTeammates = ESP:CreateToggle({
					Name = 'Priority Only',
					Function = function() if ESP.Enabled then ESP:Toggle() ESP:Toggle() end end,
					Default = true
				})
	end)
	run(function()
				local NameTags = {Enabled = false}
				local NameTagsBackground = {Value = 5}
				local NameTagsDisplayName = {Enabled = false}
				local NameTagsHealth = {Enabled = false}
				local NameTagsDistance = {Enabled = false}
				local NameTagsScale = {Value = 10}
				local NameTagsFont = {Value = 1}
				local NameTagsTeammates = {Enabled = true}
				local NameTagsStrings = {}
				local NameTagsSizes = {}
				local NameTagsDrawingFolder = {}
				local fontitems = {'Arial'}

				local NameTagAdded = function(ent)
					if NameTagsTeammates.Enabled and (not ent.Targetable) and (not ent.Friend) then return end
					local EntityNameTag = {}
					EntityNameTag.BG = Drawing.new('Square')
					EntityNameTag.BG.Filled = true
					EntityNameTag.BG.Transparency = 1 - (NameTagsBackground.Value / 10)
					EntityNameTag.BG.Color = Color3.new()
					EntityNameTag.BG.ZIndex = 1
					EntityNameTag.Text = Drawing.new('Text')
					EntityNameTag.Text.Size = 15 * (NameTagsScale.Value / 10)
					EntityNameTag.Text.Font = 1
					EntityNameTag.Text.ZIndex = 2
					NameTagsStrings[ent] = ent.Player and (NameTagsDisplayName.Enabled and ent.Player.DisplayName or ent.Player.Name) or ent.Character.Name
					if NameTagsHealth.Enabled then
						local color = Color3.fromHSV(math.clamp(ent.Health / ent.MaxHealth, 0, 1) / 2.5, 0.89, 0.75)
						NameTagsStrings[ent] = NameTagsStrings[ent]..' '..math.round(ent.Health)
					end
					if NameTagsDistance.Enabled then
						NameTagsStrings[ent] = '[%s] '..NameTagsStrings[ent]
					end
					EntityNameTag.Text.Text = NameTagsStrings[ent]
					EntityNameTag.Text.Color = ent.Player.TeamColor.Color
					EntityNameTag.BG.Size = Vector2.new(EntityNameTag.Text.TextBounds.X + 8, EntityNameTag.Text.TextBounds.Y + 7)
					NameTagsDrawingFolder[ent] = EntityNameTag
				end


				local NameTagRemoved = function(ent)
					local v = NameTagsDrawingFolder[ent]
					if v then
						NameTagsDrawingFolder[ent] = nil
						NameTagsStrings[ent] = nil
						NameTagsSizes[ent] = nil
						for _, v2 in v do
							pcall(function() v2.Visible = false v2:Remove() end)
						end
					end
				end


				local NameTagUpdated = function(ent)
					local EntityNameTag = NameTagsDrawingFolder[ent]
					if EntityNameTag then
						NameTagsSizes[ent] = nil
						NameTagsStrings[ent] = ent.Player and (NameTagsDisplayName.Enabled and ent.Player.DisplayName or ent.Player.Name) or ent.Character.Name
						if NameTagsHealth.Enabled then
							NameTagsStrings[ent] = NameTagsStrings[ent]..' '..math.round(ent.Health)
						end
						if NameTagsDistance.Enabled then
							NameTagsStrings[ent] = '[%s] '..NameTagsStrings[ent]
							EntityNameTag.Text.Text = entitylib.isAlive and string.format(NameTagsStrings[ent], math.floor((entitylib.character.RootPart.Position - ent.RootPart.Position).Magnitude)) or NameTagsStrings[ent]
						else
							EntityNameTag.Text.Text = NameTagsStrings[ent]
						end
						EntityNameTag.BG.Size = Vector2.new(EntityNameTag.Text.TextBounds.X + 8, EntityNameTag.Text.TextBounds.Y + 7)
						EntityNameTag.Text.Color = ent.Player.TeamColor.Color
					end
				end


				local NameTagLoop = function()
					for ent, EntityNameTag in NameTagsDrawingFolder do
						local headPos, headVis = gameCamera:WorldToScreenPoint(ent.RootPart.Position + Vector3.new(0, ent.HipHeight + 1, 0))
						EntityNameTag.Text.Visible = headVis
						EntityNameTag.BG.Visible = headVis
						if not headVis then
							continue
						end
						if NameTagsDistance.Enabled and entitylib.isAlive then
							local mag = math.floor((entitylib.character.RootPart.Position - ent.RootPart.Position).Magnitude)
							if NameTagsSizes[ent] ~= mag then
								EntityNameTag.Text.Text = string.format(NameTagsStrings[ent], mag)
								EntityNameTag.BG.Size = Vector2.new(EntityNameTag.Text.TextBounds.X + 8, EntityNameTag.Text.TextBounds.Y + 7)
								NameTagsSizes[ent] = mag
							end
						end
						EntityNameTag.BG.Position = Vector2.new(headPos.X - (EntityNameTag.BG.Size.X / 2), headPos.Y + (EntityNameTag.BG.Size.Y / 2))
						EntityNameTag.Text.Position = EntityNameTag.BG.Position + Vector2.new(4, 2.5)
					end
				end


				NameTags = vapelite:CreateModule({
					Name = 'NameTags',
					Function = function(callback)
						if callback then
							NameTags:Clean(entitylib.Events.EntityRemoved:Connect(NameTagRemoved))
							for _, v in entitylib.List do
								if NameTagsDrawingFolder[v] then NameTagRemoved(v) end
								NameTagAdded(v)
								NameTagUpdated(v)
							end
							NameTags:Clean(entitylib.Events.EntityAdded:Connect(function(ent)
								if NameTagsDrawingFolder[ent] then NameTagRemoved(ent) end
								NameTagAdded(ent)
							end))
							NameTags:Clean(entitylib.Events.EntityUpdated:Connect(NameTagUpdated))
							NameTags:Clean(runService.RenderStepped:Connect(NameTagLoop))
						else
							for i in NameTagsDrawingFolder do NameTagRemoved(i) end
						end
					end,
					Tooltip = 'Renders nametags on entities through walls.'
				})
				NameTagsFont = NameTags:CreateSlider({
					Name = 'Font',
					Function = function() if NameTags.Enabled then NameTags:Toggle() NameTags:Toggle() end end,
					Min = 1,
					Max = 3
				})
				NameTagsScale = NameTags:CreateSlider({
					Name = 'Scale',
					Function = function() if NameTags.Enabled then NameTags:Toggle() NameTags:Toggle() end end,
					Default = 10,
					Min = 1,
					Max = 15
				})
				NameTagsBackground = NameTags:CreateSlider({
					Name = 'Transparency',
					Function = function() if NameTags.Enabled then NameTags:Toggle() NameTags:Toggle() end end,
					Default = 5,
					Min = 0,
					Max = 10
				})
				NameTagsHealth = NameTags:CreateToggle({
					Name = 'Health',
					Function = function() if NameTags.Enabled then NameTags:Toggle() NameTags:Toggle() end end
				})
				NameTagsDistance = NameTags:CreateToggle({
					Name = 'Distance',
					Function = function() if NameTags.Enabled then NameTags:Toggle() NameTags:Toggle() end end
				})
				NameTagsDisplayName = NameTags:CreateToggle({
					Name = 'Use Displayname',
					Function = function() if NameTags.Enabled then NameTags:Toggle() NameTags:Toggle() end end,
					Default = true
				})
				NameTagsTeammates = NameTags:CreateToggle({
					Name = 'Priority Only',
					Function = function() if NameTags.Enabled then NameTags:Toggle() NameTags:Toggle() end end,
					Default = true
				})
	end)
	run(function()
		local RemoveStatus
		local old
		RemoveStatus = vapelite:CreateModule({
			Name = "RemoveStatus",
			Tooltip = 'removes them annoying ass effects on ur screen(like that static thingy or being glooped)',
			Function = function(callback)
				if callback then
					old = bedwars.VignetteController.createVignette
					bedwars.VignetteController.createVignette = function(...)
						return nil
					end
				else
					bedwars.VignetteController.createVignette = old
					old = nil
				end
			end
		})
	end)
	run(function()
		local Lobby
		Lobby = vapelite:CreateModule({
			Name = 'Lobby',
			Tooltip = 'allows you to lobby if u dont have access to the chat(like me not letting jews get my face)',
			Function = function(callback)
				if not callback then
					return
				end
				Lobby:Toggle(false)
				local s,err = pcall(function()
					bedwars.Client:Get("TeleportToLobby"):SendToServer()
				end)
				if not s then
					warn(err)
					task.wait(8)
					lobby()
				end
			end
		})
	end)
	run(function()
		local TaxRemover
		local old
		TaxRemover = vapelite:CreateModule({
			Name = 'TaxRemover',
			Function = function(callback)
				if callback then
					old = bedwars.Store.dispatch
					bedwars.Store.dispatch = function(...)
						local arg = select(2, ...)
						if arg and typeof(arg) == 'table' and arg.type == 'IncrementTaxState' then
							return nil
						end 	
						return old(...)
					end
				else
					bedwars.Store.dispatch = old
					old = nil
				end
			end
		})
	end)
	run(function()
		local TriggerBot
		local CPS
		local rayParams = RaycastParams.new()
		local BowCheck
		local function isHoldingProjectile()
			if not store.hand or not store.hand.tool then return false end
			local toolName = store.hand.tool.Name
			if toolName == "headhunter" then
				return true
			end
			if toolName:lower():find("headhunter") then
				return true
			end
			if toolName:lower():find("bow") then
				return true
			end
			if toolName:lower():find("crossbow") then
				return true
			end
			local toolMeta = bedwars.ItemMeta[toolName]
			if toolMeta and toolMeta.projectileSource then
				return true
			end
			return false
		end
		TriggerBot = vapelite:CreateModule({
			Name = 'TriggerBot',
			Function = function(callback)
				if callback then
					repeat
						local doAttack
						if not bedwars.AppController:isLayerOpen(bedwars.UILayers.MAIN) then
							if entitylib.isAlive and store.hand.toolType == 'sword' and bedwars.DaoController.chargingMaid == nil then
								local attackRange = bedwars.ItemMeta[store.hand.tool.Name].sword.attackRange
								rayParams.FilterDescendantsInstances = {lplr.Character}
		
								local unit = lplr:GetMouse().UnitRay
								local localPos = entitylib.character.RootPart.Position
								local rayRange = (attackRange or 14.4)
								local ray = bedwars.QueryUtil:raycast(unit.Origin, unit.Direction * 200, rayParams)
								if ray and (localPos - ray.Instance.Position).Magnitude <= rayRange then
									local limit = (attackRange)
									for _, ent in entitylib.List do
										doAttack = ent.Targetable and ray.Instance:IsDescendantOf(ent.Character) and (localPos - ent.RootPart.Position).Magnitude <= rayRange
										if doAttack then
											break
										end
									end
								end
		
								doAttack = doAttack or bedwars.SwordController:getTargetInRegion(attackRange or 3.8 * 3, 0)
								if doAttack then
									bedwars.SwordController:swingSwordAtMouse()
								end
							end
							if BowCheck.Enabled then
								if isHoldingProjectile() then
									local attackRange = 23
									rayParams.FilterDescendantsInstances = {lplr.Character}
			
									local unit = lplr:GetMouse().UnitRay
									local localPos = entitylib.character.RootPart.Position
									local rayRange = (attackRange)
									local ray = bedwars.QueryUtil:raycast(unit.Origin, unit.Direction * 200, rayParams)
									if ray and (localPos - ray.Instance.Position).Magnitude <= rayRange then
										local limit = (attackRange)
										for _, ent in entitylib.List do
											doAttack = ent.Targetable and ray.Instance:IsDescendantOf(ent.Character) and (localPos - ent.RootPart.Position).Magnitude <= rayRange
											if doAttack then
												break
											end
										end
									end
			
									doAttack = doAttack or bedwars.SwordController:getTargetInRegion(attackRange or 3.8 * 3, 0)
									if doAttack then
										mouse1click()
									end
								end
							end
						end
		
						task.wait(doAttack and 1 / CPS.GetRandomValue() or 0.016)
					until not TriggerBot.Enabled
				end
			end,
			Tooltip = 'Automatically swings when hovering over a entity'
		})
		CPS = TriggerBot:CreateTwoSlider({
			Name = 'CPS',
			Min = 1,
			Max = 36,
			DefaultMin = 7,
			DefaultMax = 7
		})
		BowCheck = TriggerBot:CreateToggle({Name='Bow Check'})
	end)
	run(function()
		local RemoveHitHighlight
		RemoveHitHighlight = vapelite:CreateModule({
			Name = "RemoveHitHighlight",
			Function = function(callback)
				repeat
					for i, v in entitylib.List do 
						local highlight = v.Character and v.Character:FindFirstChild('_DamageHighlight_')
						if highlight then 
							highlight:Destroy()
						end
					end
					task.wait(0.1)
				until not RemoveHitHighlight.Enabled
			end
		})
	end)
	run(function()
				local AttackRange
				local AutoCharge = {Enabled=false}
				local Angle
				local Moving
				local AttackRemote
				task.spawn(function()
					AttackRemote = bedwars.AttackRemote
				end)

				Killaura = vapelite:CreateModule({
					Name = 'Killaura',
					Function = function(callback)
							local animTime = os.clock()
							Killaura:Clean(swingEvent.Event:Connect(function(chargeRatio)
								local plr = getEntitiesNear(AttackRange.Value)
								if plr and store.hand.Type == 'sword' then
									if not bedwars.SwordController:canSee({getInstance = function() return plr.Character end}) then return end
									local selfrootpos = entitylib.character.RootPart.Position
									local localfacing = entitylib.character.RootPart.CFrame.LookVector

									local delta = (plr.RootPart.Position - selfrootpos)
									local angle = math.acos(localfacing:Dot((delta * Vector3.new(1, 0, 1)).Unit))
									if angle > (math.rad(Angle.Value) / 2) then return end
									if Moving.Enabled and entitylib.character.RootPart.Velocity.Magnitude < 3 then return end

									local swingDelta = workspace:GetServerTimeNow() - bedwars.SwordController.lastSwingServerTime
									local targetTime = AutoChargeTime.Value / 100
									if delta.Magnitude < 14.4 and AutoCharge.Enabled and (os.clock() - chargeSwingTime) < targetTime then return end
									canSwing = true
									chargeSwingTime = os.clock()


									AttackRemote:SendToServer({
										weapon = store.hand.tool,
										chargedAttack = {chargeRatio = 0},
										entityInstance = plr.Character,
										validate = {
											raycast = {
												cameraPosition = {value = gameCamera.CFrame.Position},
												cursorDirection = {value = CFrame.lookAt(gameCamera.CFrame.Position, plr.RootPart.Position).LookVector}
											},
											targetPosition = {value = plr.RootPart.Position},
											selfPosition = {value = selfrootpos + CFrame.lookAt(selfrootpos, plr.RootPart.Position).LookVector * math.max(delta.Magnitude - 14.399, 0)}
										}
									})
								end
							end))
						end
					end,
					Tooltip = 'Attack players around you without aiming at them.'
				})
				AttackRange = Killaura:CreateSlider({
					Name = 'Attack range',
					Min = 1,
					Max = 22,
					Default = 22
				})
				Angle = Killaura:CreateSlider({
					Name = 'Max angle',
					Min = 1,
					Max = 360,
					Default = 100
				})
				Moving = Killaura:CreateToggle({Name = 'Only while moving'})
			end)
end

table.insert(vapelite.Connections, web.OnMessage:Connect(vapelite.Receive))
table.insert(vapelite.Connections, web.OnClose:Connect(vapelite.Uninject))
table.insert(vapelite.Connections, lplr.OnTeleport:Connect(function() vapelite.Uninject(true) end))
vapelite:Load()
