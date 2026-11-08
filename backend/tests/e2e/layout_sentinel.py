"""S-125 — layout sentinel: read-only DOM checks for overlap, clipping and horizontal scroll.

`check_layout(page)` resizes the viewport to 375 / 768 / 1280, runs one in-page scan per
width, restores the original viewport and returns a list of JSON-serialisable findings.
It never navigates, never raises on findings and never mutates the app.

Rules (ids are stable strings used by the workflow summary):
  horizontal-scroll      document is wider than the viewport
  overlap                two visible controls / text blocks intersect and neither contains the other
  clipped-text           text or a control is cut off by its own or an ancestor's overflow
  offscreen-interactive  a control sits outside the viewport horizontally (not in a scroller)
"""

from __future__ import annotations

from typing import Any

WIDTHS = (375, 768, 1280)
HEIGHTS = {375: 812, 768: 1024, 1280: 800}

# --- thresholds (reviewable constants) ---------------------------------------
OVERLAP_MIN_SIDE_PX = 2        # intersection must be at least this wide AND this tall
OVERLAP_MIN_AREA_PX2 = 16      # ... and larger than this area
OVERLAP_MIN_FRACTION = 0.05    # ... and cover >= 5% of the smaller rect (kills 1px borders)
MAX_OVERLAP_FINDINGS = 20      # per page+width
MAX_CANDIDATES = 3000          # per page+width
CLIP_TOLERANCE_PX = 2

