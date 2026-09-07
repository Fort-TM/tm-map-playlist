namespace Sort {
    funcdef int MapSort(Map@ a, Map@ b);

    const array<MapSort@> mapMethods = {
        SortIndex,
        SortName,
        SortAuthor,
        SortUrl,
        SortUid,
        SortGamemode,
        SortVista,
        SortTags,
        SortMedals,
        SortPb,
        SortDelta,
        SortSessionPb,
        SortSessionDelta
    };

    // -1 means A is lower, 1 means A is higher, 0 means it's a tie

    int SortString(const string &in a, const string &in b) {
        const string lowerA = a.ToLower();
        const string lowerB = b.ToLower();

        if (lowerA < lowerB) return -1;
        if (lowerA > lowerB) return 1;
        return 0;
    }

    int SortIndex(Map@ a, Map@ b) {
        return Math::Clamp(a.Index - b.Index, -1, 1);
    }
    int SortName(Map@ a, Map@ b) {
        return SortString(a.Name, b.Name);
    }

    int SortAuthor(Map@ a, Map@ b) {
        return SortString(a.Author, b.Author);
    }

    int SortUrl(Map@ a, Map@ b) {
        return SortString(a.Url, b.Url);
    }

    int SortUid(Map@ a, Map@ b) {
        return SortString(a.Uid, b.Uid);
    }

    int SortGamemode(Map@ a, Map@ b) {
        return SortString(tostring(a.GameMode), tostring(b.GameMode));
    }

    int SortVista(Map@ a, Map@ b) {
        return SortString(a.VistaName, b.VistaName);
    }

    int SortTags(Map@ a, Map@ b) {
        if (a.Tags.IsEmpty() && b.Tags.IsEmpty()) {
            return SortString(a.Name, b.Name);
        }

        if (a.Tags.IsEmpty()) {
            return -1;
        }

        if (b.Tags.IsEmpty()) {
            return 1;
        }

        uint maxLength = Math::Max(a.Tags.Length, b.Tags.Length);

        for (uint i = 0; i < maxLength; i++) {
            if (a.Tags.Length <= i) {
                return -1;
            }

            if (b.Tags.Length <= i) {
                return 1;
            }

            int nameResult = SortString(a.Tags[i].Name, b.Tags[i].Name);
            if (nameResult != 0) return nameResult;
        }

        return 0;
    }

    int SortMedals(Map@ a, Map@ b) {
        return Math::Clamp(a.GetMedalScore(S_MainMedal) - b.GetMedalScore(S_MainMedal), -1, 1);
    }

    int SortPb(Map@ a, Map@ b) {
        if (!a.HasPb && !b.HasPb) return SortString(a.Name, b.Name);
        if (!a.HasPb) return -1;
        if (!b.HasPb) return 1;

        return Math::Clamp(a.Pb - b.Pb, -1, 1);
    }

    int SortDelta(Map@ a, Map@ b) {
        if (!a.HasPb && !b.HasPb) return SortString(a.Name, b.Name);
        if (!a.HasPb) return -1;
        if (!b.HasPb) return 1;

        int aDelta = a.GetMedalScore(S_MainMedal) - a.Pb;
        if (a.GameMode == GameMode::Stunt) aDelta = aDelta * -1;

        int bDelta = b.GetMedalScore(S_MainMedal) - b.Pb;
        if (b.GameMode == GameMode::Stunt) bDelta = bDelta * -1;

        return Math::Clamp(aDelta - bDelta, -1, 1);
    }

    int SortSessionPb(Map@ a, Map@ b) {
        if (!a.HasSessionPb && !b.HasSessionPb) return SortString(a.Name, b.Name);
        if (!a.HasSessionPb) return -1;
        if (!b.HasSessionPb) return 1;

        return Math::Clamp(a.SessionPb - b.SessionPb, -1, 1);
    }

    int SortSessionDelta(Map@ a, Map@ b) {
        if (!a.HasSessionPb && !b.HasSessionPb) return SortString(a.Name, b.Name);
        if (!a.HasSessionPb) return -1;
        if (!b.HasSessionPb) return 1;

        int aDelta = a.GetMedalScore(S_MainMedal) - a.SessionPb;
        if (a.GameMode == GameMode::Stunt) aDelta = aDelta * -1;

        int bDelta = b.GetMedalScore(S_MainMedal) - b.SessionPb;
        if (b.GameMode == GameMode::Stunt) bDelta = bDelta * -1;

        return Math::Clamp(aDelta - bDelta, -1, 1);
    }

    // Original code from Better TOTD by Xertrov
    void MapQuickSort(Map@[]@ arr, MapSort@ f, bool descending, int left = 0, int right = -1) {
        if (right < 0) right = arr.Length - 1;
        if (arr.Length == 0) return;

        int i = left;
        int j = right;
        Map@ pivot = arr[(left + right) / 2];

        while (i <= j) {
            if (descending) {
                while (f(arr[i], pivot) > 0) i++;
                while (f(arr[j], pivot) < 0) j--;
            } else {
                while (f(arr[j], pivot) > 0) j--;
                while (f(arr[i], pivot) < 0) i++;
            }

            if (i <= j) {
                Map@ temp = arr[i];
                @arr[i] = arr[j];
                @arr[j] = temp;
                i++;
                j--;
            }
        }

        if (left < j) MapQuickSort(arr, f, descending, left, j);
        if (i < right) MapQuickSort(arr, f, descending, i, right);
    }

    void SortMapPlaylist(UI::TableSortSpecs@ tableSpecs) {
        if (playlist.Length < 2) {
            return;
        }

        foreach (UI::TableColumnSortSpecs spec : tableSpecs.Specs) {
            if (spec.SortDirection == UI::SortDirection::None) {
                continue;
            }

            switch (spec.ColumnIndex) {
                case 13:
                    // Can't sort buttons
                    continue;
                default:
                    if (spec.ColumnIndex >= int(mapMethods.Length)) {
                        continue;
                    }

                    // For indexes, we only want to sort it when clicking the column
                    // since otherwise that will undo shuffled / moved playlists
                    if (spec.ColumnIndex == 0 && !tableSpecs.Dirty) {
                        continue;
                    }

                    MapQuickSort(playlist.Maps, mapMethods[spec.ColumnIndex], spec.SortDirection == UI::SortDirection::Descending);
                    break;
            }
        }

        tableSpecs.Dirty = false;
        playlist.Dirty = false;
    }
}
