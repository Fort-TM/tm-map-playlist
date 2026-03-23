const bool HAS_PERMISSIONS          = OpenplanetHasPaidPermissions();
const string TEMP_MAP_FOLDER        = IO::FromUserGameFolder("Maps\\Temp\\");
const string USER_FOLDER            = IO::FromUserGameFolder("");
const string IDS_LOCATION           = IO::FromStorageFolder("map_ids.json");
const string PLUGIN_NAME            = Meta::ExecutingPlugin().Name;
const string PLUGIN_ICON            = Icons::List;
const string FULL_NAME              = PLUGIN_ICON + " " + PLUGIN_NAME;
const int MAX_FRAME_TIME            = 50;

PlaylistsManager savedPlaylists     = PlaylistsManager();
MapPlaylist playlist                = MapPlaylist();

array<TM::Campaign@> WEEKLY_SHORTS;
array<TM::Campaign@> WEEKLY_GRANDS;
array<TM::Campaign@> SEASONAL_CAMPAIGNS;
array<Map@> FAVORITES;
array<TM::TOTDMonth@> TOTD_MONTHS;

const array<string> MAP_FIELDS_ARRAY = {
    "MapId",
    "MapUid",
    "OnlineMapId",
    "Uploader.Name",
    "MapType",
    "Environment",
    "Name",
    "GbxMapName",
    "Medals.Author",
    "Medals.Gold",
    "Medals.Silver",
    "Medals.Bronze",
    "Tags"
};

const string MAP_FIELDS = string::Join(MAP_FIELDS_ARRAY, ",");

const array<string> MAPPACK_FIELDS_ARRAY = {
    "MappackId",
    "Name",
    "MapCount",
    "Owner.Name",
    "Owner.UserId",
    "CreatedAt"
};

const string MAPPACK_FIELDS = string::Join(MAPPACK_FIELDS_ARRAY, ",");

enum GameMode {
    Race,
    Platform,
    Stunt,
    Royal
}

enum Vistas {
    Stadium,
    Blue_Bay,
    Red_Island,
    Green_Coast,
    White_Shore,
    Last
}

enum Medals {
    Bronze,
    Silver,
    Gold,
    Author,
#if DEPENDENCY_WARRIORMEDALS
    Warrior,
#endif
    Last
}

enum Source {
    TMX_Map_ID,
    TMX_Mappack_ID,
    URL,
    Weekly_Shorts,
    Weekly_Grands,
    Seasonal_Campaign,
    Club_Campaign,
    TOTD_Month,
    UID,
    Current_Map,
    Favorites,
    File,
    Folder,
    Last
}
