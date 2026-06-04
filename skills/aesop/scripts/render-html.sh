#!/usr/bin/env bash
# aesop: render a story markdown file into a self-contained HTML viewer.
# Usage: render-html.sh <story.md> [<out.html>]
#
# The story is plain Markdown (native diff fences, mermaid blocks, a bold caption
# paragraph above each snippet, [N] line references). This viewer upgrades it
# client-side: Mermaid rendering, diff +/- coloring, caption -> header bar, and
# BIDIRECTIONAL, LINE-PRECISE [N] references. A `<!-- aesop:lines N=a-b -->` line
# above a fence (invisible in terminal/GitHub) makes ref N highlight + scroll to
# those exact lines; without it the ref targets the whole snippet. Libraries and
# fonts load from CDN at view time, with full system fallbacks.
set -euo pipefail

SRC="${1:?usage: render-html.sh <story.md> [out.html]}"
OUT="${2:-${SRC%.md}.html}"

# Neutralize any literal closing-script tag so embedded markdown can't break out.
MD="$(sed 's#</script>#<\\/script>#g' "$SRC")"

# --- HEAD (quoted heredoc: everything literal, no shell expansion) ---
cat > "$OUT" <<'HEAD'
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>aesop: PR story</title>
<style>
@import url('https://fonts.googleapis.com/css2?family=Geist:wght@400;500;600;700&family=Geist+Mono:wght@400;500&family=Asar&display=swap');

:root{
  color-scheme:light dark;
  --font-sans:'Geist',ui-sans-serif,system-ui,-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif;
  --font-mono:'Geist Mono',ui-monospace,SFMono-Regular,Menlo,Monaco,Consolas,monospace;
  --font-serif:'Asar',Georgia,'Times New Roman',serif;
  --radius:0.625rem;
  --ease:cubic-bezier(0.16,1,0.3,1);
  /* light: warm cream surfaces */
  --bg:#faf9f6;
  --fg:#43392e;
  --muted-fg:#6f6555;
  --surface-1:#fffefb;
  --surface-2:#f1efe9;
  --code-bg:#fbfaf7;
  --border:rgba(67,57,46,.10);
  --border-subtle:rgba(67,57,46,.06);
  --brand:#2d7a4e;
  --brand-strong:#246340;
  --add-bg:rgba(45,122,78,.10);  --add-fg:#1f7a45;
  --del-bg:rgba(193,58,52,.10);  --del-fg:#bb362f;
  /* sky "key-change" highlight for referenced lines */
  --hl-bg:rgba(14,165,233,.10);  --hl-border:rgba(14,165,233,.45);
  --hl-bg-focus:rgba(59,130,246,.18); --hl-border-focus:rgba(59,130,246,.75);
  --shadow:0 1px 2px rgba(67,57,46,.05),0 4px 16px rgba(67,57,46,.04);
}
@media (prefers-color-scheme:dark){
  :root{
    --bg:#151514;
    --fg:#e7e1d6;
    --muted-fg:#a9a195;
    --surface-1:#1e1d1b;
    --surface-2:#272622;
    --code-bg:#1a1917;
    --border:rgba(255,255,255,.07);
    --border-subtle:rgba(255,255,255,.045);
    --brand:#46a574;
    --brand-strong:#5cb487;
    --add-bg:rgba(70,165,116,.14);  --add-fg:#56c98a;
    --del-bg:rgba(240,90,82,.14);   --del-fg:#f07a72;
    --shadow:0 1px 2px rgba(0,0,0,.3),0 6px 24px rgba(0,0,0,.25);
  }
}

html{scroll-behavior:smooth}
body{max-width:820px;margin:0 auto;padding:3.5rem 1.25rem 6rem;
  background:var(--bg);color:var(--fg);
  font-family:var(--font-sans);font-size:16px;line-height:1.68;
  -webkit-font-smoothing:antialiased;text-rendering:optimizeLegibility}
