class LeaderboardRecord {
    string m_accountId;
    string m_zoneId;
    string m_zoneName;
    int m_position;
    int m_score;
    uint m_timestamp;
    string m_displayName = "Unknown";
    uint m_respawns;
    uint m_time;
    string m_mapUid;

    LeaderboardRecord(Json::Value@ json, const string &in mapUid) {
        m_accountId = json["accountId"];
        m_zoneId    = json["zoneId"];
        m_zoneName  = json["zoneName"];
        m_position  = json["position"];
        m_score     = json["score"];
        m_timestamp = json["timestamp"];
        m_mapUid    = mapUid;

        if (m_score < TM::PLATFORM_OFFSET) {
            m_time = m_score;
        } else {
            // Platform records use a special formatting when they have respawns
            // Base number is 400,000,000, last 3 digits are the number of respawns
            // The rest is the race time, to the tenth. Credits to Zai for finding how it works
            m_respawns = m_score % 1000;
            m_time = int((m_score - m_respawns - TM::PLATFORM_OFFSET) / 10);
        }
    }

    LeaderboardRecord(CMapRecord@ record) {
        m_accountId   = record.AccountId;
        m_timestamp   = record.Timestamp;
        m_respawns    = record.RespawnCount;
        m_time        = record.Time;
        m_score       = TM::GetPlatformScore(m_respawns, m_time);
        m_displayName = NadeoServices::GetDisplayNameAsync(m_accountId);
        m_mapUid      = record.MapUid.GetName();

        startnew(CoroutineFunc(FetchPosition));
    }

    bool get_IsLocalPlayer() {
        return m_accountId == NadeoServices::GetAccountID();
    }

    void FetchPosition() {
        if (m_position > 0) {
            return;
        }

        m_position = TM::GetPosition(m_mapUid, m_score);
    }

    void Enable() {
#if DEPENDENCY_MLHOOK
        MLHook::Queue_SH_SendCustomEvent("TMGame_Record_ToggleGhost", { m_accountId });
#endif
    }

    bool opCmp(LeaderboardRecord@ other) {
        return other !is null && other.m_accountId == this.m_accountId && other.m_mapUid == this.m_mapUid;
    }
}
