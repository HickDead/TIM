//=============================================================================
// KFWeap_NOT_Available
//=============================================================================
// 
//=============================================================================
// Killing Floor 2
// Copyright (C) 2017 HickDead
//  - HickDead 2017.09.14
//=============================================================================

class KFWeap_NOT_Available extends KFWeapon;


/** Returns trader filter index based on weapon type */
static simulated event EFilterTypeUI GetTraderFilter()
{
	return FT_None;
}


defaultproperties
{

	// Inventory
	InventorySize=99
	GroupPriority=00
	AssociatedPerkClasses(0)=class'KFPerk_Monster'

}
