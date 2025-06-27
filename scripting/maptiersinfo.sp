#include <sourcemod>
#include <ripext>
#include <morecolors>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.4"

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
  g_TierColors.SetString("0", "{grey}");
  g_TierColors.SetString("1", "{limegreen}");
  g_TierColors.SetString("2", "{forestgreen}");
  g_TierColors.SetString("3", "{goldenrod}");
  g_TierColors.SetString("4", "{darkorange}");
  g_TierColors.SetString("5", "{orangered}");
  g_TierColors.SetString("6", "{fullred}");
  g_TierColors.SetString("7", "{fullred}");
  g_TierColors.SetString("8", "{purple}");
  g_TierColors.SetString("9", "{darkviolet}");
  g_TierColors.SetString("10", "{magenta}");
 
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

	return Plugin_Continue;
}

void GreetClient(int client) {
	char msg[256];
	Format(msg, sizeof(msg), "%t", "Greet", g_CurrentMap.Name, g_CurrentMap.SoldierTier, g_CurrentMap.DemomanTier);

	if (client == 0) {
		MC_RemoveTags(msg, sizeof(msg));
		PrintToServer(msg);
	}
	else {
  	MC_PrintToChat(client, msg);
	}
}
void GetMapTiers() {
  char url[128];
  Format(url, sizeof(url), "https://tempus2.xyz/api/v0/maps/name/%s/fullOverview", g_CurrentMap.Name);
  
  HTTPRequest req = new HTTPRequest(url);
  req.Get(HTTP_OnMapInfoReceived);
}
public void HTTP_OnMapInfoReceived(HTTPResponse res, any value) {
  if (res.Status != HTTPStatus_OK) {
    LogError("Unable to fetch mapinfo for %s", g_CurrentMap.Name);
    return;
  }
 
  JSONObject root = view_as<JSONObject>(res.Data);
  
  if (!root.HasKey("tier_info")) {
    g_CurrentMap.HasValidData = false;
    delete root;
    return;
  }
  
  JSONObject tierInfo = view_as<JSONObject>(root.Get("tier_info"));
  g_CurrentMap.HasValidData = true;
 
  if (tierInfo.HasKey("soldier")) {
    char tier[2];
    IntToString(tierInfo.GetInt("soldier"), tier, sizeof(tier));
    char color[16];
    g_TierColors.GetString(tier, color, sizeof(color));
    Format(g_CurrentMap.SoldierTier, sizeof(g_CurrentMap.SoldierTier), "%s%s{default}", color, tier);
  }
  else {
    Format(g_CurrentMap.SoldierTier, sizeof(g_CurrentMap.SoldierTier), "%t", "Not defined");
  }
 
  if (tierInfo.HasKey("demoman")) {
    char tier[2];
    IntToString(tierInfo.GetInt("demoman"), tier, sizeof(tier));
    char color[16];
    g_TierColors.GetString(tier, color, sizeof(color));
    Format(g_CurrentMap.DemomanTier, sizeof(g_CurrentMap.DemomanTier), "%s%s{default}", color, tier);
  }
  else {
    Format(g_CurrentMap.DemomanTier, sizeof(g_CurrentMap.DemomanTier), "%t", "Not defined");
  }
 
  delete tierInfo;
  delete root;
}