namespace TM {
    Map@ GetMapFromUid(const string &in mapUid) {
        _Logging::Debug("[GetMapFromUid] Getting map from UID \"" + mapUid + "\".");

        Map@ cachedMap = Cache::GetMap(mapUid);

        if (cachedMap !is null) {
            return cachedMap;
        }

        auto app = cast<CGameManiaPlanet>(GetApp());
        auto menu = app.MenuManager.MenuCustom_CurrentManiaApp;
        auto userId = menu.UserMgr.Users[0].Id;
        auto res = menu.DataFileMgr.Map_NadeoServices_GetFromUid(userId, mapUid);

        WaitAndClearTaskLater(res, menu.DataFileMgr);

        if (!res.HasSucceeded || res.HasFailed) {
            _Logging::Error("[GetMapFromUid] Failed to find a map with UID " + mapUid, true);
            _Logging::Error("[GetMapFromUid] Failed to get file URL from UID: Error " + res.ErrorCode + " - " + res.ErrorDescription);
            return null;
        }

        Map@ map = Map(res.Map);
        _Logging::Info("[GetMapFromUid] Found URL " + map.Url + " from UID " + mapUid);

        return map;
    }

    MwFastBuffer<CNadeoServicesMap@> GetMultipleMapsFromUids(array<string> uids) {
        _Logging::Trace("[GetMultipleMapsFromUids] Getting " + uids.Length + " maps from UID.");
        _Logging::Debug("[GetMultipleMapsFromUids] UIDs: " + Text::Join(uids, ", "));

        MwFastBuffer<wstring> bufferUids;

        for (uint i = 0; i < uids.Length; i++) {
            bufferUids.Add(uids[i]);
        }

        auto app = cast<CGameManiaPlanet>(GetApp());
        auto menu = app.MenuManager.MenuCustom_CurrentManiaApp;
        auto userId = menu.UserMgr.Users[0].Id;
        auto res = menu.DataFileMgr.Map_NadeoServices_GetListFromUid(userId, bufferUids);

        WaitAndClearTaskLater(res, menu.DataFileMgr);

        if (!res.HasSucceeded || res.HasFailed) {
            _Logging::Error("[GetMultipleMapsFromUids] Failed to get maps from UIDs", true);
            _Logging::Error("[GetMultipleMapsFromUids] Failed to get maps from UIDs: Error " + res.ErrorCode + " - " + res.ErrorDescription);
            return MwFastBuffer<CNadeoServicesMap@>();
        }

        _Logging::Info("[GetMultipleMapsFromUids] Found " + res.MapList.Length + " maps from " + uids.Length + " UIDs.");
        return res.MapList;
    }

    void GetWeeklyShorts() {
        if (!WEEKLY_SHORTS.IsEmpty()) {
            return;
        }

        while (!NadeoServices::IsAuthenticated("NadeoLiveServices")) {
            yield();
        }

        _Logging::Trace("[GetWeeklyShorts] Fetching weekly shorts.");

        string url = NadeoServices::BaseURLLive() + "/api/campaign/weekly-shorts?length=500&offset=0";

        auto req = NadeoServices::Get("NadeoLiveServices", url);
        req.Start();

        while (!req.Finished()) {
            yield();
        }

        int resCode = req.ResponseCode();
        Json::Value@ json = req.Json();

        _Logging::Debug("[GetWeeklyShorts] Response code: " + resCode);
        _Logging::Debug("[GetWeeklyShorts] JSON: " + Json::Write(json, true));

        if (resCode >= 400 || json.GetType() != Json::Type::Object || !json.HasKey("campaignList")) {
            _Logging::Error("[GetWeeklyShorts] Failed to get weekly shorts weeks from Nadeo Services");
            return;
        }

		if (json["campaignList"].Length == 0) {
            _Logging::Error("[GetWeeklyShorts] Weekly shorts endpoint returned 0 weeks.");
            return;
        }

        Json::Value@ weeks = json["campaignList"];

        for (uint i = 0; i < weeks.Length; i++) {
            TM::Campaign@ week = TM::Campaign(weeks[i]);
            WEEKLY_SHORTS.InsertLast(week);
        }

        _Logging::Debug("[GetWeeklyShorts] Loaded " + weeks.Length + " weekly shorts weeks.");
    }

