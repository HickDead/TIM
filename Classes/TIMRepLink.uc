/*
 *  Trader Inventory Mutator
 *
 *  (C) 2017 HickDead, Kavoh
 *
 */

class TIMRepLink extends ReplicationInfo;

struct SItem
{
	var string DefPath;
	var int TraderId;
};

var /*private*/ array<SItem> ClientItems;

var private int CurrentIndex;
var private int OriginalInventorySize;

final function StartSyncItems()
{
    SetTimer(0.05f, true, nameof(SyncItems));
}

private final function SyncItems()
{
    local SItem Item;
    
    if (CurrentIndex < ClientItems.Length)
    {
        Item = ClientItems[CurrentIndex];
        
        ClientSyncItem(Item.DefPath, Item.TraderId);
        
        ++CurrentIndex;
    }
    else
    {
        ClearTimer(nameof(SyncItems));
        
        ClientSyncFinished();
        
        CleanupRepLink(false);
    }
}

private final function CleanupRepLink(bool bClient)
{
    CurrentIndex = 0;
    ClientItems.Length = 0;
    
    Destroy();
}

private reliable client final function ClientSyncItem(string DefPath, int TraderId)
{
    local SItem Item;
    
    Item.DefPath = DefPath;
    Item.TraderId = TraderId;
    
    ClientItems.AddItem(Item);
}

private reliable client final function ClientSyncFinished()
{

	`log("===TIM=== ClientSyncFinished()");

	if( ! AddWeapons() )
		SetTimer( 0.1f, true, nameof(addWeaponsTimer));


    CleanupRepLink(true);
}


simulated function addWeaponsTimer()
{

	if( AddWeapons() )
		ClearTimer( nameof(addWeaponsTimer));

}

private reliable client final function bool AddWeapons()
{
	local WorldInfo WI;
	local KFGameReplicationInfo KFGRI;
	local KFGFxObject_TraderItems TI;
	local STraderItem item;
	local int i, index, number, SaleItemsLength;
//	local SItem RepItem;


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

//	for( i=0; i < ClientItems.Length; i++ )
	for( i=SaleItemsLength-OriginalInventorySize; i < ClientItems.Length; i++ )
	{
		item=class'TIMut'.Static.BuildWeapon( ClientItems[i].DefPath);


		// item not on client?
//		if( item.WeaponDef == None )
//			item.ClassName=name(ClientItems[i].DefPath);

/*
		// item already in trader inventory?
		index=TI.SaleItems.Find('ClassName',item.ClassName);
		if( index >= 0 )
		{
//			`log("===TIM=== duplicate ClientItem["$i$"]:"@item.ClassName);
			`log("===TIM=== duplicate ClientItem["$i$"]:"@ClientItems[i].DefPath);
			`log("===TIM=== original SaleItem["$index$"]:"@TI.SaleItems[index].ClassName);
			if( index != ClientItems[i].TraderId )
				`log("===TIM=== ### TRADER INVENTORY OUT OF SYNC!");

			continue;
		}
*/

		// lemon? indicate clientside.
		if( item.BlocksRequired == 99 )
			item.BlocksRequired=0;

		TI.SaleItems.AddItem( item);
		number++;

	}

	if( number > 0 )
		TI.SetItemsInfo( TI.SaleItems);

	foreach TI.SaleItems(item)
		`log("===TIM=== SaleItem["$item.ItemID$"]:"@item.ClassName);

	`log("===TIM=== custom Weapons added to trader inventory:"@number);


	return True;

}




defaultproperties
{
    bAlwaysRelevant=false
    bOnlyRelevantToOwner=true

	OriginalInventorySize=-1;
   
    Name="Default__TIMRepLink"
    ObjectArchetype=ReplicationInfo'Engine.Default__ReplicationInfo'
}