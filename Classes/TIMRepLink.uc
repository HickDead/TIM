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

	if( ! class'TIMut'.Static.AddWeapons(ClientItems) )
		SetTimer( 0.1f, true, nameof(addWeaponsTimer));

    CleanupRepLink(true);
}


simulated function addWeaponsTimer()
{

	if( class'TIMut'.Static.AddWeapons(ClientItems) )
		ClearTimer( nameof(addWeaponsTimer));

}



defaultproperties
{
    bAlwaysRelevant=false
    bOnlyRelevantToOwner=true
    
    Name="Default__TIMRepLink"
    ObjectArchetype=ReplicationInfo'Engine.Default__ReplicationInfo'
}