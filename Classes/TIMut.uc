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

var config array<string> CustomItems;


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


simulated event PostBeginPlay()
{
	Super.PostBeginPlay();

//	CustomItems.addItem( "Schneidzekk.KFWeapDef_Schneidzekk");
//	SaveConfig();

	buildList();

	SetTimer( 0.1f, true, nameof(addWeaponsTimer));


}

private function buildList()
{
	local string CustomItem;
	local SItem RepItem;


	foreach CustomItems(CustomItem)
	{
		if( ServerItems.Find('DefPath',CustomItem) < 0 )
		{
			RepItem.Price=-1;
			RepItem.DefPath=CustomItem;
			ServerItems.AddItem( RepItem);
			`log("===TIM=== CustomItem:"@CustomItem);
		}
	}

}

simulated function addWeaponsTimer()
{

	if( AddWeapons(ServerItems) )
	{
		ClearTimer( nameof(addWeaponsTimer));
		SyncClients();
	}

}

simulated static final function bool AddWeapons(array<SItem> RepItems)
{
	local WorldInfo WI;
	local KFGameReplicationInfo KFGRI;
	local KFGFxObject_TraderItems TI;
	local STraderItem item;
	local int number, SaleItemsLength;
	local SItem RepItem;


	WI=class'WorldInfo'.Static.GetWorldInfo();
	if( WI == none )
		return False;

	KFGRI=KFGameReplicationInfo( WI.GRI);
	if( KFGRI == none )
		return False;

	TI=KFGRI.TraderItems;
	if( TI == none )
		return False;

	SaleItemsLength=TI.SaleItems.Length;
	if( SaleItemsLength < 1 )
		return False;

	number=0;
	foreach RepItems(RepItem)
	{
		item=BuildWeapon( RepItem.DefPath);


		if( item.WeaponDef != none )
		{
			if( TI.SaleItems.Find('ClassName',item.ClassName) < 0 )
			{
				TI.SaleItems.AddItem( item);

				`log("===TIM=== adding:"@RepItem.DefPath);
				number++;
			}
		}
		else
		{
			`log("===TIM=== unable to add:"@RepItem.DefPath);
			if( WI.NetMode == NM_DedicatedServer )
				RepItems.RemoveItem( RepItem);
		}
	}

	if( number > 0 )
		TI.SetItemsInfo( TI.SaleItems);

	`log("===TIM=== Weapons added to trader inventory:"@number);

	foreach TI.SaleItems(item)
		`log("===TIM=== SaleItem["$item.ItemID$"]:"@item.ClassName);

	return True;
}


simulated static function STraderItem BuildWeapon(string CI)
{
	local STraderItem CTI;
	local class<KFWeaponDefinition> WeaponDef;
	local class<KFWeapon> WeaponClass;


	CTI.WeaponDef=none;

	WeaponDef=class<KFWeaponDefinition>(DynamicLoadObject(CI,class'Class'));;
	if( WeaponDef == none )
		return CTI;

	WeaponClass=class<KFWeapon>(DynamicLoadObject(WeaponDef.Default.WeaponClassPath,class'Class'));;
	if( WeaponClass == none )
		return CTI;

	CTI.WeaponDef=WeaponDef;
	CTI.ClassName=WeaponClass.Name;

//	if( class<KFWeap_DualBase>(WeaponClass) != none && class<KFWeap_DualBase>(WeaponClass).Default.SingleClass != none )
//		CTI.SingleClassName=class<KFWeap_DualBase>(WeaponClass).Default.SingleClass.Name;
//	else
//		CTI.SingleClassName='';
//	if( WeaponClass.Default.DualClass != none )
//		CTI.DualClassName=WeaponClass.Default.DualClass.Name;
//	else
//		CTI.DualClassName='';

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


defaultproperties
{
	Name="Default__TIMut"
	ObjectArchetype=KFMutator'KFGame.Default__KFMutator'


	bAlwaysRelevant=true
	RemoteRole=ROLE_SimulatedProxy
}




