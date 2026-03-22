namespace CurrentMap {
    void AddToCurrentPlaylist() {
        CGameCtnChallenge@ map = GetMap();

        if (map is null) {
            _Logging::Warn("Failed to get the current map!");
            return;
        }

        auto playlistName = playlist.Name == "" ? "the current playlist" : "playlist \"" + playlist.Name + "\"";

        foreach (auto listMap : playlist.Maps) {
            if (listMap.Uid == map.IdName) {
                _Logging::Warn("Current map already exists in " + playlistName + ".", true);
                return;
            }
        }

        Map@ mapInfo = FetchMapInfo(map);

        if (mapInfo is null) {
            _Logging::Warn("Failed to fetch the information for the current map!");
            return;
        }

        playlist.AddMap(mapInfo);

        UI::ShowNotification("Current map added", mapInfo.Name + " has been added to " + playlistName + ".");
    }

    void AddToPlaylists(array<MapPlaylist@> playlists) {
        CGameCtnChallenge@ map = GetMap();

        if (map is null) {
            _Logging::Warn("Failed to get the current map!");
            return;
        }

        Map@ mapInfo = FetchMapInfo(map);

        if (mapInfo is null) {
            _Logging::Warn("Failed to fetch the information for the current map!");
            return;
        }

        foreach (auto playlist : playlists) {
            playlist.AddMap(mapInfo);
        }

        UI::ShowNotification("Current map added", mapInfo.Name + " has been added to " + tostring(playlists.Length) + " " + Pluralize("playlist", playlists.Length) + ".");

        Saves::UpdateFile();
    }

    bool get_CanBeAdded() {
        CGameCtnChallenge@ map = GetMap();
        return map !is null;
    }

    CGameCtnChallenge@ GetMap() {
        if (TM::InEditor()) {
            return null;
        }
        
        CGameCtnChallenge@ map = TM::GetLoadedMap();
        
        if (map is null || map.MapInfo is null) {
            return null;
        }

        return map;
    }

    // Fetches the map information from TMX, Nadeo Services, or from the CGameCtnChallenge instance.
    Map@ FetchMapInfo(CGameCtnChallenge@ map) {
        if (map is null) {
            _Logging::Warn("[FetchMapInfo] Current map can't be added or is null!");
            return null;
        }

        Map@ mapData;

        _Logging::Trace("[FetchMapInfo] Fetching current map on TMX. UID: " + map.IdName);

        TMX::MapInfo@ tmxInfo = TMX::GetMapFromUid(map.IdName);

        if (tmxInfo is null) {
            _Logging::Trace("[FetchMapInfo] Failed to get current map on TMX, searching on Nadeo API...");
            @mapData = TM::GetMapFromUid(map.IdName);
        } else {
            @mapData = Map(tmxInfo);
        }

        if (mapData is null) {
            _Logging::Trace("[FetchMapInfo] Failed to find map on Nadeo's servers, loading CGameCtnChallenge data.");
            @mapData = Map(map, map.MapInfo.FileName);
        }

        return mapData;
    }

}