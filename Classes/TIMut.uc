
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
                TheConsole.OutputText( "[TIM] (v" $ `VERSION $ ") " $ Text);
        }
    }
}


private final function LoadSettings()
{

	`DebugFlow( ".");
	`logInfo( "Code version: "$`VERSION$", config version: "$iVersion);


	if( iVersion > 0 )
		InitSettings();
	else
		ResetSettings();

}

private final function InitSettings()
{

	`DebugFlow( ".");

	if( CustomItems.Length < 1 )
	{
//		CustomItems=DefaultItems;
//		SaveSettings();
		ResetSettings();
	}
	else if( bAddNewWeaponsToConfig && iVersion < `VERSION )
	{
		AddNewItemsToConfig();
	}


}

private final function AddNewItemsToConfig()
{

	`DebugFlow( ".");

	switch( iVersion )
	{

	case 1:
		CustomItems.AddItem( "WeaponPack.KFWeapDef_AUG9mm");
		CustomItems.AddItem( "WeaponPack.KFWeapDef_M60MG");
		CustomItems.AddItem( "WeaponPack.KFWeapDef_Spas12");

	case 2:
		CustomItems.AddItem( "M16M203MDC.KFWeapDef_M16M203MDC");

	case 3:
		CustomItems.AddItem( "KFGame.KFWeapDef_Crovel");
		CustomItems.AddItem( "KFGame.KFWeapDef_Katana");
		CustomItems.AddItem( "KFGame.KFWeapDef_Nailgun");
		CustomItems.AddItem( "KFGame.KFWeapDef_Zweihander");
		CustomItems.AddItem( "KFGame.KFWeapDef_Pulverizer");
		CustomItems.AddItem( "KFGame.KFWeapDef_Eviscerator");
		CustomItems.AddItem( "KFGame.KFWeapDef_MaceAndShield");
		CustomItems.AddItem( "KFGame.KFWeapDef_AR15");
		CustomItems.AddItem( "KFGame.KFWeapDef_Bullpup");
		CustomItems.AddItem( "KFGame.KFWeapDef_AK12");
		CustomItems.AddItem( "KFGame.KFWeapDef_SCAR");
		CustomItems.AddItem( "KFGame.KFWeapDef_Stoner63A");
		CustomItems.AddItem( "KFGame.KFWeapDef_HX25");
		CustomItems.AddItem( "KFGame.KFWeapDef_C4");
		CustomItems.AddItem( "KFGame.KFWeapDef_M79");
		CustomItems.AddItem( "KFGame.KFWeapDef_RPG7");
		CustomItems.AddItem( "KFGame.KFWeapDef_Seeker6");
		CustomItems.AddItem( "KFGame.KFWeapDef_MedicPistol");
		CustomItems.AddItem( "KFGame.KFWeapDef_MedicSMG");
		CustomItems.AddItem( "KFGame.KFWeapDef_MedicShotgun");
		CustomItems.AddItem( "KFGame.KFWeapDef_MedicRifle");
		CustomItems.AddItem( "KFGame.KFWeapDef_Remington1858");
		CustomItems.AddItem( "KFGame.KFWeapDef_Remington1858Dual");
		CustomItems.AddItem( "KFGame.KFWeapDef_Colt1911");
		CustomItems.AddItem( "KFGame.KFWeapDef_Colt1911Dual");
		CustomItems.AddItem( "KFGame.KFWeapDef_Deagle");
		CustomItems.AddItem( "KFGame.KFWeapDef_DeagleDual");
		CustomItems.AddItem( "KFGame.KFWeapDef_SW500");
		CustomItems.AddItem( "KFGame.KFWeapDef_SW500Dual");
		CustomItems.AddItem( "KFGame.KFWeapDef_MB500");
		CustomItems.AddItem( "KFGame.KFWeapDef_DoubleBarrel");
		CustomItems.AddItem( "KFGame.KFWeapDef_HZ12");
		CustomItems.AddItem( "KFGame.KFWeapDef_M4");
		CustomItems.AddItem( "KFGame.KFWeapDef_AA12");
		CustomItems.AddItem( "KFGame.KFWeapDef_CaulkBurn");
		CustomItems.AddItem( "KFGame.KFWeapDef_FlareGun");
		CustomItems.AddItem( "KFGame.KFWeapDef_FlareGunDual");
		CustomItems.AddItem( "KFGame.KFWeapDef_DragonsBreath");
		CustomItems.AddItem( "KFGame.KFWeapDef_FlameThrower");
		CustomItems.AddItem( "KFGame.KFWeapDef_MicrowaveGun");
		CustomItems.AddItem( "KFGame.KFWeapDef_Winchester1894");
		CustomItems.AddItem( "KFGame.KFWeapDef_CenterfireMB464");
		CustomItems.AddItem( "KFGame.KFWeapDef_Crossbow");
		CustomItems.AddItem( "KFGame.KFWeapDef_M14EBR");
		CustomItems.AddItem( "KFGame.KFWeapDef_RailGun");
		CustomItems.AddItem( "KFGame.KFWeapDef_9mm");
		CustomItems.AddItem( "KFGame.KFWeapDef_9mmDual");
		CustomItems.AddItem( "KFGame.KFWeapDef_MP7");
		CustomItems.AddItem( "KFGame.KFWeapDef_M16M203");
		CustomItems.AddItem( "KFGame.KFWeapDef_MP5RAS");
		CustomItems.AddItem( "KFGame.KFWeapDef_P90");
		CustomItems.AddItem( "KFGame.KFWeapDef_Kriss");
		CustomItems.AddItem( "KFGame.KFWeapDef_Hemogoblin");

		CustomItems.AddItem( "CDWM.KFWeapDef_AA12Dragon");
		CustomItems.AddItem( "CDWM.KFWeapDef_AK47");
		CustomItems.AddItem( "CDWM.KFWeapDef_BileThrower");
		CustomItems.AddItem( "CDWM.KFWeapDef_FNC");
		CustomItems.AddItem( "CDWM.KFWeapDef_HK416");
		CustomItems.AddItem( "CDWM.KFWeapDef_M4_2");
		CustomItems.AddItem( "CDWM.KFWeapDef_MK");
		CustomItems.AddItem( "CDWM.KFWeapDef_DualMauser");
		CustomItems.AddItem( "CDWM.KFWeapDef_Mauser");
		CustomItems.AddItem( "CDWM.KFWeapDef_NUKEAT");
		CustomItems.AddItem( "CDWM.KFWeapDef_RailGunZR2");
		CustomItems.AddItem( "CDWM.KFWeapDef_Rifle_Barret50");
		CustomItems.AddItem( "CDWM.KFWeapDef_ZedTimeTBall2");

		CustomItems.AddItem( "WeaponPack.KFWeapDef_AmmoBox");
		CustomItems.AddItem( "WeaponPack.KFWeapDef_AUG9mm");
		CustomItems.AddItem( "WeaponPack.KFWeapDef_DragonBlade");
		CustomItems.AddItem( "WeaponPack.KFWeapDef_DualPatriot");
		CustomItems.AddItem( "WeaponPack.KFWeapDef_Glock");
		CustomItems.AddItem( "WeaponPack.KFWeapDef_GlockDual");
		CustomItems.AddItem( "WeaponPack.KFWeapDef_H134");
		CustomItems.AddItem( "WeaponPack.KFWeapDef_Healthpack");
		CustomItems.AddItem( "WeaponPack.KFWeapDef_M60MG");
		CustomItems.AddItem( "WeaponPack.KFWeapDef_Patriot");
		CustomItems.AddItem( "WeaponPack.KFWeapDef_Skull9");
		CustomItems.AddItem( "WeaponPack.KFWeapDef_Spas12");
		CustomItems.AddItem( "WeaponPack.KFWeapDef_SVD");

	case 4:
		CustomItems.RemoveItem( "AA12Dragon.KFWeapDef_AA12Dragon");
		CustomItems.RemoveItem( "ammobox2.KFWeapDef_AmmoBox");
		CustomItems.RemoveItem( "barretw.KFWeapDef_Rifle_Barret50");
		CustomItems.RemoveItem( "BileThrower.KFWeapDef_BileThrower");
		CustomItems.RemoveItem( "hkm14w.KFWeapDef_HK416");
		CustomItems.RemoveItem( "louiville.KFWeapDef_Bat");
		CustomItems.RemoveItem( "m60.KFWeapDef_M60");
		CustomItems.RemoveItem( "m79medic.KFWeapDef_M79M");
		CustomItems.RemoveItem( "m79ss.KFWeapDef_M79SS");
		CustomItems.RemoveItem( "mac10.KFWeapDef_MAC10");
		CustomItems.RemoveItem( "mauser.KFWeapDef_DualMauser");
		CustomItems.RemoveItem( "mauser.KFWeapDef_Mauser");
		CustomItems.RemoveItem( "mk42b.KFWeapDef_MK42B");
		CustomItems.RemoveItem( "nukeatw.KFWeapDef_NUKEAT");
		CustomItems.RemoveItem( "patriot.KFWeapDef_DualPatriot");
		CustomItems.RemoveItem( "patriot.KFWeapDef_Patriot");
		CustomItems.RemoveItem( "railgunzr2.KFWeapDef_RailGunZR2");
		CustomItems.RemoveItem( "TF2SentryModV2.SentryWeaponDef");
		CustomItems.RemoveItem( "tommygun.KFWeapDef_TommyGun");
		CustomItems.AddItem( "gunz.KFWeapDef_AA12Dragon");
		CustomItems.AddItem( "gunz.KFWeapDef_AK47");
		CustomItems.AddItem( "gunz.KFWeapDef_AmmoBox");
		CustomItems.AddItem( "gunz.KFWeapDef_AUG9mm");
		CustomItems.AddItem( "gunz.KFWeapDef_BileThrower");
		CustomItems.AddItem( "gunz.KFWeapDef_DragonBlade");
		CustomItems.AddItem( "gunz.KFWeapDef_FNC");
		CustomItems.AddItem( "gunz.KFWeapDef_Glock");
		CustomItems.AddItem( "gunz.KFWeapDef_GlockDual");
		CustomItems.AddItem( "gunz.KFWeapDef_H134");
		CustomItems.AddItem( "gunz.KFWeapDef_HK416");
		CustomItems.AddItem( "gunz.KFWeapDef_M4_2");
		CustomItems.AddItem( "gunz.KFWeapDef_M60");
		CustomItems.AddItem( "gunz.KFWeapDef_M79M");
		CustomItems.AddItem( "gunz.KFWeapDef_Mauser");
		CustomItems.AddItem( "gunz.KFWeapDef_DualMauser");
		CustomItems.AddItem( "gunz.KFWeapDef_MedicKriss");
		CustomItems.AddItem( "gunz.KFWeapDef_MK");
		CustomItems.AddItem( "gunz.KFWeapDef_NUKEAT");
		CustomItems.AddItem( "gunz.KFWeapDef_Patriot");
		CustomItems.AddItem( "gunz.KFWeapDef_DualPatriot");
		CustomItems.AddItem( "gunz.KFWeapDef_RailGunZR2");
		CustomItems.AddItem( "gunz.KFWeapDef_Rifle_Barret50");
		CustomItems.AddItem( "gunz.KFWeapDef_Skull9");
		CustomItems.AddItem( "gunz.KFWeapDef_Spas12");
		CustomItems.AddItem( "gunz.KFWeapDef_Spectre");
		CustomItems.AddItem( "gunz.KFWeapDef_SVD");
		CustomItems.AddItem( "gunz.KFWeapDef_ZedTimeTBall2");

	case 5:
		CustomItems.AddItem( "KFGame.KFWeapDef_FreezeThrower");
		CustomItems.AddItem( "KFGame.KFWeapDef_HK_UMP");
		CustomItems.AddItem( "KFGameHuskLauncher.KFWeapDef_M99");
		CustomItems.AddItem( "CustomM14s.KFWeapDef_CustomM14EBR");
		CustomItems.AddItem( "CDWM.KFWeapDef_AmmoBox");
		CustomItems.AddItem( "CDWM.KFWeapDef_M60");
		CustomItems.AddItem( "CDWM.KFWeapDef_SVD");

	case 6:
		CustomItems.RemoveItem( "Armory.KFWeapDef_FNFNC");
		CustomItems.RemoveItem( "Armory.KFWeapDef_UMP");
		CustomItems.AddItem( "Armory.KFWeapDef_XM177");
		CustomItems.AddItem( "Armory.KFWeapDef_HiPower");
		CustomItems.AddItem( "WeaponPack.KFWeapDef_AK74M");
		CustomItems.AddItem( "WeaponPack.KFWeapDef_Seeker3K");
		CustomItems.AddItem( "WeaponPack.KFWeapDef_Spectre");

	case 7:
		/* oops, these three were supposed to be under case 6 */
		CustomItems.AddItem( "Hellfire.KFWeapDef_Hellfire");
		CustomItems.AddItem( "Hellfire.KFWeapDef_HellfireDual");
		CustomItems.AddItem( "PracGun.KFWeapDef_PracGun");

		CustomItems.AddItem( "HealthPack.KFWeapDef_Healthpack");
		CustomItems.AddItem( "DubstepGun.KFWeapDef_DubstepGun");
		CustomItems.AddItem( "TKB059.KFWeapDef_TKB");
		CustomItems.AddItem( "KFGame.KFWeapDef_AF2011");
		CustomItems.AddItem( "KFGame.KFWeapDef_Mac10");
		CustomItems.AddItem( "KFGame.KFWeapDef_HuskCannon");
		CustomItems.AddItem( "KFGame.KFWeapDef_AF2011Dual");
		CustomItems.RemoveItem( "WeaponPack.KFWeapDef_AK74M");
		CustomItems.RemoveItem( "WeaponPack.KFWeapDef_Spectre");
		CustomItems.AddItem( "WeaponPack.KFWeapDef_Albert");
		CustomItems.AddItem( "WeaponPack.KFWeapDef_AlbertDual");
		CustomItems.AddItem( "WeaponPack.KFWeapDef_BFG9000");
		CustomItems.AddItem( "WeaponPack.KFWeapDef_AS50");
		CustomItems.AddItem( "WeaponPack.KFWeapDef_Buzzsaw");
		CustomItems.AddItem( "WeaponPack.KFWeapDef_CZ805");
		CustomItems.AddItem( "WeaponPack.KFWeapDef_HeavyAR");
		CustomItems.AddItem( "WeaponPack.KFWeapDef_HellFireSSingle");
		CustomItems.AddItem( "WeaponPack.KFWeapDef_HellFireS");
		CustomItems.AddItem( "WeaponPack.KFWeapDef_M14EBRAR");
		CustomItems.AddItem( "WeaponPack.KFWeapDef_M16Medic");
		CustomItems.AddItem( "WeaponPack.KFWeapDef_Mac10Ext");
		CustomItems.AddItem( "WeaponPack.KFWeapDef_DualMAC10");
		CustomItems.AddItem( "WeaponPack.KFWeapDef_RLPRO");
		CustomItems.AddItem( "WeaponPack.KFWeapDef_Reaper");
		CustomItems.AddItem( "WeaponPack.KFWeapDef_Scythe");
		CustomItems.AddItem( "WeaponPack.KFWeapDef_TKB");


	case 8:
		`LogInfo( "Updating config");
		SaveSettings();
	}

}

