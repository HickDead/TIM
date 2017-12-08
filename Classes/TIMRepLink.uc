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
	var string	DefPath;
	var int		TraderId;
};

var /*private*/ array<SItem> ClientItems;

var private int		CurrentIndex;
var config bool		bDebugLog;
var config int		iRetries;


static final function SaveSettings()
{

	`DebugFlow( ".");

	Default.iRetries=3;
	Default.bDebugLog=True;
	StaticSaveConfig();
}


final function StartSyncItems()
{
    `DebugFlow( ".");

    SetTimer(0.05f, true, nameof(SyncItems));
}

private final function SyncItems()
{
    local SItem Item;

    `DebugFlow( ".");

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
    `DebugFlow( "bClient: "$bClient);

    CurrentIndex = 0;
    ClientItems.Length = 0;
    
    Destroy();
}

private reliable client final function ClientSyncItem(string DefPath, int TraderId)
{
    local SItem		Item;
    
    `DebugFlow( "DefPath: \""$DefPath$"\" TraderId: "$TraderId);
    Item.DefPath = DefPath;
    Item.TraderId = TraderId;
    
    ClientItems.AddItem(Item);
}

private reliable client final function ClientSyncFinished()
{

	`DebugFlow( ".");

	`logInfo("(v"$`VERSION$") ClientSyncFinished(): " $ ClientItems.Length@"items");

	if( iRetries < 1 )
	{
		`LogInfo( "Updating config");
		SaveSettings();
		iRetries=Default.iRetries;
	}

	Timer();

}


simulated event Timer()
{

	`DebugFlow( ".");

/*
// This doesn't work as for some unknown reason the timer isn't firing...

	if( AddClientItems() )
	 	CleanupRepLink(true);
	else
		SetTimer( 1.0f);
*/

// So we just do it in a loop without the 1 second delay instead

	while( ! AddClientItems() )
		;

 	CleanupRepLink(true);

}


private simulated final function bool AddClientItems()
{
	local KFGameReplicationInfo	KFGRI;
	local KFGFxObject_TraderItems	TI;
	local SItem			ClientItem;
	local STraderItem		item;
	local int			i, number;


	`DebugFlow( ".");

	if( WorldInfo == none )
	{
		`Debug( "no WI");
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
		item.WeaponDef=class<KFWeaponDefinition>(DynamicLoadObject(ClientItem.DefPath,class'Class'));

		if( item.WeaponDef == none )
		{
			if( iRetries > 0 )
			{
				`logWarn( "CLIENT MISSING " $ ClientItem.DefPath $ " ### Attempts left: " $ iRetries--);
				return False;
			}

			`logError( "CLIENT MISSING ITEM! ### Disconnecting! - " $ ClientItem.DefPath);
			class'TIMut'.Static.LogToConsole( "CLIENT MISSING ITEM! ### Disconnecting! - " $ ClientItem.DefPath);
			ConsoleCommand( "Disconnect");
			return True;

		}

		`logInfo( "adding SaleItem[" $ TI.SaleItems.Length $ "]: (" $ ClientItem.TraderId $ ") - " $ ClientItem.DefPath);
		item.ItemID=ClientItem.TraderId;
		TI.SaleItems.AddItem( item);
		number++;
	}

	if( number > 0 )
		TI.SetItemsInfo( TI.SaleItems);

	`logInfo( "Items added to trader inventory: " $ number);
	class'TIMut'.Static.LogToConsole( "Items added to trader inventory: " $ number);

	KFGRI.TraderItems=TI;
	return True;
}



defaultproperties
{

	bAlwaysRelevant=false
	bOnlyRelevantToOwner=true

	Name="Default__TIMRepLink"
	ObjectArchetype=ReplicationInfo'Engine.Default__ReplicationInfo'
}
