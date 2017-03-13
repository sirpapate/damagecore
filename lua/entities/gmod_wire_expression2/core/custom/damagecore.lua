
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

registerType("damage", "dmg", DamageInfo(),
 	function(self, input)
 		if IsEmpty(input) then
 			return table.Copy(DEFAULT)
 		end
 		return input
 	end,
 	nil,
 	function(retval)
 		if retval == nil then return end
 		if !istable(retval) then error("Return value is neither nil nor a table, but a "..type(retval).."!",0) end
 	end,
 	function(v)
 		return !istable(v)
 	end
)

registerOperator("ass", "dmg", "dmg", function(self, args)
	local lhs, op2, scope = args[2], args[3], args[4]
	local      rhs = op2[1](self, op2)

	local Scope = self.Scopes[scope]
	if !Scope.lookup then Scope.lookup = {} end

	local lookup = Scope.lookup
	if (lookup[rhs]) then lookup[rhs][lhs] = nil end
	if (!lookup[rhs]) then lookup[rhs] = {} end
	lookup[rhs][lhs] = true

	Scope[lhs] = rhs
	Scope.vclk[lhs] = true
	return rhs
end)

e2function number operator_is(damage dmg)
	if dmg and table.ToString(dmg) != table.ToString(DEFAULT) then return 1 else return 0 end
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
		end
	end

	damageClk = 0
end)

e2function void runOnDmg(number activate)
	if activate ~= 0 then
		self.data.dmgtriggerbyall = true
		registered_e2s[self.entity] = true
	else
		self.data.dmgtriggerbyall = false
		registered_e2s[self.entity] = nil
	end
end

e2function void runOnDmg(number activate, entity ent)
	if not IsValid(ent) then return nil end

	if activate ~= 0 then
		self.data.dmgtriggerents[ent] = true
		registered_e2s[self.entity] = true
	else
		self.data.dmgtriggerents[ent] = nil

		if not #self.data.dmgtriggerents then
			registered_e2s[self.entity] = nil
		end
	end
end

e2function void runOnDmg(number activate, array ents)
	if activate ~= 0 then
		for _,ent in pairs(ents) do
			self.data.dmgtriggerents[ent] = true
		end
		registered_e2s[self.entity] = true
	else
		for _,ent in pairs(ents) do
			self.data.dmgtriggerents[ent] = nil
		end

		if not #self.data.dmgtriggerents then
			registered_e2s[self.entity] = nil
		end
	end
end

e2function void entity:trackDamage()
	if not IsValid(this) then return nil end
	registered_e2s[self.entity] = true

	self.data.dmgtriggerents[this] = true
end

e2function void array:trackDamage()
	if not istable(this) then return end

	for _,ent in pairs(this) do
		if IsValid(ent) and isentity(ent) then
			registered_e2s[self.entity] = true

			self.data.dmgtriggerents[ent] = true
		end
	end
end

e2function void entity:stopTrackDamage()
	if not IsValid(this) then return nil end

	self.data.dmgtriggerents[this] = nil

	if not table.Count(self.data.dmgtriggerents) then
		registered_e2s[self.entity] = nil
	end
end

e2function void array:stopTrackDamage()
	if not istable(this) then return end

	for _,ent in pairs(this) do
		if IsValid(ent) and isentity(ent) then
			self.data.dmgtriggerents[ent] = nil
		end
	end

	if not table.Count(self.data.dmgtriggerents) then
		registered_e2s[self.entity] = nil
	end
end

e2function number dmgClk()
	if not damageTab or not victim then return 0 end
	if not IsValid(victim) or not IsEntity(victim) then return 0 end

	return damageClk
end

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

e2function number dmgDamage()
	if not damageTab or not victim then return 0 end
	return damageTab.Damage
end

e2function entity dmgAttacker()
	if not damageTab or not victim then return NULL end
	return damageTab.Attacker
end

e2function entity dmgVictim()
	if not damageTab or not victim then return NULL end
	return victim
end

e2function vector dmgPos()
	if not damageTab or not victim then return Vector(0,0,0) end
	return damageTab.Pos
