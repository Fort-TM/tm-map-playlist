namespace CurrentMap {
    /*
     * Add the currently loaded challenge to the current playlist if it can be added.
     * Shows a notification on success or if the map is a duplicate.
     */
    void AddCurrentMapToCurrentPlaylist() {
        auto challenge = GetAddableCurrentChallenge();
        if (challenge is null) {
            return;
        }

        auto playlistNameSentence = (playlist.Name == "" ? "the current playlist" : "playlist \"" + playlist.Name + "\"");

        foreach (auto map : playlist.Maps) {
            if (map.Uid == challenge.MapInfo.MapUid) {
                UI::ShowNotification("Duplicate Map", Text::StripFormatCodes(challenge.MapInfo.Name) + " is already present in " + playlistNameSentence + ".", _Logging::WARN_COLOR);
                return;
            }
        }

        auto map = FetchMapForChallenge(challenge);
        playlist.AddMap(map);

        UI::ShowNotification("Map Added", Text::StripOpenplanetFormatCodes(map.GbxName) + " has been added to " + playlistNameSentence + ".");
    }

    /*
     * Add the currently loaded challenge to a set of playlists if it can be added.
     * Shows a notification upon completion. Playlists that already have the map will be silently ignored.
     */
    void AddCurrentMapToPlaylists(MapPlaylist@[] playlists) {
        auto challenge = GetAddableCurrentChallenge();
        auto map = FetchMapForChallenge(challenge);
        if (map is null) {
            return;
        }

        foreach (auto playlist : playlists) {
            playlist.AddMap(map);
        }

        UI::ShowNotification("Map Added", Text::StripOpenplanetFormatCodes(map.GbxName) + " has been added to " + tostring(playlists.Length) + " " + Pluralize("playlist", playlists.Length) + ".");

        Saves::UpdateFile();
    }

    // Returns true if a map is currently loaded and it can be added to a playlist; otherwise false.
    bool CanAddCurrentChallenge() {
        return GetAddableCurrentChallenge() !is null;
    }

    // Gets the currently loaded challenge if it is addable to a playlist; otherwise returns null.
    CGameCtnChallenge@ GetAddableCurrentChallenge() {
        auto challenge = cast<CTrackMania>(GetApp()).RootMap;
        if (TM::InEditor() || challenge is null || challenge.MapInfo is null) {
            return null;
        }
        return challenge;
    }

    // Fetches a map from a challenge. First attempts to load it by UID from TMX, then from NadeoServices, then from disk.
    Map@ FetchMapForChallenge(CGameCtnChallenge@ challenge) {
        if (challenge is null) {
            _Logging::Warn("[FetchCurrentChallengeMap] Current challenge is not addable as a map");
            return null;
        }

        Map@ map;

        _Logging::Trace("[FetchCurrentChallengeMap] Performing TMX map UID lookup for " + challenge.MapInfo.MapUid);
        @map = TMX::GetMapFromUid(challenge.MapInfo.MapUid);
        if (map is null) {
            _Logging::Trace("[FetchCurrentChallengeMap] TMX lookup unsuccessful for " + challenge.MapInfo.MapUid + "; trying NadeoServices");
            @map = TM::GetMapFromUid(challenge.MapInfo.MapUid);
        }
        if (map is null) {
            _Logging::Trace("[FetchCurrentChallengeMap] NadeoServices lookup unsuccessful for " + challenge.MapInfo.MapUid + "; trying local file");
            @map = Map(challenge, challenge.MapInfo.FileName);
        }
        // Map is guaranteed non-null if we used Map ctor

        return map;
    }

}