namespace UI {
    string g_tagSearch;

    void RenderMapRow(Map@ map, uint position) {
        UI::TableNextRow();
        UI::TableNextColumn();

        if (TM::InCurrentMap() && playlist.currentMap == map) {
            // highlight current map
            UI::TableSetBgColor(UI::TableBgTarget::RowBg0, vec4(0.2, 0.55, 0.15, 0.2));
        }

        UI::AlignTextToFramePadding();
        UI::Text(tostring(map.Index));

        if (UI::TableNextColumn()) {
            UI::Text(S_ColoredNames ? map.GbxName : map.Name);

            if (S_MapThumbnail) {
                if (map.ThumbnailUrl == "") {
                    UI::SetItemTooltip("\\$f00" + Icons::Times + "\\$z No thumbnail available.");
                } else {
                    UI::ThumbnailTooltip(map.ThumbnailUrl);
                }
            }
        }

        if (UI::TableNextColumn()) {
            UI::Text(map.Author);
        }

        if (UI::TableNextColumn()) {
            UI::Text(map.Url);

            UI::SetItemTooltip("Click to copy to clipboard");
            if (UI::IsItemClicked()) {
                IO::SetClipboard(map.Url);
                UI::ShowNotification(PLUGIN_NAME, Icons::Clipboard + " URL copied to clipboard");
            }
        }

        if (UI::TableNextColumn()) {
            UI::Text(map.Uid);

            UI::SetItemTooltip("Click to copy to clipboard");
            if (UI::IsItemClicked()) {
                IO::SetClipboard(map.Uid);
                UI::ShowNotification(PLUGIN_NAME, Icons::Clipboard + " Uid copied to clipboard");
            }
        }

        if (UI::TableNextColumn()) {
            if (map.Uid == "") {
                UI::Text("-");
            } else {
                UI::Text(tostring(map.GameMode));
            }
        }

        if (UI::TableNextColumn()) {
            UI::Text(map.VistaName);
        }

        if (UI::TableNextColumn()) {
            foreach (TMX::Tag@ tag : map.Tags) {
                tag.Render();
                UI::SameLine();
            }

            // Hovering tags cell
            if (UI::TableGetHoveredRow() == UI::TableGetRowIndex() && UI::TableGetHoveredColumn() == UI::TableGetColumnIndex()) {
                UI::Text(Icons::Plus);

                if (UI::IsItemHovered()) {
                    UI::SetMouseCursor(UI::MouseCursor::Hand);
                }
                
                if (UI::IsItemClicked()) {
                    UI::OpenPopup("TagsPopup" + map.Index);
                }
            }

            UI::SetNextWindowSize(200, 400, UI::Cond::Always);
            if (UI::BeginPopup("TagsPopup" + map.Index)) {
                if (UI::IsWindowAppearing()) {
                    g_tagSearch = "";
                }

                UI::SetNextItemWidth(160);
                g_tagSearch = UI::InputText("##MapTagSearch", g_tagSearch);

                UI::Separator();

                foreach (TMX::Tag@ tag : TMX::AllTags) {
                    if (!tag.Name.ToLower().Contains(g_tagSearch.ToLower())) {
                        continue;
                    }

                    bool HasTag = map.HasTag(tag);

                    if (UI::Checkbox("##" + tag.Name, HasTag)) {
                        if (!HasTag) {
                            map.AddTag(tag);
                            playlist.OnUpdatedMaps();
                        }
                    } else if (HasTag) {
                        map.RemoveTag(tag);
                        playlist.OnUpdatedMaps();
                    }

                    UI::SameLine();
                    tag.Render();
                }

                UI::EndPopup();
            }
        }

        if (UI::TableNextColumn()) {
            Medals iconMedal = S_MainMedal;
            int mainScore = map.GetMedalScore(S_MainMedal);

#if DEPENDENCY_WARRIORMEDALS
            if (S_MainMedal == Medals::Warrior && !map.HasWarrior) {
                iconMedal = Medals::Author;
            }
#endif

            UI::Text(UI::FormatMedal(mainScore, map.GameMode, iconMedal));
            UI::MedalsToolTip(map);
        }

        if (UI::TableNextColumn()) {
            string icon = UI::GetTimeIcon(map, map.Pb);
            string time = UI::FormatTime(map.Pb, map.GameMode);
            UI::Text(icon + time);
        }

        if (UI::TableNextColumn()) {
            if (map.HasPb && !map.IsPbSecret) {
                int medalScore = map.GetMedalScore(S_MainMedal);
                UI::Text(UI::FormatDelta(medalScore, map.Pb, map.GameMode));
            }
        }

        if (UI::TableNextColumn()) {
            string sessionIcon = UI::GetTimeIcon(map, map.SessionPb);
            string sessionTime = UI::FormatTime(map.SessionPb, map.GameMode);
            UI::Text(sessionIcon + sessionTime);
        }

        if (UI::TableNextColumn()) {
            if (map.HasSessionPb) {
                int medalScore = map.GetMedalScore(S_MainMedal);
                UI::Text(UI::FormatDelta(medalScore, map.SessionPb, map.GameMode));
            }
        }

        if (UI::TableNextColumn()) {
            UI::BeginDisabled(TM::IsLoadingMap());

            if (UI::GreenButton(Icons::Play)) {
                playlist.PlayMap(map);
            }

            UI::EndDisabled();

            UI::SameLine();

            UI::BeginDisabled(position == 0);

            if (UI::Button(Icons::ArrowUp)) {
                playlist.ShiftMap(map);
            }

            UI::EndDisabled();

            UI::SetItemTooltip("Move up");

            UI::SameLine();

            UI::BeginDisabled(position == playlist.Length - 1);

            if (UI::Button(Icons::ArrowDown)) {
                playlist.ShiftMap(map, true);
            }

            UI::EndDisabled();

            UI::SetItemTooltip("Move down");

            UI::SameLine();

            if (UI::RedButton(Icons::TrashO)) {
                playlist.DeleteMap(map);
            }

            UI::SetItemTooltip("Remove map");
        }
    }

