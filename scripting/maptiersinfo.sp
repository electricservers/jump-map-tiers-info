#include <sourcemod>
#include <ripext>
#include <morecolors>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.1"
#define SOLDIER "3"
#define DEMOMAN "4"

enum struct MapInfo {
	char Name[64];
	char SoldierTier[32];
	char DemomanTier[32];
	bool HasValidData;
}

bool g_Spawned[MAXPLAYERS];
MapInfo g_CurrentMap;
StringMap g_TierColors;

public Plugin myinfo = {
	name = "Jump Maps Tiers Info", 
	author = "ampere", 
	description = "Provide map tiers info through Tempus' API", 
	version = PLUGIN_VERSION, 
	url = "https://github.com/electricservers"
};

public void OnPluginStart() {
	HookEvent("post_inventory_application", OnPIA, EventHookMode_Post);
	LoadTranslations("maptiersinfo.phrases");
	
	g_TierColors = new StringMap();
	g_TierColors.SetString("1", "{limegreen}");
	g_TierColors.SetString("2", "{forestgreen}");
	g_TierColors.SetString("3", "{goldenrod}");
	g_TierColors.SetString("4", "{darkorange}");
	g_TierColors.SetString("5", "{orangered}");
	g_TierColors.SetString("6", "{fullred}");
	
	RegConsoleCmd("sm_tier", CMD_GetTier);
}

public void OnMapStart() {
	GetCurrentMap(g_CurrentMap.Name, sizeof(g_CurrentMap.Name));
	GetMapTiers();
}

public void OnClientPostAdminCheck(int client) {
	g_Spawned[client] = false;
}

public Action CMD_GetTier(int client, int args) {
	if (g_CurrentMap.HasValidData) {
		GreetClient(client);
	}
	else {
		MC_ReplyToCommand(client, "%t", "No tiers found");
	}
	return Plugin_Handled;
}

public Action OnPIA(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (!g_Spawned[client] && g_CurrentMap.HasValidData) {
		g_Spawned[client] = true;
		GreetClient(client);
	}
}

void GreetClient(int client) {
	MC_PrintToChat(client, "%t", "Greet", g_CurrentMap.Name, g_CurrentMap.SoldierTier, g_CurrentMap.DemomanTier);
}

void GetMapTiers() {
	HTTPRequest req = new HTTPRequest("https://api.jumpacademy.tf/mapinfo");
	req.AppendQueryParam("version", "2.0");
	req.AppendQueryParam("filename", "%s", g_CurrentMap.Name);
	
	req.Get(HTTP_OnMapInfoReceived);
}

public void HTTP_OnMapInfoReceived(HTTPResponse res, any value) {
	if (res.Status != HTTPStatus_OK) {
		LogError("Unable to fetch mapinfo for %s", g_CurrentMap.Name);
		return;
	}
	
	JSONArray rootArray = view_as<JSONArray>(res.Data);
	if (rootArray.Length == 0) {
		g_CurrentMap.HasValidData = false;
	}
	else {
		JSONObject root = view_as<JSONObject>(rootArray.Get(0));
		JSONObject tiers = view_as<JSONObject>(root.Get("tier"));
		
		g_CurrentMap.HasValidData = true;
		
		if (tiers.HasKey(SOLDIER)) {
			char tier[2];
			IntToString(tiers.GetInt(SOLDIER), tier, sizeof(tier));
			char color[16];
			g_TierColors.GetString(tier, color, sizeof(color));
			Format(g_CurrentMap.SoldierTier, sizeof(g_CurrentMap.SoldierTier), "%s%s{default}", color, tier);
			PrintToServer(color);
		}
		else {
			Format(g_CurrentMap.SoldierTier, sizeof(g_CurrentMap.SoldierTier), "%t", "Not defined");
		}
		
		if (tiers.HasKey(DEMOMAN)) {
			char tier[2];
			IntToString(tiers.GetInt(DEMOMAN), tier, sizeof(tier));
			char color[16];
			g_TierColors.GetString(tier, color, sizeof(color));
			Format(g_CurrentMap.DemomanTier, sizeof(g_CurrentMap.DemomanTier), "%s%s{default}", color, tier);
		}
		else {
			Format(g_CurrentMap.DemomanTier, sizeof(g_CurrentMap.DemomanTier), "%t", "Not defined");
		}
		
		delete root;
		delete tiers;
	}
	delete rootArray;
} 