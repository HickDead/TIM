
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
var private array<string> DefaultItems;
var config array<string> CustomItems;
var config int iVersion;
var config bool bDebugLog;
var config bool bAddNewWeaponsToConfig;



static final function LogToConsole(string Text)
{
    local KFGameEngine KFGE;
    local KFGameViewportClient KFGVC;
    local Console TheConsole;
    
    KFGE = KFGameEngine(class'Engine'.Static.GetEngine());
    
    if (KFGE != none)
    {
        KFGVC = KFGameViewportClient(KFGE.GameViewport);
        
        if (KFGVC != none)
        {
            TheConsole = KFGVC.ViewportConsole;
            
            if (TheConsole != none)
                TheConsole.OutputText(Text);
        }
    }
}


private final function LoadSettings()
{
	if( iVersion > 0 )
		InitSettings();
	else
		ResetSettings();
}

private final function InitSettings()
{

	if( CustomItems.Length < 1 )
	{
		CustomItems=DefaultItems;
		SaveSettings();
	}
	else if( bAddNewWeaponsToConfig && iVersion < `VERSION )
	{
		AddNewWeaponsToConfig();
	}

}

private final function AddNewWeaponsToConfig()
{

	switch( iVersion )
	{
	case 1:
		CustomItems.AddItem("WeaponPack.KFWeapDef_AUG9mm");
		CustomItems.AddItem("WeaponPack.KFWeapDef_M60MG");
		CustomItems.AddItem("WeaponPack.KFWeapDef_Spas12");
	case 2:
		CustomItems.AddItem("M16M203MDC.KFWeapDef_M16M203MDC");
	case 3:
		SaveSettings();
	}

}

private final function ResetSettings()
{

	bAddNewWeaponsToConfig=True;
	bDebugLog=True;
	CustomItems=DefaultItems;
	SaveSettings();

}

private final function SaveSettings()
{
	iVersion=`VERSION;
    
	SaveConfig();
	class'TIMRepLink'.Static.SaveSettings();
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

	LoadSettings();

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

		// item ID already in trader inventory?  no workie due to freeID
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

			if( ServerItems.Find('TraderId',TI.SaleItems[index].ItemID) < 0 )
			{
				RepItem.DefPath=CustomItems[i];
				RepItem.TraderId=TI.SaleItems[index].ItemID;
				ServerItems.AddItem( RepItem);
			}

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
//	WorldInfo.Game.Broadcast( none, "===TIM=== (v"$iVersion$") Weapons added:"@number);
	if( number > 0 )
		LogToConsole( "===TIM=== (v"$iVersion$") custom Weapons added to trader inventory:"@number);

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

/**/
	if( WeaponClass.Default.SecondaryAmmoTexture != None )
		CTI.SecondaryAmmoImagePath="img://"$PathName(WeaponClass.Default.SecondaryAmmoTexture);
	CTI.InventoryGroup=WeaponClass.Default.InventoryGroup;
	CTI.GroupPriority=WeaponClass.Default.GroupPriority;
	WeaponClass.Static.SetTraderWeaponStats( CTI.WeaponStats);
/**/


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

	// Killing Floor 2 Official Weapons
//	DefaultItems.Add("KFGame.KFWeapDef_9mm")
//	DefaultItems.Add("KFGame.KFWeapDef_9mmDual")
//	DefaultItems.Add("KFGame.KFWeapDef_AA12")
//	DefaultItems.Add("KFGame.KFWeapDef_Ak12")
//	DefaultItems.Add("KFGame.KFWeapDef_AR15")
//	DefaultItems.Add("KFGame.KFWeapDef_Armor")
//	DefaultItems.Add("KFGame.KFWeapDef_Bullpup")
//	DefaultItems.Add("KFGame.KFWeapDef_C4")
//	DefaultItems.Add("KFGame.KFWeapDef_CaulkBurn")
//	DefaultItems.Add("KFGame.KFWeapDef_CenterfireMB464")
//	DefaultItems.Add("KFGame.KFWeapDef_Colt1911")
//	DefaultItems.Add("KFGame.KFWeapDef_Colt1911Dual")
//	DefaultItems.Add("KFGame.KFWeapDef_Crossbow")
//	DefaultItems.Add("KFGame.KFWeapDef_Crovel")
//	DefaultItems.Add("KFGame.KFWeapDef_Deagle")
//	DefaultItems.Add("KFGame.KFWeapDef_DeagleDual")
//	DefaultItems.Add("KFGame.KFWeapDef_DoubleBarrel")
//	DefaultItems.Add("KFGame.KFWeapDef_DragonsBreath")
//	DefaultItems.Add("KFGame.KFWeapDef_Eviscerator")
//	DefaultItems.Add("KFGame.KFWeapDef_FlameThrower")
//	DefaultItems.Add("KFGame.KFWeapDef_FlareGun")
//	DefaultItems.Add("KFGame.KFWeapDef_FlareGunDual")
//	DefaultItems.Add("KFGame.KFWeapDef_Grenade_Berserker")
//	DefaultItems.Add("KFGame.KFWeapDef_Grenade_Commando")
//	DefaultItems.Add("KFGame.KFWeapDef_Grenade_Demo")
//	DefaultItems.Add("KFGame.KFWeapDef_Grenade_Firebug")
//	DefaultItems.Add("KFGame.KFWeapDef_Grenade_Gunslinger")
//	DefaultItems.Add("KFGame.KFWeapDef_Grenade_Medic")
//	DefaultItems.Add("KFGame.KFWeapDef_Grenade_Sharpshooter")
//	DefaultItems.Add("KFGame.KFWeapDef_Grenade_Support")
//	DefaultItems.Add("KFGame.KFWeapDef_Grenade_SWAT")
//	DefaultItems.Add("KFGame.KFWeapDef_Healer")
//	DefaultItems.Add("KFGame.KFWeapDef_HX25")
//	DefaultItems.Add("KFGame.KFWeapDef_HZ12")
//	DefaultItems.Add("KFGame.KFWeapDef_Katana")
//	DefaultItems.Add("KFGame.KFWeapDef_Knife_Commando")
//	DefaultItems.Add("KFGame.KFWeapDef_Knife_Demo")
//	DefaultItems.Add("KFGame.KFWeapDef_Knife_Firebug")
//	DefaultItems.Add("KFGame.KFWeapDef_Knife_Gunslinger")
//	DefaultItems.Add("KFGame.KFWeapDef_Knife_Medic")
//	DefaultItems.Add("KFGame.KFWeapDef_Knife_Sharpshooter")
//	DefaultItems.Add("KFGame.KFWeapDef_Knife_Support")
//	DefaultItems.Add("KFGame.KFWeapDef_Knife_SWAT")
//	DefaultItems.Add("KFGame.KFWeapDef_Kriss")
//	DefaultItems.Add("KFGame.KFWeapDef_M14EBR")
//	DefaultItems.Add("KFGame.KFWeapDef_M16M203")
//	DefaultItems.Add("KFGame.KFWeapDef_M4")
//	DefaultItems.Add("KFGame.KFWeapDef_M79")
//	DefaultItems.Add("KFGame.KFWeapDef_MaceAndShield")
//	DefaultItems.Add("KFGame.KFWeapDef_MB500")
//	DefaultItems.Add("KFGame.KFWeapDef_MedicPistol")
//	DefaultItems.Add("KFGame.KFWeapDef_MedicRifle")
//	DefaultItems.Add("KFGame.KFWeapDef_MedicShotgun")
//	DefaultItems.Add("KFGame.KFWeapDef_MedicSMG")
//	DefaultItems.Add("KFGame.KFWeapDef_MicrowaveGun")
//	DefaultItems.Add("KFGame.KFWeapDef_MP5RAS")
//	DefaultItems.Add("KFGame.KFWeapDef_MP7")
//	DefaultItems.Add("KFGame.KFWeapDef_NailGun")
//	DefaultItems.Add("KFGame.KFWeapDef_P90")
//	DefaultItems.Add("KFGame.KFWeapDef_Pulverizer")
//	DefaultItems.Add("KFGame.KFWeapDef_RailGun")
//	DefaultItems.Add("KFGame.KFWeapDef_Random")
//	DefaultItems.Add("KFGame.KFWeapDef_Remington1858")
//	DefaultItems.Add("KFGame.KFWeapDef_Remington1858Dual")
//	DefaultItems.Add("KFGame.KFWeapDef_RPG7")
//	DefaultItems.Add("KFGame.KFWeapDef_SCAR")
//	DefaultItems.Add("KFGame.KFWeapDef_Stoner63A")
//	DefaultItems.Add("KFGame.KFWeapDef_SW500")
//	DefaultItems.Add("KFGame.KFWeapDef_SW500Dual")
//	DefaultItems.Add("KFGame.KFWeapDef_Welder")
//	DefaultItems.Add("KFGame.KFWeapDef_Winchester1894")
//	DefaultItems.Add("KFGame.KFWeapDef_Zweihander")


	// == Unofficial Weapons Pack -- http://steamcommunity.com/sharedfiles/filedetails/?id=679839492 *
	DefaultItems.Add("KFGameHuskLauncher.KFWeapDef_BatAxe")
	DefaultItems.Add("KFGameHuskLauncher.KFWeapDef_BloatBileThrower")
	DefaultItems.Add("KFGameHuskLauncher.KFWeapDef_DwarvesAxe")
	DefaultItems.Add("KFGameHuskLauncher.KFWeapDef_FireAxe")
	DefaultItems.Add("KFGameHuskLauncher.KFWeapDef_FlameKatana")
	DefaultItems.Add("KFGameHuskLauncher.KFWeapDef_Flare")
	DefaultItems.Add("KFGameHuskLauncher.KFWeapDef_FlareDual")
	DefaultItems.Add("KFGameHuskLauncher.KFWeapDef_HuskCannon")
	DefaultItems.Add("KFGameHuskLauncher.KFWeapDef_M32")
//	DefaultItems.Add("KFGameHuskLauncher.KFWeapDef_M99")
	DefaultItems.Add("KFGameHuskLauncher.KFWeapDef_Mac10")
	DefaultItems.Add("KFGameHuskLauncher.KFWeapDef_MKB42")
	DefaultItems.Add("KFGameHuskLauncher.KFWeapDef_PPSH")

	// == Killing Floor 1 Game Mode -- http://steamcommunity.com/sharedfiles/filedetails/?id=681599774 *
//	DefaultItems.Add("KF1.KFWeapDef_9mm2")
//	DefaultItems.Add("KF1.KFWeapDef_9mmDual2")
//	DefaultItems.Add("KF1.KFWeapDef_AA122")
//	DefaultItems.Add("KF1.KFWeapDef_AK122")
//	DefaultItems.Add("KF1.KFWeapDef_AR152")
//	DefaultItems.Add("KF1.KFWeapDef_Bullpup2")
//	DefaultItems.Add("KF1.KFWeapDef_C42")
//	DefaultItems.Add("KF1.KFWeapDef_Colt19112")
//	DefaultItems.Add("KF1.KFWeapDef_Colt1911Dual2")
//	DefaultItems.Add("KF1.KFWeapDef_Crossbow2")
//	DefaultItems.Add("KF1.KFWeapDef_Deagle2")
//	DefaultItems.Add("KF1.KFWeapDef_DeagleDual2")
//	DefaultItems.Add("KF1.KFWeapDef_DoubleBarrel2")
//	DefaultItems.Add("KF1.KFWeapDef_DragonsBreath2")
//	DefaultItems.Add("KF1.KFWeapDef_FlareRev")
//	DefaultItems.Add("KF1.KFWeapDef_FlareRevDual")
//	DefaultItems.Add("KF1.KFWeapDef_FreezeGun")
//	DefaultItems.Add("KF1.KFWeapDef_Grenade_Demo2")
//	DefaultItems.Add("KF1.KFWeapDef_Grenade_Medic2")
//	DefaultItems.Add("KF1.KFWeapDef_HX252")
//	DefaultItems.Add("KF1.KFWeapDef_HZ122")
//	DefaultItems.Add("KF1.KFWeapDef_Knife_Commando2")
//	DefaultItems.Add("KF1.KFWeapDef_M14EBR2")
//	DefaultItems.Add("KF1.KFWeapDef_M16M2032")
//	DefaultItems.Add("KF1.KFWeapDef_M42")
//	DefaultItems.Add("KF1.KFWeapDef_M792")
//	DefaultItems.Add("KF1.KFWeapDef_MB5002")
//	DefaultItems.Add("KF1.KFWeapDef_MedicLauncher")
//	DefaultItems.Add("KF1.KFWeapDef_MedicPistol2")
//	DefaultItems.Add("KF1.KFWeapDef_MedicRifle2")
//	DefaultItems.Add("KF1.KFWeapDef_MedicShotgun2")
//	DefaultItems.Add("KF1.KFWeapDef_MedicSMG2")
//	DefaultItems.Add("KF1.KFWeapDef_RailGun2")
//	DefaultItems.Add("KF1.KFWeapDef_RPG72")
//	DefaultItems.Add("KF1.KFWeapDef_SCAR2")
//	DefaultItems.Add("KF1.KFWeapDef_Stoner63A2")
//	DefaultItems.Add("KF1.KFWeapDef_SWBOOM")
//	DefaultItems.Add("KF1.KFWeapDef_Winchester18942")

	// == Armory Unofficial Weapons Pack -- http://steamcommunity.com/sharedfiles/filedetails/?id=888134329 **
	DefaultItems.Add("Armory.KFWeapDef_AK74M")
	DefaultItems.Add("Armory.KFWeapDef_AKM")
	DefaultItems.Add("Armory.KFWeapDef_AKS74U")
	DefaultItems.Add("Armory.KFWeapDef_BAR")
	DefaultItems.Add("Armory.KFWeapDef_CZ75")
	DefaultItems.Add("Armory.KFWeapDef_DualMK23")
	DefaultItems.Add("Armory.KFWeapDef_DualTT33")
	DefaultItems.Add("Armory.KFWeapDef_FNFNC")
	DefaultItems.Add("Armory.KFWeapDef_G3")
	DefaultItems.Add("Armory.KFWeapDef_Galil")
	DefaultItems.Add("Armory.KFWeapDef_M14")
	DefaultItems.Add("Armory.KFWeapDef_M1Carbine")
	DefaultItems.Add("Armory.KFWeapDef_M4Carbine")
	DefaultItems.Add("Armory.KFWeapDef_MAS4956")
	DefaultItems.Add("Armory.KFWeapDef_MK23")
	DefaultItems.Add("Armory.KFWeapDef_OTs_33")
	DefaultItems.Add("Armory.KFWeapDef_Spectre")
	DefaultItems.Add("Armory.KFWeapDef_SVD")
	DefaultItems.Add("Armory.KFWeapDef_SVT40")
	DefaultItems.Add("Armory.KFWeapDef_Thermobaric")
	DefaultItems.Add("Armory.KFWeapDef_TT33")
	DefaultItems.Add("Armory.KFWeapDef_UMP")
	DefaultItems.Add("Armory.KFWeapDef_VAL")

	// == LordOfWar Weapon Mutator -- http://steamcommunity.com/sharedfiles/filedetails/?id=890082699
	DefaultItems.Add("AA12Dragon.KFWeapDef_AA12Dragon")
	DefaultItems.Add("ammobox2.KFWeapDef_AmmoBox")
	DefaultItems.Add("barretw.KFWeapDef_Rifle_Barret50")
	DefaultItems.Add("BileThrower.KFWeapDef_BileThrower")
	DefaultItems.Add("hkm14w.KFWeapDef_HK416")
	DefaultItems.Add("louiville.KFWeapDef_Bat")
	DefaultItems.Add("m60.KFWeapDef_M60")
	DefaultItems.Add("m79medic.KFWeapDef_M79M")
	DefaultItems.Add("m79ss.KFWeapDef_M79SS")
	DefaultItems.Add("mac10.KFWeapDef_MAC10")
	DefaultItems.Add("mauser.KFWeapDef_DualMauser")
	DefaultItems.Add("mauser.KFWeapDef_Mauser")
	DefaultItems.Add("mk42b.KFWeapDef_MK42B")
	DefaultItems.Add("nukeatw.KFWeapDef_NUKEAT")
	DefaultItems.Add("patriot.KFWeapDef_DualPatriot")
	DefaultItems.Add("patriot.KFWeapDef_Patriot")
	DefaultItems.Add("railgunzr2.KFWeapDef_RailGunZR2")
	DefaultItems.Add("TF2SentryModV2.SentryWeaponDef")
	DefaultItems.Add("tommygun.KFWeapDef_TommyGun")

	// == AKS-74u -- http://steamcommunity.com/sharedfiles/filedetails/?id=896034477 (*)
	DefaultItems.Add("AKS74UMut.KFWeapDef_AKS74U")

	// == Custom M14EBRs -- http://steamcommunity.com/sharedfiles/filedetails/?id=959410214 **
//	DefaultItems.Add("CustomM14s.KFWeapDef_CustomM14EBR")
	DefaultItems.Add("CustomM14s.KFWeapDef_IronSightM14EBR")

	// == Schneidzekk -- http://steamcommunity.com/sharedfiles/filedetails/?id=1117901956
	DefaultItems.Add("Schneidzekk.KFWeapDef_Schneidzekk")

	// == CustomM14EBR Mutator -- http://steamcommunity.com/sharedfiles/filedetails/?id=1134625264
	DefaultItems.Add("CustomM14Mut.KFWeapDef_CustomM14EBR")

	// == CustomLAR Mutator -- http://steamcommunity.com/sharedfiles/filedetails/?id=1131782590
	DefaultItems.Add("CustomLARMut.KFWeapDef_LAR")

	// == M99 Sniper rifle -- http://steamcommunity.com/sharedfiles/filedetails/?id=1137411101
	DefaultItems.Add("M99.KFWeapDef_M99")

	// == Weapon Pack -- http://steamcommunity.com/sharedfiles/filedetails/?id=1147408497
	DefaultItems.Add("WeaponPack.KFWeapDef_AUG9mm")
	DefaultItems.Add("WeaponPack.KFWeapDef_M60MG")
	DefaultItems.Add("WeaponPack.KFWeapDef_Spas12")
	//DefaultItems.Add("WeaponPack.KFWeapDef_SVD")

	// == M16M203MDC -- http://steamcommunity.com/sharedfiles/filedetails/?id=1150733214
	DefaultItems.Add("M16M203MDC.KFWeapDef_M16M203MDC")

/*
	// == BassCannon -- http://steamcommunity.com/sharedfiles/filedetails/?id=1137726392
	DefaultItems.Add("BassCannon.KFWeapDef_BassCannon")

	// == Helfire shotgun -- http://steamcommunity.com/sharedfiles/filedetails/?id=1137952760
	DefaultItems.Add("Hellfire.KFWeapDef_Hellfire")
	DefaultItems.Add("Hellfire.KFWeapDef_HellfireDual")

	// == Tracer Pistols -- http://steamcommunity.com/sharedfiles/filedetails/?id=1138237412
	DefaultItems.Add("Tracer.KFWeapDef_Tracer")
	DefaultItems.Add("Tracer.KFWeapDef_TracerDual")

	// == SawHammer -- http://steamcommunity.com/sharedfiles/filedetails/?id=1138303678
	DefaultItems.Add("SawHammer.KFWeapDef_SawHammer")
*/

}






