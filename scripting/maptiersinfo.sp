#include <sourcemod>
#include <ripext>
#include <morecolors>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0"
#define SOLDIER "3"
#define DEMOMAN "4"

enum struct MapInfo {
	char Name[64];
	int SoldierTier;
	int DemomanTier;
}

bool g_Spawned[MAXPLAYERS];
MapInfo g_CurrentMap;

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
}

public void OnMapStart() {
	GetCurrentMap(g_CurrentMap.Name, sizeof(g_CurrentMap.Name));
	GetMapTiers();
}

public void OnClientPostAdminCheck(int client) {
	g_Spawned[client] = false;
}

public Action OnPIA(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (!g_Spawned[client]) {
		g_Spawned[client] = true;
		GreetClient(client);
	}
}

void GreetClient(int client) {
	char name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));
	MC_PrintToChat(client, "%t", "Greet", name, g_CurrentMap.Name, g_CurrentMap.SoldierTier, g_CurrentMap.DemomanTier);
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
	JSONObject root = view_as<JSONObject>(rootArray.Get(0));
	JSONObject tiers = view_as<JSONObject>(root.Get("tier"));
	
	g_CurrentMap.SoldierTier = tiers.GetInt(SOLDIER);
	g_CurrentMap.DemomanTier = tiers.GetInt(DEMOMAN);
	
	delete rootArray;
	delete root;
	delete tiers;
}