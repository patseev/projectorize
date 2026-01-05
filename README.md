# Projectorize

Scripts to prepare media files for projector playback. Handles Dolby audio conversion (projectors often don't support AC3/E-AC3), audio track replacement, and track selection.

## Prerequisites

- **ffmpeg / ffprobe** - Audio conversion and codec detection
- **mkvmerge / mkvpropedit** - MKV muxing and track manipulation (MKVToolNix)

Install on macOS:
```bash
brew install ffmpeg mkvtoolnix
```

---

## Scripts

### Audio Replacement

Replace original audio tracks with external audio files.

| Script | Scope | Matching |
|--------|-------|----------|
| `replace-audio-with-mka.sh` | Single file | Manual |
| `replace-audio-directory.sh` | Directory | Episode number |
| `projectorize-no-dolby.sh` | Directory | Sorted filename |

#### `replace-audio-with-mka.sh`
Replace audio in a single MKV file with an external audio file. Sets new audio as default track.

```bash
./replace-audio-with-mka.sh <video.mkv> <audio.mka>
```

**Example:**
```bash
./replace-audio-with-mka.sh movie.mkv russian_audio.mka
# Output: movie_with_mka.mkv
```

#### `replace-audio-directory.sh`
Batch replace audio by matching episode numbers extracted from filenames. Supports multiple audio formats (.mka, .aac, .ac3, .mp3, .flac, .opus, .m4a).

```bash
./replace-audio-directory.sh <video_dir> <audio_dir> [output_dir]
```

**Example:**
```bash
./replace-audio-directory.sh "Anime Series/" "Anime Series/Russian Audio/"
# Matches: Episode_01.mkv <-> rus_01.mka (by episode number)
# Output: Episode_01_rus.mkv (in video directory)
```

**Use when:** Video and audio files have different naming conventions but contain episode numbers.

#### `projectorize-no-dolby.sh`
Batch mux MKV files with MKA audio. Pairs files by sorted filename order. Automatically converts Dolby audio (AC3/E-AC3) to AAC.

```bash
./projectorize-no-dolby.sh <mkv_dir> <mka_dir> <output_dir>
```

**Example:**
```bash
./projectorize-no-dolby.sh videos/ audio/ output/
# Pairs by sorted order: video_01.mkv <-> audio_01.mka
# Converts Dolby to AAC if detected
```

**Use when:** Files are consistently named and sort in matching order. Requires equal number of files in both directories.

---

### Dolby Conversion

Convert Dolby audio (AC3/E-AC3) to AAC for projector compatibility.

| Script | Scope |
|--------|-------|
| `is-dolby.sh` | Single file (check only) |
| `remove-dolby.sh` | Single file |
| `remove-dolby-directory.sh` | Directory |

#### `is-dolby.sh`
Check if a file's main audio track is Dolby. Does not modify the file.

```bash
./is-dolby.sh <video-file>
```

**Example:**
```bash
./is-dolby.sh movie.mkv
# Output: "Dolby audio detected as main track: ac3"
# Or: "Main audio track is not Dolby (codec: aac)"
```

#### `remove-dolby.sh`
Convert Dolby audio to AAC (192kbps). Copies video stream without re-encoding. Skips conversion if audio is already non-Dolby.

```bash
./remove-dolby.sh <video-file>
```

**Example:**
```bash
./remove-dolby.sh movie.mkv
# Output: movie_no_dolby.mkv (same directory)
```

#### `remove-dolby-directory.sh`
Batch version of `remove-dolby.sh` for entire directories.

```bash
./remove-dolby-directory.sh <input_dir> <output_dir>
```

**Example:**
```bash
./remove-dolby-directory.sh downloads/ converted/
# Processes all MKV files, converts Dolby to AAC
# Non-Dolby files are copied unchanged
```

---

### Track Selection

Manage audio track selection and defaults.

| Script | Purpose |
|--------|---------|
| `keep-audio-track.sh` | Remove all but one audio track |
| `projectorize-with-selected-track.sh` | Set default track + convert Dolby |

#### `keep-audio-track.sh`
Keep only a specific audio track, removing all others. Useful for reducing file size or removing unwanted dubs.

```bash
./keep-audio-track.sh <track-id> <input_dir> <output_dir>
```

**Example:**
```bash
# Find track IDs first:
mkvmerge -i movie.mkv
# Track ID 1: audio (A_AAC) [language:jpn]
# Track ID 2: audio (A_AC3) [language:eng]

./keep-audio-track.sh 1 videos/ output/
# Output: movie_audio1.mkv (Japanese audio only)
```

#### `projectorize-with-selected-track.sh`
Set a specific audio track as default (for projector auto-selection) and convert to AAC if it's Dolby.

```bash
./projectorize-with-selected-track.sh <track-number> <input_dir> <output_dir>
```

**Example:**
```bash
./projectorize-with-selected-track.sh 2 videos/ output/
# Sets track 2 as default
# Converts track 2 to AAC if Dolby
# Output: movie_projectorized.mkv
```

---

## Quick Reference

| I want to... | Use this script |
|--------------|-----------------|
| Check if file has Dolby audio | `is-dolby.sh` |
| Convert single file Dolby→AAC | `remove-dolby.sh` |
| Convert directory Dolby→AAC | `remove-dolby-directory.sh` |
| Replace audio in one file | `replace-audio-with-mka.sh` |
| Batch replace audio (episode matching) | `replace-audio-directory.sh` |
| Batch replace audio (sorted order) + Dolby fix | `projectorize-no-dolby.sh` |
| Keep only one audio track | `keep-audio-track.sh` |
| Set default track + Dolby fix | `projectorize-with-selected-track.sh` |