_JS = r"""
(args) => {
  const A = args;
  const findings = [];
  const vw = window.innerWidth;
  const INTERACTIVE = 'a[href], button, input:not([type=hidden]), select, textarea, summary, ' +
    '[role=button], [role=link], [role=tab], [role=menuitem], [role=checkbox], [role=switch], ' +
    '[tabindex]:not([tabindex="-1"])';
  const SKIP_TAGS = new Set(['SCRIPT','STYLE','NOSCRIPT','TEMPLATE','OPTION','HEAD','TITLE','META','LINK']);

  const cssPath = (el) => {
    const parts = [];
    let cur = el;
    for (let depth = 0; cur && cur.nodeType === 1 && depth < 3; depth++, cur = cur.parentElement) {
      let s = cur.tagName.toLowerCase();
      if (cur.id) s += '#' + cur.id;
      const cls = (typeof cur.className === 'string' ? cur.className : '').trim().split(/\s+/).filter(Boolean).slice(0, 3);
      if (cls.length) s += '.' + cls.join('.');
      parts.unshift(s);
    }
    return parts.join(' > ');
  };
  const nameOf = (el) => {
    const v = el.getAttribute('aria-label') || el.getAttribute('alt') || el.getAttribute('placeholder') ||
      (el.value && typeof el.value === 'string' ? el.value : '') || (el.innerText || el.textContent || '');
    return v.replace(/\s+/g, ' ').trim().slice(0, 40);
  };
  const describe = (el) => ({
    tag: el.tagName.toLowerCase(), name: nameOf(el),
    text: (el.innerText || '').replace(/\s+/g, ' ').trim().slice(0, 60), path: cssPath(el),
  });
  const ignored = (el) => A.ignore.length > 0 && A.ignore.some((s) => { try { return el.closest(s); } catch (e) { return false; } });
  const hiddenByAttr = (el) => !!el.closest('[aria-hidden="true"], [inert], [hidden]');
  const visible = (el) => {
    if (typeof el.checkVisibility === 'function') {
      if (!el.checkVisibility({ checkOpacity: true, checkVisibilityCSS: true })) return false;
    }
    return !hiddenByAttr(el) && !ignored(el);
  };
  const okRect = (r) => r.width >= 2 && r.height >= 2;
  const rectObj = (r) => ({ left: r.left, top: r.top, right: r.right, bottom: r.bottom, width: r.width, height: r.height });
  const fixedRoot = (el) => {
    for (let cur = el; cur && cur.nodeType === 1; cur = cur.parentElement) {
      const p = getComputedStyle(cur).position;
      if (p === 'fixed' || p === 'sticky') return cur;
    }
    return null;
  };
  const scrollerAncestor = (el) => {
    for (let cur = el.parentElement; cur && cur !== document.body && cur !== document.documentElement; cur = cur.parentElement) {
      const ox = getComputedStyle(cur).overflowX;
      if (ox === 'auto' || ox === 'scroll' || ox === 'hidden' || ox === 'clip') return cur;
    }
    return null;
  };
  const push = (rule, detail, a, b) => findings.push({ rule, detail, a: describe(a), b: b ? describe(b) : null });

  // ---- 1. horizontal scroll -------------------------------------------------
  const sw = document.documentElement.scrollWidth;
  if (sw > vw + 1) {
    const offenders = [];
    for (const el of document.body.querySelectorAll('*')) {
      if (SKIP_TAGS.has(el.tagName)) continue;
      const r = el.getBoundingClientRect();
      if (r.right > vw + 1 && okRect(r) && visible(el)) offenders.push({ el, right: r.right });
    }
    offenders.sort((x, y) => y.right - x.right);
    const top = offenders.slice(0, 3).map((o) => `"${nameOf(o.el)}" (${cssPath(o.el)}) right=${Math.round(o.right)}`);
    push('horizontal-scroll', `scrollWidth=${sw} innerWidth=${vw}` + (top.length ? `; widest: ${top.join('; ')}` : ''), document.documentElement, null);
  }

  // ---- candidate sets ---------------------------------------------------------
  const items = new Map();   // el -> { el, interactive, rects }
  let truncated = false;
  const consider = (el) => {
    if (items.size >= A.maxCandidates) { truncated = true; return; }
    if (!visible(el)) return;
    const interactive = el.matches(INTERACTIVE);
    let rects = [];
    if (interactive) {
      const r = el.getBoundingClientRect();
      if (okRect(r)) rects = [rectObj(r)];
    } else {
      const range = document.createRange();
      for (const n of el.childNodes) {
        if (n.nodeType === 3 && n.nodeValue.trim()) {
          range.selectNodeContents(n);
          for (const r of range.getClientRects()) if (okRect(r)) rects.push(rectObj(r));
        }
      }
    }
    if (!rects.length) return;
    items.set(el, { el, interactive, rects });
  };
  for (const el of document.body.querySelectorAll('*')) {
    if (SKIP_TAGS.has(el.tagName) || el.closest('svg') ) continue;
    if (el.matches(INTERACTIVE)) { consider(el); continue; }
    for (const n of el.childNodes) {
      if (n.nodeType === 3 && n.nodeValue.trim()) { consider(el); break; }
    }
  }
  const list = [...items.values()];

  // ---- 2. overlap ---------------------------------------------------------------
  const bounds = list.map((it) => ({
    it,
    top: Math.min(...it.rects.map((r) => r.top)),
    bottom: Math.max(...it.rects.map((r) => r.bottom)),
  })).sort((x, y) => x.top - y.top);
  let overlapCount = 0, overlapExtra = 0;
  const seen = new Set();
  for (let i = 0; i < bounds.length; i++) {
    for (let j = i + 1; j < bounds.length && bounds[j].top < bounds[i].bottom; j++) {
      const a = bounds[i].it, b = bounds[j].it;
      if (a.el.contains(b.el) || b.el.contains(a.el)) continue;
      if (fixedRoot(a.el) !== fixedRoot(b.el)) continue;     // floating layer vs page flow: by design
      let best = null;
      for (const ra of a.rects) for (const rb of b.rects) {
        const w = Math.min(ra.right, rb.right) - Math.max(ra.left, rb.left);
        const h = Math.min(ra.bottom, rb.bottom) - Math.max(ra.top, rb.top);
        if (w < A.minSide || h < A.minSide) continue;
        const area = w * h;
        if (area <= A.minArea) continue;
        const smaller = Math.min(ra.width * ra.height, rb.width * rb.height);
        if (area < A.minFraction * smaller) continue;
        if (!best || area > best.area) best = { w, h, area };
      }
      if (!best) continue;
      if (overlapCount >= A.maxOverlap) { overlapExtra++; continue; }
      overlapCount++;
      push('overlap', `"${nameOf(a.el)}" (${cssPath(a.el)}) overlaps "${nameOf(b.el)}" (${cssPath(b.el)}) by ${Math.round(best.w)}x${Math.round(best.h)}px`, a.el, b.el);
    }
  }
  if (overlapExtra) {
    const last = findings.filter((f) => f.rule === 'overlap').pop();
    if (last) last.detail += ` (+${overlapExtra} more overlap(s) not listed)`;
  }

  // ---- 3. clipped text ----------------------------------------------------------
  const clipVals = new Set(['hidden', 'clip']);
  for (const it of list) {
    const el = it.el;
    const cs = getComputedStyle(el);
    const ellipsis = cs.textOverflow === 'ellipsis';
    if (clipVals.has(cs.overflowX) && el.clientWidth > 0 && el.scrollWidth > el.clientWidth + A.clipTol && !(ellipsis && !it.interactive)) {
      push('clipped-text', `content is ${el.scrollWidth}px wide inside a ${el.clientWidth}px box with overflow:${cs.overflowX}`, el, null);
      continue;
    }
    const lineClamp = cs.getPropertyValue('-webkit-line-clamp');
    if (clipVals.has(cs.overflowY) && el.clientHeight > 0 && el.scrollHeight > el.clientHeight + A.clipTol && (!lineClamp || lineClamp === 'none')) {
      push('clipped-text', `content is ${el.scrollHeight}px tall inside a ${el.clientHeight}px box with overflow:${cs.overflowY}`, el, null);
      continue;
    }
    if (!it.interactive) {
      for (let anc = el.parentElement; anc && anc !== document.body && anc !== document.documentElement; anc = anc.parentElement) {
        const ox = getComputedStyle(anc).overflowX;
        if (ox !== 'hidden' && ox !== 'clip') continue;
        const ar = anc.getBoundingClientRect();
        const cut = it.rects.some((r) => r.right > ar.right + A.clipTol || r.left < ar.left - A.clipTol);
        if (cut) push('clipped-text', 'text is cut off by an ancestor with overflow:' + ox, el, anc);
        break;
      }
    }
  }

  // ---- 4. offscreen interactive ---------------------------------------------------
  for (const it of list) {
    if (!it.interactive) continue;
    const r = it.rects[0];
    if (r.right > vw + 1 || r.left < -1) {
      if (scrollerAncestor(it.el)) continue;
      push('offscreen-interactive', `control spans x=${Math.round(r.left)}..${Math.round(r.right)} with a ${vw}px viewport`, it.el, null);
    }
  }
  return { findings, truncated };
}
"""