private final function ResetSettings()
{

	`DebugFlow( ".");
	`LogInfo( "Resetting config");
	bAddNewWeaponsToConfig=True;
	bDebugLog=True;
	CustomItems=DefaultItems;
	SaveSettings();

}

private final function SaveSettings()
{

	`DebugFlow( ".");
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
    
    `DebugFlow( ".");

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
    
    `DebugFlow( ".");

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
    
    `DebugFlow( ".");

    bRepReady = true;
    
    foreach RepClients(RepClient)
    {
        SyncClient(RepClient);
    }
}

private final function SyncClient(SClient RepClient)
{
	`DebugFlow( ".");

	RepClient.RepLink.ClientItems=ServerItems;
	RepClient.RepLink.StartSyncItems();
}

function NotifyLogin(Controller C)
{
    `DebugFlow( ".");

    CreateRepLink(C);
    
    Super.NotifyLogin(C);
}

function NotifyLogout(Controller C)
{
    `DebugFlow( ".");

    DestroyRepLink(C);
    
    Super.NotifyLogout(C);
}

function GetSeamlessTravelActorList(bool bEntry, out array<Actor> Actors)
{
    `DebugFlow( ".");

    DestroyClients();
    
    Super.GetSeamlessTravelActorList(bEntry, Actors);
}



