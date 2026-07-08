import json
from pathlib import Path

import pytest

from paddle_bakeoff import match_token

FIXTURE = Path(__file__).resolve().parents[2] / "spec" / "fixtures" / "fuzzy_vectors.json"


def _matches(pattern, text, ratio, is_regex):
    tok = {"pattern": pattern, "regex": is_regex}
    _exact, fuzzy = match_token(tok, text, ratio)
    return fuzzy


def _load_vectors():
    vectors = json.loads(FIXTURE.read_text(encoding="utf-8"))
    return [
        pytest.param(v, id=f"{v['pattern']!r}|{v['text'][:30]!r}|ratio={v['ratio']}")
        for v in vectors
    ]


@pytest.mark.parametrize("vec", _load_vectors())
def test_fuzzy_vector(vec):
    result = _matches(
        vec["pattern"],
        vec["text"],
        vec["ratio"],
        vec.get("regex", False),
    )
    assert result == vec["expected"], (
        f"pattern={vec['pattern']!r} text={vec['text']!r} "
        f"ratio={vec['ratio']} regex={vec.get('regex', False)} "
        f"got={result} expected={vec['expected']}"
    )
