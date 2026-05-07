namespace TM {
    bool g_loadingMap = false;

    const uint COOLDOWN = 2500;

    void LoadMap(ref@ mapData) {
        try {
            Map@ map = cast<Map>(mapData);

            if (IsLoadingMap()) {
                // A map is already loading, ignore
                return;
            }

            _Logging::Debug("[LoadMap] Loading map \"" + map.Name + "\" with map type \"" + map.MapType + "\"");

            if (!Permissions::PlayLocalMap()) {
                _Logging::Error("Missing permission to play local maps. Club / Standard access is required.", true);
                return;
            }

            g_loadingMap = true;

            ClosePauseMenu();

            CTrackMania@ app = cast<CTrackMania>(GetApp());
            app.BackToMainMenu();

            while (!app.ManiaTitleControlScriptAPI.IsReady) {
                yield();
            }

            if (S_Editor) {
                app.ManiaTitleControlScriptAPI.EditMap(map.Url, "", "");
            } else {
                string gameMode;

                if (!TM::ModesFromMapType.Get(map.MapType, gameMode)) {
                    _Logging::Warn("[LoadMap] Unknown map type \"" + map.MapType + "\" from map \"" + map.Name + "\". Map might fail to load!", true);
                }

                app.ManiaTitleControlScriptAPI.PlayMap(map.Url, gameMode, "");
            }

            const uint start = Time::Now;

            while (Time::Now < start + COOLDOWN || IsLoadingScreen()) {
                yield();
            }

            g_loadingMap = false;
            @playlist.currentMap = map;
        } catch {
            _Logging::Error("[LoadMap] An error occurred while loading the map", true);
            g_loadingMap = false;
        }
    }

    bool InMap() {
        CGameCtnChallenge@ map = GetLoadedMap();
        return map !is null;
    }

    CGameCtnChallenge@ GetLoadedMap() {
        auto app = GetApp();
        return app.RootMap;
    }

    bool InEditor() {
        CTrackMania@ app = cast<CTrackMania>(GetApp());
        return app.Editor !is null;
    }

    bool InCurrentMap() {
        if (playlist.currentMap is null) {
            return false;
        }

        CGameCtnChallenge@ map = GetLoadedMap();

        if (map is null || map.IdName == "") {
            return false;
        }

        return map.IdName.ToLower() == playlist.currentMap.Uid.ToLower();
    }

    void ClosePauseMenu() {
        if (IsPauseMenuDisplayed()) {
            CSmArenaClient@ playground = cast<CSmArenaClient>(GetApp().CurrentPlayground);

            if (playground !is null) {
                playground.Interface.ManialinkScriptHandler.CloseInGameMenu(CGameScriptHandlerPlaygroundInterface::EInGameMenuResult::Resume);
            }
        }
    }

    bool IsPauseMenuDisplayed() {
        CTrackMania@ app = cast<CTrackMania>(GetApp());
        return app.ManiaPlanetScriptAPI.ActiveContext_InGameMenuDisplayed;
    }

    bool IsLoadingScreen() {
        CTrackMania@ app = cast<CTrackMania>(GetApp());
        auto pgCSApi = app.Network.PlaygroundClientScriptAPI;

        if (pgCSApi !is null && pgCSApi.IsLoadingScreen) {
            return true;
        }

        auto pg = app.PlaygroundScript;
        if (pg is null) return false;

        auto uiManager = pg.UIManager;
        if (uiManager !is null && uiManager.HoldLoadingScreen) {
            return true;
        }

        return false;
    }

    bool IsLoadingMap() {
        return g_loadingMap;
    }

    array<uint> royalTimes = { 0, 0, 0, 0 };

    int GetFinishScore() {
        if (!TM::InCurrentMap()) {
            return -1;
        }

        auto app = cast<CTrackMania>(GetApp());
        int score = -1;

        CSmArenaClient@ playground = cast<CSmArenaClient>(app.CurrentPlayground);
        CSmArenaRulesMode@ script = cast<CSmArenaRulesMode>(app.PlaygroundScript);

        if (playground !is null && script !is null && playground.GameTerminals.Length > 0) {
            CSmPlayer@ player = cast<CSmPlayer>(playground.GameTerminals[0].ControlledPlayer);

            if (player is null) {
                return -1;
            }

            auto seq = playground.GameTerminals[0].UISequence_Current;

            if (seq == SGamePlaygroundUIConfig::EUISequence::Finish || seq == SGamePlaygroundUIConfig::EUISequence::UIInteraction) {
                CSmScriptPlayer@ playerScriptAPI = cast<CSmScriptPlayer>(player.ScriptAPI);
                auto ghost = script.Ghost_RetrieveFromPlayer(playerScriptAPI);

                if (ghost !is null) {
                    switch (playlist.currentMap.GameMode) {
                        case GameMode::Stunt:
                            score = ghost.Result.StuntsScore;
                            break;
                        case GameMode::Platform:
                            score = ghost.Result.NbRespawns;
                            break;
                        case GameMode::Race:
                        case GameMode::Royal:
                        default:
                            if (ghost.Result.Time > 0 && ghost.Result.Time < uint(-1)) {
                                score = ghost.Result.Time;
                            }
                            break;
                    }

                    script.DataFileMgr.Ghost_Release(ghost.Id);

                    // from the Random Altered Campaign Challenge plugin https://openplanet.dev/plugin/randomalteredcampaign
                    // Credit to ArEyeses for the code
                    if (playlist.currentMap.GameMode == GameMode::Royal) {
                        uint resIndex = player.CurrentLaunchedRespawnLandmarkIndex;

                        if (resIndex >= 0 && resIndex < playground.Arena.MapLandmarks.Length) {
                            uint section = playground.Arena.MapLandmarks[resIndex].Order;

                            if (section == 5) {
                                return royalTimes[0] + royalTimes[1] + royalTimes[2] + royalTimes[3] + score;
                            }

                            royalTimes[section - 1] = score;

                            // Reset section times from previous runs
                            for (uint i = section; i < royalTimes.Length; i++) {
                                royalTimes[i] = 0;
                            }

                            return -1;
                        }

                        return -1;
                    }
                }
            }
        }

        return score;
    }
}
