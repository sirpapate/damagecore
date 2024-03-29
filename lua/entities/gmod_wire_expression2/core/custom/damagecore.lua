local function isFriend(owner, player)
	if owner == player then
		return true
	end

    if CPPI then
		for _, friend in pairs(player:CPPIGetFriends()) do
			if friend == owner then
				return true
			end
		end

		return false
    else
        return E2Lib.isFriend(owner, player)
    end
end


local function isOwner(chip, entity, canTargetPlayers)
    if CPPI then
		if entity:IsPlayer() and canTargetPlayers then
			return isFriend(chip.player, entity)
		else
	        return entity:CPPICanTool(chip.player, "wire_expression2")
		end
    else
        return E2Lib.isOwner(chip, entity)
    end
end


E2Lib.RegisterExtension("damagecore", true)

local damageType = {
	"DMG_GENERIC",
	"DMG_CRUSH",
	"DMG_BULLET",
	"DMG_SLASH",
	"DMG_BURN",
	"DMG_VEHICLE",
	"DMG_FALL",
	"DMG_BLAST",
	"DMG_CLUB",
	"DMG_SHOCK",
	"DMG_SONIC",
	"DMG_ENERGYBEAM",
	"DMG_NEVERGIB",
	"DMG_ALWAYSGIB",
	"DMG_DROWN",
	"DMG_PARALYZE",
	"DMG_NERVEGAS",
	"DMG_POISON",
	"DMG_ACID",
	"DMG_AIRBOAT",
	"DMG_BLAST_SURFACE",
	"DMG_BUCKSHOT",
	"DMG_DIRECT",
	"DMG_DISSOLVE",
	"DMG_DROWNRECOVER",
	"DMG_PHYSGUN",
	"DMG_PLASMA",
	"DMG_PREVENT_PHYSICS_FORCE",
	"DMG_RADIATION",
	"DMG_REMOVENORAGDOLL",
	"DMG_SLOWBURN"
}

local valid_damage_type = {}

for _,cname in pairs(damageType) do
	local value = _G[cname]
	valid_damage_type[value] = true
	E2Lib.registerConstant(cname, value)
end

local DEFAULT = {
	AmmoType         	= 0,
	Attacker         	= NULL,
	Victim           	= NULL,
	BaseDamage       	= 0,
	Damage           	= 0,
	Force            	= Vector(0,0,0),
	Pos              	= Vector(0,0,0),
	Type             	= 0,
	Inflictor        	= NULL,
	ReportedPosition 	= Vector(0,0,0),
	IsBulletDamage   	= 0,
	IsExplosionDamage	= 0,
	IsFallDamage     	= 0
}

local function damagetotab(dmg)
	if not dmg then return end
	local dmginfo = {
		AmmoType         	= dmg:GetAmmoType(),
		Attacker         	= dmg:GetAttacker(),
		Damage           	= dmg:GetDamage(),
		Force            	= dmg:GetDamageForce(),
		Pos              	= dmg:GetDamagePosition(),
		Type             	= dmg:GetDamageType(),
		Inflictor        	= dmg:GetInflictor(),
		ReportedPosition 	= dmg:GetReportedPosition(),
		IsBulletDamage   	= dmg:IsBulletDamage(),
		IsExplosionDamage	= dmg:IsExplosionDamage(),
		IsFallDamage     	= dmg:IsFallDamage()
	}
	return dmginfo
end

local function tabtodamage(tab)
	local dmg = DamageInfo()

	dmg:SetAmmoType(tab.AmmoType)
	dmg:SetAttacker(tab.Attacker)
	dmg:SetDamage(tab.Damage)
	dmg:SetDamageForce(tab.Force)
	dmg:SetDamagePosition(tab.Pos)
	dmg:SetDamageType(tab.Type)
	dmg:SetInflictor(tab.Inflictor)
	dmg:SetReportedPosition(tab.ReportedPosition)

	return dmg
end

