"""Keyword gate for review text. Conservative word-boundary match only."""

from __future__ import annotations

import re

# Explicit slurs and sexual/obscene terms. Not a general toxicity classifier.
_DISALLOWED = (
    "fuck",
    "fucking",
    "fucker",
    "shit",
    "bullshit",
    "asshole",
    "bitch",
    "bastard",
    "cunt",
    "cock",
    "dick",
    "pussy",
    "whore",
    "slut",
    "nigger",
    "nigga",
    "faggot",
    "retard",
    "rape",
    "rapist",
)

_PATTERN = re.compile(r"\b(" + "|".join(re.escape(w) for w in _DISALLOWED) + r")\b", re.IGNORECASE)


def contains_disallowed_language(*parts: str | None) -> bool:
    text = " ".join(p for p in parts if p)
    return bool(text and _PATTERN.search(text))