event PreBeginPlay()
{
	`DebugFlow( ".");

	Super.PreBeginPlay();
}


event PostBeginPlay()
{

	`DebugFlow( ".");

	super.PostBeginPlay();

	if( WorldInfo.Game.BaseMutator == None )
		WorldInfo.Game.BaseMutator=Self;
	else
		WorldInfo.Game.BaseMutator.AddMutator( Self);

	LoadSettings();

	SetTimer( 1.0f, true, nameof(ItemsTimer));

}


function InitMutator(string Options, out string ErrorMessage)
{
	`DebugFlow( ".");

	super.InitMutator( Options, ErrorMessage );
}


private function ItemsTimer()
{

	`DebugFlow( ".");

	if( AddItems() )
	{
		ClearTimer( nameof(ItemsTimer));
		SyncClients();
	}

}


final function bool AddItems()
{
	local KFGameReplicationInfo KFGRI;
	local KFGFxObject_TraderItems TI;
	local string CustomItem;
	local STraderItem item;
	local int i, number;
	local SItem RepItem;


	`DebugFlow( ".");

	if( WorldInfo == none )
	{
		`Debug( "no WI");
		return False;
	}

	KFGRI = KFGameReplicationInfo(WorldInfo.GRI);
	if( KFGRI == none )
	{
		`Debug( "no KFGRI");
		return False;
	}

	TI=new class'KFGFxObject_TraderItems';

	number=0;
	foreach CustomItems( CustomItem, i)
	{
		item.WeaponDef=class<KFWeaponDefinition>(DynamicLoadObject(CustomItem,class'Class'));
		if( item.WeaponDef == none )
		{
			`logInfo( "dropping unknown CustomItem["$i$"]: "$ CustomItem);
			continue;
		}

		RepItem.DefPath=CustomItem;
		RepItem.TraderId=number;
		ServerItems.AddItem( RepItem);

		`logInfo( "adding CustomItem["$i$"]: " $ CustomItem);
		item.ItemID=RepItem.TraderId;
		TI.SaleItems.AddItem( item);

		number++;
	}

	if( number > 0 )
		TI.SetItemsInfo( TI.SaleItems);

	`logInfo( "Items added to trader inventory: "$number);
	LogToConsole( "Items added to trader inventory: "$ number);

	KFGRI.TraderItems=TI;
	return True;
}


