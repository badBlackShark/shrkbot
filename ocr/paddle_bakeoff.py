#!/usr/bin/env python3
"""
paddle_bakeoff.py - Compare PaddleOCR configurations with weighted, per-image
ground-truth scoring.

The previous version scored against one flat keyword list, so every config
pegged the same recall and the metric couldn't discriminate. This version scores
each image against its OWN expected-token list, with:

  - PER-IMAGE ground truth  -> no artificial ceiling; harder images pull scores
    apart, so configs actually rank.
  - WEIGHTED tokens          -> weight 3 = critical (make-or-break: the domain,
    the payout amount, core crypto/scam terms), 2 = high, 1 = normal transcription.
  - CRITICAL RECALL reported separately -> a config that reads 95% of the text but
    misses the domain or the amount is UNSHIPPABLE, and this makes that visible.
  - NORMALIZED matching       -> whitespace/newlines collapsed and number-group
    separators tolerated, so "5 600", "5,600", "5600", "$5600.00" all count as the
    amount. This alone fixed the amount looking "missed" last run.

Ground truth for scam1.jpg / scam2.jpg is built in below. Point --truth at a JSON
file to grade a larger set (20-50 images) without editing code:

    { "myimage.png": [ {"pattern": "tuzawin", "weight": 3},
                        {"pattern": "5[\\\\s,]?600", "weight": 3, "regex": true,
                         "label": "$5,600"} ] }

--------------------------------------------------------------------------------
SETUP   python -m pip install paddleocr paddlepaddle pillow   (+ easyocr, optional)
USAGE   python paddle_bakeoff.py --images ./images --repeats 3
        python paddle_bakeoff.py --images ./images --truth ground_truth.json
--------------------------------------------------------------------------------
"""

import argparse
import json
import re
import tempfile
import time
from pathlib import Path

IMAGE_EXTS = {".png", ".jpg", ".jpeg", ".webp", ".bmp", ".tif", ".tiff"}

INCLUDE_EASYOCR = False
EASYOCR_ON_GPU = False

CRITICAL_WEIGHT = 3  # tokens at this weight or above count toward "critical recall"


def T(pattern, weight=1, regex=False, label=None):
    """Build a ground-truth token. weight 3=critical, 2=high, 1=normal."""
    return {"pattern": pattern, "weight": weight, "regex": regex,
            "label": label or pattern}


# --- Built-in ground truth for the two sample scam images --------------------
# ~40 tokens total. Critical (w3): domain, amount, and the core crypto/scam terms
# that constitute "this is the scam". High (w2): strong secondary signals + the
# hard wallet-address string. Normal (w1): general text that measures raw quality.
GROUND_TRUTH = {
    "scam1.jpg": [
        # --- critical ---
        T("tuzawin", 3, label="tuzawin (scam domain)"),
        T(r"5[\s,]?600", 3, regex=True, label="$5,600 (amount)"),
        T("cryptocurrency", 3),
        T("promo code", 3),
        T("withdraw", 3),
        # --- high ---
        T("casino", 2),
        T("bonus", 2),
        T(r"\bbet\b", 2, regex=True, label="BET (promo code)"),
        T("mrbeast", 2, label="MrBeast (impersonated)"),
        T("vyro", 2, label="Vyro (fake project)"),
        T("reward", 2),
        # --- normal ---
        T("pleased to announce", 1),
        T("celebrate", 1),
        T("immediately", 1),
        T("beast games", 1),
        T("media personality", 1),
        T("followers", 1),
        T("subscriptions", 1),
        T("this post will be deleted", 1),
        T("miss your chance", 1),
        T("stay tuned", 1),
    ],
    "scam2.jpg": [
        # --- critical ---
        T(r"5[\s,]?600", 3, regex=True, label="5,600 (amount)"),
        T("usdt", 3, label="USDT"),
        T("withdrawal success", 3),
        T("tether", 3),
        # --- high ---
        T("te51enb", 2, label="wallet address prefix (hard)"),
        T("wallet address", 2),
        T("withdraw method", 2),
        T("completed", 2),
        T("receive usdt", 2),
        T("block explorer", 2),
        T("network fee", 2),
        # --- normal ---
        T("bonuses", 1),
        T("vip-club", 1, label="VIP-Club"),
        T("bank card", 1),
        T("visa", 1),
        T("your balance", 1),
        T("select crypto", 1),
        T("continue", 1),
        T(r"\btrx\b", 1, regex=True, label="TRX"),
    ],
}


# --- PaddleOCR configurations to compare -------------------------------------
AUX_OFF = dict(use_doc_orientation_classify=False,
               use_doc_unwarping=False,
               use_textline_orientation=False)

