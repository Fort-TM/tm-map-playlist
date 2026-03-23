namespace UI {
    Source g_source = Source::TMX_Map_ID;
    string g_field = "";
    TM::Campaign@ g_campaign;
    int g_clubId;
    int g_campaignId;
    string g_dropdownSearch;

    void RenderSources() {
        UI::SetNextItemWidth(180);
        if (UI::BeginCombo("##AddSource", tostring(g_source).Replace("_", " "))) {
            for (uint i = 0; i < Source::Last; i++) {
                UI::PushID("SourceBtn" + i);

                if (UI::Selectable(tostring(Source(i)).Replace("_", " "), g_source == Source(i))) {
                    g_source = Source(i);
                    g_field = "";
                    g_clubId = 0;
                    g_campaignId = 0;
                    @g_campaign = null;
                }

                UI::PopID();
            }

            UI::EndCombo();
        }

        UI::SameLine();

        switch (g_source) {
            case Source::Weekly_Shorts:
            case Source::Weekly_Grands:
            case Source::Seasonal_Campaign:
            case Source::TOTD_Month:
                RenderDropdown();
                break;
            case Source::Club_Campaign:
                RenderClubCampaignFields();
                break;
            case Source::Favorites:
                RenderFavoritesButtons();
                break;
            case Source::Current_Map:
                RenderCurrentMapButtons();
                break;
            default:
                RenderField();
                break;
        }
    }

    void RenderField() {
        bool pressedEnter = false;

        int inputFlags = UI::InputTextFlags::EnterReturnsTrue;
        UI::InputTextCallback@ callback;

        if (g_source == Source::TMX_Map_ID || g_source == Source::TMX_Mappack_ID) {
            inputFlags |= UI::InputTextFlags::CharsDecimal | UI::InputTextFlags::CallbackCharFilter | UI::InputTextFlags::CallbackAlways;
            @callback = UI::IdCallback;
        }

        UI::SetNextItemWidth(225);
        g_field = UI::InputText("##SourceInput", g_field, pressedEnter, inputFlags, callback);

        UI::SameLine();

        UI::BeginDisabled(g_field.Length == 0);

        if (g_source == Source::TMX_Mappack_ID && UI::Button("Select...##SelectMappackButton")) {
            startnew(CoroutineFuncUserdataInt64(playlist.SelectMappackAsync), Text::ParseInt(g_field));
            g_field = "";
        } else if (g_source == Source::Folder && UI::Button("Select...##SelectFolderButton")) {
            startnew(CoroutineFuncUserdataString(playlist.SelectFolderAsync), CleanPath(g_field));
            g_field = "";
        }

        UI::SameLine();

        if ((UI::GreenButton("Add##AddButton") || pressedEnter) && g_field.Length > 0) {
            playlist.Add(g_source, g_field);
            g_field = "";
        }

        UI::EndDisabled();
    }

    void RenderDropdown() {
        array<TM::Campaign@> campaigns = {};

        switch (g_source) {
            case Source::Weekly_Shorts:
                for (uint i = 0; i < WEEKLY_SHORTS.Length; i++) {
                    campaigns.InsertLast(WEEKLY_SHORTS[i]);
                }
                break;
            case Source::Weekly_Grands:
                for (uint i = 0; i < WEEKLY_GRANDS.Length; i++) {
                    campaigns.InsertLast(WEEKLY_GRANDS[i]);
                }
                break;
            case Source::Seasonal_Campaign:
                for (uint i = 0; i < SEASONAL_CAMPAIGNS.Length; i++) {
                    campaigns.InsertLast(SEASONAL_CAMPAIGNS[i]);
                }
                break;
            case Source::TOTD_Month:
                for (uint i = 0; i < TOTD_MONTHS.Length; i++) {
                    campaigns.InsertLast(TOTD_MONTHS[i]);
                }
                break;
            default:
                break;
        }

        UI::BeginDisabled(campaigns.IsEmpty());

        UI::SetNextItemWidth(150);
        if (UI::BeginCombo("##Campaigns", g_campaign is null ? "None" : g_campaign.Name)) {
            if (UI::IsWindowAppearing()) {
                g_dropdownSearch = "";
            }

            UI::SetNextItemWidth(120);
            g_dropdownSearch = UI::InputText("##CampaignSearch", g_dropdownSearch);

            UI::Separator();

            if (UI::Selectable("None", g_campaign is null)) {
                @g_campaign = null;
            }

            for (uint i = 0; i < campaigns.Length; i++) {
                TM::Campaign@ campaign = campaigns[i];

                if (!campaign.Name.ToLower().Contains(g_dropdownSearch.ToLower())) {
                    continue;
                }

                UI::PushID("CampaignsBtn" + i);

                if (UI::Selectable(campaign.Name, g_campaign !is null && g_campaign.Name == campaign.Name)) {
                    @g_campaign = campaign;
                }

                UI::PopID();
            }

            UI::EndCombo();
        }

        UI::EndDisabled();

        if (campaigns.IsEmpty()) UI::SetItemTooltip("Couldn't find any " + tostring(g_source).Replace("_", " ") + "\n\nTry reloading them in the Dev settings.");

        UI::SameLine();

        UI::BeginDisabled(g_campaign is null);

        if (UI::Button("Select...") && g_campaign !is null) {
            Renderables::Add(SelectMaps(g_campaign));
        }

        UI::SameLine();

        if (UI::GreenButton("Add##CampaignButton") && g_campaign !is null) {
            startnew(CoroutineFuncUserdata(playlist.AddCampaign), g_campaign);
            @g_campaign = null;
        }

        UI::EndDisabled();
    }

    void RenderClubCampaignFields() {
        UI::SetNextItemWidth(70);
        g_clubId = UI::InputInt("##ClubId", g_clubId, 0);
        UI::SetItemTooltip("Club ID");

        UI::SameLine();

        UI::SetNextItemWidth(70);
        g_campaignId = UI::InputInt("##CampaignId", g_campaignId, 0);
        UI::SetItemTooltip("Campaign ID");

        UI::SameLine();

        UI::BeginDisabled(g_clubId <= 0 || g_campaignId <= 0);

        array<int> ids = { g_clubId, g_campaignId };

        if (UI::Button("Select...##SelectMapsButton")) {
            startnew(CoroutineFuncUserdata(playlist.SelectCampaignMapsAsync), ids);
        }

        UI::SameLine();

        if (UI::GreenButton("Add##ClubCampaignButton")) {
            startnew(CoroutineFuncUserdata(playlist.AddCampaignAsync), ids);
            g_clubId = 0;
            g_campaignId = 0;
        }

        UI::EndDisabled();

        UI::SameLine();

        UI::Separator(UI::SeparatorFlags::Vertical);

        UI::SameLine();

        if (UI::Button(Icons::Search + " Search")) {
            Renderables::Add(SearchCampaigns());
        }
    }

    void RenderFavoritesButtons() {
        UI::BeginDisabled(FAVORITES.IsEmpty());

        if (UI::Button("Select...##SelectFavorites")) {
            playlist.AddFavorites(true);
        }

        if (FAVORITES.IsEmpty()) UI::SetItemTooltip("You don't have any maps in your favorites\n\nIf you have added a map, reload them in the Dev settings.");

        UI::SameLine();

        if (UI::GreenButton("Add##AddFavorites")) {
            playlist.AddFavorites();
        }

        if (FAVORITES.IsEmpty()) UI::SetItemTooltip("You don't have any maps in your favorites\n\nIf you have added a map, reload them in the Dev settings.");

        UI::EndDisabled();
    }

    void RenderCurrentMapButtons() {
        UI::BeginDisabled(!CurrentMap::CanBeAdded);

        UI::BeginDisabled(savedPlaylists.IsEmpty());

        if (UI::Button("Select playlists...##SelectPlaylists")) {
            Renderables::Add(AddToPlaylist());
        }

        UI::EndDisabled();

        if (savedPlaylists.IsEmpty()) {
            UI::SetItemTooltip("You don't have any saved playlists!");
        }

        UI::SameLine();

        if (UI::GreenButton("Add##AddCurrentMap")) {
            startnew(CurrentMap::AddToCurrentPlaylist);
        }

        UI::EndDisabled();
    }
}
