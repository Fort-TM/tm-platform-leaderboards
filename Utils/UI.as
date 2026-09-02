namespace UI {
    vec2 MeasureButton(const string &in label) {
        vec2 text = UI::MeasureString(label);
        vec2 padding = UI::GetStyleVarVec2(UI::StyleVar::FramePadding);

        return text + padding * 2;
    }

    void CenterAlign() {
        vec2 region = UI::GetWindowSize();
        UI::SetCursorPosX(region.x / 2);
    }

    void CenterAlign(float elementWidth) {
        UI::SetCursorPosX((UI::GetWindowSize().x - elementWidth) * 0.5);
    }

    bool CenteredButton(const string &in text) {
        vec2 button = MeasureButton(text);
        UI::CenterAlign(button.x);

        return UI::Button(text);
    }

    bool CenteredButton(const string &in text, float color) {
        vec2 button = MeasureButton(text);
        UI::CenterAlign(button.x);

        return UI::ButtonColored(text, color);
    }

    void CenteredText(const string &in text, bool disabled = false) {
        UI::AlignTextToFramePadding();
        float textWidth = UI::MeasureString(text).x;
        UI::CenterAlign(textWidth);

        if (disabled) UI::TextDisabled(text);
        else UI::Text(text);
    }

    string OrdinalNumber(int number) {
        if (number <= 0) {
            return "-";
        }

        int j = number % 10;
        int k = number % 100;

        if (j == 1 && k != 11) {
            return tostring(number) + "st";
        }

        if (j == 2 && k != 12) {
            return tostring(number) + "nd";
        }

        if (j == 3 && k != 13) {
            return tostring(number) + "rd";
        }

        return tostring(number) + "th";
    }

    void RecordRow(LeaderboardRecord@ record) {
        UI::TableNextRow();
        UI::TableNextColumn();

        UI::AlignTextToFramePadding();
        UI::Text(OrdinalNumber(record.m_position));

        UI::TableNextColumn();
        UI::Text(record.m_displayName);

        UI::TableNextColumn();
        UI::Text(Time::Format(record.m_time));

        UI::TableNextColumn();
        UI::Text(tostring(record.m_respawns));

        UI::TableNextColumn();

        UI::Text(Time::FormatString("%d %b %Y", record.m_timestamp));

        if (UI::TableNextColumn()) {
            if (UI::Button(Icons::Eye)) {
                record.Enable();
            }
            UI::SetItemTooltip("Toggle");
        }
    }
}