    void GetWeeklyGrands() {
        if (!WEEKLY_GRANDS.IsEmpty()) {
            return;
        }

        while (!NadeoServices::IsAuthenticated("NadeoLiveServices")) {
            yield();
        }

        _Logging::Trace("[GetWeeklyGrands] Fetching weekly grands.");

        string url = NadeoServices::BaseURLLive() + "/api/campaign/weekly-grands?length=500&offset=0";

        auto req = NadeoServices::Get("NadeoLiveServices", url);
        req.Start();

        while (!req.Finished()) {
            yield();
        }

        int resCode = req.ResponseCode();
        Json::Value@ json = req.Json();

        _Logging::Debug("[GetWeeklyGrands] Response code: " + resCode);
        _Logging::Debug("[GetWeeklyGrands] JSON: " + Json::Write(json, true));

        if (resCode >= 400 || json.GetType() != Json::Type::Object || !json.HasKey("campaignList")) {
            _Logging::Error("[GetWeeklyGrands] Failed to get weekly grands from Nadeo Services");
            return;
        }

		if (json["campaignList"].Length == 0) {
            _Logging::Error("[GetWeeklyGrands] Weekly grands endpoint returned 0 weeks.");
            return;
        }

        Json::Value@ weeks = json["campaignList"];

        for (uint i = 0; i < weeks.Length; i++) {
            TM::Campaign@ week = TM::Campaign(weeks[i]);
            WEEKLY_GRANDS.InsertLast(week);
        }

        _Logging::Debug("[GetWeeklyGrands] Loaded " + weeks.Length + " weekly grands weeks.");
    }

    void GetSeasonalCampaigns() {
        if (!SEASONAL_CAMPAIGNS.IsEmpty()) {
            return;
        }

        while (!NadeoServices::IsAuthenticated("NadeoLiveServices")) {
            yield();
        }

        _Logging::Trace("[GetSeasonalCampaigns] Fetching seasonal campaigns.");

        string url = NadeoServices::BaseURLLive() + "/api/campaign/official?length=500&offset=0";

        auto req = NadeoServices::Get("NadeoLiveServices", url);
        req.Start();

        while (!req.Finished()) {
            yield();
        }

        int resCode = req.ResponseCode();
        Json::Value@ json = req.Json();

        _Logging::Debug("[GetSeasonalCampaigns] Response code: " + resCode);
        _Logging::Debug("[GetSeasonalCampaigns] JSON: " + Json::Write(json, true));

        if (resCode >= 400 || json.GetType() != Json::Type::Object || !json.HasKey("campaignList")) {
            _Logging::Error("[GetSeasonalCampaigns] Failed to get seasonal campaigns from Nadeo Services.");
            return;
        }

		if (json["campaignList"].Length == 0) {
            _Logging::Error("[GetSeasonalCampaigns] Seasonal campaigns endpoint returned 0 campaigns.");
            return;
        }

        Json::Value@ campaigns = json["campaignList"];

        for (uint i = 0; i < campaigns.Length; i++) {
            TM::Campaign@ season = TM::Campaign(campaigns[i]);
            SEASONAL_CAMPAIGNS.InsertLast(season);
        }

        _Logging::Debug("[GetSeasonalCampaigns] Loaded " + campaigns.Length + " seasonal campaigns.");
    }

    void GetFavorites() {
        if (!FAVORITES.IsEmpty()) {
            return;
        }

        _Logging::Trace("[GetFavorites] Fetching favorites.");

        auto app = cast<CGameManiaPlanet>(GetApp());
        auto menu = app.MenuManager.MenuCustom_CurrentManiaApp;
        auto userId = menu.UserMgr.Users[0].Id;
        auto res = menu.DataFileMgr.Map_NadeoServices_GetFavoriteList(userId, MwFastBuffer<wstring>(), true, false, true, false);

        WaitAndClearTaskLater(res, menu.DataFileMgr);

        if (!res.HasSucceeded || res.HasFailed) {
            _Logging::Error("[GetFavorites] Failed to get favorite maps", true);
            _Logging::Error("[GetFavorites] Failed to get favorite maps: Error " + res.ErrorCode + " - " + res.ErrorDescription);
            return;
        }

        _Logging::Info("[GetFavorites] Found " + res.MapList.Length + " maps in favorites.");

        MwFastBuffer<CNadeoServicesMap@> favoriteMaps = res.MapList;

        for (uint i = 0; i < favoriteMaps.Length; i++) {
            Map@ map = Map(favoriteMaps[i]);
            FAVORITES.InsertLast(map);
        }

        _Logging::Debug("[GetFavorites] Loaded " + favoriteMaps.Length + " favorites.");
    }

