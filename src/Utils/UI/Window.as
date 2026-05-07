namespace UI {
    bool g_focusMapList = false;

    void RenderMainWindow() {
        if (!g_showMainWindow) {
            return;
        }

        UI::PushStyleVar(UI::StyleVar::WindowPadding, vec2(10, 10));
        UI::PushStyleVar(UI::StyleVar::WindowRounding, 10.0);
        UI::PushStyleVar(UI::StyleVar::FramePadding, vec2(10, 6));
        UI::PushStyleVar(UI::StyleVar::WindowTitleAlign, vec2(.5, .5));
        UI::PushStyleColor(UI::Col::TabActive, vec4(0.45, 0.45, 0.45, 1.0));
        UI::PushStyleColor(UI::Col::TabHovered, vec4(0.35, 0.35, 0.35, 1));
        UI::PushStyleColor(UI::Col::Tab, vec4(0.25, 0.25, 0.25, 1));

        UI::SetNextWindowSize(600, 400, UI::Cond::FirstUseEver);

        UI::Begin(FULL_NAME, g_showMainWindow, UI::WindowFlags::NoCollapse | UI::WindowFlags::NoDocking);
        UI::BeginTabBar("WindowTabs", UI::TabBarFlags::FittingPolicyResizeDown);

        int mapTabFlags = UI::TabItemFlags::None;

        if (g_focusMapList) {
            mapTabFlags |= UI::TabItemFlags::SetSelected;
        }

        if (UI::BeginTabItem("Maps", mapTabFlags)) {
            UI::BeginChild("MapsChild");
            UI::RenderSources();

            UI::SameLine();

            vec2 dimensions = UI::MeasureButton(Icons::Random);
            UI::RightAlignButtons(dimensions.x * 2, 2);

            UI::BeginDisabled(playlist.IsEmpty());

            if (UI::Button(Icons::Random)) {
                playlist.Randomize();
            }

            UI::SetItemTooltip("Shuffle playlist");

            UI::SameLine();

            if (UI::RedButton(Icons::TrashO)) {
                playlist.Clear();
            }

            UI::SetItemTooltip("Clear playlist");

            UI::EndDisabled();

            UI::PushTableVars();
            if (UI::BeginTable("Maps", 14, UI::TableFlags::RowBg | UI::TableFlags::ScrollY | UI::TableFlags::BordersInnerV | UI::TableFlags::PadOuterX | UI::TableFlags::SizingStretchSame | UI::TableFlags::Hideable | UI::TableFlags::Sortable)) {
                UI::TableSetupScrollFreeze(0, 1);

                if (g_focusMapList) {
                    UI::SetScrollY(0);
                    g_focusMapList = false;
                }

                UI::TableSetupColumn("Nº", UI::TableColumnFlags::WidthFixed, 30);
                UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthStretch);
                UI::TableSetupColumn("Author", UI::TableColumnFlags::WidthFixed, playlist.columnWidths.Author);
                UI::TableSetupColumn("URL", UI::TableColumnFlags::WidthFixed, playlist.columnWidths.Url);
                UI::TableSetupColumn("UID", UI::TableColumnFlags::WidthFixed, playlist.columnWidths.Uid);
                UI::TableSetupColumn("Mode", UI::TableColumnFlags::WidthFixed, 60 * UI::GetScale());
                UI::TableSetupColumn("Vista", UI::TableColumnFlags::WidthFixed, playlist.columnWidths.Vistas);
                UI::TableSetupColumn("Tags", UI::TableColumnFlags::WidthFixed, playlist.columnWidths.Tags);
                UI::TableSetupColumn("Medals", UI::TableColumnFlags::WidthFixed, playlist.columnWidths.Medals);
                UI::TableSetupColumn("PB", UI::TableColumnFlags::WidthFixed, 110 * UI::GetScale());
                UI::TableSetupColumn("Delta", UI::TableColumnFlags::WidthFixed, 90 * UI::GetScale());
                UI::TableSetupColumn("S. PB", UI::TableColumnFlags::WidthFixed, 110 * UI::GetScale());
                UI::TableSetupColumn("S. Delta", UI::TableColumnFlags::WidthFixed, 90 * UI::GetScale());
                UI::TableSetupColumn("Buttons", UI::TableColumnFlags::WidthFixed | UI::TableColumnFlags::NoSort);
                UI::TableHeadersRow();

                UI::TableSetColumnEnabled(1, S_MapName);
                UI::TableSetColumnEnabled(2, S_MapAuthor);
                UI::TableSetColumnEnabled(3, S_MapUrl);
                UI::TableSetColumnEnabled(4, S_MapUid);
                UI::TableSetColumnEnabled(5, S_MapGamemode);
                UI::TableSetColumnEnabled(6, S_MapVista);
                UI::TableSetColumnEnabled(7, S_MapTags);
                UI::TableSetColumnEnabled(8, S_MapMedals);
                UI::TableSetColumnEnabled(9, S_MapPb);
                UI::TableSetColumnEnabled(10, S_MapDelta);
                UI::TableSetColumnEnabled(11, S_MapSessionPb);
                UI::TableSetColumnEnabled(12, S_MapSessionDelta);
                UI::TableSetColumnEnabled(13, S_MapButtons);

                auto specs = UI::TableGetSortSpecs();

                if (specs !is null && (specs.Dirty || playlist.Dirty)) {
                    Sort::SortMapPlaylist(specs);
                }

                UI::ListClipper clipper(playlist.Length);
                while (clipper.Step()) {
                    for (int i = clipper.DisplayStart; i < Math::Min(clipper.DisplayEnd, playlist.Length); i++) {
                        UI::PushID("PlaylistMap"+i);
                        Map@ map = playlist[i];
                        UI::RenderMapRow(map, i);
                        UI::PopID();
                    }
                }
                UI::EndTable();
            }

            UI::PopTableVars();

            UI::EndChild();

            UI::EndTabItem();
        }

        if (UI::BeginTabItem("Playlists")) {
            UI::BeginChild("PlaylistsChild");

            UI::BeginDisabled(playlist.IsEmpty());

            if (UI::GreenButton(Icons::Plus + " New")) {
                Renderables::Add(AddPlaylist());
            }

            UI::SetItemTooltip("Save current playlist");

            UI::EndDisabled();

            UI::PushTableVars();
            if (UI::BeginTable("Playlists", 6, UI::TableFlags::RowBg | UI::TableFlags::ScrollY | UI::TableFlags::BordersInnerV | UI::TableFlags::PadOuterX | UI::TableFlags::SizingStretchSame | UI::TableFlags::Hideable | UI::TableFlags::Sortable)) {
                UI::TableSetupScrollFreeze(0, 1);

                UI::TableSetupColumn("Nº", UI::TableColumnFlags::WidthFixed | UI::TableColumnFlags::NoSort, 30);
                UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthStretch);
                UI::TableSetupColumn("Map Count", UI::TableColumnFlags::WidthFixed, 80 * UI::GetScale());
                UI::TableSetupColumn("Tags", UI::TableColumnFlags::WidthFixed, savedPlaylists.columnWidths.Tags);
                UI::TableSetupColumn("Created at", UI::TableColumnFlags::WidthFixed);
                UI::TableSetupColumn("Buttons", UI::TableColumnFlags::WidthFixed | UI::TableColumnFlags::NoSort);
                UI::TableHeadersRow();

                UI::TableSetColumnEnabled(1, S_PlaylistName);
                UI::TableSetColumnEnabled(2, S_PlaylistMapCount);
                UI::TableSetColumnEnabled(3, S_PlaylistTags);
                UI::TableSetColumnEnabled(4, S_PlaylistDate);
                UI::TableSetColumnEnabled(5, S_PlaylistButtons);

                auto specs = UI::TableGetSortSpecs();

                if (specs !is null && (specs.Dirty || savedPlaylists.Dirty)) {
                    Sort::SortPlaylists(specs);
                }

                UI::ListClipper clipper(savedPlaylists.Length);
                while (clipper.Step()) {
                    for (int i = clipper.DisplayStart; i < Math::Min(clipper.DisplayEnd, savedPlaylists.Length); i++) {
                        UI::PushID("Playlist"+i);
                        MapPlaylist@ list = savedPlaylists[i];
                        UI::RenderPlaylistRow(list, i);
                        UI::PopID();
                    }
                }
                UI::EndTable();
            }
            UI::PopTableVars();

            UI::EndChild();

            UI::EndTabItem();
        }

        if (UI::BeginTabItem("Settings")) {
            UI::BeginChild("SettingsChild");
            UI::BeginTabBar("SettingsTabs", UI::TabBarFlags::FittingPolicyResizeDown);

            if (UI::BeginTabItem(Icons::Wrench + " General")) {
                RenderGeneralSettings();
                UI::EndTabItem();
            }

            if (UI::BeginTabItem(Icons::List + " Playlist")) {
                RenderPlaylistSettings();
                UI::EndTabItem();
            }

            if (UI::BeginTabItem(Icons::Eye + " Display")) {
                RenderDisplaySettings();
                UI::EndTabItem();
            }

            if (UI::BeginTabItem(Icons::KeyboardO + " Hotkeys")) {
                RenderHotkeySettings();
                UI::EndTabItem();
            }

            if (UI::BeginTabItem(Icons::Code + " Dev")) {
                RenderDevSettings();
                UI::EndTabItem();
            }

            UI::EndTabBar();

            UI::EndChild();

            UI::EndTabItem();
        }

        UI::EndTabBar();

        UI::End();

        UI::PopStyleColor(3);
        UI::PopStyleVar(4);
    }
}