registerType("damage", "xdm", DamageInfo(),
 	function(self, input)
 		if IsEmpty(input) then
 			return table.Copy(DEFAULT)
 		end
 		return input
 	end,
 	nil,
 	function(retval)
 		if retval == nil then return end
 		if not istable(retval) then error("Return value is neither nil nor a table, but a "..type(retval).."!",0) end
 	end,
 	function(v)
 		return not istable(v)
 	end
)

registerOperator("ass", "xdm", "xdm", function(self, args)
	local lhs, op2, scope = args[2], args[3], args[4]
	local      rhs = op2[1](self, op2)

	local Scope = self.Scopes[scope]
	if not Scope.lookup then Scope.lookup = {} end

	local lookup = Scope.lookup
	if (lookup[rhs]) then lookup[rhs][lhs] = nil end
	if (not lookup[rhs]) then lookup[rhs] = {} end
	lookup[rhs][lhs] = true

	Scope[lhs] = rhs
	Scope.vclk[lhs] = true
	return rhs
end)


e2function number operator_is(damage dmg)
	if dmg and table.ToString(dmg) ~= table.ToString(DEFAULT) then return 1 else return 0 end
end

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

local registered_e2s = {}
local victim = nil
local damageTab = {}
local damageInfo = nil
local damageClk = 0

registerCallback("construct", function(self)
	self.data.dmgtriggerbyall = false
	self.data.dmgtriggerents = {}
end)

registerCallback("destruct",function(self)
	registered_e2s[self.entity] = nil
end)

hook.Add("EntityRemoved", "E2DmgClkRemove", function(ent)
	for e2,_ in pairs(registered_e2s) do
		e2.context.data.dmgtriggerents[ent] = nil

		if not #e2.context.data.dmgtriggerents then
			registered_e2s[e2] = nil
		end
	end
end)

E2Lib.registerEvent("damage", {
	{ "Victim", "e" },
	{ "Damage", "xdm" }
})

E2Lib.registerEvent("trackedDamage", {
	{ "Victim", "e" },
	{ "Damage", "xdm" }
})

E2Lib.registerEvent("playerDamage", {
	{ "Victim", "e" },
	{ "Damage", "xdm" }
})

hook.Add("EntityTakeDamage","Expresion2TakeDamageInfo", function( targat, dmginfo )
	victim = targat
	damageTab = damagetotab(dmginfo)
	damageInfo = dmginfo
	damageClk = 1

	for ent,_ in pairs(registered_e2s) do
		if IsValid(ent) and IsValid(targat) and damageInfo then
			if ent.context.data.dmgtriggerbyall or ent.context.data.dmgtriggerents[victim] then
				ent:Execute()
			end

			-- 
			if ent.context.data.dmgtriggerents[victim] and ent.ExecuteEvent then
				ent:ExecuteEvent("trackedDamage", {victim, damageTab})
			end
		end
	end

	if IsValid(victim) and damageInfo then
		E2Lib.triggerEvent("damage", {victim, damageTab})

		if victim:IsPlayer() then
			E2Lib.triggerEvent("playerDamage", {victim, damageTab})
		end
	end

	damageClk = 0
end)

--- If set to 1, E2 will run when an entity takes damage.
[nodiscard, deprecated = "Use the damage event instead"]
e2function void runOnDmg(number activate)
	if activate ~= 0 then
		self.data.dmgtriggerbyall = true
		registered_e2s[self.entity] = true
	else
		self.data.dmgtriggerbyall = false
		registered_e2s[self.entity] = nil
	end
end

--- If set to 1, E2 will run when specified entity takes damage.
[nodiscard, deprecated = "Use the damage event instead"]
e2function void runOnDmg(number activate, entity entity)
	if not IsValid(this) then return self:throw("Invalid entity", nil) end

	if activate ~= 0 then
		self.data.dmgtriggerents[entity] = true
		registered_e2s[self.entity] = true
	else
		self.data.dmgtriggerents[entity] = nil

		if not #self.data.dmgtriggerents then
			registered_e2s[self.entity] = nil
		end
	end
