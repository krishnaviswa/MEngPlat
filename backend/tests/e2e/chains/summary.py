"""S-125 — job-summary classification for chain runs.

Fed by hooks in `chains/conftest.py`; rendered to markdown at session finish.

Per test report:
  call passed                         -> PASS
  call failed                         -> FAIL   (layout flips say "functional steps passed; N layout finding(s)")
  call failed with XPASS(strict)      -> FAIL   ("known gap now passes ...")
  call skipped with wasxfail          -> KNOWN-GAP (reason = xfail reason)
  setup/call skipped, no wasxfail     -> SKIPPED
  setup/teardown failed               -> FAIL   (reason prefixed "error:")
Per chain: any FAIL -> FAIL; else main test SKIPPED -> SKIPPED; else any gap test KNOWN-GAP -> KNOWN-GAP; else PASS.
"""

from __future__ import annotations

import os
from dataclasses import dataclass, field
from pathlib import Path

PASS, FAIL, KNOWN_GAP, SKIPPED = "PASS", "FAIL", "KNOWN-GAP", "SKIPPED"
XPASS_MESSAGE = "known gap now passes - remove xfail and update README §14"


@dataclass
class _Result:
    status: str
    reason: str
    is_gap: bool


@dataclass
class WorkflowSummary:
    results: dict[str, list[_Result]] = field(default_factory=dict)
    findings: list[dict] = field(default_factory=list)
    warnings: list[str] = field(default_factory=list)

    # -- feeding ---------------------------------------------------------------
    def add_report(self, chain: str, test_name: str, rep) -> None:
        is_gap = test_name.endswith("_gap")
        wasxfail = getattr(rep, "wasxfail", None)
        text = _longrepr_text(rep)
        if rep.when == "call":
            if rep.passed:
                self._add(chain, PASS, "", is_gap)
            elif rep.failed:
                if "XPASS(strict)" in text:
                    self._add(chain, FAIL, XPASS_MESSAGE, is_gap)
                else:
                    flips = getattr(rep, "wf_layout_flip", 0)
                    reason = (
                        f"functional steps passed; {flips} layout finding(s)"
                        if flips
                        else _first_line(text)
                    )
                    self._add(chain, FAIL, reason, is_gap)
            elif rep.skipped:
                if wasxfail is not None:
                    self._add(chain, KNOWN_GAP, str(wasxfail) or "known gap", is_gap)
                else:
                    self._add(chain, SKIPPED, _skip_reason(rep), is_gap)
        elif rep.when == "setup":
            if rep.skipped and wasxfail is None:
                self._add(chain, SKIPPED, _skip_reason(rep), is_gap)
            elif rep.failed:
                self._add(chain, FAIL, "error: " + _first_line(text), is_gap)
        elif rep.when == "teardown" and rep.failed:
            self._add(chain, FAIL, "error: " + _first_line(text), is_gap)

    def _add(self, chain: str, status: str, reason: str, is_gap: bool) -> None:
        self.results.setdefault(chain, []).append(_Result(status, reason, is_gap))

    def add_findings(self, chain: str, findings: list[dict]) -> None:
        for f in findings:
            self.findings.append({**f, "chain": chain})

    def add_warning(self, text: str) -> None:
        if text not in self.warnings:
            self.warnings.append(text)

    # -- classification ----------------------------------------------------------
    def chain_status(self, chain: str) -> tuple[str, str]:
        rs = self.results.get(chain, [])
        fails = [r for r in rs if r.status == FAIL]
        if fails:
            return FAIL, "; ".join(dict.fromkeys(r.reason for r in fails if r.reason)) or "failed"
        mains = [r for r in rs if not r.is_gap]
        if mains and all(r.status == SKIPPED for r in mains):
            return SKIPPED, mains[0].reason
        gaps = [r for r in rs if r.status == KNOWN_GAP]
        if gaps:
            return KNOWN_GAP, "; ".join(dict.fromkeys(r.reason for r in gaps))
        if rs and all(r.status == SKIPPED for r in rs):
            return SKIPPED, rs[0].reason
        return PASS, ""

    # -- rendering ---------------------------------------------------------------
    def render(self) -> str:
        lines = ["### Cross-role workflow chains", "", "| Chain | Status | Reason |", "| --- | --- | --- |"]
        counts = {PASS: 0, FAIL: 0, KNOWN_GAP: 0, SKIPPED: 0}
        for chain in sorted(self.results):
            status, reason = self.chain_status(chain)
            counts[status] += 1
            lines.append(f"| `{chain}` | **{status}** | {_cell(reason)} |")
        lines += [
            "",
            f"PASS {counts[PASS]} · FAIL {counts[FAIL]} · KNOWN-GAP {counts[KNOWN_GAP]} · SKIPPED {counts[SKIPPED]}",
            "",
            "### Layout findings",
            "",
        ]
        if not self.findings:
            lines.append("No layout findings.")
        else:
            lines += ["| Chain | Page | Width | Rule | Elements / detail |", "| --- | --- | --- | --- | --- |"]
            for f in self.findings:
                where = f"{f.get('url', '')}" + (f" ({f['label']})" if f.get("label") else "")
                lines.append(
                    f"| `{f['chain']}` | `{_cell(where)}` | {f['width']}px | {f['rule']} | {_cell(f['detail'])} |"
                )
        if self.warnings:
            lines += ["", "### Warnings", ""] + [f"- {w}" for w in self.warnings]
        return "\n".join(lines) + "\n"

    def write(self) -> Path | None:
        if not self.results:
            return None
        # Only write when a run asked for it (workflow sets WF_SUMMARY_PATH) or e2e is really on —
        # a default `pytest` (all chains opt-in-skipped) must not litter the working tree.
        if not os.environ.get("WF_SUMMARY_PATH") and os.environ.get("E2E") != "1":
            return None
        path = Path(os.environ.get("WF_SUMMARY_PATH", "workflow-summary.md"))
        path.write_text(self.render(), encoding="utf-8")
        return path


REGISTRY = WorkflowSummary()


def _longrepr_text(rep) -> str:
    lr = getattr(rep, "longrepr", None)
    if lr is None:
        return ""
    try:
        return str(lr)
    except Exception:  # noqa: BLE001
        return ""


def _first_line(text: str) -> str:
    for line in text.splitlines():
        line = line.strip()
        if line.startswith("E "):
            return line[2:].strip()[:240]
        if line.startswith("AssertionError") or line.startswith("Failed"):
            return line[:240]
    lines = [ln.strip() for ln in text.splitlines() if ln.strip()]
    return (lines[-1] if lines else "failed")[:240]


def _skip_reason(rep) -> str:
    lr = getattr(rep, "longrepr", None)
    if isinstance(lr, tuple) and len(lr) == 3:
        return str(lr[2]).replace("Skipped: ", "")[:240]
    return _first_line(_longrepr_text(rep)) or "skipped"


def _cell(text: str) -> str:
    return str(text).replace("|", "\\|").replace("\n", " ")
