
/*
 *  Trader Inventory Mutator
 *
 *  (C) 2017 HickDead, Kavoh
 *
 */

class TIMut extends KFMutator
	config(TIM)
	dependson(KFGFxObject_TraderItems)
;


struct SClient
{
    var TIMRepLink         RepLink;
    var KFPlayerController KFPC;
};


var private array<SClient> RepClients;
var private bool bRepReady;
var private array<SItem> ServerItems;

var private int OriginalInventorySize;
var private array<string> DefaultCustomItems;
var config array<string> CustomItems;
var config int iVersion;
var config bool bDebugLog;
var config bool bAddNewWeaponsToConfig;



static final function LoadSettings(out array<string> CurrentItems)
{
	if( Default.iVersion > 0 )
		InitSettings();
	else
		ResetSettings();

	CurrentItems=Default.CustomItems;
}

private static final function InitSettings()
{

	if( Default.CustomItems.Length < 1 )
	{
		Default.CustomItems=Default.DefaultCustomItems;
		SaveSettings();
	}
	else if( Default.bAddNewWeaponsToConfig && Default.iVersion < `VERSION )
	{
		AddNewWeaponsToConfig();
	}

}

private static final function AddNewWeaponsToConfig()
{

	switch( Default.iVersion )
	{
	case 2:
// ...\Src\TIM\Classes\TIMut.uc(67) : Error, Type mismatch in 'add(...)'
//		Default.CustomItems.Add("SawHammer.KFWeapDef_SawHammer")
	case 3:
//		Default.CustomItems.Add("Hellfire.KFWeapDef_Hellfire")
//		Default.CustomItems.Add("Hellfire.KFWeapDef_HellfireDual")
	case 4:
		SaveSettings();
	}

}

private static final function ResetSettings()
{

	Default.bAddNewWeaponsToConfig=True;
	Default.bDebugLog=True;
	Default.CustomItems=Default.DefaultCustomItems;
	SaveSettings();

}

private static final function SaveSettings()
{
    Default.iVersion = `VERSION;
    
    StaticSaveConfig();
}


private final function CreateRepLink(Controller C)
{
    local KFPlayerController KFPC;
    local SClient RepClient;
    
    KFPC = KFPlayerController(C);
    
    if (KFPC == none || KFPC.Player == none || NetConnection(KFPC.Player) == none)
        return;
    
    RepClient.RepLink = Spawn(class'TIMRepLink', KFPC);
    RepClient.KFPC = KFPC;
    
    RepClients.AddItem(RepClient);
    
    if (bRepReady)
        SyncClient(RepClient);
}

private final function DestroyRepLink(Controller C)
{
    local KFPlayerController KFPC;
    local int Index;
    
    KFPC = KFPlayerController(C);
    
    if (KFPC == none)
        return;
    
    Index = RepClients.Find('KFPC', KFPC);
    
    if (Index < 0)
        return;
    
    if (RepClients[Index].RepLink != none)
        RepClients[Index].RepLink.Destroy();
    
    RepClients.Remove(Index, 1);
}

private final function DestroyClients()
{
    local SClient RepClient;
    
    foreach RepClients(RepClient)
    {
        if (RepClient.RepLink != none)
            RepClient.RepLink.Destroy();
    }
    
    RepClients.Length = 0;
}

private final function SyncClients()
{
    local SClient RepClient;
    
    bRepReady = true;
    
    foreach RepClients(RepClient)
    {
        SyncClient(RepClient);
    }
}

private final function SyncClient(SClient RepClient)
{
	RepClient.RepLink.ClientItems=ServerItems;
	RepClient.RepLink.StartSyncItems();
}

function NotifyLogin(Controller C)
{
    CreateRepLink(C);
    
    Super.NotifyLogin(C);
}

function NotifyLogout(Controller C)
{
    DestroyRepLink(C);
    
    Super.NotifyLogout(C);
}

function GetSeamlessTravelActorList(bool bEntry, out array<Actor> Actors)
{
    DestroyClients();
    
    Super.GetSeamlessTravelActorList(bEntry, Actors);
}



event PostBeginPlay()
{
	`log("===TIM=== PostBeginPlay()");
	super.PostBeginPlay();
	if( WorldInfo.Game.BaseMutator == None )
		WorldInfo.Game.BaseMutator=Self;
	else
		WorldInfo.Game.BaseMutator.AddMutator( Self);

//	CustomItems.addItem( "Schneidzekk.KFWeapDef_Schneidzekk");
//	SaveConfig();

	LoadSettings( CustomItems);

	SetTimer( 1.0f, true, nameof(addWeaponsTimer));

}



private function addWeaponsTimer()
{

	if( AddWeapons() )
	{
		ClearTimer( nameof(addWeaponsTimer));
		SyncClients();
	}

}


final function bool AddWeapons()
{
	local KFGameReplicationInfo KFGRI;
	local KFGFxObject_TraderItems TI;
	local STraderItem item;
	local int i, index, number, saleItemsLength, freeID;
	local SItem RepItem;


	if( WorldInfo == none )
		return False;

	KFGRI = KFGameReplicationInfo(WorldInfo.GRI);
	if( KFGRI == none )
		return False;

	TI=KFGRI.TraderItems;
	if( TI == none )
		return False;
    
	saleItemsLength=TI.SaleItems.Length;
	if( saleItemsLength < 1 )
		return False;

	if( OriginalInventorySize < 0 )
		OriginalInventorySize=saleItemsLength;

	// find highest ItemID in use
	freeID=-1;
	foreach TI.SaleItems(item)
		if( item.ItemID > freeID )
			freeID=item.ItemID;
	freeID++;

	number=0;
	for( i=saleItemsLength-OriginalInventorySize; i < CustomItems.Length; i++ )
	{

		`Debug("CustomItem["$i$"]:"@CustomItems[i]);
		item=BuildWeapon( CustomItems[i]);
		item.ItemID=freeID+number;

		// item not on server?
		if( item.WeaponDef == none )
		{
			`Debug("dropping unknown CustomItem["$i$"]:"@CustomItems[i]);
			continue;
		}

		// item ID already in trader inventory?
		index=TI.SaleItems.Find('ItemID',item.ItemId);
		if( index >= 0 )
		{
			`Debug("skipping present SaleItem["$index$"]: ("$TI.SaleItems[index].ItemID$") -"@TI.SaleItems[index].ClassName);
			continue;
		}

		// item ClassName already in trader inventory?
		index=TI.SaleItems.Find( 'ClassName', item.ClassName);
		if( index >= 0 )
		{
			`Debug("skipping duplicate SaleItem["$index$"]: ("$TI.SaleItems[index].ItemID$") -"@TI.SaleItems[index].ClassName);
			continue;
		}

		RepItem.DefPath=CustomItems[i];
		RepItem.TraderId=item.ItemID;
		ServerItems.AddItem( RepItem);

		`Debug("adding SaleItem["$TI.SaleItems.Length$"]: ("$item.ItemID$") -"@item.ClassName);
		TI.SaleItems.AddItem( item);
		number++;
	}


	if( number > 0 )
		TI.SetItemsInfo( TI.SaleItems);

	for( i=0; i < TI.SaleItems.Length; i++ )
		`Debug("SaleItem["$i$"]: ("$TI.SaleItems[i].ItemID$") -"@TI.SaleItems[i].WeaponDef.Name@"-"@TI.SaleItems[i].ClassName);

	`log("===TIM=== custom Weapons added to trader inventory:"@number);

	return True;
}


simulated static function STraderItem BuildWeapon(string CI)
{
	local STraderItem CTI;
	local class<KFWeaponDefinition> WeaponDef;
	local class<KFWeapon> WeaponClass;


	CTI.WeaponDef=none;
	CTI.BlocksRequired=99;

	WeaponDef=class<KFWeaponDefinition>(DynamicLoadObject(CI,class'Class'));
	if( WeaponDef == none )
		return CTI;

	WeaponClass=class<KFWeapon>(DynamicLoadObject(WeaponDef.Default.WeaponClassPath,class'Class'));
	if( WeaponClass == none )
		return CTI;

	CTI.WeaponDef=WeaponDef;
	CTI.ClassName=WeaponClass.Name;

	if( class<KFWeap_DualBase>(WeaponClass) != none && class<KFWeap_DualBase>(WeaponClass).Default.SingleClass != none )
		CTI.SingleClassName=class<KFWeap_DualBase>(WeaponClass).Default.SingleClass.Name;
	else
		CTI.SingleClassName='';

	if( WeaponClass.Default.DualClass != none )
		CTI.DualClassName=WeaponClass.Default.DualClass.Name;
	else
		CTI.DualClassName='';

	CTI.AssociatedPerkClasses=WeaponClass.Static.GetAssociatedPerkClasses();

	CTI.MagazineCapacity=WeaponClass.Default.MagazineCapacity[0];
	CTI.InitialSpareMags=WeaponClass.Default.InitialSpareMags[0];
	CTI.MaxSpareAmmo=WeaponClass.Default.SpareAmmoCapacity[0];
	CTI.InitialSecondaryAmmo=WeaponClass.Default.InitialSpareMags[1]*WeaponClass.Default.MagazineCapacity[1];
	CTI.MaxSecondaryAmmo=WeaponClass.Default.SpareAmmoCapacity[1];

	CTI.BlocksRequired=WeaponClass.Default.InventorySize;
	WeaponClass.Static.SetTraderWeaponStats(CTI.WeaponStats);

	CTI.InventoryGroup=WeaponClass.Default.InventoryGroup;
	CTI.GroupPriority=WeaponClass.Default.GroupPriority;

	CTI.TraderFilter=WeaponClass.Static.GetTraderFilter();
	CTI.AltTraderFilter=WeaponClass.Static.GetAltTraderFilter();


	return CTI;
}



function AddMutator(Mutator M)
{
	// The buck stops with us.
	if( M != Self )
	{
		if( M.Class == Class )
			M.Destroy();
		else
			Super.AddMutator( M);
	}
}



defaultproperties
{
	Name="Default__TIMut"
	ObjectArchetype=KFMutator'KFGame.Default__KFMutator'

	bAlwaysRelevant=true
	RemoteRole=ROLE_SimulatedProxy

	OriginalInventorySize=-1
////	DefaultCustomItems=("Schneidzekk.KFWeapDef_Schneidzekk","CustomM14Mut.KFWeapDef_CustomM14EBR","CustomLARMut.KFWeapDef_LAR", "M99.KFWeapDef_M99")


//	DefaultCustomItems.Add("KFGame.KFWeapDef_9mm")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_9mmDual")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_AA12")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_Ak12")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_AR15")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_Armor")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_Bullpup")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_C4")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_CaulkBurn")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_CenterfireMB464")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_Colt1911")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_Colt1911Dual")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_Crossbow")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_Crovel")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_Deagle")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_DeagleDual")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_DoubleBarrel")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_DragonsBreath")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_Eviscerator")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_FlameThrower")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_FlareGun")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_FlareGunDual")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_Grenade_Berserker")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_Grenade_Commando")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_Grenade_Demo")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_Grenade_Firebug")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_Grenade_Gunslinger")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_Grenade_Medic")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_Grenade_Sharpshooter")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_Grenade_Support")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_Grenade_SWAT")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_Healer")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_HX25")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_HZ12")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_Katana")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_Knife_Commando")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_Knife_Demo")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_Knife_Firebug")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_Knife_Gunslinger")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_Knife_Medic")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_Knife_Sharpshooter")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_Knife_Support")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_Knife_SWAT")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_Kriss")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_M14EBR")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_M16M203")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_M4")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_M79")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_MaceAndShield")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_MB500")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_MedicPistol")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_MedicRifle")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_MedicShotgun")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_MedicSMG")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_MicrowaveGun")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_MP5RAS")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_MP7")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_NailGun")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_P90")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_Pulverizer")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_RailGun")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_Random")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_Remington1858")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_Remington1858Dual")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_RPG7")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_SCAR")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_Stoner63A")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_SW500")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_SW500Dual")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_Welder")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_Winchester1894")
//	DefaultCustomItems.Add("KFGame.KFWeapDef_Zweihander")


	// == Unofficial Weapons Pack -- http://steamcommunity.com/sharedfiles/filedetails/?id=679839492 *
	DefaultCustomItems.Add("KFGameHuskLauncher.KFWeapDef_BatAxe")
	DefaultCustomItems.Add("KFGameHuskLauncher.KFWeapDef_BloatBileThrower")
	DefaultCustomItems.Add("KFGameHuskLauncher.KFWeapDef_DwarvesAxe")
	DefaultCustomItems.Add("KFGameHuskLauncher.KFWeapDef_FireAxe")
	DefaultCustomItems.Add("KFGameHuskLauncher.KFWeapDef_FlameKatana")
	DefaultCustomItems.Add("KFGameHuskLauncher.KFWeapDef_Flare")
	DefaultCustomItems.Add("KFGameHuskLauncher.KFWeapDef_FlareDual")
	DefaultCustomItems.Add("KFGameHuskLauncher.KFWeapDef_HuskCannon")
	DefaultCustomItems.Add("KFGameHuskLauncher.KFWeapDef_M32")
//	DefaultCustomItems.Add("KFGameHuskLauncher.KFWeapDef_M99")
	DefaultCustomItems.Add("KFGameHuskLauncher.KFWeapDef_Mac10")
	DefaultCustomItems.Add("KFGameHuskLauncher.KFWeapDef_MKB42")
	DefaultCustomItems.Add("KFGameHuskLauncher.KFWeapDef_PPSH")

	// == Killing Floor 1 Game Mode -- http://steamcommunity.com/sharedfiles/filedetails/?id=681599774 *
//	DefaultCustomItems.Add("KF1.KFWeapDef_9mm2")
//	DefaultCustomItems.Add("KF1.KFWeapDef_9mmDual2")
//	DefaultCustomItems.Add("KF1.KFWeapDef_AA122")
//	DefaultCustomItems.Add("KF1.KFWeapDef_AK122")
//	DefaultCustomItems.Add("KF1.KFWeapDef_AR152")
//	DefaultCustomItems.Add("KF1.KFWeapDef_Bullpup2")
//	DefaultCustomItems.Add("KF1.KFWeapDef_C42")
//	DefaultCustomItems.Add("KF1.KFWeapDef_Colt19112")
//	DefaultCustomItems.Add("KF1.KFWeapDef_Colt1911Dual2")
//	DefaultCustomItems.Add("KF1.KFWeapDef_Crossbow2")
//	DefaultCustomItems.Add("KF1.KFWeapDef_Deagle2")
//	DefaultCustomItems.Add("KF1.KFWeapDef_DeagleDual2")
//	DefaultCustomItems.Add("KF1.KFWeapDef_DoubleBarrel2")
//	DefaultCustomItems.Add("KF1.KFWeapDef_DragonsBreath2")
//	DefaultCustomItems.Add("KF1.KFWeapDef_FlareRev")
//	DefaultCustomItems.Add("KF1.KFWeapDef_FlareRevDual")
//	DefaultCustomItems.Add("KF1.KFWeapDef_FreezeGun")
//	DefaultCustomItems.Add("KF1.KFWeapDef_Grenade_Demo2")
//	DefaultCustomItems.Add("KF1.KFWeapDef_Grenade_Medic2")
//	DefaultCustomItems.Add("KF1.KFWeapDef_HX252")
//	DefaultCustomItems.Add("KF1.KFWeapDef_HZ122")
//	DefaultCustomItems.Add("KF1.KFWeapDef_Knife_Commando2")
//	DefaultCustomItems.Add("KF1.KFWeapDef_M14EBR2")
//	DefaultCustomItems.Add("KF1.KFWeapDef_M16M2032")
//	DefaultCustomItems.Add("KF1.KFWeapDef_M42")
//	DefaultCustomItems.Add("KF1.KFWeapDef_M792")
//	DefaultCustomItems.Add("KF1.KFWeapDef_MB5002")
//	DefaultCustomItems.Add("KF1.KFWeapDef_MedicLauncher")
//	DefaultCustomItems.Add("KF1.KFWeapDef_MedicPistol2")
//	DefaultCustomItems.Add("KF1.KFWeapDef_MedicRifle2")
//	DefaultCustomItems.Add("KF1.KFWeapDef_MedicShotgun2")
//	DefaultCustomItems.Add("KF1.KFWeapDef_MedicSMG2")
//	DefaultCustomItems.Add("KF1.KFWeapDef_RailGun2")
//	DefaultCustomItems.Add("KF1.KFWeapDef_RPG72")
//	DefaultCustomItems.Add("KF1.KFWeapDef_SCAR2")
//	DefaultCustomItems.Add("KF1.KFWeapDef_Stoner63A2")
//	DefaultCustomItems.Add("KF1.KFWeapDef_SWBOOM")
//	DefaultCustomItems.Add("KF1.KFWeapDef_Winchester18942")

	// == Armory Unofficial Weapons Pack -- http://steamcommunity.com/sharedfiles/filedetails/?id=888134329 **
	DefaultCustomItems.Add("Armory.KFWeapDef_AK74M")
	DefaultCustomItems.Add("Armory.KFWeapDef_AKM")
	DefaultCustomItems.Add("Armory.KFWeapDef_AKS74U")
	DefaultCustomItems.Add("Armory.KFWeapDef_BAR")
	DefaultCustomItems.Add("Armory.KFWeapDef_CZ75")
	DefaultCustomItems.Add("Armory.KFWeapDef_DualMK23")
	DefaultCustomItems.Add("Armory.KFWeapDef_DualTT33")
	DefaultCustomItems.Add("Armory.KFWeapDef_FNFNC")
	DefaultCustomItems.Add("Armory.KFWeapDef_G3")
	DefaultCustomItems.Add("Armory.KFWeapDef_Galil")
	DefaultCustomItems.Add("Armory.KFWeapDef_M14")
	DefaultCustomItems.Add("Armory.KFWeapDef_M1Carbine")
	DefaultCustomItems.Add("Armory.KFWeapDef_M4Carbine")
	DefaultCustomItems.Add("Armory.KFWeapDef_MAS4956")
	DefaultCustomItems.Add("Armory.KFWeapDef_MK23")
	DefaultCustomItems.Add("Armory.KFWeapDef_OTs_33")
	DefaultCustomItems.Add("Armory.KFWeapDef_Spectre")
	DefaultCustomItems.Add("Armory.KFWeapDef_SVD")
	DefaultCustomItems.Add("Armory.KFWeapDef_SVT40")
	DefaultCustomItems.Add("Armory.KFWeapDef_Thermobaric")
	DefaultCustomItems.Add("Armory.KFWeapDef_TT33")
	DefaultCustomItems.Add("Armory.KFWeapDef_UMP")
	DefaultCustomItems.Add("Armory.KFWeapDef_VAL")

	// == LordOfWar Weapon Mutator -- http://steamcommunity.com/sharedfiles/filedetails/?id=890082699
	DefaultCustomItems.Add("AA12Dragon.KFWeapDef_AA12Dragon")
	DefaultCustomItems.Add("ammobox2.KFWeapDef_AmmoBox")
	DefaultCustomItems.Add("barretw.KFWeapDef_Rifle_Barret50")
	DefaultCustomItems.Add("BileThrower.KFWeapDef_BileThrower")
	DefaultCustomItems.Add("hkm14w.KFWeapDef_HK416")
	DefaultCustomItems.Add("louiville.KFWeapDef_Bat")
	DefaultCustomItems.Add("m60.KFWeapDef_M60")
	DefaultCustomItems.Add("m79medic.KFWeapDef_M79M")
	DefaultCustomItems.Add("m79ss.KFWeapDef_M79SS")
	DefaultCustomItems.Add("mac10.KFWeapDef_MAC10")
	DefaultCustomItems.Add("mauser.KFWeapDef_DualMauser")
	DefaultCustomItems.Add("mauser.KFWeapDef_Mauser")
	DefaultCustomItems.Add("mk42b.KFWeapDef_MK42B")
	DefaultCustomItems.Add("nukeatw.KFWeapDef_NUKEAT")
	DefaultCustomItems.Add("patriot.KFWeapDef_DualPatriot")
	DefaultCustomItems.Add("patriot.KFWeapDef_Patriot")
	DefaultCustomItems.Add("railgunzr2.KFWeapDef_RailGunZR2")
	DefaultCustomItems.Add("TF2SentryModV2.SentryWeaponDef")
	DefaultCustomItems.Add("tommygun.KFWeapDef_TommyGun")

	// == AKS-74u -- http://steamcommunity.com/sharedfiles/filedetails/?id=896034477 (*)
	DefaultCustomItems.Add("AKS74UMut.KFWeapDef_AKS74U")

	// == Custom M14EBRs -- http://steamcommunity.com/sharedfiles/filedetails/?id=959410214 **
//	DefaultCustomItems.Add("CustomM14s.KFWeapDef_CustomM14EBR")
	DefaultCustomItems.Add("CustomM14s.KFWeapDef_IronSightM14EBR")

	// == Schneidzekk -- http://steamcommunity.com/sharedfiles/filedetails/?id=1117901956
	DefaultCustomItems.Add("Schneidzekk.KFWeapDef_Schneidzekk")

	// == CustomM14EBR Mutator -- http://steamcommunity.com/sharedfiles/filedetails/?id=1134625264
	DefaultCustomItems.Add("CustomM14Mut.KFWeapDef_CustomM14EBR")

	// == CustomLAR Mutator -- http://steamcommunity.com/sharedfiles/filedetails/?id=1131782590
	DefaultCustomItems.Add("CustomLARMut.KFWeapDef_LAR")

	// == M99 Sniper rifle -- http://steamcommunity.com/sharedfiles/filedetails/?id=1137411101
	DefaultCustomItems.Add("M99.KFWeapDef_M99")

/*
	// == BassCannon -- http://steamcommunity.com/sharedfiles/filedetails/?id=1137726392
	DefaultCustomItems.Add("BassCannon.KFWeapDef_BassCannon")

	// == Helfire shotgun -- http://steamcommunity.com/sharedfiles/filedetails/?id=1137952760
	DefaultCustomItems.Add("Hellfire.KFWeapDef_Hellfire")
	DefaultCustomItems.Add("Hellfire.KFWeapDef_HellfireDual")

	// == Tracer Pistols -- http://steamcommunity.com/sharedfiles/filedetails/?id=1138237412
	DefaultCustomItems.Add("Tracer.KFWeapDef_Tracer")
	DefaultCustomItems.Add("Tracer.KFWeapDef_TracerDual")

	// == SawHammer -- http://steamcommunity.com/sharedfiles/filedetails/?id=1138303678
	DefaultCustomItems.Add("SawHammer.KFWeapDef_SawHammer")
*/

}