end

--- If set to 1, E2 will run when specified entities take damage.
[nodiscard, deprecated = "Use the damage event instead"]
e2function void runOnDmg(number activate, array entities)
	if activate ~= 0 then
		for _,ent in pairs(entities) do
			self.data.dmgtriggerents[ent] = true
		end
		registered_e2s[self.entity] = true
	else
		for _,ent in pairs(entities) do
			self.data.dmgtriggerents[ent] = nil
		end

		if not #self.data.dmgtriggerents then
			registered_e2s[self.entity] = nil
		end
	end
end

--- E2 will run when the specified entity takes damage.
e2function void entity:trackDamage()
	if not IsValid(this) then return self:throw("Invalid entity", nil) end

	registered_e2s[self.entity] = true

	self.data.dmgtriggerents[this] = true
end

--- E2 will run when the specified entities take damage.
e2function void array:trackDamage()
	if not istable(this) then return self:throw("Invalid array", nil) end
	for _, ent in pairs(this) do
		if not IsValid(ent) then return self:throw("Invalid entity", nil) end
	end

	for _,ent in pairs(this) do
		registered_e2s[self.entity] = true

		self.data.dmgtriggerents[ent] = true
	end
end

--- E2 will no longer run when the specified entity takes damage.
e2function void entity:stopTrackDamage()
	if not IsValid(this) then return self:throw("Invalid entity", nil) end

	self.data.dmgtriggerents[this] = nil

	if not table.Count(self.data.dmgtriggerents) then
		registered_e2s[self.entity] = nil
	end
end

--- E2 will no longer run when the specified entities take damage.
e2function void array:stopTrackDamage()
	if not istable(this) then return self:throw("Invalid array", nil) end
	for _, ent in pairs(this) do
		if not IsValid(ent) then return self:throw("Invalid entity", nil) end
	end

	for _,ent in pairs(this) do
		self.data.dmgtriggerents[ent] = nil
	end

	if not table.Count(self.data.dmgtriggerents) then
		registered_e2s[self.entity] = nil
	end
end

--- Returns a array of all tracked entities.
e2function array getDamageTrackedEntities()
	local entities = {}

	for entity, tracked in pairs(self.data.dmgtriggerents) do
		if tracked then
			table.insert(entities, entity)
		end
	end

	return entities
end

--- Returns 1 if the entity is tracked. Returns 0 otherwise.
e2function number entity:isDamageTracked()
	if not IsValid(this) then return self:throw("Invalid entity", nil) end
	
	return self.data.dmgtriggerents[this] and 1 or 0
end

--- Returns 1 if the chip is being executed because of a damage event. Returns 0 otherwise.
[nodiscard, deprecated = "Use the damage event instead"]
e2function number dmgClk()
	if not damageTab or not victim then return 0 end
	if not IsValid(victim) or not IsEntity(victim) then return 0 end

	return damageClk
end

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

[nodiscard, deprecated = "Use the damage event instead"]
e2function number dmgDamage()
	if not damageTab or not victim then return 0 end
	return damageTab.Damage
end

[nodiscard, deprecated = "Use the damage event instead"]
e2function entity dmgAttacker()
	if not damageTab or not victim then return NULL end
	return damageTab.Attacker
end

[nodiscard, deprecated = "Use the damage event instead"]
e2function entity dmgVictim()
	if not damageTab or not victim then return NULL end
	return victim
end

[nodiscard, deprecated = "Use the damage event instead"]
e2function vector dmgPos()
	if not damageTab or not victim then return Vector(0,0,0) end
	return damageTab.Pos
end

[nodiscard, deprecated = "Use the damage event instead"]
e2function vector dmgForce()
	if not damageTab or not victim then return Vector(0,0,0) end
	return damageTab.Force
end

[nodiscard, deprecated = "Use the damage event instead"]
e2function entity dmgInflictor()
	if not damageTab or not victim then return NULL end
	return damageTab.Inflictor
