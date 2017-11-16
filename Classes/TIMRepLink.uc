/*
 *  Trader Inventory Mutator Replication Link
 *
 *  (C) 2017 HickDead, Kavoh
 *
 */

class TIMRepLink extends ReplicationInfo
	config(TIM)
;


struct SItem
{
	var string DefPath;
	var int TraderId;
};

var /*private*/ array<SItem> ClientItems;

var private int CurrentIndex;
var private int OriginalInventorySize;
var config bool bDebugLog;


static final function SaveSettings()
{
	Default.bDebugLog=True;
	StaticSaveConfig();
}


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

	`log("===TIM=== (v"$`VERSION$") ClientSyncFinished():"@ClientItems.Length@"items");

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
	local KFGameReplicationInfo KFGRI;
	local KFGFxObject_TraderItems TI;
	local SItem ClientItem;
	local STraderItem item;
	local int i, number;


	if( WorldInfo == none )
	{
		`Debug( "===TIM=== no WI");
		return False;
	}

	KFGRI=KFGameReplicationInfo( WorldInfo.GRI);
	if( KFGRI == none )
	{
		`Debug( "no KFGRI");
		return False;
	}

	TI=new class'KFGFxObject_TraderItems';

	number=0;
	foreach ClientItems( ClientItem, i)
	{
		item=class'TIMut'.Static.LoadWeapon( ClientItem.DefPath);
		item.ItemID=ClientItem.TraderId;

		if( item.WeaponDef == none )
		{
			`log( "===TIM=== ### CLIENT MISSING ITEM! ### Disconnecting! - "$ClientItem.DefPath);
			class'TIMut'.Static.LogToConsole( "===TIM=== (v"$`VERSION$") ### CLIENT MISSING WEAPON! ### Disconnecting! - "$ClientItem.DefPath);
			ConsoleCommand( "Disconnect");
		}

		`Debug( "adding SaleItem["$TI.SaleItems.Length$"]: ("$ClientItem.TraderId$") - "$ClientItem.DefPath);
		TI.SaleItems.AddItem( item);
		number++;
	}

	if( number > 0 )
		TI.SetItemsInfo( TI.SaleItems);

	`log( "===TIM=== custom Weapons added to trader inventory: "$number);
	class'TIMut'.Static.LogToConsole( "===TIM=== (v"$`VERSION$") custom Weapons added to trader inventory: "$number);

	KFGRI.TraderItems=TI;
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
