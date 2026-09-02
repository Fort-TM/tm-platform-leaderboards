enum LogLevel {
    Error,
    Warn,
    Info,
    Debug,
    Trace
}

namespace _Logging {
    const vec4 ERROR_COLOR = UI::HSV(1.0, 1.0, 1.0);
    const vec4 WARN_COLOR  = UI::HSV(0.11, 1.0, 1.0);

    void Error(const string &in text, bool notification = false) {
        if (S_LogLevel >= LogLevel::Error) {
            error("[ERROR] " + text);

            if (notification) {
                UI::ShowNotification(Meta::ExecutingPlugin().Name + " - Error", text, ERROR_COLOR, 6000);
            }
        }
    }

    void Warn(const string &in text, bool notification = false) {
        if (S_LogLevel >= LogLevel::Warn) {
            warn("[WARN] " + text);

            if (notification) {
                UI::ShowNotification(Meta::ExecutingPlugin().Name + " - Warning", text, WARN_COLOR, 6000);
            }
        }
    }

    void Info(const string &in text) {
        if (S_LogLevel >= LogLevel::Info) {
            print("[INFO] " + text);
        }
    }

    void Debug(const string &in text) {
        if (S_LogLevel >= LogLevel::Debug) {
            trace("[DEBUG] " + text);
        }
    }

    void Trace(const string &in text) {
        if (S_LogLevel >= LogLevel::Trace) {
            trace("[TRACE] " + text);
        }
    }
}