end

[nodiscard, deprecated = "Use the damage event instead"]
e2function string dmgType()
	if not damageTab or not victim then return "" end

	if damageTab.IsExplosionDamage then
		return "Explosive" end
	if damageTab.IsBulletDamage or damageTab.Type == DMG_BUCKSHOT then
		return "Bullet" end
	if damageTab.Type == DMG_SLASH or damageTab.Type == DMG_CLUB then
		return "Melee" end
	if damageTab.IsFallDamage then
		return "Fall" end
	if damageTab.Type == DMG_CRUSH then
		return "Crush" end
end

////////////////////////////////////////////////////

local sbox_E2_Dmg_Simple = CreateConVar( "sbox_E2_Dmg_Simple", "2", FCVAR_ARCHIVE )

[nodiscard, deprecated = "Use takeDamage instead"]
e2function void entity:dmgApplyDamage(number damage)
	if not IsValid(this) then return self:throw("Invalid entity", nil) end

	if sbox_E2_Dmg_Simple:GetInt() == 2 then
		if this.CPPICanDamage then
			if not this:CPPICanDamage(self.player) then
				return self:throw("You do not own this entity", nil)
			end
		else
			if not isOwner(self, this, true) then
				return self:throw("You do not own this entity", nil)
			end
		end
	elseif sbox_E2_Dmg_Simple:GetInt() == 3 and not self.player:IsAdmin() then
		return self:throw("You do not have access", nil)
	elseif sbox_E2_Dmg_Simple:GetInt() == 4 then
		return self:throw("Deactivated", nil)
	end

	local dmginfo = DamageInfo()
	dmginfo:SetAttacker(self.player)
	dmginfo:SetDamage(damage)
	dmginfo:SetInflictor(self.entity)
	this:TakeDamageInfo(dmginfo)
end


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


--- Makes an empty damage.
e2function damage damage()
	return table.Copy(DEFAULT)
end


[nodiscard, deprecated = "Use the damage event instead"]
e2function damage lastDamage()
	if not damageTab then return table.Copy(DEFAULT) end
	return table.Copy(damageTab)
end

[nodiscard, deprecated = "Use the damage event instead"]
e2function entity lastDamageVictim()
	if not victim then return NULL end
	return victim
end

--- Returns a copy of the damage.
e2function damage damage:clone()
	return table.Copy(this)
end


-- local sbox_E2_Dmg_Override = CreateConVar( "sbox_E2_Dmg_Override", "3", FCVAR_ARCHIVE )

-- e2function void lastDamageOverride(damage dmg)
--	if damageClk then
--		if not victim or not dmg then return nil end

--		if sbox_E2_Dmg_Override:GetInt() == 2 then
--			if victim:IsPlayer() then
--				if not isFriend(self.player, victim) then
--					return nil
--				end
--			else
--				if not victim:CPPICanDamage(self.player) then
--					return nil
--				end
--			end
--		elseif sbox_E2_Dmg_Override:GetInt() == 3 and not self.player:IsAdmin() then
--			return nil
--		elseif sbox_E2_Dmg_Override:GetInt() == 4 then
--			return nil
--		end

--		damageInfo = tabtodamage(dmg)
--	end
-- end


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

local ids = {
	["AmmoType"] = "s",
	["Attacker"] = "e",
	["Victim"] = "e",
	["BaseDamage"] = "n",
	["Damage"] = "n",
	["Force"] = "v",
	["Position"] = "v",
	["Type"] = "n",
	["Inflictor"] = "e",
	["ReportedPosition"] = "v",
	["IsBulletDamage"] = "n",
	["IsExplosionDamage"] = "n",
	["IsFallDamage"] = "n"
}

local DEFAULT = {n={},ntypes={},s={},stypes={},size=0}

