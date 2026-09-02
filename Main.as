const bool HAS_PERMISSIONS = Permissions::ViewRecords() && Permissions::PlayRecords();

string g_currentMapUid = "";
bool g_inPlatform = false;
bool g_resetPos = false;

array<LeaderboardRecord@> g_leaderboard;
LeaderboardRecord@ g_personalBest;

void Main() {
    if (!HAS_PERMISSIONS) {
        _Logging::Error("You don't have enough permissions to use this plugin!", true);

        Meta::Plugin@ self = Meta::ExecutingPlugin();
        Meta::UnloadPlugin(self);
        return;
    }

    NadeoServices::AddAudience("NadeoLiveServices");

    while (!S_ShowWindow) {
        yield();
    }

    string currentUid = "";
    auto app = cast<CTrackMania>(GetApp());

    while (true) {
        yield();

        if (app.RootMap is null || app.Editor !is null) {
            g_leaderboard.RemoveRange(0, g_leaderboard.Length);
            @g_personalBest = null;
            g_inPlatform = false;
            g_currentMapUid = "";
            g_resetPos = true;
        } else if (app.RootMap.IdName != g_currentMapUid) {
            g_currentMapUid = app.RootMap.IdName;

            if (app.RootMap.MapType.EndsWith("Platform")) {
                g_inPlatform = true;
                g_resetPos = true;
                UpdateLeaderboard();
            } else {
                g_inPlatform = false;
            }
        }

        sleep(250);
    }
}

void RenderMenu() {
    if (!HAS_PERMISSIONS) {
        return;
    }

    string keyName = S_WindowHotkey == VirtualKey::None ? "" : tostring(S_WindowHotkey);

    if (UI::MenuItem("\\$FC0" + Icons::Table + "\\$z " + Meta::ExecutingPlugin().Name, keyName, S_ShowWindow)) {
        S_ShowWindow = !S_ShowWindow;
    }
}

UI::InputBlocking OnKeyPress(bool down, VirtualKey key) {
    if (!HAS_PERMISSIONS) {
        return UI::InputBlocking::DoNothing;
    }

    if (UI::WantCaptureKeyboard()) {
        return UI::InputBlocking::DoNothing;
    }

    if (key == S_WindowHotkey) {
        S_ShowWindow = !S_ShowWindow;
        return UI::InputBlocking::Block;
    }

    return UI::InputBlocking::DoNothing;
}

void UpdateLeaderboard() {
    g_leaderboard.RemoveRange(0, g_leaderboard.Length);
    @g_personalBest = null;
    g_resetPos = true;

    if (g_currentMapUid == "") {
        return;
    }

    g_leaderboard = TM::GetMapRecords(g_currentMapUid, 0);

    for (uint i = 0; i < g_leaderboard.Length; i++) {
        if (g_leaderboard[i].IsLocalPlayer) {
            @g_personalBest = g_leaderboard[i];
            return;
        }
    }

    // if length is not multiple of 100, then there's no more records, otherwise check if game has any PB stored
    if (g_leaderboard.Length % 100 == 0 && TM::HasRecordOnMap(g_currentMapUid)) {
        @g_personalBest = TM::GetPlayerPB(g_currentMapUid);
    }
}