::selection{background:var(--brand);color:#fff}

h1{font-family:var(--font-serif);font-weight:400;font-size:2.15rem;line-height:1.2;
  letter-spacing:-.01em;margin:0 0 .6rem}
h2{font-family:var(--font-serif);font-weight:400;font-size:1.5rem;line-height:1.3;
  margin:3rem 0 1rem;padding-left:.7rem;border-left:3px solid var(--brand)}
h3{font-weight:600;font-size:1.05rem;margin:2rem 0 .6rem;color:var(--fg)}
p{margin:1rem 0}
a{color:var(--brand);text-decoration:none}
a:hover{color:var(--brand-strong);text-decoration:underline}
strong{font-weight:600}
hr{border:0;border-top:1px solid var(--border);margin:2.5rem 0}

/* inline code + generic fences */
code{font-family:var(--font-mono);font-size:.88em}
:not(pre)>code{background:var(--surface-2);border:1px solid var(--border-subtle);
  border-radius:5px;padding:.08em .38em;font-size:.84em}
pre{background:var(--code-bg);border:1px solid var(--border);border-radius:var(--radius);
  padding:1rem;overflow:auto;font-size:.84rem;line-height:1.55}

/* diff snippet card: caption header + colored body */
.story-diff{border:1px solid var(--border);border-radius:var(--radius);overflow:hidden;
  margin:1.5rem 0;box-shadow:var(--shadow);scroll-margin-top:1.5rem}
.story-diff .cap{background:var(--surface-2);color:var(--muted-fg);
  padding:.55rem .9rem;font-size:.8rem;line-height:1.5;border-bottom:1px solid var(--border)}
.story-diff .cap code{background:transparent;border:0;color:var(--fg);padding:0;font-weight:500}
.story-diff pre{margin:0;border:0;border-radius:0;background:var(--code-bg)}
.add{background:var(--add-bg);color:var(--add-fg);display:block;scroll-margin-top:5rem}
.del{background:var(--del-bg);color:var(--del-fg);display:block;scroll-margin-top:5rem}
.ctx{display:block;color:var(--fg);opacity:.85;scroll-margin-top:5rem}
/* line(s) a prose ref points at: persistent sky accent + flash on navigation */
.ref-line{background:var(--hl-bg);box-shadow:inset 3px 0 0 var(--hl-border)}
.snip-anchor{display:block;height:0;scroll-margin-top:1.5rem}

/* bidirectional reference badges */
a.ref{background:#0ea5e9;color:#fff;border-radius:5px;padding:0 .4rem;margin:0 .05rem;
  font-family:var(--font-mono);font-size:.72rem;font-weight:600;text-decoration:none;
  cursor:pointer;line-height:1.5;display:inline-block;vertical-align:.05em}
a.ref:hover{background:#0284c7;text-decoration:none}
.ref-src{scroll-margin-top:5rem}
@keyframes aesopFlash{
  0%{background:var(--hl-bg-focus);box-shadow:inset 3px 0 0 var(--hl-border-focus),0 0 0 3px var(--hl-border-focus)}
  100%{background:var(--hl-bg);box-shadow:inset 3px 0 0 var(--hl-border),0 0 0 3px transparent}}
.ref-line:target{animation:aesopFlash 1.3s var(--ease) 2}
.ref-src:target{outline:2px solid var(--hl-border-focus);outline-offset:2px;border-radius:4px}
.story-diff:has(.snip-anchor:target){outline:2px solid var(--hl-border-focus);outline-offset:2px}

/* the moral: risk table */
table{border-collapse:collapse;width:100%;margin:1.2rem 0;font-size:.93rem;
  border:1px solid var(--border);border-radius:var(--radius);overflow:hidden}
th,td{border-bottom:1px solid var(--border);padding:.55rem .8rem;text-align:left;vertical-align:top}
th{background:var(--surface-2);font-weight:600}
tr:last-child td{border-bottom:0}

blockquote{border-left:3px solid var(--brand);margin:1.2rem 0;padding:.3rem 1rem;
  color:var(--muted-fg);background:var(--surface-2);border-radius:0 6px 6px 0}

.mermaid{background:var(--surface-1);border:1px solid var(--border);border-radius:var(--radius);
  padding:1.2rem;margin:1.5rem 0;text-align:center;box-shadow:var(--shadow)}
</style>
</head>
<body>
<div id="content">Rendering…</div>
<script id="src" type="text/plain">
HEAD

# --- MD payload (the only expanded part) ---
printf '%s\n' "$MD" >> "$OUT"

# --- TAIL (quoted heredoc: JS backticks/$ stay literal) ---
cat >> "$OUT" <<'TAIL'
</script>
<!-- CDN libs are version-pinned. For a hardened/offline viewer, vendor these
     files locally, OR add Subresource Integrity: fetch the pinned file, compute
     openssl dgst -sha384 -binary file | openssl base64 -A, and set
     integrity="sha384-<hash>" on the <script>. (No fabricated hash here, a
     wrong integrity value silently blocks the script.) -->
<script src="https://cdn.jsdelivr.net/npm/marked@15/marked.min.js" crossorigin="anonymous"></script>
<script type="module">
import mermaid from "https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs";

const md = document.getElementById("src").textContent;
const root = document.getElementById("content");
const esc = s => s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");

// Parse `<!-- aesop:lines N=a-b M=c -->` sidecars from the RAW markdown, in order,
// pairing each with the diff fence it precedes. lineMaps[diffBlockIndex] = {N:[a,b]}.
const lineMaps = [];
{
  let pending = null, idx = -1, inFence = false;
  for (const line of md.split("\n")) {
    const fence = line.match(/^```(\w*)/);
    if (fence) {
      if (!inFence) {
        inFence = true;
        if (fence[1] === "diff") { idx++; lineMaps[idx] = pending || {}; pending = null; }
      } else {
        inFence = false;
      }
      continue;
    }
    if (inFence) continue;
    const m = line.match(/^<!--\s*aesop:lines\s+(.*?)\s*-->/);
    if (m) {
      pending = pending || {};
      for (const pair of m[1].trim().split(/\s+/)) {
        const mm = pair.match(/^(\d+)=(\d+)(?:-(\d+))?$/);
        if (mm) pending[mm[1]] = [parseInt(mm[2], 10), parseInt(mm[3] || mm[2], 10)];
      }
    }
  }
}

root.innerHTML = marked.parse(md);

// 1. Mermaid: code.language-mermaid -> div.mermaid
root.querySelectorAll("pre > code.language-mermaid").forEach(c => {
  const d = document.createElement("div");
  d.className = "mermaid";
  d.textContent = c.textContent;
  c.closest("pre").replaceWith(d);
});

// 2. Diff snippets: wrap each diff fence; lift the preceding <p> into a caption
//    header; color +/- lines; tag the line(s) each ref points at.
const targetNums = new Set();
root.querySelectorAll("pre > code.language-diff").forEach((c, blockIdx) => {
  const pre = c.closest("pre");
  const wrapper = document.createElement("div");
  wrapper.className = "story-diff";
  pre.replaceWith(wrapper);

  // caption = the paragraph immediately above the fence (per the format contract).
  // Each [N] in it is the snippet's back-link to the prose.
  const blockRefs = [];
  const prev = wrapper.previousElementSibling;
  if (prev && prev.tagName === "P") {
    const cap = document.createElement("div");
    cap.className = "cap";
    cap.innerHTML = prev.innerHTML.replace(
      /(?:<code>)?\[(\d+)\](?:<\/code>)?/g,
      (_, n) => {
        targetNums.add(n);
        blockRefs.push(n);
        return '<a class="ref ref-tgt" id="reftgt-' + n + '" href="#refsrc-' + n + '">' + n + '</a>';
      });
    prev.remove();
    wrapper.appendChild(cap);
  }

  // whole-snippet fallback anchors for refs with no explicit line map
  const map = lineMaps[blockIdx] || {};
  const mapped = new Set(Object.keys(map));
  for (const ref of blockRefs) {
    if (!mapped.has(ref)) {
      const a = document.createElement("span");
      a.className = "snip-anchor";
      a.id = "refline-" + ref;
      wrapper.appendChild(a);
    }
  }

  // colored body; the start line of each mapped range carries id="refline-N",
  // every line in a range gets .ref-line.
  const lines = c.textContent.replace(/\n$/, "").split("\n");
  const body = lines.map((ln, j) => {
    const n = j + 1;
    let cls = ln.startsWith("+") ? "add" : ln.startsWith("-") ? "del" : "ctx";
    let id = "";
    for (const ref of Object.keys(map)) {
      const r = map[ref];
      if (n >= r[0] && n <= r[1]) {
        cls += " ref-line";
        if (n === r[0]) id = ' id="refline-' + ref + '"';
      }
    }
    return '<span class="' + cls + '"' + id + '>' + esc(ln) + '</span>';
  }).join("\n");
  const bodyPre = document.createElement("pre");
  const bodyCode = document.createElement("code");
  bodyCode.innerHTML = body;
  bodyPre.appendChild(bodyCode);
  wrapper.appendChild(bodyPre);
});

// 3. Prose [N] -> source link to the exact line(s) (#refline-N). Only numbers a
//    caption claimed. Walk text nodes outside PRE/CODE/A so arr[0] is untouched.
const seen = new Set();
const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT, {
  acceptNode(n) {
    if (!n.nodeValue.includes("[")) return NodeFilter.FILTER_REJECT;
    for (let p = n.parentElement; p && p !== root; p = p.parentElement) {
      if (p.tagName === "PRE" || p.tagName === "CODE" || p.tagName === "A")
        return NodeFilter.FILTER_REJECT;
    }
    return NodeFilter.FILTER_ACCEPT;
  }
});
const textNodes = [];
while (walker.nextNode()) textNodes.push(walker.currentNode);
for (const node of textNodes) {
  const parts = node.nodeValue.split(/(\[\d+\])/);
  if (parts.length < 2) continue;
  const frag = document.createDocumentFragment();
  for (const part of parts) {
    const m = part.match(/^\[(\d+)\]$/);
    if (m && targetNums.has(m[1])) {
      const a = document.createElement("a");
      a.className = "ref ref-src";
      a.textContent = m[1];
      a.href = "#refline-" + m[1];
      if (!seen.has(m[1])) { a.id = "refsrc-" + m[1]; seen.add(m[1]); }
      frag.appendChild(a);
    } else if (part) {
      frag.appendChild(document.createTextNode(part));
    }
  }
  node.replaceWith(frag);
}

const dark = matchMedia("(prefers-color-scheme: dark)").matches;
mermaid.initialize({
  startOnLoad: false,
  theme: dark ? "dark" : "neutral",
  themeVariables: {
    primaryColor: dark ? "#46a574" : "#2d7a4e",
    primaryTextColor: dark ? "#e7e1d6" : "#43392e",
    lineColor: dark ? "#6f6f6f" : "#9c948a",
    fontFamily: "Geist, ui-sans-serif, system-ui, sans-serif"
  }
});
mermaid.run();
</script>
</body>
</html>
TAIL

echo "$OUT"