    void RenderPlaylistRow(MapPlaylist@ list, int position) {
        UI::TableNextRow();
        UI::TableNextColumn();

        UI::AlignTextToFramePadding();
        UI::Text(tostring(position + 1));

        if (UI::TableNextColumn()) {
            UI::Text(list.Name);
        }

        if (UI::TableNextColumn()) {
            UI::Text(tostring(list.Length));
        }

        if (UI::TableNextColumn()) {
            foreach (TMX::Tag@ tag : list.Tags) {
                tag.Render();
                UI::SameLine();
            }

            // Hovering tags cell
            if (UI::TableGetHoveredRow() == UI::TableGetRowIndex() && UI::TableGetHoveredColumn() == UI::TableGetColumnIndex()) {
                UI::Text(Icons::Plus);

                if (UI::IsItemHovered()) {
                    UI::SetMouseCursor(UI::MouseCursor::Hand);
                }

                if (UI::IsItemClicked()) {
                    UI::OpenPopup("PlaylistTagsPopup" + position);
                }
            }

            UI::SetNextWindowSize(200, 400, UI::Cond::Always);
            if (UI::BeginPopup("PlaylistTagsPopup" + position)) {
                if (UI::IsWindowAppearing()) {
                    g_tagSearch = "";
                }

                UI::SetNextItemWidth(160);
                g_tagSearch = UI::InputText("##PlaylistTagSearch", g_tagSearch);

                UI::Separator();

                foreach (TMX::Tag@ tag : TMX::AllTags) {
                    if (!tag.Name.ToLower().Contains(g_tagSearch.ToLower())) {
                        continue;
                    }

                    bool HasTag = list.HasTag(tag);

                    if (UI::Checkbox("##" + tag.Name, HasTag)) {
                        if (!HasTag) {
                            list.AddTag(tag);
                            savedPlaylists.OnUpdatedPlaylists();
                        }
                    } else if (HasTag) {
                        list.RemoveTag(tag);
                        savedPlaylists.OnUpdatedPlaylists();
                    }

                    UI::SameLine();
                    tag.Render();
                }

                UI::EndPopup();
            }
        }

        if (UI::TableNextColumn()) {
            UI::Text(Time::FormatString("%F %T", list.CreatedAt));
        }

        if (UI::TableNextColumn()) {
            UI::BeginDisabled(playlist.IsEmpty());

            if (UI::Button(Icons::FloppyO)) {
                Saves::EditPlaylist(list.Name, playlist);
            }
            UI::SetItemTooltip("Save current playlist as \""+ list.Name +"\".");

            UI::EndDisabled();

            UI::SameLine();

            if (UI::Button(Icons::Upload)) {
                playlist = list;
                g_focusMapList = true;
                playlist.GetPlaylistPbs();
                UI::ShowNotification(PLUGIN_NAME, "Loaded playlist \"" + list.Name + "\"!");
            }
            UI::SetItemTooltip("Load");

            UI::SameLine();

            if (UI::Button(Icons::Pencil)) {
                Renderables::Add(EditPlaylist(list));
            }
            UI::SetItemTooltip("Edit");

            UI::SameLine();

            if (UI::RedButton(Icons::TrashO)) {
                Renderables::Add(DeletePlaylist(list));
            }
            UI::SetItemTooltip("Delete");
        }
    }

    void PushTableVars() {
        UI::PushStyleColor(UI::Col::TableRowBgAlt, vec4(0.1f, 0.1f, 0.1f, .7));
        UI::PushStyleColor(UI::Col::TableRowBg, vec4(0.13f, 0.13f, 0.13f, .7));
        UI::PushStyleColor(UI::Col::TableBorderLight, vec4(.25, .25, .25, 1));
        UI::PushStyleColor(UI::Col::HeaderHovered, vec4(0.3f, 0.3f, 0.3f, 0.8f));
        UI::PushStyleVar(UI::StyleVar::CellPadding, UI::GetStyleVarVec2(UI::StyleVar::CellPadding) + vec2(6, 1));
    }

    void PopTableVars() {
        UI::PopStyleVar();
        UI::PopStyleColor(4);
    }
}
