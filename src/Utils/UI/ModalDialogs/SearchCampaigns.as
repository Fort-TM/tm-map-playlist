class SearchCampaigns: ModalDialog {
    bool m_loading = false;
    bool m_resetScroll = false;
    string m_search;
    array<TM::ClubActivity@> m_results;

    SearchCampaigns() {
        super("Search campaigns##SearchCampaigns");
        this.m_size = vec2(800, 600);
        startnew(CoroutineFunc(this.GetCampaigns));
    }

    void GetCampaigns() {
        this.m_loading = true;
        this.m_results.RemoveRange(0, m_results.Length);

        this.m_results = TM::SearchClubCampaigns(this.m_search);

        this.m_loading = false;
        this.m_resetScroll = true;
    }

    void RenderDialog() override {
        this.m_search = UI::InputText("##searchCampaign", this.m_search);

        UI::SameLine();

        UI::BeginDisabled(this.m_loading);

        if (UI::Button(Icons::Search + " Search")) {
            startnew(CoroutineFunc(this.GetCampaigns));
        }

        UI::EndDisabled();
        
        if (this.m_loading) {
            UI::Text(Icons::AnimatedHourglass + " Loading...");
            return;
        }
        
        if (this.m_results.Length == 0) {
            UI::Text("No results.");
            return;
        }

        UI::PushTableVars();

        if (UI::BeginTable("CampaignList", 4, UI::TableFlags::RowBg | UI::TableFlags::ScrollY | UI::TableFlags::PadOuterX | UI::TableFlags::SizingStretchSame)) {
            UI::TableSetupScrollFreeze(0, 1);
            UI::TableSetupColumn("Campaign", UI::TableColumnFlags::WidthStretch);
            UI::TableSetupColumn("Club", UI::TableColumnFlags::WidthStretch);
            UI::TableSetupColumn("Count", UI::TableColumnFlags::WidthFixed, 40);
            UI::TableSetupColumn("", UI::TableColumnFlags::WidthFixed);

            UI::TableHeadersRow();

            // I'm seriously accepting better solutions for resetting the scrolling in the conditional rendering of a table
            if (this.m_resetScroll) {
                UI::SetScrollY(0);
                this.m_resetScroll = false;
            }

            UI::ListClipper clipper(this.m_results.Length);

            while (clipper.Step()) {
                for (int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++) {
                    UI::TableNextRow();
                    TM::ClubActivity@ result = this.m_results[i];

                    UI::TableNextColumn();

                    UI::AlignTextToFramePadding();
                    UI::Text(result.Name);

                    if (result.ThumbnailUrl == "") {
                        UI::SetItemTooltip("\\$f00" + Icons::Times + "\\$z No thumbnail available.");
                    } else {
                        UI::ThumbnailTooltip(result.ThumbnailUrl);
                    }

                    UI::TableNextColumn();
                    UI::Text(result.ClubName);

                    UI::TableNextColumn();
                    UI::Text(tostring(result.MapCount));

                    UI::TableNextColumn();

                    if (UI::Button("Select##Campaign" + i)) {
                        this.Close();
                        Renderables::Add(SelectMaps(result.ActivityCampaign));
                    }

                    UI::SameLine();

                    if (UI::Button("Add##Campaign" + i)) {
                        this.Close();
                        startnew(CoroutineFuncUserdata(playlist.AddCampaign), result.ActivityCampaign);
                    }
                }
            }

            UI::EndTable();
        }

        UI::PopTableVars();
    }
}
