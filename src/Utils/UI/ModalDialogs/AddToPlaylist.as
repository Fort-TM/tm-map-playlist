class AddToPlaylist: ModalDialog {
    CGameCtnChallenge@ m_currentMap;

    array<bool> m_checkedPlaylists;
    array<bool> m_alreadyPresentPlaylists;

    AddToPlaylist() {
        super("Add to Playlist##AddToPlaylist");
        m_size = vec2(700, 500);
        startnew(CoroutineFunc(this.GetCurrentMap));
    }

    void GetCurrentMap() {
        if (savedPlaylists.IsEmpty()) {
            Close();
            return;
        }

        CGameCtnChallenge@ map = CurrentMap::GetMap();

        if (map is null || map.MapInfo is null) {
            Close();
            return;
        }

        @m_currentMap = map;

        m_checkedPlaylists = array<bool>(savedPlaylists.Length);
        m_alreadyPresentPlaylists = array<bool>(savedPlaylists.Length);

        for (uint i = 0; i < savedPlaylists.Length; i++) {
            foreach (auto listMap : savedPlaylists[i].Maps) {
                if (listMap.Uid == m_currentMap.IdName) {
                    m_alreadyPresentPlaylists[i] = true;
                    break;
                }
            }
        }
    }

    void RenderDialog() override {
        if (m_currentMap is null || m_currentMap.MapInfo is null) {
            return;
        }

        UI::AlignTextToFramePadding();

        string mapName = Text::OpenplanetFormatCodes(CleanGbxText(m_currentMap.MapName));
        UI::Text(mapName + "\\$z will be added to the selected playlists.");

        vec2 region = UI::GetContentRegionAvail();

        if (UI::BeginChild("PlaylistsChild", vec2(0, region.y - (40 * UI::GetScale())))) {
            UI::PushTableVars();

            if (UI::BeginTable("PlaylistsTable", 3, UI::TableFlags::ScrollY | UI::TableFlags::BordersInnerH | UI::TableFlags::BordersInnerV | UI::TableFlags::PadOuterX)) {
                UI::TableSetupScrollFreeze(0, 1);
                UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthStretch);
                UI::TableSetupColumn("Tags", UI::TableColumnFlags::WidthStretch);
                UI::TableSetupColumn("Map Count", UI::TableColumnFlags::WidthFixed, 80 * UI::GetScale());

                UI::TableHeadersRow();

                for (uint i = 0; i < savedPlaylists.Length; i++) {
                    const MapPlaylist@ list = savedPlaylists[i];

                    UI::TableNextRow();
                    UI::TableNextColumn();

                    UI::BeginDisabled(m_alreadyPresentPlaylists[i]);

                    m_checkedPlaylists[i] = UI::Checkbox(list.Name, m_checkedPlaylists[i]);

                    if (m_alreadyPresentPlaylists[i]) {
                        UI::SameLine();
                        UI::Text(Icons::ExclamationCircle);
                        UI::SetItemTooltip("Current map is already in this playlist!");
                    }

                    UI::TableNextColumn();

                    foreach (TMX::Tag@ tag : list.Tags) {
                        tag.Render();
                        UI::SameLine();
                    }

                    UI::TableNextColumn();

                    UI::Text(tostring(list.Maps.Length));

                    UI::EndDisabled();
                }
            }

            UI::EndTable();

            UI::PopTableVars();
        }
    
        UI::EndChild();

        uint checkedPlaylistCount = 0;
        foreach (bool checked : m_checkedPlaylists) {
            if (checked) {
                checkedPlaylistCount++;
            }
        }

        string playlistText = "Add to " + tostring(checkedPlaylistCount) + " " + Pluralize("playlist", checkedPlaylistCount);
        float addButtonWidth = UI::MeasureButton(playlistText).x;

        UI::RightAlignButton(addButtonWidth);

        UI::BeginDisabled(checkedPlaylistCount == 0);

        if (UI::GreenButton(playlistText)) {
            startnew(CoroutineFunc(this.AddToSelectedPlaylists));
            Close();
        }

        UI::EndDisabled();
    }

    void AddToSelectedPlaylists() {
        array<MapPlaylist@> selectedPlaylists;

        for (uint i = 0; i < m_checkedPlaylists.Length; i++) {
            if (m_checkedPlaylists[i]) {
                selectedPlaylists.InsertLast(savedPlaylists[i]);
            }
        }

        CurrentMap::AddToPlaylists(selectedPlaylists);
    }
}