PADDLE_CONFIGS = [
    ("v6_medium (default, aux ON)", dict(lang="en"), None),
    ("v6_medium (aux OFF)", dict(lang="en", **AUX_OFF), None),
    ("v5_server (aux OFF)", dict(
        text_detection_model_name="PP-OCRv5_server_det",
        text_recognition_model_name="PP-OCRv5_server_rec", **AUX_OFF), None),
    ("v5_mobile (aux OFF)", dict(
        text_detection_model_name="PP-OCRv5_mobile_det",
        text_recognition_model_name="PP-OCRv5_mobile_rec", **AUX_OFF), None),
    ("v4 (aux OFF)", dict(ocr_version="PP-OCRv4", lang="en", **AUX_OFF), None),
]
# (Dropped the downscale row -- it was a no-op on these image sizes. Add it back
#  with a small max-width if you start seeing large phone screenshots.)


# --- Matching / scoring ------------------------------------------------------

def normalize(s):
    """Lowercase and collapse all whitespace (incl. newlines) to single spaces."""
    return re.sub(r"\s+", " ", (s or "").lower()).strip()


def fuzzy_substring_distance(pattern, text):
    """Minimum edit distance between `pattern` and ANY substring of `text`
    (Sellers' approximate string matching). O(len(pattern) * len(text)), pure
    Python, no deps. Row 0 = zeros lets the match start anywhere; the answer is
    the min of the final row (match can end anywhere)."""
    m, n = len(pattern), len(text)
    if m == 0:
        return 0
    if n == 0:
        return m
    prev = [0] * (n + 1)
    for i in range(1, m + 1):
        cur = [i] + [0] * n
        pc = pattern[i - 1]
        for j in range(1, n + 1):
            cost = 0 if pc == text[j - 1] else 1
            cur[j] = min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + cost)
        prev = cur
    return min(prev)


def match_token(tok, norm_text, fuzzy_ratio):
    """Return (exact_hit, fuzzy_hit).

    Regex tokens (the amount, BET, TRX) are matched exactly either way -- fuzzy
    edit distance doesn't apply to a pattern. Plain tokens get a fuzzy pass whose
    allowed edits scale with token length: floor(len * ratio). At ratio 0.2 that
    is 0 edits for <=4 chars (exact required), 1 for 5-9, 2 for 10-14 -- so
    'tuzowin' still matches 'tuzawin' but short tokens stay strict."""
    pat = tok["pattern"]
    if tok.get("regex"):
        hit = re.search(pat, norm_text) is not None
        return hit, hit
    pat = pat.lower()
    if pat in norm_text:
        return True, True
    max_dist = int(len(pat) * fuzzy_ratio)
    if max_dist <= 0:
        return False, False
    return False, fuzzy_substring_distance(pat, norm_text) <= max_dist


def score(text, tokens, fuzzy_ratio):
    """Score under BOTH exact and fuzzy matching in one pass so a single run
    shows how much fuzzy matching recovers. missed_crit is the FUZZY miss list --
    the criticals that fail even with fuzzy, i.e. the true blockers."""
    norm = normalize(text)
    tot_w = crit_tot = 0
    got_w = {"exact": 0, "fuzzy": 0}
    crit_got = {"exact": 0, "fuzzy": 0}
    missed_crit = []
    for tok in tokens:
        w = tok["weight"]
        tot_w += w
        is_crit = w >= CRITICAL_WEIGHT
        crit_tot += 1 if is_crit else 0
        exact, fuzzy = match_token(tok, norm, fuzzy_ratio)
        if exact:
            got_w["exact"] += w
            if is_crit:
                crit_got["exact"] += 1
        if fuzzy:
            got_w["fuzzy"] += w
            if is_crit:
                crit_got["fuzzy"] += 1
        elif is_crit:
            missed_crit.append(tok["label"])
    return {
        "weighted_exact": (got_w["exact"] / tot_w) if tot_w else None,
        "weighted_fuzzy": (got_w["fuzzy"] / tot_w) if tot_w else None,
        "crit_exact": crit_got["exact"], "crit_fuzzy": crit_got["fuzzy"],
        "crit_tot": crit_tot, "missed_crit": missed_crit,
    }


# --- Downscale + Paddle result parsing ---------------------------------------

