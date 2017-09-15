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
var private const class<KFWeapon> LemonWepClass;
var private const class<KFWeaponDefinition> LemonWepDefClass;
var private int OriginalInventorySize;


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



function InitMutator(string Options, out string ErrorMessage)
{
	`log("===TIM=== InitMutator()");
	super.InitMutator( Options, ErrorMessage );

//	CustomItems.addItem( "Schneidzekk.KFWeapDef_Schneidzekk");
//	SaveConfig();

	SetTimer( 0.1f, true, nameof(addWeaponsTimer));

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
	local WorldInfo WI;
	local KFGameReplicationInfo KFGRI;
	local KFGFxObject_TraderItems TI;
	local STraderItem item;
	local int i, index, number, SaleItemsLength;
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

	if( OriginalInventorySize < 0 )
		OriginalInventorySize=SaleItemsLength;


	number=0;
//	for( i=0; i < CustomItems.Length; i++ )
	for( i=SaleItemsLength-OriginalInventorySize; i < CustomItems.Length; i++ )
	{

		`log("===TIM=== CustomItem["$i$"]:"@CustomItems[i]);

		item=BuildWeapon( CustomItems[i]);

		// item not on server?
//		if( item.WeaponDef == none )
//		if( item.ClassName == Default.LemonWepClass.Name )
//		{
//			`log("===TIM=== dropping CustomItem["$i$"]:"@CustomItems[i]);
//			continue;
//		}

		// item already in trader inventory?
		index=TI.SaleItems.Find( 'ClassName', item.ClassName);
		if( index >= 0 )
		{
			`log("===TIM=== duplicate of SaleItem["$index$"]:"@TI.SaleItems[index].ClassName);
			continue;
		}

		RepItem.TraderId=SaleItemsLength+number;
		RepItem.DefPath=CustomItems[i];
		if( item.ClassName == Default.LemonWepClass.Name )
			RepItem.DefPath="TIM.KFWeapDef_Unavailable";
		ServerItems.AddItem( RepItem);
		number++;

		`log("===TIM=== adding SaleItem["$SaleItemsLength+number$"]:"@item.ClassName);

		TI.SaleItems.AddItem( item);

	}


	if( number > 0 )
		TI.SetItemsInfo( TI.SaleItems);

	foreach TI.SaleItems(item)
		`log("===TIM=== SaleItem["$item.ItemID$"]:"@item.ClassName);

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
//		return CTI;
		WeaponDef=Default.LemonWepDefClass;

	WeaponClass=class<KFWeapon>(DynamicLoadObject(WeaponDef.Default.WeaponClassPath,class'Class'));
	if( WeaponClass == none )
	{
//		return CTI;
		WeaponDef=Default.LemonWepDefClass;
		WeaponClass=Default.LemonWepClass;

	}

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


defaultproperties
{
	Name="Default__TIMut"
	ObjectArchetype=KFMutator'KFGame.Default__KFMutator'

	OriginalInventorySize=-1
	LemonWepClass=Class'TIM.KFWeap_NOT_Available'
	LemonWepDefClass=Class'TIM.KFWeapDef_Unavailable'

	bAlwaysRelevant=true
	RemoteRole=ROLE_SimulatedProxy
}




