class PlaylistsManager {
    array<MapPlaylist@> Playlists;

    bool Dirty = false;
    PlaylistColumns@ columnWidths = PlaylistColumns();

    void OnUpdatedPlaylists() {
        this.columnWidths.Update(this.Playlists);
        this.Dirty = true;
    }

    uint get_Length() {
        return this.Playlists.Length;
    }

    bool IsEmpty() {
        return this.Playlists.IsEmpty();
    }

    void Add(MapPlaylist@ list) {
        this.Playlists.InsertLast(list);
        this.OnUpdatedPlaylists();
    }

    void Delete(const string &in name) {
        for (uint i = 0; i < this.Playlists.Length; i++) {
            if (this.Playlists[i].Name == name) {
                this.Playlists.RemoveAt(i);
                break;
            }
        }

        this.OnUpdatedPlaylists();
    }

    void Edit(const string &in name, MapPlaylist@ list) {
        for (uint i = 0; i < this.Playlists.Length; i++) {
            if (this.Playlists[i].Name == name) {
                this.Playlists[i].Name = list.Name;
                this.Playlists[i].Maps = list.Maps;
                this.Playlists[i].Tags = list.Tags;
                break;
            }
        }

        this.OnUpdatedPlaylists();
    }

    MapPlaylist@ get_opIndex(uint i) {
        return this.Playlists[i];
    }

    void set_opIndex(uint i, MapPlaylist@ list) {
        @this.Playlists[i] = list;
    }
}