    void GetTOTDMonths() {
        if (!TOTD_MONTHS.IsEmpty()) {
            return;
        }

        while (!NadeoServices::IsAuthenticated("NadeoLiveServices")) {
            yield();
        }

        _Logging::Trace("[GetTOTDMonths] Fetching TOTD months.");

        string url = NadeoServices::BaseURLLive() + "/api/token/campaign/month?offset=0&length=250";

        auto req = NadeoServices::Get("NadeoLiveServices", url);
        req.Start();

        while (!req.Finished()) {
            yield();
        }

        int resCode = req.ResponseCode();
        Json::Value@ json = req.Json();

        _Logging::Debug("[GetTOTDMonths] Response code: " + resCode);
        //_Logging::Trace("[GetTOTDMonths] JSON: " + Json::Write(json, true));

        if (resCode >= 400 || json.GetType() != Json::Type::Object || !json.HasKey("monthList")) {
            _Logging::Error("[GetTOTDMonths] Failed to get TOTD months from Nadeo Services");
            return;
        }

		if (json["monthList"].Length == 0) {
            _Logging::Error("[GetTOTDMonths] TOTD endpoint returned 0 months.");
            return;
        }

        Json::Value@ monthList = json["monthList"];

        for (uint i = 0; i < monthList.Length; i++) {
            Json::Value@ data = monthList[i];

            if (data["days"].Length == 0) {
                // Month doesn't have any maps
                continue;
            }

            TM::TOTDMonth@ month = TM::TOTDMonth(monthList[i]);
            TOTD_MONTHS.InsertLast(month);
        }

        _Logging::Debug("[GetTOTDMonths] Loaded " + TOTD_MONTHS.Length + " TOTD months.");
    }

    Campaign@ GetClubCampaign(int clubId, int campaignId) {
        if (!Permissions::PlayPublicClubCampaign()) {
            _Logging::Error("Missing permission to play club campaigns!", true);
            return null;
        }

        while (!NadeoServices::IsAuthenticated("NadeoLiveServices")) {
            yield();
        }

        _Logging::Trace("[GetClubCampaign] Getting campaign #" + campaignId + " from club #" + clubId);

        string url = NadeoServices::BaseURLLive() + "/api/token/club/" + clubId + "/campaign/" + campaignId;

        _Logging::Debug("[GetClubCampaign] Club campaign API request: " + url);

        auto req = NadeoServices::Get("NadeoLiveServices", url);
        req.Start();

        while (!req.Finished()) {
            yield();
        }

        int resCode = req.ResponseCode();
        Json::Value@ json = req.Json();

        _Logging::Debug("[GetClubCampaign] Response code: " + resCode);
        _Logging::Debug("[GetClubCampaign] JSON: " + Json::Write(json, true));

        if (json.GetType() == Json::Type::Array) {
            if (json[0] == "activity:error-notFound") {
                _Logging::Error("[GetClubCampaign] Failed to get club campaign: A club or campaign with that ID doesn't exist!", true);
                return null;
            }

            _Logging::Error("[GetClubCampaign] Failed to get club campaign: " + string(json[0]), true);
            return null;
        }

		if (resCode >= 400 || json.GetType() != Json::Type::Object || !json.HasKey("campaign")) {
            _Logging::Error("[GetClubCampaign] Failed to get club campaign from Nadeo Services");
            return null;
        }

        Json::Value@ data = json["campaign"];

        _Logging::Info("[GetClubCampaign] Found club campaign " + string(data["name"]) + " from the club " + string(json["clubName"]));

        return Campaign(data);
    }

