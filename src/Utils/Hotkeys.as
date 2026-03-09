namespace _Hotkeys {
    enum HotkeySetting {
        None,
        Switch,
        MainWindow,
        Timer,
        AddCurrentMap,
        AddCurrentMapModal,
    }

    HotkeySetting g_detectingSetting = HotkeySetting::None;

    bool get_ListeningForKey() {
        return g_detectingSetting != HotkeySetting::None;
    }

    void StopListeningForKey() {
        g_detectingSetting = HotkeySetting::None;
    }

    bool get_ListeningForSwitchKey() { return g_detectingSetting == HotkeySetting::Switch; }
    void set_ListeningForSwitchKey(bool detect) { g_detectingSetting = detect ? HotkeySetting::Switch : HotkeySetting::None; }

    bool get_ListeningForWindowKey() { return g_detectingSetting == HotkeySetting::MainWindow; }
    void set_ListeningForWindowKey(bool detect) { g_detectingSetting = detect ? HotkeySetting::MainWindow : HotkeySetting::None; }

    bool get_ListeningForTimerKey() { return g_detectingSetting == HotkeySetting::Timer; }
    void set_ListeningForTimerKey(bool detect) { g_detectingSetting = detect ? HotkeySetting::Timer : HotkeySetting::None; }

    bool get_ListeningForAddCurrentMapKey() { return g_detectingSetting == HotkeySetting::AddCurrentMap; }
    void set_ListeningForAddCurrentMapKey(bool detect) { g_detectingSetting = detect ? HotkeySetting::AddCurrentMap : HotkeySetting::None; }

    bool get_ListeningForAddCurrentMapModalKey() { return g_detectingSetting == HotkeySetting::AddCurrentMapModal; }
    void set_ListeningForAddCurrentMapModalKey(bool detect) { g_detectingSetting = detect ? HotkeySetting::AddCurrentMapModal : HotkeySetting::None; }

    string GetKeyName(VirtualKey key) {
        if (key == VirtualKey(0)) {
            return "None";
        }

        const string name = tostring(key);

        if (name == tostring(int(key))) {
            return "";
        }

        return name;
    }

    bool IsKeyUsed(VirtualKey key) {
        if (key == VirtualKey(0)) {
            return false;
        }

        array<VirtualKey> usedKeys = {
            S_SwitchKey,
            S_WindowKey,
            S_TimerKey,
            S_AddCurrentMapKey,
            S_AddCurrentMapModalKey
        };

        return usedKeys.Find(key) > -1;
    }

    void RemoveHotkey(VirtualKey key) {
        if (!IsKeyUsed(key)) {
            return;
        }

        _Logging::Trace("[RemoveHotkey] Removing hotkey " + tostring(key));

        if (S_SwitchKey == key) {
            S_SwitchKey = VirtualKey(0);
        } else if (S_WindowKey == key) {
            S_WindowKey = VirtualKey(0);
        } else if (S_TimerKey == key) {
            S_TimerKey = VirtualKey(0);
        } else if (S_AddCurrentMapKey == key) {
            S_AddCurrentMapKey = VirtualKey(0);
        } else if (S_AddCurrentMapModalKey == key) {
            S_AddCurrentMapModalKey = VirtualKey(0);
        }
    }

    void AssignHotkey(VirtualKey key) {
        if (!ListeningForKey) {
            return;
        }

        _Logging::Trace("[AssignHotkey] Assigning hotkey " + tostring(key));

        RemoveHotkey(key);

        switch (g_detectingSetting) {
            case HotkeySetting::Switch:
                S_SwitchKey = key;
                break;
            case HotkeySetting::MainWindow:
                S_WindowKey = key;
                break;
            case HotkeySetting::Timer:
                S_TimerKey = key;
                break;
            case HotkeySetting::AddCurrentMap:
                S_AddCurrentMapKey = key;
                break;
            case HotkeySetting::AddCurrentMapModal:
                S_AddCurrentMapModalKey = key;
                break;
            default:
                break;
        }

        StopListeningForKey();
    }

    void RenderHotkeyCombo(const string &in label, VirtualKey currentKey) {
        UI::SetNextItemWidth(175);

        if (UI::BeginCombo(label, GetKeyName(currentKey))) {
            for (int i = 0; i <= 254; i++) {
                VirtualKey key = VirtualKey(i);
                string keyName = GetKeyName(key);
                bool taken = key != currentKey && IsKeyUsed(key);

                if (keyName == "") {
                    continue;
                }

                UI::BeginDisabled(taken);

                if (UI::Selectable(keyName, currentKey == key)) {
                    AssignHotkey(key);
                }

                if (taken) {
                    UI::SetItemTooltip("Key already used for a different setting!");
                }

                UI::EndDisabled();
            }

            UI::EndCombo();
        }
    }
}
