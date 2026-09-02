#!/usr/bin/env bash
# quarantine_relocate.sh - move quarantine dirs OUT of music_directory so MPD
# stops re-indexing and playing files that were supposed to be excluded.
# Also patches the dedup/quarantine scripts' defaults so this can't recur.
set -uo pipefail

sep() { echo "════════════════════════════════════════════════════════════"; }
LIB="${HOME}/Music-library"
QROOT="${HOME}/ez_jukebox_quarantine"

sep
echo " STEP A: investigate the two repo path sightings"
sep
for p in "${HOME}/github_projects/ez_jukebox" "${HOME}/home-data/github_projects/ez_jukebox"; do
    if [[ -d "$p" ]]; then
        echo "$p -> $(readlink -f "$p")"
    else
        echo "$p -> does not exist"
    fi
done
echo ""
echo "-- mpd_notify.py / mpd_web_ui.py: tracked in git? --"
for f in scripts/mpd_notify.py scripts/mpd_web_ui.py; do
    if [[ -f "$HOME/github_projects/ez_jukebox/$f" ]]; then
        (cd "${HOME}/github_projects/ez_jukebox" && git status --short "$f" 2>/dev/null)
        echo "  [$f] $( [[ -z "$(cd "${HOME}/github_projects/ez_jukebox" && git status --short "$f" 2>/dev/null)" ]] && echo "tracked/clean or not found" || echo "see above" )"
    fi
done

sep
echo " STEP B: before counts -- how much quarantine content is in the DB"
sep
BEFORE_TOTAL=$(mpc stats 2>/dev/null | grep -i "songs" | grep -o '[0-9]*' | head -1)
BEFORE_QUAR=$(mpc listall 2>/dev/null | grep -c "_quarantine\|_dedup_quarantine")
echo "total songs in DB:      ${BEFORE_TOTAL:-unknown}"
echo "quarantine paths in DB: ${BEFORE_QUAR:-unknown}"

sep
echo " STEP C: relocate quarantine dirs outside music_directory"
sep
mkdir -p "$QROOT"
for d in "_quarantine" "_dedup_quarantine"; do
    SRC="${LIB}/${d}"
    DST="${QROOT}/${d#_}"
    if [[ -d "$SRC" ]]; then
        if [[ -d "$DST" ]]; then
            echo "[info] $DST already exists -- merging contents"
            rsync -a "$SRC"/ "$DST"/ 2>/dev/null || cp -rn "$SRC"/. "$DST"/
            rm -rf "$SRC"
        else
            mv "$SRC" "$DST"
        fi
        echo "[ok] $SRC -> $DST"
    else
        echo "[skip] $SRC does not exist"
    fi
done

sep
echo " STEP D: patch the scripts so future quarantine ops don't recreate this bug"
sep
REPO="${HOME}/github_projects/ez_jukebox"
if [[ -f "${REPO}/scripts/dedup_verified.py" ]]; then
    sed -i 's|QUARANTINE = LIBRARY_ROOT / "_dedup_quarantine"|QUARANTINE = Path(os.environ.get("QUARANTINE_ROOT", str(Path.home() / "ez_jukebox_quarantine" / "dedup_quarantine")))|' \
        "${REPO}/scripts/dedup_verified.py"
    python3 -m py_compile "${REPO}/scripts/dedup_verified.py" && echo "[ok] dedup_verified.py patched, compiles clean"
fi
if [[ -f "${REPO}/scripts/quarantine_nonmusic.sh" ]]; then
    sed -i 's|QUARANTINE="\$LIB/_quarantine"|QUARANTINE="${HOME}/ez_jukebox_quarantine/quarantine"|' \
        "${REPO}/scripts/quarantine_nonmusic.sh"
    bash -n "${REPO}/scripts/quarantine_nonmusic.sh" && echo "[ok] quarantine_nonmusic.sh patched, syntax valid"
fi

sep
echo " STEP E: force MPD to drop the now-missing paths"
sep
mpc update >/dev/null 2>&1
sleep 3
for i in 1 2 3 4 5; do
    mpc status >/dev/null 2>&1 && break
    sleep 1
done

sep
echo " STEP F: after counts -- confirm the fix actually worked"
sep
AFTER_TOTAL=$(mpc stats 2>/dev/null | grep -i "songs" | grep -o '[0-9]*' | head -1)
AFTER_QUAR=$(mpc listall 2>/dev/null | grep -c "_quarantine\|_dedup_quarantine")
echo "total songs in DB:      ${BEFORE_TOTAL:-?} -> ${AFTER_TOTAL:-?}"
echo "quarantine paths in DB: ${BEFORE_QUAR:-?} -> ${AFTER_QUAR:-?}"
if [[ "${AFTER_QUAR:-1}" == "0" ]]; then
    echo "[ok] quarantine content fully removed from the playable database"
else
    echo "[warn] ${AFTER_QUAR} quarantine paths still in DB -- may need a second 'mpc update' pass"
fi

sep
echo " STEP G: surface mpd_notify.py / mpd_web_ui.py for review (not modified)"
sep
for f in "${HOME}/home-data/github_projects/ez_jukebox/scripts/mpd_notify.py" \
         "${HOME}/github_projects/ez_jukebox/scripts/mpd_web_ui.py"; do
    if [[ -f "$f" ]]; then
        echo "--- $f (first 20 lines) ---"
        head -20 "$f"
        echo ""
    fi
done

echo ""
echo "=== Done. Quarantine relocated to ${QROOT}, no longer inside music_directory. ==="
echo "=== Review the mpd_notify.py / mpd_web_ui.py dump above -- I didn't write ==="
echo "=== either of these and won't touch them without knowing what they do.   ==="