    array<TM::ClubActivity@> SearchClubCampaigns(const string &in query = "", int offset = 0) {
        if (!Permissions::PlayPublicClubCampaign()) {
            _Logging::Error("Missing permission to play club campaigns!", true);
            return {};
        }

        while (!NadeoServices::IsAuthenticated("NadeoLiveServices")) {
            yield();
        }

        _Logging::Trace("[SearchClubCampaigns] Searching club campaigns.");
        _Logging::Debug("[SearchClubCampaigns] Query: " + query + ". Offset: " + offset);

        string searchUrl = NadeoServices::BaseURLLive() + "/api/token/club/campaign?length=200&offset=" + offset;

        if (query != "") {
            searchUrl += "&name=" + query;
        }

        Net::HttpRequest@ req = NadeoServices::Get("NadeoLiveServices", searchUrl);

        req.Start();

        while (!req.Finished()) {
            yield();
        }

        int resCode = req.ResponseCode();
        Json::Value@ json = req.Json();

        _Logging::Debug("[SearchClubCampaigns] Response code: " + resCode);

        if (resCode >= 400 || json.GetType() != Json::Type::Object || !json.HasKey("clubCampaignList")) {
            _Logging::Error("[SearchClubCampaigns] Something went wrong while searching for club campaigns.", true);
            return {};
        }

        Json::Value@ list = json["clubCampaignList"];

        _Logging::Debug("[SearchClubCampaigns] Found " + list.Length + " club campaigns.");

        array<TM::ClubActivity@> campaigns;

        for (uint i = 0; i < list.Length; i++) {
            campaigns.InsertLast(TM::ClubActivity(list[i]));
        }

        return campaigns;
    }

    uint MAX_ATTEMPTS = 5;
    uint LENGTH = 250;

    int GetCampaignIdFromActivity(int clubId, int activityId) {
        if (!Permissions::PlayPublicClubCampaign()) {
            _Logging::Error("Missing permission to play club campaigns!", true);
            return -1;
        }

        while (!NadeoServices::IsAuthenticated("NadeoLiveServices")) {
            yield();
        }

        _Logging::Trace("[GetCampaignIdFromActivity] Searching campaign #" + activityId + " in club #" + clubId);

        for (uint i = 0; i < MAX_ATTEMPTS; i++) {
            uint offset = LENGTH * i;
            uint currentPage = i + 1;

            string url = NadeoServices::BaseURLLive() + "/api/token/club/" + clubId + "/activity?length=" + LENGTH + "&offset=" + offset + "&active=true";

            _Logging::Debug("[GetCampaignIdFromActivity] Club activities API request: " + url);

            auto req = NadeoServices::Get("NadeoLiveServices", url);
            req.Start();

            while (!req.Finished()) {
                yield();
            }

            int resCode = req.ResponseCode();
            Json::Value@ json = req.Json();

            _Logging::Debug("[GetCampaignIdFromActivity] Response code: " + resCode);

            if (resCode >= 400 || json.GetType() != Json::Type::Object || !json.HasKey("activityList")) {
                _Logging::Error("[GetCampaignIdFromActivity] Failed to get club campaign ID from Nadeo Services");
                return -1;
            }

            Json::Value@ activities = json["activityList"];

            for (uint a = 0; a < activities.Length; a++) {
                Json::Value@ activity = activities[a];

                if (activity["activityType"] != "campaign") {
                    continue;
                }

                if (activity["id"] == activityId) {
                    return activity["campaignId"];
                }
            }

            uint items = json["itemCount"];
            uint maxPages = json["maxPage"];

            if (items < LENGTH || maxPages == currentPage) {
            	// We reached the end without finding the activity
                return -1;
            }

            if (currentPage < MAX_ATTEMPTS) {
                sleep(1000);
            }
        }

        return -1;
    }

    uint g_lastRequest = 0;
    array<Map@> g_queue;
    const uint PB_COOLDOWN = 3000;

    void GetPb(ref@ mapRef) {
        Map@ map = cast<Map>(mapRef);

        if (map is null || map.Uid == "" || g_queue.Find(map) > -1 || map.GameMode == GameMode::Royal || map.HasPb) {
            return;
        }

        uint now = Time::Now;
        g_lastRequest = now;
        g_queue.InsertLast(map);

        sleep(PB_COOLDOWN);

        if (g_lastRequest > now) {
            // Another request
            return;
        }

        array<Map@> mapList = g_queue;
        g_queue.RemoveRange(0, g_queue.Length);
        QueueMapPbs(mapList);
    }

