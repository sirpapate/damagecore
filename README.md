[comment]: <> (## For more information, go to the [GitHub Page][GitHub Page])
[comment]: <> (To convert this file in Steam format, use this website: https://steamdown.vercel.app/)

# DamageCore

DamageCore is an extension module for the Wire Expression 2 Chip. It enables players to detect and/or deal damage to other entities.


## Workshop Installation

The DamageCore is available on the Steam Workshop! Go to the [DamageCore Workshop Page][DamageCore Workshop Page] and press `Subscribe`. For can go to the [Expression 2 Core Collection][Expression 2 Core Collection] for more extensions.

## Manual Installation

Clone this repository into your `steamapps\common\GarrysMod\garrysmod\addons` folder using this command if you are using git:

    git clone https://github.com/sirpapate/damagecore.git

## Documentation

### Events

| Declaration                                         | Replacing                                      | Description                                                                                     |
|-----------------------------------------------------|------------------------------------------------|-------------------------------------------------------------------------------------------------|
| event damage(Victim:entity, Damage:damage)        | runOnDmg, dmgClk, lastDamage, lastDamageVictim | Triggered when an entity takes damage.                                                          |
| event trackedDamage(Victim:entity, Damage:damage) |                                                | Triggered when an entity in the list of tracked (with "E:trackDamage()") entities takes damage. |
| event playerDamage(Victim:entity, Damage:damage)  |                                                | Triggered when a player takes damage.                                                           |

### Tick Functions
| Function                     | Return | Description                                                                             |
|------------------------------|:------:|-----------------------------------------------------------------------------------------|
| runOnDmg(N)                |        | If set to 1, E2 will run when an entity takes damage.                                   |
| runOnDmg(N,E)              |        | If set to 1, E2 will run when specified entity takes damage.                            |
| runOnDmg(N,R)              |        | If set to 1, E2 will run when specified entities take damage.                           |
| E:trackDamage()            |        | E2 will run when the specified entity takes damage.                                     |
| T:trackDamage()            |        | E2 will run when the specified entities take damage.                                    |
| E:stopTrackDamage()        |        | E2 will no longer run when the specified entity takes damage.                           |
| R:stopTrackDamage()        |        | E2 will no longer run when the specified entities take damage.                          |
| getDamageTrackedEntities() | R      | Returns a array of all tracked entities.                                                |
| E:isDamageTracked()        | N      | Returns 1 if the entity is tracked. Returns 0 otherwise.                                |
| dmgClk()                   | N      | Returns 1 if the chip is being executed because of a damage event. Returns 0 otherwise. |
| lastDamage()               | XDM    | Returns the last damage.                                                                |
| lastDamageVictim()         | E      | Returns the victim of the last damage.                                                  |

### Damage Type
| Function                  | Return | Description                                                             |
|---------------------------|:------:|-------------------------------------------------------------------------|
| damage()                | XDM    | Makes an empty damage.                                                  |
| XDM:clone()             | XDM    | Returns a copy of the damage.                                           |
| XDM:toTable()           | T      | Converts the damage into a table.                                       |
| XDM:getDamage()         | N      | Returns the damage amount.                                              |
| XDM:getAttacker()       | E      | Returns the attacker of damage.                                         |
| XDM:getForce()          | V      | Returns a vector representing the damage force.                         |
| XDM:getPosition()       | V      | Returns the position where the damage was or is going to be applied to. |
| XDM:getType()           | N      | Returns a bitflag which indicates the damage type of the damage.        |
| XDM:getInflictor()      | E      | Returns the inflictor of the damage. This is not necessarily a weapon.  |
| XDM:isBulletDamage()    | N      | Returns 1 if the damage was caused by a bullet.                         |
| XDM:isExplosionDamage() | N      | Returns 1 if the damage contains explosion damage.                      |
| XDM:isFallDamage()      | N      | Returns 1 if the damage contains fall damage.                           |
| XDM:setDamage(N)        | XDM    | Sets the amount of damage. Returns itself.                              |
| XDM:setAttacker(E)      | XDM    | Sets the attacker of the damage. Returns itself.                        |
| XDM:setForce(V)         | XDM    | Sets the directional force of the damage. Returns itself.               |
| XDM:setPosition(V)      | XDM    | Sets the position of where the damage gets applied to. Returns itself.  |
| XDM:setType(N)          | XDM    | Sets the damage type. Returns itself.                                   |
| XDM:setInflictor(E)     | XDM    | Sets the inflictor of the damage for example a weapon. Returns itself.  |

### Applying Damage Functions
| Function                 | Return | Description                                                                                                              |
|--------------------------|:------:|--------------------------------------------------------------------------------------------------------------------------|
| canDamage(E)           | N      | Returns 1 if the entity can be damaged by the player.                                                                    |
| E:takeDamage(XDM)      |        | Applies the damage specified by the damage info to the entity.                                                           |
| E:takeDamage(N,E)      |        | Applies the specified amount of damage to the entity. (Damage Amount)                                                    |
| E:takeDamage(N,E)      |        | Applies the specified amount of damage to the entity. (Damage Amount, Attacker)                                          |
| E:takeDamage(N,E,E)    |        | Applies the specified amount of damage to the entity. (Damage Amount, Attacker, Inflictor)                               |
| blastDamage(XDM,V,N)   |        | Applies spherical damage based on damage info to all entities in the specified radius. (Damage, Position, Radius)        |
| blastDamage(E,E,V,N,N) |        | Applies explosion damage to all entities in the specified radius. (Attacker, Inflictor, Position, Radius, Damage Amount) |




[DamageCore Workshop Page]: <https://steamcommunity.com/sharedfiles/filedetails/?id=217370580>
[Expression 2 Core Collection]: <https://steamcommunity.com/workshop/filedetails/?id=726399057>
[GitHub Page]: <https://github.com/sirpapate/damagecore>