end

e2function vector dmgForce()
	if not damageTab or not victim then return Vector(0,0,0) end
	return damageTab.Force
end

e2function entity dmgInflictor()
	if not damageTab or not victim then return NULL end
	return damageTab.Inflictor
end

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

local function isfriend(ply1, ply2)
	if not CPPI then
		return true
	end

	for k, v in pairs( ply2:CPPIGetFriends() )  do
		if v == ply1 then
			return true
		end
	end

	return false
end

local sbox_E2_Dmg_Simple = CreateConVar( "sbox_E2_Dmg_Simple", "2", FCVAR_ARCHIVE )

e2function void entity:dmgApplyDamage(number damage)
	if not IsValid(this) then return nil end

	if sbox_E2_Dmg_Simple:GetInt() == 2 then
		if this:IsPlayer() then
			if not isfriend(self.player, this) then
				return nil
			end
		else
			if CPPI then
				if this.CPPICanDamage then
					if not this:CPPICanDamage(self.player) then
						return nil
					end
				else
					if not isfriend(this:CPPIGetOwner(), self.player) then
						return nil
					end
				end
			end
		end
	elseif sbox_E2_Dmg_Simple:GetInt() == 3 and not self.player:IsAdmin() then
		return nil
	elseif sbox_E2_Dmg_Simple:GetInt() == 4 then
		return nil
	end

	local dmginfo = DamageInfo()
	dmginfo:SetAttacker(self.player)
	dmginfo:SetDamage(damage)
	dmginfo:SetInflictor(self.entity)
	this:TakeDamageInfo(dmginfo)
end


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



e2function damage damage()
	return table.Copy(DEFAULT)
end


e2function damage lastDamage()
	if not damageTab then return table.Copy(DEFAULT) end
	return table.Copy(damageTab)
end

e2function entity lastDamageVictim()
	if not victim then return NULL end
	return victim
end

e2function damage damage:clone()
	return table.Copy(this)
end


-- local sbox_E2_Dmg_Override = CreateConVar( "sbox_E2_Dmg_Override", "3", FCVAR_ARCHIVE )

-- e2function void lastDamageOverride(damage dmg)
--	if damageClk then
--		if not victim or not dmg then return nil end

--		if sbox_E2_Dmg_Override:GetInt() == 2 then
--			if victim:IsPlayer() then
--				if not isfriend(self.player, victim) then
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

e2function entity damage:getAttacker()
	if not this then return NULL end
	return this.Attacker
end

e2function number damage:getDamage()
	if not this then return 0 end
	return this.Damage
end

e2function vector damage:getForce()
	if not this then return Vector(0,0,0) end
	return this.Force
end

e2function vector damage:getPosition()
	if not this then return Vector(0,0,0) end
	return this.Pos
end

e2function number damage:getType()
	if not this then return 0 end
	return this.Type
end

e2function entity damage:getInflictor()
	if not this then return NULL end
	return this.Inflictor
end


///////////////////////////////////////////////////////////////////

e2function number damage:isBulletDamage()
	if not this then return 0 end
	return this.IsBulletDamage and 1 or 0
end

e2function number damage:isExplosionDamage()
	if not this then return 0 end
	return this.IsExplosionDamage and 1 or 0
end

e2function number damage:isFallDamage()
	if not this then return 0 end
	return this.IsFallDamage and 1 or 0
end


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

e2function damage damage:setAttacker(entity attacker)
	if not IsValid(attacker) then return end

	if not this or not IsValid(attacker) then return nil end
	this.Attacker = attacker
	return this
end

e2function damage damage:setDamage(number damage)
	if not this  or not damage then return nil end
	this.Damage = damage
	return this
end

e2function damage damage:setForce(vector force)
	if not this or not isvector(force) then return nil end
	this.Force = Vector(force[1], force[2], force[3])
	return this
end

e2function damage damage:setPosition(vector pos)
	if not this or not isvector(pos) then return nil end
	this.Pos = Vector(pos[1], pos[2], pos[3])
	return this
end

e2function damage damage:setType(number type)
	if not this or not type then return nil end
	this.Type = type
	return this