--- Converts the damage into a table.
e2function table damage:toTable()
	if not this then return DEFAULT end

	local ret = table.Copy(DEFAULT)
	local size = 0
	for k,v in pairs( this ) do
		if (ids[k]) then
			if isbool(v) then v = v and 1 or 0 end
			ret.s[k] = v
			ret.stypes[k] = ids[k]
			size = size + 1
		end
	end
	ret.size = size
	return ret
end


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

--- Returns the attacker of damage.
e2function entity damage:getAttacker()
	if not this then return NULL end
	return this.Attacker
end

--- Returns the damage amount.
e2function number damage:getDamage()
	if not this then return 0 end
	return this.Damage
end

--- Returns a vector representing the damage force.
e2function vector damage:getForce()
	if not this then return Vector(0,0,0) end
	return this.Force
end

--- Returns the position where the damage was or is going to be applied to.
e2function vector damage:getPosition()
	if not this then return Vector(0,0,0) end
	return this.Pos
end

--- Returns a bitflag which indicates the damage type of the damage.
e2function number damage:getType()
	if not this then return 0 end
	return this.Type
end

--- 	Returns the inflictor of the damage. This is not necessarily a weapon.
e2function entity damage:getInflictor()
	if not this then return NULL end
	return this.Inflictor
end


///////////////////////////////////////////////////////////////////

--- Returns 1 if the damage was caused by a bullet.
e2function number damage:isBulletDamage()
	if not this then return 0 end
	return this.IsBulletDamage and 1 or 0
end

--- Returns 1 if the damage contains explosion damage.
e2function number damage:isExplosionDamage()
	if not this then return 0 end
	return this.IsExplosionDamage and 1 or 0
end

--- Returns 1 if the damage contains fall damage.
e2function number damage:isFallDamage()
	if not this then return 0 end
	return this.IsFallDamage and 1 or 0
end


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

--- Sets the attacker of the damage. Returns itself.
e2function damage damage:setAttacker(entity attacker)
	if not IsValid(attacker) then return self:throw("Invalid entity", nil) end

	if not this or not IsValid(attacker) then return nil end
	this.Attacker = attacker
	return this
end

--- Sets the amount of damage. Returns itself.
e2function damage damage:setDamage(number damage)
	if not this or not damage then return nil end
	this.Damage = damage
	return this
end

--- Sets the directional force of the damage. Returns itself.
e2function damage damage:setForce(vector force)
	if not this or not isvector(force) then return nil end
	this.Force = Vector(force[1], force[2], force[3])
	return this
end

--- Sets the position of where the damage gets applied to. Returns itself.
e2function damage damage:setPosition(vector position)
	if not this or not isvector(position) then return nil end
	this.Pos = Vector(position[1], position[2], position[3])
	return this
end

--- Sets the damage type. Returns itself.
e2function damage damage:setType(number type)
	if not this or not type then return nil end
	this.Type = type
	return this
end

--- Sets the inflictor of the damage for example a weapon. Returns itself.
e2function damage damage:setInflictor(entity inflictor)
	if not IsValid(inflictor) then return self:throw("Invalid entity", nil) end

	if not this or not inflictor then return nil end
	this.Inflictor = inflictor
	return this
end


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

local sbox_E2_Dmg_Adv = CreateConVar( "sbox_E2_Dmg_Adv", "2", FCVAR_ARCHIVE )

local function candamage(self, ent)
	local ply = self.player
	
	if sbox_E2_Dmg_Adv:GetInt() == 2 and CPPI then
		if ent.CPPICanDamage then
			if not ent:CPPICanDamage(ply) then
				return false
			end
		else
			return isOwner(self, ent, true)
		end
	elseif sbox_E2_Dmg_Adv:GetInt() == 3 and not ply:IsAdmin() then
		return false
	elseif sbox_E2_Dmg_Adv:GetInt() == 4 then
		return false
	end

	return true
end

--- Returns 1 if the entity can be damaged by the player.
e2function number canDamage(entity target)
	if not candamage(self, target) then return 0 end

	return 1
end

