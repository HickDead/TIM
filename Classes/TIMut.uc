
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
	local int i, index, number, saleItemsLength, freeID;
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

		`log("===TIM=== CustomItem["$i$"]:"@CustomItems[i]);
		item=BuildWeapon( CustomItems[i]);
		item.ItemID=freeID+number;

		// item not on server?
		if( item.WeaponDef == none )
		{
			`log("===TIM=== dropping unknown CustomItem["$i$"]:"@CustomItems[i]);
			continue;
		}

		// item ID already in trader inventory?
		index=TI.SaleItems.Find('ItemID',item.ItemId);
		if( index >= 0 )
		{
			`log("===TIM=== skipping present SaleItem["$index$"]: ("$TI.SaleItems[index].ItemID$") -"@TI.SaleItems[index].ClassName);
			continue;
		}

		// item ClassName already in trader inventory?
		index=TI.SaleItems.Find( 'ClassName', item.ClassName);
		if( index >= 0 )
		{
			`log("===TIM=== skipping duplicate SaleItem["$index$"]: ("$TI.SaleItems[index].ItemID$") -"@TI.SaleItems[index].ClassName);
			continue;
		}

		RepItem.DefPath=CustomItems[i];
		RepItem.TraderId=item.ItemID;
		ServerItems.AddItem( RepItem);

		`log("===TIM=== adding SaleItem["$TI.SaleItems.Length$"]: ("$item.ItemID$") -"@item.ClassName);
		TI.SaleItems.AddItem( item);
		number++;
	}


	if( number > 0 )
		TI.SetItemsInfo( TI.SaleItems);

	for( i=0; i < TI.SaleItems.Length; i++ )
		`log("===TIM=== SaleItem["$i$"]: ("$TI.SaleItems[i].ItemID$") -"@TI.SaleItems[i].ClassName);

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

	OriginalInventorySize=-1

	bAlwaysRelevant=true
	RemoteRole=ROLE_SimulatedProxy
}




