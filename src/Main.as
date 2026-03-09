void Main() {
    if (!HAS_PERMISSIONS) {
        _Logging::Error("You don't have enough permissions to use this plugin!", true);

        Meta::Plugin@ self = Meta::ExecutingPlugin();
        Meta::UnloadPlugin(self);
    }

#if !DEPENDENCY_WARRIORMEDALS
    // if plugin was uninstalled, reset settings
    if (S_GoalMedal > Medals::Author || S_MainMedal > Medals::Author) {
        S_GoalMedal = Medals::Author;
        S_MainMedal = Medals::Author;
    }
#endif

    Saves::LoadPlaylists();
    Cache::LoadIdCache();

    NadeoServices::AddAudience("NadeoLiveServices");
    NadeoServices::AddAudience("NadeoServices");

    startnew(MainLoop);
    startnew(PbLoop);
    startnew(TMX::GetTags);

    if (!S_SkipLoad) {
        while (!g_showMainWindow) {
            yield();
        }

        TM::GetWeeklyShorts();
        TM::GetWeeklyGrands();
        TM::GetSeasonalCampaigns();
        TM::GetTOTDMonths();
        TM::GetFavorites();
    }
}

void OnDisabled() {
    Cache::StoreMapIds();
    Saves::UpdateFile();
}

void OnDestroyed() {
    Cache::StoreMapIds();
    Saves::UpdateFile();
}

[Setting hidden]
bool g_showMainWindow = true;

[Setting hidden]
bool g_showTimer = false;

void RenderMenu() {
    if (!HAS_PERMISSIONS) {
        return;
    }

    if (UI::BeginMenu(FULL_NAME)) {
        if (UI::MenuItem(Icons::WindowMaximize + " Main Window", "", g_showMainWindow)) {
            g_showMainWindow = !g_showMainWindow;
        }

        if (UI::MenuItem(Icons::ClockO + " Display timer", "", g_showTimer)) {
            g_showTimer = !g_showTimer;
        }

        if (UI::BeginMenu(Icons::Plus + " Add current map to...", CurrentMap::CanAddCurrentChallenge())) {
            if (UI::MenuItem("Current playlist")) {
                startnew(CurrentMap::AddCurrentMapToCurrentPlaylist);
            }
            if (UI::MenuItem("Saved playlists")) {
                Renderables::Add(AddToPlaylist());
            }
            UI::EndMenu();
        }

        UI::EndMenu();
    }
}

void Render() {
    if (!HAS_PERMISSIONS || (S_HideWithOP && !UI::IsOverlayShown()) || (S_HideWithGameUI && !UI::IsGameUIVisible())) {
        return;
    }

    UI::RenderMainWindow();
    Timer::Render();

    Renderables::Render();
}

void Update(float dt) {
    Timer::Update();
}

UI::InputBlocking OnKeyPress(bool down, VirtualKey key) {
    if (!HAS_PERMISSIONS) return UI::InputBlocking::DoNothing;

    if (_Hotkeys::ListeningForKey) {
        _Hotkeys::AssignHotkey(key);
        return UI::InputBlocking::Block;
    }

    if (key == S_WindowKey) {
        g_showMainWindow = !g_showMainWindow;
        return UI::InputBlocking::Block;
    }

    if (key == S_TimerKey) {
        g_showTimer = !g_showTimer;
        return UI::InputBlocking::Block;
    }

    if (key == S_SwitchKey && !playlist.IsEmpty() && !TM::IsLoadingMap()) {
        playlist.NextMap();
        return UI::InputBlocking::Block;
    }

    if (key == S_AddCurrentMapKey) {
        startnew(CurrentMap::AddCurrentMapToCurrentPlaylist);
        return UI::InputBlocking::Block;
    }

    if (key == S_AddCurrentMapModalKey) {
        if ((!S_HideWithOP || UI::IsOverlayShown()) && (!S_HideWithGameUI || UI::IsGameUIVisible())) {
            Renderables::Add(AddToPlaylist());
        }
        return UI::InputBlocking::Block;
    }

    return UI::InputBlocking::DoNothing;
}

void MainLoop() {
    string currentUid = "";
    bool notified = false;

    auto app = cast<CTrackMania>(GetApp());

    while (playlist.IsEmpty() || playlist.currentMap is null) {
        yield();
    }

    while (true) {
        yield();

        if (TM::InEditor() || !TM::InCurrentMap()) {
            sleep(1000);
            continue;
        }

        if (app.RootMap.IdName != currentUid) {
            currentUid = app.RootMap.IdName;
            notified = false;
        }

        int score = TM::GetFinishScore();
        bool inverse = playlist.currentMap.GameMode == GameMode::Stunt;

        if (score <= -1) {
            sleep(50);
            continue;
        }

        Cache::SetSessionPb(currentUid, score, inverse);

        if (S_SwitchOnMedal && !notified) {
            int goal = playlist.currentMap.GetMedalScore(S_GoalMedal);

            if ((inverse && score >= goal) || (!inverse && score <= goal)) {
                string medalName = tostring(S_GoalMedal);

#if DEPENDENCY_WARRIORMEDALS
                if (S_GoalMedal == Medals::Warrior && !playlist.currentMap.HasWarrior) {
                    medalName = tostring(Medals(Medals::Warrior - 1));
                }
#endif
                UI::ShowNotification(PLUGIN_NAME, "Got the " + medalName + " medal! Loading next map...");
                notified = true;

                sleep(1000);
                playlist.NextMap();
            }
        }

        sleep(1000);
    }
}

void PbLoop() {
    auto app = cast<CTrackMania>(GetApp());

    while (true) {
        if (TM::InEditor() || !TM::InMap()) {
            sleep(1000);
            continue;
        }

        if (app.Network is null || app.Network.ClientManiaAppPlayground is null) {
            sleep(500);
            continue;
        }

        auto userId = app.UserManagerScript.Users[0].Id;
        auto map = app.RootMap;
        string mapUid = map.IdName;

        bool isStunt = map.MapType == "TrackMania\\TM_Stunt";
        bool isPlatform = map.MapType == "TrackMania\\TM_Platform";
        bool isClones = map.MapInfo !is null && map.MapInfo.TMObjective_NbClones > 0;

        string mode = "TimeAttack";
        if (isStunt) {
            mode = "Stunt";
        } else if (isPlatform) {
            mode = "Platform";
        } else if (isClones) {
            mode = "TimeAttackClone";
        }

        auto scoreMgr = app.Network.ClientManiaAppPlayground.ScoreMgr;
        uint score = scoreMgr.Map_GetRecord_v2(userId, mapUid, "PersonalBest", "", mode, "");

        if (score < uint(-1)) {
            Cache::SetPb(mapUid, score, isStunt);
        }

        sleep(500);
    }
}