void Render() {
    if (!HAS_PERMISSIONS) {
        return;
    }

    if (!S_ShowWindow) {
        return;
    }

    if (S_HideWithGameUI && !UI::IsGameUIVisible()) {
        return;
    }

    if (S_HideWithOP && !UI::IsOverlayShown()) {
        return;
    }

    if (S_HideOutsidePlatform && !g_inPlatform) {
        return;
    }

    UI::PushStyleVar(UI::StyleVar::WindowTitleAlign, vec2(.5, .5));
    UI::PushStyleVar(UI::StyleVar::CellPadding, UI::GetStyleVarVec2(UI::StyleVar::CellPadding) + vec2(7, 1));

    UI::SetNextWindowSize(700, 600, UI::Cond::FirstUseEver);

    UI::Begin(Meta::ExecutingPlugin().Name, S_ShowWindow);

    if (g_currentMapUid == "") {
        UI::CenteredText("Not in a map");
    } else if (!g_inPlatform) {
        UI::CenteredText("Map is not Platform");
    } else if (g_leaderboard.IsEmpty()) {
        if (TM::IsLoadingRecords) {
            UI::CenteredText(Icons::AnimatedHourglass + " Loading records");
        } else {
            UI::CenteredText("No records found");
        }
    } else {
        UI::BeginDisabled(TM::IsLoadingRecords);

        if (UI::CenteredButton(Icons::Refresh + " Reload")) {
            startnew(UpdateLeaderboard);
        }

        UI::EndDisabled();

        float childHeight = g_personalBest is null ? 0 : 45 * UI::GetScale();

        UI::BeginChild("Table", UI::GetContentRegionAvail() - vec2(0, childHeight));

        float tableWidth = UI::GetContentRegionAvail().x;

        if (UI::BeginTable("MapLeaderboard", 6, UI::TableFlags::RowBg | UI::TableFlags::PadOuterX | UI::TableFlags::Hideable)) {
            if (g_resetPos) {
                UI::SetScrollY(0);
                g_resetPos = false;
            }

            UI::TableSetupColumn("Position", UI::TableColumnFlags::WidthFixed, 60 * UI::GetScale());
            UI::TableSetupColumn("Player", UI::TableColumnFlags::WidthStretch);
            UI::TableSetupColumn("Time", UI::TableColumnFlags::WidthFixed, 90 * UI::GetScale());
            UI::TableSetupColumn("Respawns", UI::TableColumnFlags::WidthFixed, 60 * UI::GetScale());
            UI::TableSetupColumn("Date", UI::TableColumnFlags::WidthFixed, 80 * UI::GetScale());
            UI::TableSetupColumn("##Buttons", UI::TableColumnFlags::WidthFixed);
            UI::TableHeadersRow();

#if !DEPENDENCY_MLHOOK
            UI::TableSetColumnEnabled(5, false);
#endif

            UI::ListClipper clipper(g_leaderboard.Length);

            while (clipper.Step()) {
                for (int i = clipper.DisplayStart; i < Math::Min(clipper.DisplayEnd, g_leaderboard.Length); i++) {
                    UI::PushID("Record" + i);
                    UI::RecordRow(g_leaderboard[i]);
                    UI::PopID();
                }
            }

            UI::EndTable();

            if (TM::IsLoadingRecords) {
                UI::CenteredText(Icons::AnimatedHourglass + " Loading");
            } else if (g_leaderboard.Length % 100 == 0 && UI::CenteredButton("Load More", 0.33f)) {
                // We get records in batches of 100, so if it's not a multiple, then there's no more records
                startnew(TM::LoadMoreRecords);
            }
        }

        UI::EndChild();

        if (g_personalBest !is null) {
            UI::Separator();

            if (UI::BeginTable("PersonalBest", 6, UI::TableFlags::RowBg | UI::TableFlags::PadOuterX | UI::TableFlags::Hideable, vec2(tableWidth, 0))) {
                UI::TableSetupColumn("Position", UI::TableColumnFlags::WidthFixed, 60 * UI::GetScale());
                UI::TableSetupColumn("Player", UI::TableColumnFlags::WidthStretch);
                UI::TableSetupColumn("Time", UI::TableColumnFlags::WidthFixed, 90 * UI::GetScale());
                UI::TableSetupColumn("Respawns", UI::TableColumnFlags::WidthFixed, 60 * UI::GetScale());
                UI::TableSetupColumn("Date", UI::TableColumnFlags::WidthFixed, 80 * UI::GetScale());
                UI::TableSetupColumn("##Buttons", UI::TableColumnFlags::WidthFixed);

#if !DEPENDENCY_MLHOOK
                UI::TableSetColumnEnabled(5, false);
#endif

                UI::PushID("PB");
                UI::RecordRow(g_personalBest);
                UI::PopID();

                UI::EndTable();
            }
        }
    }

    UI::End();

    UI::PopStyleVar(2);
}