function AddMutator(Mutator M)
{
	`DebugFlow( ".");

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


	// == Killing Floor 2 Official Weapons -- http://steamcommunity.com/app/232090/
	DefaultItems.Add( "KFGame.KFWeapDef_9mm")
	DefaultItems.Add( "KFGame.KFWeapDef_Remington1858")
	DefaultItems.Add( "KFGame.KFWeapDef_Crovel")
	DefaultItems.Add( "KFGame.KFWeapDef_AR15")
	DefaultItems.Add( "KFGame.KFWeapDef_MedicPistol")
	DefaultItems.Add( "KFGame.KFWeapDef_Remington1858Dual")
	DefaultItems.Add( "KFGame.KFWeapDef_MB500")
	DefaultItems.Add( "KFGame.KFWeapDef_CaulkBurn")
	DefaultItems.Add( "KFGame.KFWeapDef_Winchester1894")
	DefaultItems.Add( "KFGame.KFWeapDef_MP7")
	DefaultItems.Add( "KFGame.KFWeapDef_HX25")
	DefaultItems.Add( "KFGame.KFWeapDef_9mmDual")
	DefaultItems.Add( "KFGame.KFWeapDef_Colt1911")
	DefaultItems.Add( "KFGame.KFWeapDef_FlareGun")
	DefaultItems.Add( "KFGame.KFWeapDef_Deagle")
	DefaultItems.Add( "KFGame.KFWeapDef_Katana")
	DefaultItems.Add( "KFGame.KFWeapDef_Nailgun")
	DefaultItems.Add( "KFGame.KFWeapDef_Bullpup")
	DefaultItems.Add( "KFGame.KFWeapDef_C4")
	DefaultItems.Add( "KFGame.KFWeapDef_M79")
	DefaultItems.Add( "KFGame.KFWeapDef_MedicSMG")
	DefaultItems.Add( "KFGame.KFWeapDef_Colt1911Dual")
	DefaultItems.Add( "KFGame.KFWeapDef_DoubleBarrel")
	DefaultItems.Add( "KFGame.KFWeapDef_FlareGunDual")
	DefaultItems.Add( "KFGame.KFWeapDef_DragonsBreath")
	DefaultItems.Add( "KFGame.KFWeapDef_CenterfireMB464")
	DefaultItems.Add( "KFGame.KFWeapDef_Crossbow")
	DefaultItems.Add( "KFGame.KFWeapDef_MP5RAS")
	DefaultItems.Add( "KFGame.KFWeapDef_SW500")
	DefaultItems.Add( "KFGame.KFWeapDef_HZ12")
	DefaultItems.Add( "KFGame.KFWeapDef_AF2011")
	DefaultItems.Add( "KFGame.KFWeapDef_Zweihander")
	DefaultItems.Add( "KFGame.KFWeapDef_AK12")
	DefaultItems.Add( "KFGame.KFWeapDef_MedicShotgun")
	DefaultItems.Add( "KFGame.KFWeapDef_DeagleDual")
	DefaultItems.Add( "KFGame.KFWeapDef_M4")
	DefaultItems.Add( "KFGame.KFWeapDef_FlameThrower")
	DefaultItems.Add( "KFGame.KFWeapDef_M14EBR")
	DefaultItems.Add( "KFGame.KFWeapDef_P90")
	DefaultItems.Add( "KFGame.KFWeapDef_FreezeThrower")
	DefaultItems.Add( "KFGame.KFWeapDef_Hemogoblin")
	DefaultItems.Add( "KFGame.KFWeapDef_Mac10")
	DefaultItems.Add( "KFGame.KFWeapDef_Pulverizer")
	DefaultItems.Add( "KFGame.KFWeapDef_M16M203")
	DefaultItems.Add( "KFGame.KFWeapDef_HK_UMP")
	DefaultItems.Add( "KFGame.KFWeapDef_MaceAndShield")
	DefaultItems.Add( "KFGame.KFWeapDef_SCAR")
	DefaultItems.Add( "KFGame.KFWeapDef_Stoner63A")
	DefaultItems.Add( "KFGame.KFWeapDef_RPG7")
	DefaultItems.Add( "KFGame.KFWeapDef_Seeker6")
	DefaultItems.Add( "KFGame.KFWeapDef_MedicRifle")
	DefaultItems.Add( "KFGame.KFWeapDef_SW500Dual")
	DefaultItems.Add( "KFGame.KFWeapDef_AA12")
	DefaultItems.Add( "KFGame.KFWeapDef_MicrowaveGun")
	DefaultItems.Add( "KFGame.KFWeapDef_RailGun")
	DefaultItems.Add( "KFGame.KFWeapDef_Kriss")
	DefaultItems.Add( "KFGame.KFWeapDef_HuskCannon")
	DefaultItems.Add( "KFGame.KFWeapDef_AF2011Dual")
	DefaultItems.Add( "KFGame.KFWeapDef_Eviscerator")

//	DefaultItems.Add( "KFGame.KFWeapDef_Grenade_Berserker")
//	DefaultItems.Add( "KFGame.KFWeapDef_Grenade_Commando")
//	DefaultItems.Add( "KFGame.KFWeapDef_Grenade_Demo")
//	DefaultItems.Add( "KFGame.KFWeapDef_Grenade_Firebug")
//	DefaultItems.Add( "KFGame.KFWeapDef_Grenade_Gunslinger")
//	DefaultItems.Add( "KFGame.KFWeapDef_Grenade_Medic")
//	DefaultItems.Add( "KFGame.KFWeapDef_Grenade_Sharpshooter")
//	DefaultItems.Add( "KFGame.KFWeapDef_Grenade_Support")
//	DefaultItems.Add( "KFGame.KFWeapDef_Grenade_SWAT")
//	DefaultItems.Add( "KFGame.KFWeapDef_Healer")
//	DefaultItems.Add( "KFGame.KFWeapDef_Knife_Berserker")
//	DefaultItems.Add( "KFGame.KFWeapDef_Knife_Commando")
//	DefaultItems.Add( "KFGame.KFWeapDef_Knife_Demo")
//	DefaultItems.Add( "KFGame.KFWeapDef_Knife_Firebug")
//	DefaultItems.Add( "KFGame.KFWeapDef_Knife_Gunslinger")
//	DefaultItems.Add( "KFGame.KFWeapDef_Knife_Medic")
//	DefaultItems.Add( "KFGame.KFWeapDef_Knife_Sharpshooter")
//	DefaultItems.Add( "KFGame.KFWeapDef_Knife_Support")
//	DefaultItems.Add( "KFGame.KFWeapDef_Knife_SWAT")
//	DefaultItems.Add( "KFGame.KFWeapDef_Random")
//	DefaultItems.Add( "KFGame.KFWeapDef_Welder")


	// == Unofficial Weapons Pack -- http://steamcommunity.com/sharedfiles/filedetails/?id=679839492 *
	DefaultItems.Add( "KFGameHuskLauncher.KFWeapDef_BatAxe")
	DefaultItems.Add( "KFGameHuskLauncher.KFWeapDef_BloatBileThrower")
	DefaultItems.Add( "KFGameHuskLauncher.KFWeapDef_DwarvesAxe")
	DefaultItems.Add( "KFGameHuskLauncher.KFWeapDef_FireAxe")
	DefaultItems.Add( "KFGameHuskLauncher.KFWeapDef_FlameKatana")
	DefaultItems.Add( "KFGameHuskLauncher.KFWeapDef_Flare")
	DefaultItems.Add( "KFGameHuskLauncher.KFWeapDef_FlareDual")
	DefaultItems.Add( "KFGameHuskLauncher.KFWeapDef_HuskCannon")
	DefaultItems.Add( "KFGameHuskLauncher.KFWeapDef_M32")
	DefaultItems.Add( "KFGameHuskLauncher.KFWeapDef_M99")
	DefaultItems.Add( "KFGameHuskLauncher.KFWeapDef_Mac10")
	DefaultItems.Add( "KFGameHuskLauncher.KFWeapDef_MKB42")
	DefaultItems.Add( "KFGameHuskLauncher.KFWeapDef_PPSH")

	// == Killing Floor 1 Game Mode -- http://steamcommunity.com/sharedfiles/filedetails/?id=681599774 *
//	DefaultItems.Add( "KF1.KFWeapDef_9mm2")
//	DefaultItems.Add( "KF1.KFWeapDef_9mmDual2")
//	DefaultItems.Add( "KF1.KFWeapDef_AA122")
//	DefaultItems.Add( "KF1.KFWeapDef_AK122")
//	DefaultItems.Add( "KF1.KFWeapDef_AR152")
//	DefaultItems.Add( "KF1.KFWeapDef_Bullpup2")
//	DefaultItems.Add( "KF1.KFWeapDef_C42")
//	DefaultItems.Add( "KF1.KFWeapDef_Colt19112")
//	DefaultItems.Add( "KF1.KFWeapDef_Colt1911Dual2")
//	DefaultItems.Add( "KF1.KFWeapDef_Crossbow2")
//	DefaultItems.Add( "KF1.KFWeapDef_Deagle2")
//	DefaultItems.Add( "KF1.KFWeapDef_DeagleDual2")
//	DefaultItems.Add( "KF1.KFWeapDef_DoubleBarrel2")
//	DefaultItems.Add( "KF1.KFWeapDef_DragonsBreath2")
//	DefaultItems.Add( "KF1.KFWeapDef_FlareRev")
//	DefaultItems.Add( "KF1.KFWeapDef_FlareRevDual")
//	DefaultItems.Add( "KF1.KFWeapDef_FreezeGun")
//	DefaultItems.Add( "KF1.KFWeapDef_Grenade_Demo2")
//	DefaultItems.Add( "KF1.KFWeapDef_Grenade_Medic2")
//	DefaultItems.Add( "KF1.KFWeapDef_HX252")
//	DefaultItems.Add( "KF1.KFWeapDef_HZ122")
//	DefaultItems.Add( "KF1.KFWeapDef_Knife_Commando2")
//	DefaultItems.Add( "KF1.KFWeapDef_M14EBR2")
//	DefaultItems.Add( "KF1.KFWeapDef_M16M2032")
//	DefaultItems.Add( "KF1.KFWeapDef_M42")
//	DefaultItems.Add( "KF1.KFWeapDef_M792")
//	DefaultItems.Add( "KF1.KFWeapDef_MB5002")
//	DefaultItems.Add( "KF1.KFWeapDef_MedicLauncher")
//	DefaultItems.Add( "KF1.KFWeapDef_MedicPistol2")
//	DefaultItems.Add( "KF1.KFWeapDef_MedicRifle2")
//	DefaultItems.Add( "KF1.KFWeapDef_MedicShotgun2")
//	DefaultItems.Add( "KF1.KFWeapDef_MedicSMG2")
//	DefaultItems.Add( "KF1.KFWeapDef_RailGun2")
//	DefaultItems.Add( "KF1.KFWeapDef_RPG72")
//	DefaultItems.Add( "KF1.KFWeapDef_SCAR2")
//	DefaultItems.Add( "KF1.KFWeapDef_Stoner63A2")
//	DefaultItems.Add( "KF1.KFWeapDef_SWBOOM")
//	DefaultItems.Add( "KF1.KFWeapDef_Winchester18942")

	// == Armory Unofficial Weapons Pack -- http://steamcommunity.com/sharedfiles/filedetails/?id=888134329 **
	DefaultItems.Add( "Armory.KFWeapDef_AK74M")
	DefaultItems.Add( "Armory.KFWeapDef_AKM")
	DefaultItems.Add( "Armory.KFWeapDef_AKS74U")
	DefaultItems.Add( "Armory.KFWeapDef_BAR")
	DefaultItems.Add( "Armory.KFWeapDef_CZ75")
	DefaultItems.Add( "Armory.KFWeapDef_DualMK23")
	DefaultItems.Add( "Armory.KFWeapDef_DualTT33")
////	DefaultItems.Add( "Armory.KFWeapDef_FNFNC")
	DefaultItems.Add( "Armory.KFWeapDef_G3")
	DefaultItems.Add( "Armory.KFWeapDef_Galil")
	DefaultItems.Add( "Armory.KFWeapDef_HiPower")
	DefaultItems.Add( "Armory.KFWeapDef_M14")
	DefaultItems.Add( "Armory.KFWeapDef_M1Carbine")
	DefaultItems.Add( "Armory.KFWeapDef_M4Carbine")
	DefaultItems.Add( "Armory.KFWeapDef_MAS4956")
	DefaultItems.Add( "Armory.KFWeapDef_MK23")
	DefaultItems.Add( "Armory.KFWeapDef_OTs_33")
	DefaultItems.Add( "Armory.KFWeapDef_Spectre")
	DefaultItems.Add( "Armory.KFWeapDef_SVD")
	DefaultItems.Add( "Armory.KFWeapDef_SVT40")
	DefaultItems.Add( "Armory.KFWeapDef_Thermobaric")
	DefaultItems.Add( "Armory.KFWeapDef_TT33")
////	DefaultItems.Add( "Armory.KFWeapDef_UMP")
	DefaultItems.Add( "Armory.KFWeapDef_VAL")
	DefaultItems.Add( "Armory.KFWeapDef_XM177")

/*
	// == LordOfWar Weapon Mutator -- http://steamcommunity.com/sharedfiles/filedetails/?id=890082699 *
//	DefaultItems.Add( "AA12Dragon.KFWeapDef_AA12Dragon")
//	DefaultItems.Add( "ammobox2.KFWeapDef_AmmoBox")
//	DefaultItems.Add( "barretw.KFWeapDef_Rifle_Barret50")
//	DefaultItems.Add( "BileThrower.KFWeapDef_BileThrower")
//	DefaultItems.Add( "hkm14w.KFWeapDef_HK416")
	DefaultItems.Add( "louiville.KFWeapDef_Bat")
//	DefaultItems.Add( "m60.KFWeapDef_M60")
	DefaultItems.Add( "m79medic.KFWeapDef_M79M")
	DefaultItems.Add( "m79ss.KFWeapDef_M79SS")
	DefaultItems.Add( "mac10.KFWeapDef_MAC10")
//	DefaultItems.Add( "mauser.KFWeapDef_DualMauser")
//	DefaultItems.Add( "mauser.KFWeapDef_Mauser")
//	DefaultItems.Add( "mk42b.KFWeapDef_MK42B")
//	DefaultItems.Add( "nukeatw.KFWeapDef_NUKEAT")
//	DefaultItems.Add( "patriot.KFWeapDef_DualPatriot")
//	DefaultItems.Add( "patriot.KFWeapDef_Patriot")
//	DefaultItems.Add( "railgunzr2.KFWeapDef_RailGunZR2")
	DefaultItems.Add( "TF2SentryModV2.SentryWeaponDef")
	DefaultItems.Add( "tommygun.KFWeapDef_TommyGun")
*/
	// == GUNZ -- http://steamcommunity.com/sharedfiles/filedetails/?id=890082699
	DefaultItems.Add( "gunz.KFWeapDef_AA12Dragon")
	DefaultItems.Add( "gunz.KFWeapDef_AK47")
	DefaultItems.Add( "gunz.KFWeapDef_AmmoBox")
	DefaultItems.Add( "gunz.KFWeapDef_AUG9mm")
	DefaultItems.Add( "gunz.KFWeapDef_BileThrower")
	DefaultItems.Add( "gunz.KFWeapDef_DragonBlade")
	DefaultItems.Add( "gunz.KFWeapDef_FNC")
	DefaultItems.Add( "gunz.KFWeapDef_Glock")
	DefaultItems.Add( "gunz.KFWeapDef_GlockDual")
	DefaultItems.Add( "gunz.KFWeapDef_H134")
//	DefaultItems.Add( "gunz.KFWeapDef_Healthpack")
	DefaultItems.Add( "gunz.KFWeapDef_HK416")
	DefaultItems.Add( "gunz.KFWeapDef_M4_2")
	DefaultItems.Add( "gunz.KFWeapDef_M60")
	DefaultItems.Add( "gunz.KFWeapDef_M79M")
	DefaultItems.Add( "gunz.KFWeapDef_Mauser")
	DefaultItems.Add( "gunz.KFWeapDef_DualMauser")
	DefaultItems.Add( "gunz.KFWeapDef_MedicKriss")
	DefaultItems.Add( "gunz.KFWeapDef_MK")
	DefaultItems.Add( "gunz.KFWeapDef_NUKEAT")
	DefaultItems.Add( "gunz.KFWeapDef_Patriot")
	DefaultItems.Add( "gunz.KFWeapDef_DualPatriot")
	DefaultItems.Add( "gunz.KFWeapDef_RailGunZR2")
	DefaultItems.Add( "gunz.KFWeapDef_Rifle_Barret50")
	DefaultItems.Add( "gunz.KFWeapDef_Skull9")
	DefaultItems.Add( "gunz.KFWeapDef_Spas12")
	DefaultItems.Add( "gunz.KFWeapDef_Spectre")
	DefaultItems.Add( "gunz.KFWeapDef_SVD")
	DefaultItems.Add( "gunz.KFWeapDef_ZedTimeTBall2")
	DefaultItems.Add( "HealthPack.KFWeapDef_Healthpack")

	// == AKS-74u -- http://steamcommunity.com/sharedfiles/filedetails/?id=896034477 (*)
	DefaultItems.Add( "AKS74UMut.KFWeapDef_AKS74U")

	// == Custom M14EBRs -- http://steamcommunity.com/sharedfiles/filedetails/?id=959410214 **
	DefaultItems.Add( "CustomM14s.KFWeapDef_CustomM14EBR")
	DefaultItems.Add( "CustomM14s.KFWeapDef_IronSightM14EBR")

	// == CD Weapons Mod -- http://steamcommunity.com/sharedfiles/filedetails/?id=969556681
	DefaultItems.Add( "CDWM.KFWeapDef_AA12Dragon")
	DefaultItems.Add( "CDWM.KFWeapDef_AK47")
	DefaultItems.Add( "CDWM.KFWeapDef_AmmoBox")
	DefaultItems.Add( "CDWM.KFWeapDef_BileThrower")
	DefaultItems.Add( "CDWM.KFWeapDef_FNC")
	DefaultItems.Add( "CDWM.KFWeapDef_HK416")
	DefaultItems.Add( "CDWM.KFWeapDef_M4_2")
	DefaultItems.Add( "CDWM.KFWeapDef_M60")
	DefaultItems.Add( "CDWM.KFWeapDef_MK")
	DefaultItems.Add( "CDWM.KFWeapDef_DualMauser")
	DefaultItems.Add( "CDWM.KFWeapDef_Mauser")
	DefaultItems.Add( "CDWM.KFWeapDef_NUKEAT")
	DefaultItems.Add( "CDWM.KFWeapDef_RailGunZR2")
	DefaultItems.Add( "CDWM.KFWeapDef_Rifle_Barret50")
	DefaultItems.Add( "CDWM.KFWeapDef_SVD")
	DefaultItems.Add( "CDWM.KFWeapDef_ZedTimeTBall2")

	// == YeeHaw: Horzine Scientist -- http://steamcommunity.com/sharedfiles/filedetails/?id=1095651180
//	DefaultItems.Add( "YeeHaw.YHWeapDef_Grenade_BloatMine")
//	DefaultItems.Add( "YeeHaw.YHWeapDef_Grenade_Scientist")
//	DefaultItems.Add( "YeeHaw.YHWeapDef_Healer")
//	DefaultItems.Add( "YeeHaw.YHWeapDef_MedicPistol")
//	DefaultItems.Add( "YeeHaw.YHWeapDef_MedicRifle")
//	DefaultItems.Add( "YeeHaw.YHWeapDef_MedicSMG")
//	DefaultItems.Add( "YeeHaw.YHWeapDef_MedicShotgun")
//	DefaultItems.Add( "YeeHaw.YHWeapDef_MicrowaveGun")
//	DefaultItems.Add( "YeeHaw.YHWeapDef_RailGun")

	// == Schneidzekk -- http://steamcommunity.com/sharedfiles/filedetails/?id=1117901956
	DefaultItems.Add( "Schneidzekk.KFWeapDef_Schneidzekk")

	// == CustomM14EBR Mutator -- http://steamcommunity.com/sharedfiles/filedetails/?id=1134625264
	DefaultItems.Add( "CustomM14Mut.KFWeapDef_CustomM14EBR")

	// == CustomLAR Mutator -- http://steamcommunity.com/sharedfiles/filedetails/?id=1131782590
	DefaultItems.Add( "CustomLARMut.KFWeapDef_LAR")

	// == M99 Sniper rifle -- http://steamcommunity.com/sharedfiles/filedetails/?id=1137411101
	DefaultItems.Add( "M99.KFWeapDef_M99")

	// == Helfire shotguns -- http://steamcommunity.com/sharedfiles/filedetails/?id=1137952760
	DefaultItems.Add( "Hellfire.KFWeapDef_Hellfire")
	DefaultItems.Add( "Hellfire.KFWeapDef_HellfireDual")

	// == M16M203MDC -- http://steamcommunity.com/sharedfiles/filedetails/?id=1150733214
	DefaultItems.Add( "M16M203MDC.KFWeapDef_M16M203MDC")

	// == PracGun -- http://steamcommunity.com/sharedfiles/filedetails/?id=1219165574
	DefaultItems.Add( "PracGun.KFWeapDef_PracGun")

	// == The Dubstep Gun -- http://steamcommunity.com/sharedfiles/filedetails/?id=1332626173
	DefaultItems.Add( "DubstepGun.KFWeapDef_DubstepGun")

	// == TKB-059 Custom Weapon -- https://steamcommunity.com/sharedfiles/filedetails/?id=1380383392&searchtext=
	DefaultItems.Add( "CustomItems=TKB059.KFWeapDef_TKB")

	// == Weapon Pack -- http://steamcommunity.com/sharedfiles/filedetails/?id=1147408497
////	DefaultItems.Add( "WeaponPack.KFWeapDef_AK74M")
	DefaultItems.Add( "WeaponPack.KFWeapDef_Albert")
	DefaultItems.Add( "WeaponPack.KFWeapDef_AlbertDual")
	DefaultItems.Add( "WeaponPack.KFWeapDef_AmmoBox")
	DefaultItems.Add( "WeaponPack.KFWeapDef_AS50")
	DefaultItems.Add( "WeaponPack.KFWeapDef_AUG9mm")
	DefaultItems.Add( "WeaponPack.KFWeapDef_BFG9000")
	DefaultItems.Add( "WeaponPack.KFWeapDef_Buzzsaw")
	DefaultItems.Add( "WeaponPack.KFWeapDef_CZ805")
	DefaultItems.Add( "WeaponPack.KFWeapDef_DragonBlade")
	DefaultItems.Add( "WeaponPack.KFWeapDef_Glock")
	DefaultItems.Add( "WeaponPack.KFWeapDef_GlockDual")
	DefaultItems.Add( "WeaponPack.KFWeapDef_H134")
	DefaultItems.Add( "WeaponPack.KFWeapDef_Healthpack")
	DefaultItems.Add( "WeaponPack.KFWeapDef_HeavyAR")
	DefaultItems.Add( "WeaponPack.KFWeapDef_HellFireSSingle")
	DefaultItems.Add( "WeaponPack.KFWeapDef_HellFireS")
	DefaultItems.Add( "WeaponPack.KFWeapDef_M14EBRAR")
	DefaultItems.Add( "WeaponPack.KFWeapDef_M16Medic")
	DefaultItems.Add( "WeaponPack.KFWeapDef_M60MG")
	DefaultItems.Add( "WeaponPack.KFWeapDef_Mac10Ext")
	DefaultItems.Add( "WeaponPack.KFWeapDef_DualMAC10")
	DefaultItems.Add( "WeaponPack.KFWeapDef_Patriot")
	DefaultItems.Add( "WeaponPack.KFWeapDef_DualPatriot")
	DefaultItems.Add( "WeaponPack.KFWeapDef_RLPRO")
	DefaultItems.Add( "WeaponPack.KFWeapDef_Reaper")
	DefaultItems.Add( "WeaponPack.KFWeapDef_Scythe")
	DefaultItems.Add( "WeaponPack.KFWeapDef_Seeker3K")
	DefaultItems.Add( "WeaponPack.KFWeapDef_Skull9")
	DefaultItems.Add( "WeaponPack.KFWeapDef_Spas12")
////	DefaultItems.Add( "WeaponPack.KFWeapDef_Spectre")
	DefaultItems.Add( "WeaponPack.KFWeapDef_SVD")
	DefaultItems.Add( "WeaponPack.KFWeapDef_TKB")



/*
	// == BassCannon -- http://steamcommunity.com/sharedfiles/filedetails/?id=1137726392
	DefaultItems.Add( "BassCannon.KFWeapDef_BassCannon")

	// == Tracer Pistols -- http://steamcommunity.com/sharedfiles/filedetails/?id=1138237412
	DefaultItems.Add( "Tracer.KFWeapDef_Tracer")
	DefaultItems.Add( "Tracer.KFWeapDef_TracerDual")

	// == SawHammer -- http://steamcommunity.com/sharedfiles/filedetails/?id=1138303678
	DefaultItems.Add( "SawHammer.KFWeapDef_SawHammer")
*/

}






