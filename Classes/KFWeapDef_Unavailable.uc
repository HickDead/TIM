//=============================================================================
// KFWeapDef_Unavailable
//=============================================================================
// 
//=============================================================================
// Killing Floor 2
// Copyright (C) 2017 HickDead
//  - HickDead 2017.09.14
//=============================================================================

class KFWeapDef_Unavailable extends KFWeaponDefinition
	abstract;


static function string GetItemName()
{
        return "Unavailable!";
}

static function string GetItemDescription()
{
        return "This item is NOT available.";
}


DefaultProperties
{
	WeaponClassPath="TIM.KFWeap_NOT_Available"

	BuyPrice=999999
	AmmoPricePerMag=999999
//	ImagePath="WEP_UI_KRISS_TEX.UI_WeaponSelect_KRISS"

	EffectiveRange=0
}
