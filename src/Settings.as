// --- General ---

[Setting hidden]
bool S_HideWithOP = true;

[Setting hidden]
bool S_HideWithGameUI = true;

// --- Playlist ---

[Setting hidden]
bool S_Editor = false;

[Setting hidden]
bool S_Loop = false;

[Setting hidden]
bool S_Timer = false;

[Setting hidden]
int S_TimeLimit = 300;

[Setting hidden]
bool S_SwitchOnMedal = false;

[Setting hidden]
Medals S_GoalMedal = Medals::Author;

// --- Display ---

[Setting hidden]
bool S_ColoredNames = true;

[Setting hidden]
bool S_ColoredTags = true;

[Setting hidden]
bool S_MapThumbnail = true;

[Setting hidden]
Medals S_MainMedal = Medals::Author;

[Setting hidden]
bool S_MapName = true;

[Setting hidden]
bool S_MapAuthor = true;

[Setting hidden]
bool S_MapUrl = false;

[Setting hidden]
bool S_MapUid = false;

[Setting hidden]
bool S_MapGamemode = false;

[Setting hidden]
bool S_MapVista = false;

[Setting hidden]
bool S_MapTags = true;

[Setting hidden]
bool S_MapMedals = true;

[Setting hidden]
bool S_MapPb = true;

[Setting hidden]
bool S_MapDelta = true;

[Setting hidden]
bool S_MapSessionPb = false;

[Setting hidden]
bool S_MapSessionDelta = false;

[Setting hidden]
bool S_MapButtons = true;

[Setting hidden]
bool S_PlaylistName = true;

[Setting hidden]
bool S_PlaylistMapCount = true;

[Setting hidden]
bool S_PlaylistTags = true;

[Setting hidden]
bool S_PlaylistDate = true;

[Setting hidden]
bool S_PlaylistButtons = true;

// --- Hotkeys ---

[Setting hidden]
VirtualKey S_SwitchKey = VirtualKey(0);

[Setting hidden]
VirtualKey S_WindowKey = VirtualKey(0);

[Setting hidden]
VirtualKey S_TimerKey = VirtualKey(0);

[Setting hidden]
VirtualKey S_AddCurrentMapKey = VirtualKey(0);

[Setting hidden]
VirtualKey S_AddCurrentMapModalKey = VirtualKey(0);

// --- Dev ---

[Setting hidden]
LogLevel S_LogLevel = LogLevel::Info;

[Setting hidden]
bool S_SkipLoad = false;


// --- Tabs rendering ---

[SettingsTab name="General" order="1" icon="Wrench"]
void RenderGeneralSettings() {
    UI::BeginChild("GeneralSettings");

    if (UI::Button("Reset to default")) {
        S_HideWithOP = true;
        S_HideWithGameUI = true;
    }

    S_HideWithOP = UI::Checkbox("Show/Hide with Openplanet overlay", S_HideWithOP);
    S_HideWithGameUI = UI::Checkbox("Show/Hide with game UI", S_HideWithGameUI);

    UI::EndChild();
}

[SettingsTab name="Playlist" order="2" icon="List"]
void RenderPlaylistSettings() {
    UI::BeginChild("PlaylistSettings");

    if (UI::Button("Reset to default")) {
        S_Editor = false;
        S_Loop = false;
        S_Timer = false;
        S_TimeLimit = 300;
        S_SwitchOnMedal = false;
        S_GoalMedal = Medals::Author;
    }

    S_Editor = UI::Checkbox("Load in editor", S_Editor);
    UI::SettingDescription("When enabled, maps will be loaded in the editor.");

    S_Loop = UI::Checkbox("Loop playlist", S_Loop);
    UI::SettingDescription("When enabled, the playlist will start again after reaching the last map.");

    S_Timer = UI::Checkbox("Time limit", S_Timer);
    UI::SettingDescription("Automatically switch to the next map after the timer is up.");

    if (S_Timer) {
        UI::SetNextItemWidth(150);
        S_TimeLimit = UI::InputInt("Time limit per map (in seconds)", S_TimeLimit, 0);

        if (UI::IsItemActive() && !Timer::Paused) {
            Timer::Pause();
        }
    }

    S_SwitchOnMedal = UI::Checkbox("Auto switch on medal", S_SwitchOnMedal);
    string medalText = "When enabled, the plugin will automatically switch to the next map after reaching the selected medal.";
#if DEPENDENCY_WARRIORMEDALS
    medalText += "\n\nIf a map doesn't have a Warrior time, it will default to the Author medal instead.";
#endif
    medalText += "\n\nNOTE: Doesn't work in the editor or in maps from unknown sources.";

    UI::SettingDescription(medalText);


    if (S_SwitchOnMedal) {
        UI::SetNextItemWidth(175);
        if (UI::BeginCombo("Goal medal", tostring(S_GoalMedal))) {
            for (int i = 0; i < Medals::Last; i++) {
                if (UI::Selectable(tostring(Medals(i)), S_GoalMedal == Medals(i))) {
                    S_GoalMedal = Medals(i);
                }
            }
            UI::EndCombo();
        }
    }

    UI::EndChild();
}