def _settle(page: Any) -> None:
    """Let fonts + two animation frames settle after a resize — no sleeps."""
    page.evaluate(
        "() => document.fonts.ready.then(() => new Promise(r => requestAnimationFrame(() => requestAnimationFrame(r))))"
    )
    page.evaluate("() => window.scrollTo(0, 0)")


def _path_of(url: str) -> str:
    # path + query, no scheme/host — keeps summaries stable across localhost / runner hosts
    rest = url.split("://", 1)[-1]
    slash = rest.find("/")
    return rest[slash:] if slash >= 0 else "/"


def check_layout_at(page: Any, width: int, *, ignore_selectors: tuple[str, ...] = (), label: str = "") -> list[dict]:
    """Scan at one width without restoring the viewport (use `check_layout` normally)."""
    page.set_viewport_size({"width": width, "height": HEIGHTS.get(width, 800)})
    _settle(page)
    result = page.evaluate(
        _JS,
        {
            "ignore": list(ignore_selectors),
            "maxCandidates": MAX_CANDIDATES,
            "maxOverlap": MAX_OVERLAP_FINDINGS,
            "minSide": OVERLAP_MIN_SIDE_PX,
            "minArea": OVERLAP_MIN_AREA_PX2,
            "minFraction": OVERLAP_MIN_FRACTION,
            "clipTol": CLIP_TOLERANCE_PX,
        },
    )
    check_layout.last_truncated = check_layout.last_truncated or bool(result["truncated"])
    url = _path_of(page.url)
    out = []
    for f in result["findings"]:
        out.append({**f, "url": url, "width": width, "label": label})
    return out


def check_layout(
    page: Any,
    *,
    widths: tuple[int, ...] = WIDTHS,
    label: str = "",
    ignore_selectors: tuple[str, ...] = (),
) -> list[dict]:
    """Scan the current page at each width; always restores the original viewport."""
    check_layout.last_truncated = False
    orig = page.viewport_size or {"width": 1280, "height": 720}
    findings: list[dict] = []
    try:
        for w in widths:
            findings.extend(check_layout_at(page, w, ignore_selectors=ignore_selectors, label=label))
    finally:
        page.set_viewport_size(orig)
    return findings


check_layout.last_truncated = False  # type: ignore[attr-defined]