--- Applies the damage specified by the damage info to the entity.
e2function void entity:takeDamage(damage damage)
	if not this or not damage then return nil end
	if not IsValid(this) then return self:throw("Invalid entity", nil) end
	if not candamage(self, this) then self:throw("You do not own this entity", nil) end


	if not IsValid(damage.Attacker) then
		damage.Attacker = self.player
	end

	if not IsValid(damage.Inflictor) then
		damage.Inflictor = self.entity
	end

	local dmginfo = tabtodamage(damage)
	this:TakeDamageInfo(dmginfo)
end

--- Applies the specified amount of damage to the entity. (Damage Amount)
e2function void entity:takeDamage(number damageAmount)
	if not this or not damageAmount then return nil end
	if not IsValid(this) then return self:throw("Invalid entity", nil) end
	if not candamage(self, this) then self:throw("You do not own this entity", nil) end

	attacker = self.player
	inflictor = self.entity

	this:TakeDamage(damageAmount, attacker, inflictor)
end

--- Applies the specified amount of damage to the entity. (Damage Amount, Attacker)
e2function void entity:takeDamage(number damageAmount, entity attacker)
	if not this or not damageAmount then return nil end
	if not IsValid(this) then return self:throw("Invalid entity", nil) end
	if not candamage(self, this) then self:throw("You do not own this entity", nil) end

	if not IsValid(attacker) then
		attacker = self.player
	end

	inflictor = self.entity
	this:TakeDamage(damageAmount, attacker, inflictor)
end

--- Applies the specified amount of damage to the entity. (Damage Amount, Attacker, Inflictor)
e2function void entity:takeDamage(number damageAmount, entity attacker, entity inflictor)
	if not this or not damageAmount then return nil end
	if not IsValid(this) then return self:throw("Invalid entity", nil) end
	if not candamage(self, this) then self:throw("You do not own this entity", nil) end

	if not IsValid(attacker) then
		attacker = self.player
	end

	if not IsValid(inflictor) then
		inflictor = self.entity
	end

	this:TakeDamage(damageAmount, attacker, inflictor)
end

--- Applies spherical damage based on damage info to all entities in the specified radius. (Damage, Position, Radius)
e2function void blastDamage(damage damage, vector position, number radius)
	if sbox_E2_Dmg_Adv:GetInt() == 2 and not self.player:IsAdmin() then return self:throw("You do not have access", nil)
	elseif sbox_E2_Dmg_Adv:GetInt() == 3 and not self.player:IsAdmin() then return self:throw("You do not have access", nil)
	elseif sbox_E2_Dmg_Adv:GetInt() == 4 then return self:throw("You do not have access", nil) end

	if not IsValid(damage.Attacker) then
		damage.Attacker = self.player
	end

	if not IsValid(damage.Inflictor) then
		damage.Inflictor = self.entity
	end

	local dmginfo = tabtodamage(damage)
	local pos = Vector(position[1], position[2], position[3])
	util.BlastDamageInfo(dmginfo, pos, radius)
end

--- Applies explosion damage to all entities in the specified radius. (Attacker, Inflictor, Position, Radius, Damage Amount)
e2function void blastDamage(entity inflictor, entity attacker, vector position, number radius, number damageAmount)
	if not IsValid(inflictor) then return self:throw("Invalid entity", nil) end
	if not IsValid(attacker) then return self:throw("Invalid entity", nil) end

	if sbox_E2_Dmg_Adv:GetInt() == 2 and not self.player:IsAdmin() then return self:throw("You do not have access", nil)
	elseif sbox_E2_Dmg_Adv:GetInt() == 3 and not self.player:IsAdmin() then return self:throw("You do not have access", nil)
	elseif sbox_E2_Dmg_Adv:GetInt() == 4 then return self:throw("You do not have access", nil) end

	if not IsValid(attacker) then
		attacker = self.player
	end

	if not IsValid(inflictor) then
		inflictor = self.entity
	end

	local pos = Vector(position[1], position[2], position[3])
	util.BlastDamage(inflictor, attacker, pos, radius, damageAmount)
end
