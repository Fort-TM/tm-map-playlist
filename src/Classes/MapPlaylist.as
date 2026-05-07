class MapPlaylist {
    array<Map@> Maps;
    Map@ currentMap;
    string Name;
    int CreatedAt;
    array<TMX::Tag@> Tags;
    MapColumns@ columnWidths = MapColumns();
    bool Dirty = false; // For sorting

    MapPlaylist() { }

    MapPlaylist(Json::Value@ json) {
        _Logging::Debug("Loading playlist \"" + string(json["Name"]) + "\" from JSON");
        _Logging::Debug(Json::Write(json, true));

        this.Name = json["Name"];
        this.CreatedAt = json["Timestamp"];

        for (uint i = 0; i < json["Maps"].Length; i++) {
            Json::Value@ map = json["Maps"][i];

            if (map.GetType() != Json::Type::Object) {
                _Logging::Warn("Invalid JSON type for playlist map. Ignoring...");
                continue;
            }

            this.AddMap(Map(map));
        }

        for (uint i = 0; i < json["Tags"].Length; i++) {
            Json::Value@ tag = json["Tags"][i];
            this.Tags.InsertLast(TMX::Tag(tag));
        }

        _Logging::Info("Succesfully loaded playlist \"" + this.Name + "\" from JSON");
    }

    uint get_Length() {
        return this.Maps.Length;
    }

    Map@ opIndex(uint i) {
        return this.Maps[i];
    }

    bool IsEmpty() {
        return this.Maps.IsEmpty();
    }

    bool HasTag(TMX::Tag@ tag) {
        return this.Tags.Find(tag) > -1;
    }

    void AddTag(TMX::Tag@ tag) {
        if (!this.HasTag(tag)) {
            this.Tags.InsertLast(tag);

            if (this.Tags.Length > 1) {
                this.Tags.Sort(function(a, b) { return a.Name < b.Name; });
            }
        }
    }

    void RemoveTag(TMX::Tag@ tag) {
        if (this.HasTag(tag)) {
            int tagIndex = this.Tags.Find(tag);
            this.Tags.RemoveAt(tagIndex);
        }
    }

    void Clear() {
        _Logging::Debug("Clearing playlist...");

        this.Maps.RemoveRange(0, Maps.Length);
        this.columnWidths.Reset();
        @this.currentMap = null;
        this.Dirty = true;
    }

    void OnUpdatedMaps() {
        this.columnWidths.Update(this.Maps);
        this.Dirty = true;
    }

    void GetPlaylistPbs() {
        foreach(Map@ map : this.Maps) {
            startnew(TM::GetPb, map);
        }
    }

    void PlayMap(Map@ map) {
        startnew(TM::LoadMap, map);
    }

    void NextMap() {
        if (this.Maps.IsEmpty()) return;

        try {
            if (this.currentMap is null) {
                startnew(TM::LoadMap, this.Maps[0]);
                return;
            }
            
            if (this.Maps.Length == 1) {
                // No need to load the same map
                return;
            }

            int index = Maps.FindByRef(this.currentMap);

            if (index == int(this.Maps.Length - 1)) {
                // reached last item
                if (S_Loop) {
                    startnew(TM::LoadMap, this.Maps[0]);
                }
            } else {
                startnew(TM::LoadMap, this.Maps[index + 1]);
            }
        } catch {
            _Logging::Error("An error occurred while switching maps: " + getExceptionInfo(), true);
        }
    }

    void DeleteMap(Map@ map) {
        _Logging::Debug("Deleting map " + map.toString());

        try {
            if (this.Maps.IsEmpty()) return;

            int index = this.Maps.FindByRef(map);

            if (index == -1) {
                _Logging::Error("Failed to find map " + map.toString() + " index while deleting it from playlist!");
                return;
            }

            if (this.currentMap !is null && this.currentMap == map) {
                @this.currentMap = null;
            }

            for (uint i = 0; i < this.Maps.Length; i++) {
                if (this.Maps[i].Index > map.Index) {
                    this.Maps[i].Index--;
                }
            }

            this.Maps.RemoveAt(index);
            this.OnUpdatedMaps();
        } catch {
            _Logging::Error("An error occurred while deleting a map: " + getExceptionInfo(), true);
            _Logging::Warn("Failed to delete map \"" + map.toString() + "\"");
        }
    }

    void ShiftMap(Map@ map, bool down = false) {
        try {
            int index = this.Maps.FindByRef(map);

            if (index == -1) {
                _Logging::Error("Failed to find map " + map.toString() + " index while moving it in playlist!");
                return;
            }

            _Logging::Debug("Shifting map " + map.toString() + " in playlist.");

            this.Maps.RemoveAt(index);

            // In a table, the first elements are up
            if (down) {
                this.Maps.InsertAt(index + 1, map);
            } else {
                this.Maps.InsertAt(index - 1, map);
            }
        } catch {
            _Logging::Error("An error occurred while moving a map in the playlist: " + getExceptionInfo(), true);
            _Logging::Warn("Failed to shift map \"" + map.toString() + "\"");
        }
    }

    // Durstenfeld shuffle
    void Randomize() {
        try {
            _Logging::Debug("Randomizing playlist. Playlist length: " + this.Maps.Length);
            array<Map@> shuffled = this.Maps;

            for (int i = shuffled.Length - 1; i > 0; i--) {
                int j = Math::Rand(0, i + 1);
                Map@ temp = shuffled[i];
                @shuffled[i] = shuffled[j];
                @shuffled[j] = temp;
            }

            this.Maps = shuffled;
        } catch {
            _Logging::Error("An error occurred while randomizing the playlist: " + getExceptionInfo(), true);
        }
    }

    Json::Value@ ToJson() {
        _Logging::Trace("Converting playlist to JSON");

        Json::Value json = Json::Object();
        json["Name"] = this.Name;
        json["Maps"] = Json::Array();
        json["Tags"] = Json::Array();
        json["Timestamp"] = this.CreatedAt;

        try {
            foreach (Map@ map : this.Maps) {
                json["Maps"].Add(map.ToJson());
            }

            foreach (TMX::Tag@ tag : this.Tags) {
                json["Tags"].Add(tag.ToJson());
            }

            return json;
        } catch {
            _Logging::Error("An error occurred while converting the playlist to a JSON: " + getExceptionInfo(), true);
            return null;
        }
    }

    // Addition methods

    void Add(Source source, const string &in field) {
        switch (source) {
            case Source::TMX_Map_ID:
                startnew(CoroutineFuncUserdataString(this.AddFromTMXId), field);
                break;
            case Source::TMX_Mappack_ID:
                startnew(CoroutineFuncUserdataString(this.AddMappack), field);
                break;
            case Source::UID:
                startnew(CoroutineFuncUserdataString(this.AddFromUid), field);
                break;
            case Source::File:
                startnew(CoroutineFuncUserdataString(this.AddFromFile), CleanPath(field));
                break;
            case Source::Folder:
                startnew(CoroutineFuncUserdataString(this.AddFolder), CleanPath(field));
                break;
            case Source::URL:
            default:
                startnew(CoroutineFuncUserdataString(this.AddFromUrl), field);
                break;
        }
    }

    void AddMap(Map map) {
        _Logging::Trace("Adding " + map.toString() + " to the playlist");

        for (uint i = 0; i < this.Maps.Length; i++) {
            if (map == this.Maps[i]) {
                _Logging::Warn("Duplicated map \"" + map.toString() + "\" detected. Skipping...");
                return;
            }
        }

        map.Index = this.Maps.Length + 1;

        this.Maps.InsertLast(map);
        this.OnUpdatedMaps();

        // only fetch PB if it's from the current playlist
        if (this is playlist) {
            startnew(TM::GetPb, map);
        }
    }

    void AddCampaign(ref@ campRef) {
        TM::Campaign@ campaign = cast<TM::Campaign>(campRef);

        _Logging::Debug("Adding the " + campaign.Name + " campaign to the playlist");

        campaign.LoadMapData();

        while (!campaign.LoadedData) {
            yield();
        }

        for (uint i = 0; i < campaign.MapList.Length; i++) {
            this.AddMap(campaign.MapList[i]);
        }
    }

    void AddFromUid(const string &in uid) {
        if (uid.Length < 25 || uid.Length > 27) {
            _Logging::Error("Invalid UID \"" + uid + "\" received. Ignoring...", true);
            return;
        }

        _Logging::Debug("Adding map with UID \"" + uid + "\" to playlist");

        Map@ result = TM::GetMapFromUid(uid);

        if (result !is null) {
            this.AddMap(result);
            _Logging::Info("Added map with UID \"" + uid + "\" to the playlist!");
        }
    }

    void AddFromTMXId(const string &in mapId) {
        _Logging::Debug("Adding TMX map with ID #" + mapId);

        try {
            TMX::MapInfo@ info = TMX::GetMap(Text::ParseInt(mapId));

            if (info !is null) {
                this.AddMap(Map(info));
                _Logging::Info("Added TMX map with ID #" + mapId + " to the playlist!");
            }
        } catch {
            _Logging::Error("An error occurred while adding map with ID #" + mapId + " to the playlist: " + getExceptionInfo(), true);
        }
    }

    void AddMappack(const string &in id) {
        _Logging::Debug("Adding TMX mappack with ID #" + id);

        try {
            TMX::MappackInfo@ mappack = TMX::GetMappack(Text::ParseInt(id));

            if (mappack is null) {
                _Logging::Warn("Failed to add mappack to playlist! Mappack doesn't exist or is private.", true);
                return;
            }
            
            if (mappack.MapCount == 0) {
                _Logging::Warn("Failed to add mappack to playlist! Mappack is empty.", true);
                return;
            }

            mappack.GetMaps();

            array<Map@> maps = mappack.Maps;

            for (uint i = 0; i < maps.Length; i++) {
                this.AddMap(maps[i]);
            }

            _Logging::Info("Added " + maps.Length + " maps to the playlist!");
        } catch {
            _Logging::Error("An error occurred while adding the maps from mappack ID #" + id + ": " + getExceptionInfo(), true);
        }
    }

    void AddFromFile(const string &in path) {
        try {
            _Logging::Debug("Adding map from file path " + path);

            CGameCtnChallenge@ cmap = TM::GetMapFromPath(path);

            if (cmap is null) {
                _Logging::Warn("Failed to get map from provided path.", true);
                return;
            }

            this.AddMap(Map(cmap, path));
            _Logging::Info("Added map file to the playlist!");
        } catch {
            _Logging::Error("An error occurred while adding a map from path \"" + path + "\": " + getExceptionInfo(), true);
        }
    }

    int regexFlags = Regex::Flags::ECMAScript | Regex::Flags::CaseInsensitive;

    void AddFromUrl(const string &in str) {
        _Logging::Debug("Adding URL \"" + str + "\"");

        if (Regex::IsMatch(str, "\\d{1,6}")) {
            this.AddFromTMXId(str);
        } else if (Regex::Contains(str, "https?:\\/\\/(www\\.)?trackmania\\.exchange\\/(mapgbx|maps\\/download|tracks|tracks\\/view|maps|maps\\/view|s\\/tr|mapshow)\\/\\d{1,6}", regexFlags)) {
            array<string> id = Regex::Search(str, "\\/(\\d{1,6})");

            if (!id.IsEmpty()) {
                this.AddFromTMXId(id[1]);
            }
        } else if (Regex::Contains(str, "https?:\\/\\/(www\\.)?trackmania\\.exchange\\/(mappack|mappack\\/view|s\\/m|mappackshow)\\/\\d{1,6}", regexFlags)) {
            array<string> id = Regex::Search(str, "\\/(\\d{1,6})");

            if (!id.IsEmpty()) {
                this.AddMappack(id[1]);
            }
        } else if (Regex::Contains(str, "https?:\\/\\/(www\\.)?trackmania\\.io\\/.*?\\/\\w{25,27}\\/?$", regexFlags)) {
            array<string> uid = Regex::Search(str, "(\\w{25,27})\\/?$");

            if (!uid.IsEmpty()) {
                this.AddFromUid(uid[1]);
            }
        } else if (Regex::Contains(str, "https?:\\/\\/(www\\.)?trackmania\\.com\\/tracks\\/\\w{25,27}\\/?", regexFlags)) {
            array<string> uid = Regex::Search(str, "(\\w{25,27})");

            if (!uid.IsEmpty()) {
                this.AddFromUid(uid[1]);
            }
        } else if (Regex::Contains(str, "https?:\\/\\/(www\\.)?trackmania\\.io\\/#\\/campaigns\\/.*?\\/\\d{1,6}\\/?$", regexFlags)) {
            array<string> matches = Regex::Search(str, "campaigns\\/(.*?)\\/(\\d{1,6})");
            int clubId;
            int campaignId;

            if (!matches.IsEmpty() && Text::TryParseInt(matches[2], campaignId)) {
                if (matches[1] == "seasonal") {
                    this.AddSeasonalCampaign(campaignId);
                } else if (matches[1] == "weeklyshorts") {
                    this.AddWeeklyShortCampaign(campaignId);
                } else if (matches[1] == "weeklygrands") {
                    this.AddWeeklyGrandCampaign(campaignId);
                } else if (Text::TryParseInt(matches[1], clubId)) {
                    this.AddClubCampaign(clubId, campaignId);
                } else {
                    _Logging::Error("Failed to add campaign from Trackmania.io link", true);
                }
            }
        } else if (Regex::Contains(str, "https?:\\/\\/(www\\.)?trackmania\\.com\\/clubs\\/\\d{1,6}\\/campaigns\\/\\d{1,6}\\/?$", regexFlags)) {
            array<string> matches = Regex::Search(str, "clubs\\/(\\d{1,6})\\/campaigns\\/(\\d{1,6})");
            int clubId;
            int activityId;

            if (!matches.IsEmpty() && Text::TryParseInt(matches[1], clubId) && Text::TryParseInt(matches[2], activityId)) {
                int campaignId = TM::GetCampaignIdFromActivity(clubId, activityId);

                if (campaignId == -1) {
                    _Logging::Error("Failed to find campaign from activity ID", true);
                    return;
                }

                this.AddClubCampaign(clubId, campaignId);
            }
        } else if (Regex::Contains(str, "https?:\\/\\/(www\\.)?trackmania\\.com\\/campaigns\\/\\d{4}\\/\\w*?\\/?$", regexFlags)) {
            // Official campaigns on the site use the format year/season
            array<string> matches = Regex::Search(str, "campaigns\\/(\\d{4})\\/(\\w*?)\\/?$");

            if (!matches.IsEmpty()) {
                string name = matches[2] + " " + matches[1];

                this.AddSeasonalCampaign(name);
            }
        } else if (Regex::IsMatch(str, "\\w{25,27}", regexFlags)) {
            this.AddFromUid(str);
        } else {
            _Logging::Warn("Unknown URL received, most features might fail to work properly.", true);
            this.AddMap(Map(str));
        }
    }

    void AddFolder(const string &in path) {
        try {
            if (!IO::FolderExists(path)) {
                _Logging::Warn("Failed to find folder in provided path. Make sure to use an absolute path!", true);
                return;
            }

            array<Map@> folderMaps = TM::GetMapsFromFolder(path);

            if (folderMaps.IsEmpty()) {
                _Logging::Warn("Failed to find any maps in the provided folder!", true);
                return;
            }

            for (uint i = 0; i < folderMaps.Length; i++) {
                this.AddMap(folderMaps[i]);
            }
        } catch {
            _Logging::Error("An error occurred while adding maps from folder in path \"" + path + "\": " + getExceptionInfo(), true);
        }
    }

    void SelectFolderAsync(const string &in path) {
        try {
            if (!IO::FolderExists(path)) {
                _Logging::Warn("Failed to find folder in provided path. Make sure to use an absolute path!", true);
                return;
            }

            array<Map@> folderMaps = TM::GetMapsFromFolder(path);

            if (folderMaps.IsEmpty()) {
                _Logging::Warn("Failed to find any maps in the provided folder!", true);
                return;
            }

            Renderables::Add(SelectMaps(folderMaps));
        } catch {
            _Logging::Error("An error occurred while adding maps from folder in path \"" + path + "\": " + getExceptionInfo(), true);
        }
    }

    void AddSeasonalCampaign(int campaignId) {
        foreach (TM::Campaign@ season : SEASONAL_CAMPAIGNS) {
            if (campaignId == season.Id) {
                startnew(CoroutineFuncUserdata(this.AddCampaign), season);
                return;
            }
        }

        _Logging::Error("Failed to find a seasonal campaign with that ID", true);
    }

    void AddSeasonalCampaign(const string &in name) {
        foreach (TM::Campaign@ season : SEASONAL_CAMPAIGNS) {
            if (name.ToLower() == season.Name.ToLower()) {
                startnew(CoroutineFuncUserdata(this.AddCampaign), season);
                return;
            }
        }

        _Logging::Error("Failed to find a seasonal campaign with that name", true);
    }

    void AddWeeklyShortCampaign(int campaignId) {
        foreach (TM::Campaign@ week : WEEKLY_SHORTS) {
            if (campaignId == week.Id) {
                startnew(CoroutineFuncUserdata(this.AddCampaign), week);
                return;
            }
        }

        _Logging::Error("Failed to find a weekly shorts week with that ID", true);
    }

    void AddWeeklyGrandCampaign(int campaignId) {
        foreach (TM::Campaign@ week : WEEKLY_GRANDS) {
            if (campaignId == week.Id) {
                startnew(CoroutineFuncUserdata(this.AddCampaign), week);
                return;
            }
        }

        _Logging::Error("Failed to find a weekly grands week with that ID", true);
    }

    void AddClubCampaign(int clubId, int campaignId, bool selectMaps = false) {
        TM::Campaign@ campaign = TM::GetClubCampaign(clubId, campaignId);

        if (campaign !is null) {
            if (selectMaps) {
                Renderables::Add(SelectMaps(campaign));
            } else {
                startnew(CoroutineFuncUserdata(this.AddCampaign), campaign);
            }
        }
    }

    void AddCampaignAsync(ref@ idRef) {
        array<int> ids = cast<array<int>>(idRef);

        this.AddClubCampaign(ids[0], ids[1]);
    }

    void SelectCampaignMapsAsync(ref@ idRef) {
        array<int> ids = cast<array<int>>(idRef);

        this.AddClubCampaign(ids[0], ids[1], true);
    }

    void SelectMappackAsync(int64 mappackId) {
        TMX::MappackInfo@ mappack = TMX::GetMappack(mappackId);

        if (mappack is null) {
            _Logging::Warn("Failed to add mappack to playlist! Mappack doesn't exist or is private.", true);
            return;
        } 
        
        if (mappack.MapCount == 0) {
            _Logging::Warn("Failed to add mappack to playlist! Mappack is empty.", true);
            return;
        }

        mappack.GetMaps();

        Renderables::Add(SelectMaps(mappack));
    }

    void AddFavorites(bool selectMaps = false) {
        if (selectMaps) {
            Renderables::Add(SelectMaps(FAVORITES));
        } else {
            for (uint i = 0; i < FAVORITES.Length; i++) {
                this.AddMap(FAVORITES[i]);
            }
        }
    }
}