def maybe_downscale(path, max_width):
    if not max_width:
        return str(path), (lambda: None)
    try:
        from PIL import Image
    except ImportError:
        return str(path), (lambda: None)
    img = Image.open(path)
    if img.width <= max_width:
        return str(path), (lambda: None)
    resized = img.resize((max_width, int(img.height * (max_width / img.width))))
    tmp = tempfile.NamedTemporaryFile(suffix=".png", delete=False)
    resized.save(tmp.name)
    tmp.close()
    return tmp.name, (lambda: Path(tmp.name).unlink(missing_ok=True))


def paddle_parse(res):
    for getter in (
        lambda: (res["rec_texts"], res.get("rec_scores", [])),
        lambda: (getattr(res, "rec_texts"), getattr(res, "rec_scores", [])),
    ):
        try:
            texts, scores = getter()
            if texts is not None:
                return list(texts), list(scores or [])
        except Exception:
            pass
    texts, scores = [], []
    try:
        for line in res or []:
            if len(line) >= 2 and isinstance(line[1], (list, tuple)):
                texts.append(line[1][0])
                scores.append(line[1][1])
    except Exception:
        pass
    return texts, scores


# --- Predictor builders ------------------------------------------------------

def build_paddle(kwargs, downscale):
    from paddleocr import PaddleOCR
    t0 = time.perf_counter()
    ocr = PaddleOCR(**kwargs)
    load = time.perf_counter() - t0

    def predict(path):
        img_path, cleanup = maybe_downscale(path, downscale)
        try:
            texts, scores = [], []
            if hasattr(ocr, "predict"):
                try:
                    for res in ocr.predict(img_path) or []:
                        t, s = paddle_parse(res)
                        texts += t
                        scores += s
                except Exception:
                    texts, scores = [], []
            if not texts and hasattr(ocr, "ocr"):
                for res in (ocr.ocr(img_path) or []):
                    t, s = paddle_parse(res)
                    texts += t
                    scores += s
            return "\n".join(map(str, texts)).strip()
        finally:
            cleanup()

    return predict, load


def build_easyocr(downscale):
    import easyocr
    t0 = time.perf_counter()
    reader = easyocr.Reader(["en"], gpu=EASYOCR_ON_GPU)
    load = time.perf_counter() - t0

    def predict(path):
        img_path, cleanup = maybe_downscale(path, downscale)
        try:
            results = reader.readtext(img_path, detail=1)
            return "\n".join(r[1] for r in results).strip()
        finally:
            cleanup()

    return predict, load


# --- Main --------------------------------------------------------------------