[SettingsTab name="Display" order="3" icon="Eye"]
void RenderDisplaySettings() {
    UI::BeginChild("DisplaySettings");

    if (UI::Button("Reset to default")) {
        S_ColoredNames = true;
        S_ColoredTags = true;
        S_MapThumbnail = true;

        S_MainMedal = Medals::Author;

        S_MapName = true;
        S_MapAuthor = true;
        S_MapUrl = false;
        S_MapUid = false;
        S_MapGamemode = false;
        S_MapVista = false;
        S_MapTags = true;
        S_MapMedals = true;
        S_MapPb = true;
        S_MapDelta = true;
        S_MapSessionPb = false;
        S_MapSessionDelta = false;
        S_MapButtons = true;

        S_PlaylistName = true;
        S_PlaylistMapCount = true;
        S_PlaylistTags = true;
        S_PlaylistDate = true;
        S_PlaylistButtons = true;
    }

    S_ColoredTags = UI::Checkbox("Use TMX colors for tags", S_ColoredTags);
    UI::SettingDescription("When disabled, tags will use the default gray background color instead of the colors provided by TMX");

    UI::PushFontSize(21);
    UI::SeparatorText("Maps");
    UI::PopFontSize();

    S_ColoredNames = UI::Checkbox("Display colored map names", S_ColoredNames);
    S_MapThumbnail = UI::Checkbox("Display thumbnail when hovering a map name", S_MapThumbnail);

    array<bool> mapValues = { S_MapName, S_MapAuthor, S_MapUrl, S_MapUid, S_MapGamemode, S_MapVista, S_MapTags, S_MapMedals, S_MapPb, S_MapDelta, S_MapSessionPb, S_MapSessionDelta, S_MapButtons };
    string mapComboText = GetComboText(mapValues);

    UI::SetNextItemWidth(145);
    if (UI::BeginCombo("Displayed columns##Map", mapComboText)) {
        S_MapName = UI::Checkbox("Name##Map", S_MapName);
        S_MapAuthor = UI::Checkbox("Author##Map", S_MapAuthor);
        S_MapUrl = UI::Checkbox("URL##Map", S_MapUrl);
        S_MapUid = UI::Checkbox("UID##Map", S_MapUid);
        S_MapGamemode = UI::Checkbox("Mode##Map", S_MapGamemode);
        S_MapVista = UI::Checkbox("Vista##Map", S_MapVista);
        S_MapTags = UI::Checkbox("TMX Tags##Map", S_MapTags);
        S_MapMedals = UI::Checkbox("Medals##Map", S_MapMedals);
        S_MapPb = UI::Checkbox("PB##Map", S_MapPb);
        S_MapDelta = UI::Checkbox("Delta##Map", S_MapDelta);
        S_MapSessionPb = UI::Checkbox("Session PB##Map", S_MapSessionPb);
        S_MapSessionDelta = UI::Checkbox("Session Delta##Map", S_MapSessionDelta);
        S_MapButtons = UI::Checkbox("Buttons##Map", S_MapButtons);

        UI::EndCombo();
    }

    UI::SetNextItemWidth(145);
    if (UI::BeginCombo("Main medal", tostring(S_MainMedal))) {
        for (int i = 0; i < Medals::Last; i++) {
            if (UI::Selectable(tostring(Medals(i)), S_MainMedal == Medals(i))) {
                S_MainMedal = Medals(i);
            }
        }
        UI::EndCombo();
    }

    string settingText = "The medal shown in the Medals column and used to calculate the delta to your PB.";
#if DEPENDENCY_WARRIORMEDALS
    settingText += "\n\nIf a map doesn't have a Warrior time, it will default to the Author medal instead.";
#endif
    UI::SettingDescription(settingText);

    UI::PushFontSize(21);
    UI::SeparatorText("Playlists");
    UI::PopFontSize();

    array<bool> playlistValues = { S_PlaylistName, S_PlaylistMapCount, S_PlaylistTags, S_PlaylistDate, S_PlaylistButtons };
    string playlistComboText = GetComboText(playlistValues);

    UI::SetNextItemWidth(145);
    if (UI::BeginCombo("Displayed columns##Playlist", playlistComboText)) {
        S_PlaylistName = UI::Checkbox("Name##Playlist", S_PlaylistName);
        S_PlaylistMapCount = UI::Checkbox("Map Count##Playlist", S_PlaylistMapCount);
        S_PlaylistTags = UI::Checkbox("Tags##Playlist", S_PlaylistTags);
        S_PlaylistDate = UI::Checkbox("Created at##Playlist", S_PlaylistDate);
        S_PlaylistButtons = UI::Checkbox("Buttons##Playlist", S_PlaylistButtons);

        UI::EndCombo();
    }

    UI::EndChild();
}

