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
var private const class<KFWeapon> LemonWepClass;


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
	else
	 	CleanupRepLink(true);


}


simulated function addWeaponsTimer()
{

	if( AddWeapons() )
	{
		ClearTimer( nameof(addWeaponsTimer));
	 	CleanupRepLink(true);
	}

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

	for( i=SaleItemsLength-OriginalInventorySize; i < ClientItems.Length; i++ )
	{
		`log("===TIM=== ClientItem["$i$"]:"@ClientItems[i].DefPath);

		item=class'TIMut'.Static.BuildWeapon( ClientItems[i].DefPath);
		item.ItemID=ClientItems[i].TraderId;

		// item not on client?
		if( item.WeaponDef == None )
		{
			`log("===TIM=== dropping unknown ClientItem["$i$"]: ("$item.ItemID$") -"@ClientItems[i].DefPath);

//			`log("===TIM=== ### CLIENT MISSING WEAPON! ###");
//			ConsoleCommand( "Disconnect");

			item=class'TIMut'.Static.BuildWeapon( "TIM.KFWeapDef_Unavailable");
		}

		// item ID already in trader inventory?
		index=TI.SaleItems.Find('ItemID',item.ItemId);
		if( index >= 0 )
		{
			`log("===TIM=== skipping present SaleItem["$index$"]: ("$TI.SaleItems[index].ItemID$") -"@TI.SaleItems[index].ClassName);

			if( TI.SaleItems[index].ClassName != item.ClassName )
			{
				`log("===TIM=== ### TRADER INVENTORY OUT OF SYNC! ###");
				ConsoleCommand( "Disconnect");
			}

			continue;
		}


		if( item.ClassName != Default.LemonWepClass.Name )
		{
			// item ClassName already in trader inventory? (really shouldn't happen)
			index=TI.SaleItems.Find('ClassName',item.ClassName);
			if( index >= 0 )
			{
				`log("===TIM=== skipping duplicate SaleItem["$index$"]: ("$TI.SaleItems[index].ItemID$") -"@TI.SaleItems[index].ClassName);

				if( TI.SaleItems[index].ItemID != ClientItems[i].TraderId )
				{
					`log("===TIM=== ### TRADER INVENTORY OUT OF SYNC! ###");
					ConsoleCommand( "Disconnect");
				}

				continue;
			}
		}

		`log("===TIM=== adding SaleItem["$TI.SaleItems.Length$"]: ("$item.ItemID$") -"@item.ClassName);
		TI.SaleItems.AddItem( item);
		number++;
	}

	if( number > 0 )
		TI.SetItemsInfo( TI.SaleItems);

	for( i=0; i < TI.SaleItems.Length; i++ )
		`log("===TIM=== SaleItem["$i$"]: ("$TI.SaleItems[i].ItemID$") -"@TI.SaleItems[i].ClassName);

	`log("===TIM=== custom Weapons added to trader inventory:"@number);
//	 BroadcastHandler.BroadcastText( None, ourPlayerController, "===TIM=== custom Weapons added:"@number, 'TIM' );


	return True;

}




defaultproperties
{
	bAlwaysRelevant=false
	bOnlyRelevantToOwner=true

	OriginalInventorySize=-1;
	LemonWepClass=Class'TIM.KFWeap_NOT_Available'

	Name="Default__TIMRepLink"
	ObjectArchetype=ReplicationInfo'Engine.Default__ReplicationInfo'
}
