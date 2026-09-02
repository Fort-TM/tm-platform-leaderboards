namespace TM {
    const uint PLATFORM_OFFSET = 400000000;
    bool g_loadingRecords = false;

    bool get_IsLoadingRecords() {
        return g_loadingRecords;
    }

    array<LeaderboardRecord@> GetMapRecords(const string &in mapUid, int offset = 0) {
        while (!NadeoServices::IsAuthenticated("NadeoLiveServices")) {
            yield();
        }

        _Logging::Trace("[GetMapRecords] Getting map records for " + mapUid + ". Offset: " + offset);

        string url = NadeoServices::BaseURLLive() + "/api/token/leaderboard/group/Personal_Best/map/" + mapUid + "/top?length=100&onlyWorld=true&offset=" + offset;
        _Logging::Trace("[GetMapRecords] URL: " + url);

        g_loadingRecords = true;

        Net::HttpRequest@ req = NadeoServices::Get("NadeoLiveServices", url);

        await(req.Start());

        _Logging::Trace("[GetMapRecords] Response: " + req.String());
        auto res = req.Json();

        if (res.GetType() != Json::Type::Object) {
            _Logging::Error("[GetMapRecords] Error when getting map records: API didn't return an object!", true);
            g_loadingRecords = false;
            return {};
        }

        array<LeaderboardRecord@> leaderboard;
        array<string> accountIds;

        try {
            Json::Value@ records = res["tops"][0]["top"];

            for (uint i = 0; i < records.Length; i++) {
                auto record = LeaderboardRecord(records[i], mapUid);
                accountIds.InsertLast(record.m_accountId);
                leaderboard.InsertLast(record);
            }

            dictionary displayNames = NadeoServices::GetDisplayNamesAsync(accountIds);

            for (uint i = 0; i < leaderboard.Length; i++) {
                string name;

                if (displayNames.Get(leaderboard[i].m_accountId, name)) {
                    leaderboard[i].m_displayName = name;
                }
            }

            _Logging::Trace("[GetMapRecords] Found " + leaderboard.Length + " records for map UID " + mapUid);
            g_loadingRecords = false;
            return leaderboard;
        } catch {
            _Logging::Error("[GetMapRecords] Failed to get map records: " + getExceptionInfo(), true);
            g_loadingRecords = false;
            return {};
        }
    }

    void LoadMoreRecords() {
        g_loadingRecords = true;

        auto app = cast<CTrackMania>(GetApp());
        array<LeaderboardRecord@> records = GetMapRecords(app.RootMap.IdName, g_leaderboard.Length);

        for (uint i = 0; i < records.Length; i++) {
            g_leaderboard.InsertLast(records[i]);
        }

        g_loadingRecords = false;
    }

    LeaderboardRecord@ GetPlayerPB(const string &in mapUid) {
        auto app = cast<CGameManiaPlanet>(GetApp());
        auto mccma = app.MenuManager.MenuCustom_CurrentManiaApp;
        auto userId = mccma.UserMgr.Users[0].Id;

        MwFastBuffer<wstring> bufferIds = MwFastBuffer<wstring>();
        bufferIds.Add(mccma.LocalUser.WebServicesUserId);

        _Logging::Trace("[GetPlayerPB] Searching player PB for UID " + mapUid);

        auto res = mccma.ScoreMgr.Map_GetPlayerListRecordList(userId, bufferIds, mapUid, "PersonalBest", "", "Platform", "");

        while (res.IsProcessing) {
            yield();
        }

        try {
            if (!res.HasSucceeded || res.HasFailed) {
                _Logging::Error("[GetPlayerPB] Failed to get PB from UID: Error " + res.ErrorCode + " - " + res.ErrorDescription);
                mccma.ScoreMgr.TaskResult_Release(res.Id);
                return null;
            }

            if (res.MapRecordList.Length == 0) {
                _Logging::Trace("[GetPlayerPB] Failed to find a PB for UID " + mapUid);
                mccma.ScoreMgr.TaskResult_Release(res.Id);
                return null;
            }

            LeaderboardRecord@ record = LeaderboardRecord(res.MapRecordList[0]);
            mccma.ScoreMgr.TaskResult_Release(res.Id);

            return record;
        } catch {
            _Logging::Error("[GetPlayerPB] Failed to get player PB: " + getExceptionInfo(), true);
            return null;
        }
    }

    int GetPosition(const string &in mapUid, uint score) {
        while (!NadeoServices::IsAuthenticated("NadeoLiveServices")) {
            yield();
        }

        string url = NadeoServices::BaseURLLive() + "/api/token/leaderboard/group/Personal_Best/map/" + mapUid + "/surround/0/0?score=" + score + "&onlyWorld=true";

        _Logging::Trace("[GetPosition] Fetching position for score " + score + " for UID " + mapUid);
        _Logging::Trace("[GetPosition] URL: " + url);
        Net::HttpRequest@ req = NadeoServices::Get("NadeoLiveServices", url);

        await(req.Start());

        _Logging::Trace("[GetPosition] Response: " + req.String());
        auto res = req.Json();

        if (res.GetType() != Json::Type::Object) {
            _Logging::Error("[GetPosition] Error when getting score position: API didn't return an object!", true);
            return -1;
        }

        try {
            Json::Value@ record = res["tops"][0]["top"][0];
            return record["position"];
        } catch {
            _Logging::Error("[GetPosition] Failed to get score position: " + getExceptionInfo(), true);
            return -1;
        }
    }

    bool HasRecordOnMap(const string &in mapUid) {
        auto app = cast<CTrackMania>(GetApp());

        if (app.RootMap is null || app.Network is null || app.Network.ClientManiaAppPlayground is null) {
            return false;
        }

        if (app.RootMap.MapType != "TrackMania\\TM_Platform") {
            return false;
        }

        auto userId = app.UserManagerScript.Users[0].Id;

        auto scoreMgr = app.Network.ClientManiaAppPlayground.ScoreMgr;
        uint score = scoreMgr.Map_GetRecord_v2(userId, mapUid, "PersonalBest", "", "Platform", "");

        return score >= 0;
    }

    // Converts a platform run to the format used by the leaderboard. Needed for the surround endpoint
    int GetPlatformScore(uint respawns, uint time) {
        if (respawns == 0) {
            return time;
        }

        return PLATFORM_OFFSET + (time / 100) * 1000 + respawns;
    }
}