    void QueueMapPbs(array<Map@> maps) {
        GetMapIds(maps);

        array<string> raceIds;
        array<string> cloneIds;
        array<string> stuntIds;
        array<string> platformIds;

        foreach (Map@ map : maps) {
            string mapId = Cache::GetMapId(map.Uid);

            if (mapId == "") {
                continue;
            }

            switch (map.GameMode) {
                case GameMode::Race:
                    if (map.HasClones) {
                        cloneIds.InsertLast(mapId);
                    } else {
                        raceIds.InsertLast(mapId);
                    }

                    break;
                case GameMode::Stunt:
                    stuntIds.InsertLast(mapId);
                    break;
                case GameMode::Platform:
                    platformIds.InsertLast(mapId);
                    break;
                default:
                    break;
            }
        }

        if (!raceIds.IsEmpty()) GetPbs(raceIds, GameMode::Race);
        if (!cloneIds.IsEmpty()) GetPbs(cloneIds, GameMode::Race, true);
        if (!stuntIds.IsEmpty()) GetPbs(stuntIds, GameMode::Stunt);
        if (!platformIds.IsEmpty()) GetPbs(platformIds, GameMode::Platform);
    }

    void GetPbs(array<string> ids, GameMode mode, bool clones = false) {
        while (!NadeoServices::IsAuthenticated("NadeoServices")) {
            yield();
        }

        string userId = NadeoServices::GetAccountID();
        array<array<string>> idChunks = Chunks(ids, 200);

        string modeName = "TimeAttack";

        if (mode == GameMode::Stunt || mode == GameMode::Platform) {
            modeName = tostring(mode);
        } else if (clones) {
            modeName = "TimeAttackClone";
        }

        _Logging::Trace("[GetPbs] Getting PBs for " + ids.Length + " " + modeName + " maps.");

        for (uint c = 0; c < idChunks.Length; c++) {
            string url = NadeoServices::BaseURLCore() + "/v2/accounts/" + userId + "/mapRecords?mapIdList=" + Text::Join(idChunks[c], ",") + "&gameMode=" + modeName;

            _Logging::Debug("[GetPbs] Account PBs API request: " + url);

            auto req = NadeoServices::Get("NadeoServices", url);
            req.Start();

            while (!req.Finished()) {
                yield();
            }

            int resCode = req.ResponseCode();
            Json::Value@ json = req.Json();

            _Logging::Debug("[GetPbs] Response code: " + resCode);

            if (resCode >= 400 || json.GetType() != Json::Type::Array) {
                _Logging::Error("[GetPbs] Failed to get account PBs from Nadeo Services.");
                return;
            }

            _Logging::Debug("[GetPbs] Found " + json.Length + " " + modeName + " records.");

            for (uint i = 0; i < json.Length; i++) {
                Json::Value@ record = json[i];

                string mapId = record["mapId"];
                string gamemode = record["gameMode"];

                int score;

                if (gamemode == "Stunt") {
                    score = record["recordScore"]["score"];
                } else if (gamemode == "Platform") {
                    score = record["recordScore"]["respawnCount"];
                } else {
                    score = record["recordScore"]["time"];
                }

                string mapUid = Cache::GetMapUid(mapId);
                Cache::SetPb(mapUid, score, gamemode == "Stunt");
            }

            if (c != idChunks.Length - 1) {
                sleep(1000);
            }
        }
    }

    void GetMapIds(array<Map@> maps) {
        _Logging::Trace("[GetMapIds] Getting map IDs for " + maps.Length + " maps.");

        array<string> uids;

        for (uint i = 0; i < maps.Length; i++) {
            if (maps[i].Uid == "" || Cache::GetMapId(maps[i].Uid) != "") {
                continue;
            }

            uids.InsertLast(maps[i].Uid);
        }

        if (uids.IsEmpty()) {
            return;
        }

        array<array<string>> uidChunks = Chunks(uids, 275);

        for (uint c = 0; c < uidChunks.Length; c++) {
            auto idMaps = GetMultipleMapsFromUids(uidChunks[c]);

            _Logging::Debug("[GetMapIds] Found " + idMaps.Length + " map IDs from " + uidChunks[c].Length + " UIDs.");

            for (uint m = 0; m < idMaps.Length; m++) {
                Cache::SetMapId(idMaps[m].Uid, idMaps[m].Id);
                Cache::SetThumbnailUrl(idMaps[m].Uid, idMaps[m].ThumbnailUrl);
            }
        }
    }
}