end

e2function damage damage:setInflictor(entity inflictor)
	if not IsValid(inflictor) then return end

	if not this or not inflictor then return nil end
	this.Inflictor = inflictor
	return this
end


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

local sbox_E2_Dmg_Adv = CreateConVar( "sbox_E2_Dmg_Adv", "2", FCVAR_ARCHIVE )

local function candamage(ply, ent)
	if sbox_E2_Dmg_Adv:GetInt() == 2 and CPPI then
		if ent:IsPlayer() then
			if not isfriend(ply, ent) then
				return false
			end
		else
			if ent.CPPICanDamage then
				if not ent:CPPICanDamage(ply) then
					return false
				end
			else
				local owner = ent:CPPIGetOwner()
				return candamage(ply, owner)
			end
		end
	elseif sbox_E2_Dmg_Adv:GetInt() == 3 and not ply:IsAdmin() then
		return false
	elseif sbox_E2_Dmg_Adv:GetInt() == 4 then
		return false
	end

	return true
end

e2function void entity:takeDamage(damage dmg)
	if not IsValid(this) then return nil end
	if not this or not dmg then return nil end
	if not candamage(self.player, this) then return nil end


	if not IsValid(dmg.Attacker) then
		dmg.Attacker = self.player
	end

	if not IsValid(dmg.Inflictor) then
		dmg.Inflictor = self.entity
	end

	local dmginfo = tabtodamage(dmg)
	this:TakeDamageInfo(dmginfo)
end

e2function void entity:takeDamage(number dmg)
	if not IsValid(this) then return nil end
	if not this or not dmg then return nil end
	if not candamage(self.player, this)  then return nil end

	attacker = self.player
	inflictor = self.entity

	this:TakeDamage(dmg, attacker, inflictor)
end

e2function void entity:takeDamage(number dmg, entity attacker)
	if not IsValid(this) then return nil end
	if not this or not dmg then return nil end
	if not candamage(self.player, this)  then return nil end

	if not IsValid(attacker) then
		attacker = self.player
	end

	inflictor = self.entity
	this:TakeDamage(dmg, attacker, inflictor)
end

e2function void entity:takeDamage(number dmg, entity attacker, entity inflictor)
	if not IsValid(this) then return nil end
	if not this or not dmg then return nil end
	if not candamage(self.player, this)  then return nil end

	if not IsValid(attacker) then
		attacker = self.player
	end

	if not IsValid(inflictor) then
		inflictor = self.entity
	end

	this:TakeDamage(dmg, attacker, inflictor)
end

e2function void blastDamage(damage dmg, vector pos, number radius)
	if sbox_E2_Dmg_Adv:GetInt() == 2 and not self.player:IsAdmin() then return nil
	elseif sbox_E2_Dmg_Adv:GetInt() == 3 and not self.player:IsAdmin() then return nil
	elseif sbox_E2_Dmg_Adv:GetInt() == 4 then return nil end

	if not IsValid(dmg.Attacker) then
		dmg.Attacker = self.player
	end

	if not IsValid(dmg.Inflictor) then
		dmg.Inflictor = self.entity
	end

	local dmginfo = tabtodamage(dmg)
	local pos = Vector(pos[1], pos[2], pos[3])
	util.BlastDamageInfo(dmginfo, pos, radius)
end

e2function void blastDamage(entity inflictor, entity attacker, vector pos, number radius, number damage)
	if not IsValid(inflictor) then return end
	if not IsValid(attacker) then return end

	if sbox_E2_Dmg_Adv:GetInt() == 2 and not self.player:IsAdmin() then return nil
	elseif sbox_E2_Dmg_Adv:GetInt() == 3 and not self.player:IsAdmin() then return nil
	elseif sbox_E2_Dmg_Adv:GetInt() == 4 then return nil end

	if not IsValid(attacker) then
		attacker = self.player
	end

	if not IsValid(inflictor) then
		inflictor = self.entity
	end

	local pos = Vector(pos[1], pos[2], pos[3])
	util.BlastDamage(inflictor, attacker, pos, radius, damage)
end