def main():
    ap = argparse.ArgumentParser(description="Compare PaddleOCR configurations.")
    ap.add_argument("--images", default="./images")
    ap.add_argument("--repeats", type=int, default=1,
                    help="Runs per image per config (1st=cold, rest=warm mean)")
    ap.add_argument("--truth", default=None,
                    help="JSON file of per-image ground-truth tokens (extends built-in)")
    ap.add_argument("--fuzzy-ratio", type=float, default=0.2,
                    help="Allowed edits as a fraction of token length (0.2 -> "
                         "1 edit at 5-9 chars, 2 at 10-14). 0 disables fuzzy.")
    ap.add_argument("--out", default="paddle_report.md")
    args = ap.parse_args()

    truth = dict(GROUND_TRUTH)
    if args.truth:
        truth.update(json.loads(Path(args.truth).read_text(encoding="utf-8")))

    folder = Path(args.images)
    if not folder.is_dir():
        print(f"'{folder}' is not a folder. Pass one with --images.")
        return
    images = sorted(p for p in folder.iterdir() if p.suffix.lower() in IMAGE_EXTS)
    if not images:
        print(f"No images in {folder.resolve()}.")
        return

    graded = [im for im in images if im.name in truth]
    ungraded = [im.name for im in images if im.name not in truth]
    if ungraded:
        print(f"Note: no ground truth for {ungraded} -- timed but not scored.")
    total_crit = sum(sum(1 for t in truth[im.name] if t["weight"] >= CRITICAL_WEIGHT)
                     for im in graded)

    configs = list(PADDLE_CONFIGS)
    if INCLUDE_EASYOCR:
        configs.append(("EasyOCR baseline", "EASYOCR", None))

    print(f"{len(images)} image(s) ({len(graded)} graded), {len(configs)} config(s), "
          f"repeats={args.repeats}, {total_crit} critical tokens, "
          f"fuzzy_ratio={args.fuzzy_ratio}\n")

    report = [f"# PaddleOCR configuration bake-off\n\n",
              f"Folder: `{folder.resolve()}` — {len(graded)} graded image(s), "
              f"repeats={args.repeats}, fuzzy_ratio={args.fuzzy_ratio}\n"]
    summary = []

    for label, kwargs, downscale in configs:
        print(f"### {label}")
        report.append(f"\n## {label}\n\n")
        try:
            if kwargs == "EASYOCR":
                predict, load = build_easyocr(downscale)
            else:
                predict, load = build_paddle(kwargs, downscale)
        except Exception as e:
            print(f"  init skipped: {e}\n")
            report.append(f"_init skipped: {e}_\n")
            continue
        print(f"  model load: {load:.2f}s")
        report.append(f"Model load: {load:.2f}s\n\n")

        warm_times = []
        w_exact, w_fuzzy = [], []
        crit_exact_total = crit_fuzzy_total = 0
        missed_crit_all = []                    # fuzzy misses = true blockers
        for img in images:
            times, text = [], ""
            for _ in range(max(1, args.repeats)):
                t0 = time.perf_counter()
                try:
                    text = predict(img)
                except Exception as e:
                    text = f"(error: {e})"
                times.append(time.perf_counter() - t0)
            cold = times[0]
            warm = (sum(times[1:]) / len(times[1:])) if len(times) > 1 else times[0]
            warm_times.append(warm)

            if img.name in truth:
                sc = score(text, truth[img.name], args.fuzzy_ratio)
                w_exact.append(sc["weighted_exact"])
                w_fuzzy.append(sc["weighted_fuzzy"])
                crit_exact_total += sc["crit_exact"]
                crit_fuzzy_total += sc["crit_fuzzy"]
                missed_crit_all += [f"{m} ({img.name})" for m in sc["missed_crit"]]
                cstr = f"{sc['crit_exact']}->{sc['crit_fuzzy']}/{sc['crit_tot']}"
                print(f"  {img.name:20} warm {warm:5.2f}s  "
                      f"crit(exact->fuzzy) {cstr}")
                report.append(
                    f"**{img.name}** — cold {cold:.2f}s, warm {warm:.2f}s, "
                    f"critical exact {sc['crit_exact']}/{sc['crit_tot']} -> "
                    f"fuzzy {sc['crit_fuzzy']}/{sc['crit_tot']}"
                    + (f", STILL MISSED: {', '.join(sc['missed_crit'])}"
                       if sc["missed_crit"] else "")
                    + f"\n\n```\n{text or '(no text)'}\n```\n\n")
            else:
                print(f"  {img.name:20} warm {warm:5.2f}s  (ungraded)")
                report.append(f"**{img.name}** — warm {warm:.2f}s (ungraded)\n\n"
                              f"```\n{text or '(no text)'}\n```\n\n")

        warm_mean = sum(warm_times) / len(warm_times)
        we = (sum(w_exact) / len(w_exact)) if w_exact else None
        wf = (sum(w_fuzzy) / len(w_fuzzy)) if w_fuzzy else None
        summary.append((label, warm_mean, we, wf, crit_exact_total,
                        crit_fuzzy_total, total_crit, missed_crit_all))
        print()

    # Decision table: FUZZY critical recall first (closest to real operational
    # recall with a fuzzy classifier), then exact critical, then speed.
    def sort_key(r):
        frac = (r[5] / r[6]) if r[6] else 0
        return (-frac, -(r[4]), r[1])
    summary.sort(key=sort_key)

    print("=== Summary (fuzzy critical, then exact critical, then speed) ===")
    report.append("\n## Summary\n\n"
                  "| Config | Warm/img (s) | Weighted exact->fuzzy | "
                  "Critical exact | Critical fuzzy |\n"
                  "|---|---|---|---|---|\n")
    for label, warm, we, wf, ce, cf, ct, missed in summary:
        wes = f"{we * 100:.0f}%" if we is not None else "n/a"
        wfs = f"{wf * 100:.0f}%" if wf is not None else "n/a"
        print(f"  {label:34} warm {warm:6.2f}s  weighted {wes:>4}->{wfs:<4}  "
              f"crit {ce}->{cf}/{ct}")
        report.append(f"| {label} | {warm:.2f} | {wes} -> {wfs} "
                      f"| {ce}/{ct} | {cf}/{ct} |\n")

    # Criticals that fail EVEN WITH fuzzy -- the true blockers.
    report.append("\n### Critical tokens missed even with fuzzy matching\n\n")
    print("\n--- Blockers that survive fuzzy matching ---")
    for label, _, _, _, ce, cf, ct, missed in summary:
        status = "none" if not missed else ", ".join(sorted(set(missed)))
        print(f"  {label:34} {status}")
        report.append(f"- **{label}**: {status}\n")

    Path(args.out).write_text("".join(report), encoding="utf-8")
    print(f"\nWrote {args.out}")


if __name__ == "__main__":
    main()