PRAGMA foreign_keys = ON;
-- Schema version: 1

-- NOTES:
-- Time values are all milliseconds
-- Position and Duration values are all milliseconds
-- artwork_path points to cached image file

CREATE TABLE IF NOT EXISTS albums (
    album_id TEXT PRIMARY KEY, -- Stable id
    album_title TEXT NOT NULL, -- Album Name
    album_artist TEXT NOT NULL, -- Album Artist(s) Name
    year INTEGER,
    artwork_thumbnail_path TEXT, -- local cached artwork path
    artwork_hq_path TEXT,
    date_added_ms INTEGER
);

CREATE TABLE IF NOT EXISTS tracks (
    track_id TEXT PRIMARY KEY, -- Stable id
    track_uri TEXT NOT NULL,
    track_title TEXT NOT NULL, -- Track name
    album_title TEXT NOT NULL, -- Album Name
    album_id TEXT NOT NULL,
    track_artist TEXT NOT NULL,
    track_duration_ms INTEGER NOT NULL,

    track_path TEXT, -- fs path
    track_source TEXT, -- iOS (later if Frau Dr. melanie wants the other method)
    year INTEGER,

    artwork_thumbnail_path TEXT, -- local cached artwork path
    artwork_hq_path TEXT,
    artwork_url TEXT, -- I think this is local too sometimes

    date_added_ms INTEGER, -- When it was indexed
    track_modified_last_ms INTEGER, -- File was modified last (e.g., using the metadata editor)
    track_size INTEGER, -- Bytes

    track_number INTEGER, -- In album
    is_metadata_managed INTEGER NOT NULL DEFAULT 1, -- 1 = device managed, 0 = user edited
    has_lrc INTEGER DEFAULT 0,
    lrc_path TEXT,
    replay_gain_db REAL, -- ReplayGain normalization value in dB

    FOREIGN KEY(album_id) REFERENCES albums(album_id) ON DELETE CASCADE
);

-- Common library queries
CREATE INDEX IF NOT EXISTS index_tracks_album_id ON tracks(album_id);
CREATE INDEX IF NOT EXISTS index_tracks_title ON tracks(track_title);
CREATE INDEX IF NOT EXISTS index_tracks_artist ON tracks(track_artist);

CREATE TABLE IF NOT EXISTS playlists (
    playlist_id TEXT PRIMARY KEY, -- Stable id (UUID)
    playlist_name TEXT NOT NULL,
    is_generated INTEGER NOT NULL DEFAULT 0, -- Bool
    created_at_ms INTEGER NOT NULL,
    updated_at_ms INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS playlist_items (
    playlist_id TEXT NOT NULL, -- Stable id (UUID)
    track_id TEXT NOT NULL,
    position INTEGER NOT NULL, -- Order in playlist
    date_added_ms INTEGER NOT NULL,
    PRIMARY KEY (playlist_id, track_id), -- Block duplicates

    FOREIGN KEY (playlist_id) REFERENCES playlists(playlist_id) ON DELETE CASCADE,
    FOREIGN KEY (track_id) REFERENCES tracks(track_id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS index_playlist_items_order ON playlist_items(playlist_id, position);


-- Listening history
CREATE TABLE IF NOT EXISTS played_tracks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    track_id TEXT NOT NULL,

    started_at_ms INTEGER NOT NULL, --  Listening started
    ended_at_ms INTEGER, --  Listening ended

    start_position_ms INTEGER NOT NULL DEFAULT 0, -- relevant for knowing actual listen time
    end_position_ms INTEGER, -- relevant for knowing actual listen time
    total_listened_ms INTEGER, -- derived: end_position_ms - start_position_ms
    segment_started_at_ms INTEGER, -- set on play, cleared on pause
    segment_start_position_ms INTEGER,
    completed INTEGER NOT NULL DEFAULT 0,

    FOREIGN KEY (track_id) REFERENCES tracks(track_id) ON DELETE NO ACTION
);

CREATE INDEX IF NOT EXISTS index_played_tracks_time ON played_tracks(started_at_ms DESC);
CREATE INDEX IF NOT EXISTS index_played_tracks_track_time ON played_tracks(track_id, started_at_ms DESC);
CREATE UNIQUE INDEX IF NOT EXISTS index_tracks_uri_unique ON tracks(track_uri);


-- Tags for tracks (genre, mood, user-defined, etc.)
-- Stored separately to allow multiple tags per track
CREATE TABLE IF NOT EXISTS tags (
    tag_id INTEGER PRIMARY KEY AUTOINCREMENT,
    tag_name TEXT NOT NULL UNIQUE COLLATE NOCASE,
    tag_type TEXT NOT NULL DEFAULT 'genre'  -- 'genre', 'mood', 'user', etc.
);

CREATE TABLE IF NOT EXISTS track_tags (
    track_id TEXT NOT NULL,
    tag_id INTEGER NOT NULL,
    PRIMARY KEY (track_id, tag_id),
    FOREIGN KEY (track_id) REFERENCES tracks(track_id) ON DELETE CASCADE,
    FOREIGN KEY (tag_id) REFERENCES tags(tag_id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS index_track_tags_tag ON track_tags(tag_id);


-- Artist metadata (MusicBrainz / Wikidata)
CREATE TABLE IF NOT EXISTS artists (
    artist_name TEXT PRIMARY KEY,
    mbid TEXT,
    wikidata_id TEXT,
    image_path TEXT,
    image_thumbnail_path TEXT,
    bio TEXT,
    fetched_at_ms INTEGER
);