[SettingsTab name="Hotkeys" order="4" icon="KeyboardO"]
void RenderHotkeySettings() {
    UI::BeginChild("HotkeySettings");

    if (UI::Button("Reset to default")) {
        _Hotkeys::StopListeningForKey();
        S_SwitchKey = VirtualKey(0);
        S_WindowKey = VirtualKey(0);
        S_TimerKey = VirtualKey(0);
        S_AddCurrentMapKey = VirtualKey(0);
        S_AddCurrentMapModalKey = VirtualKey(0);
    }

    _Hotkeys::RenderHotkeyCombo("Switch map", S_SwitchKey);
    UI::SettingDescription("Hotkey to switch to the next map in the playlist.");

    UI::SameLine();

    if (_Hotkeys::ListeningForSwitchKey) {
        UI::Text("Press a key");
    } else if (UI::GreyButton("Detect##Switch")) {
        _Hotkeys::ListeningForSwitchKey = true;
    }

    _Hotkeys::RenderHotkeyCombo("Show/Hide main window", S_WindowKey);

    UI::SameLine();

    if (_Hotkeys::ListeningForWindowKey) {
        UI::Text("Press a key");
    } else if (UI::GreyButton("Detect##Window")) {
        _Hotkeys::ListeningForWindowKey = true;
    }

    _Hotkeys::RenderHotkeyCombo("Show/Hide timer", S_TimerKey);

    UI::SameLine();

    if (_Hotkeys::ListeningForTimerKey) {
        UI::Text("Press a key");
    } else if (UI::GreyButton("Detect##Timer")) {
        _Hotkeys::ListeningForTimerKey = true;
    }

    _Hotkeys::RenderHotkeyCombo("Add current map", S_AddCurrentMapKey);

    UI::SameLine();

    if (_Hotkeys::ListeningForAddCurrentMapKey) {
        UI::Text("Press a key");
    } else if (UI::GreyButton("Detect##AddCurrentMap")) {
        _Hotkeys::ListeningForAddCurrentMapKey = true;
    }

    _Hotkeys::RenderHotkeyCombo("Add current map to selected playlists", S_AddCurrentMapModalKey);

    UI::SameLine();

    if (_Hotkeys::ListeningForAddCurrentMapModalKey) {
        UI::Text("Press a key");
    } else if (UI::GreyButton("Detect##AddCurrentMapModal")) {
        _Hotkeys::ListeningForAddCurrentMapModalKey = true;
    }

    UI::EndChild();
}

[SettingsTab name="Dev" order="5" icon="Code"]
void RenderDevSettings() {
    UI::BeginChild("DevSettings");

    if (UI::Button("Reset to default")) {
        S_LogLevel = LogLevel::Info;
        S_SkipLoad = false;
    }

    UI::SetNextItemWidth(175);
    if (UI::BeginCombo("Log level", tostring(S_LogLevel))) {
        for (int i = 0; i <= LogLevel::Trace; i++) {
            if (UI::Selectable(tostring(LogLevel(i)), S_LogLevel == LogLevel(i))) {
                S_LogLevel = LogLevel(i);
            }
        }
        UI::EndCombo();
    }

    UI::PushFontSize(21);
    UI::SeparatorText("Data");
    UI::PopFontSize();

    S_SkipLoad = UI::Checkbox("Skip loading data", S_SkipLoad);
    UI::SettingDescription("Skip loading seasonal campaigns, weekly shorts / grands, favorites, and TOTDs.");

    if (UI::OrangeButton(Icons::Refresh + " Reload Seasonal Campaigns")) {
        SEASONAL_CAMPAIGNS.RemoveRange(0, SEASONAL_CAMPAIGNS.Length);
        startnew(TM::GetSeasonalCampaigns);
    }

    if (UI::OrangeButton(Icons::Refresh + " Reload Weekly Grands")) {
        WEEKLY_GRANDS.RemoveRange(0, WEEKLY_GRANDS.Length);
        startnew(TM::GetWeeklyGrands);
    }

    if (UI::OrangeButton(Icons::Refresh + " Reload Weekly Shorts")) {
        WEEKLY_SHORTS.RemoveRange(0, WEEKLY_SHORTS.Length);
        startnew(TM::GetWeeklyShorts);
    }

    if (UI::OrangeButton(Icons::Refresh + " Reload Favorites")) {
        FAVORITES.RemoveRange(0, FAVORITES.Length);
        startnew(TM::GetFavorites);
    }

    if (UI::OrangeButton(Icons::Refresh + " Reload TOTDs")) {
        TOTD_MONTHS.RemoveRange(0, TOTD_MONTHS.Length);
        startnew(TM::GetTOTDMonths);
    }

    UI::PushFontSize(21);
    UI::SeparatorText("Cache");
    UI::PopFontSize();

    if (UI::RedButton(Icons::TrashO + " Clear map cache")) {
        Cache::ClearMapCache();
    }

    if (UI::RedButton(Icons::TrashO + " Clear session PBs")) {
        Cache::ClearSessionPBs();
    }

    UI::EndChild();
}
