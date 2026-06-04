#!/usr/bin/env bash
# aesop: render a story markdown file into a self-contained HTML viewer.
# Usage: render-html.sh <story.md> [<out.html>]
# Renders Markdown (marked), Mermaid diagrams, and story-diff blocks with
# +/- coloring and line-reference badges. Libraries loaded from CDN at view time.
set -euo pipefail

SRC="${1:?usage: render-html.sh <story.md> [out.html]}"
OUT="${2:-${SRC%.md}.html}"

# Neutralize any literal closing-script tag so embedded markdown can't break out.
MD="$(sed 's#</script>#<\\/script>#g' "$SRC")"

cat > "$OUT" <<HTML
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>aesop — PR story</title>
<style>
  :root{color-scheme:light dark}
  body{max-width:880px;margin:2rem auto;padding:0 1rem;
    font:16px/1.6 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif}
  pre{background:#0d1117;color:#e6edf3;padding:1rem;border-radius:8px;overflow:auto}
  code{font-family:ui-monospace,SFMono-Regular,Menlo,monospace}
  .story-diff{border:1px solid #30363d;padding:0}
  .story-diff .cap{display:block;background:#161b22;color:#8b949e;
    padding:.4rem .8rem;font-size:.8rem;border-bottom:1px solid #30363d}
  .story-diff .body{display:block;padding:1rem}
  .add{background:rgba(46,160,67,.15);color:#3fb950;display:block}
  .del{background:rgba(248,81,73,.15);color:#f85149;display:block}
  .ref{background:#bb8009;color:#fff;border-radius:4px;padding:0 .35rem;
    font-size:.78rem;font-weight:700}
  table{border-collapse:collapse;width:100%}
  th,td{border:1px solid #30363d;padding:.4rem .6rem;text-align:left}
  blockquote{border-left:4px solid #888;margin:0;padding:.2rem 1rem;color:#888}
  .mermaid{background:#fff;border-radius:8px;padding:1rem;text-align:center}
</style>
</head>
<body>
<div id="content">Rendering…</div>
<script id="src" type="text/plain">
$MD
</script>
<!-- CDN libs are version-pinned. For a hardened/offline viewer, vendor these
     files locally, OR add Subresource Integrity: fetch the pinned file, compute
     openssl dgst -sha384 -binary file | openssl base64 -A, and set
     integrity="sha384-<hash>" on the <script>. (No fabricated hash here — a
     wrong integrity value silently blocks the script.) -->
<script src="https://cdn.jsdelivr.net/npm/marked@15/marked.min.js" crossorigin="anonymous"></script>
<script type="module">
import mermaid from "https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs";
const md = document.getElementById("src").textContent;
// Prose [N] markers: marked turns **[N]** into <strong>[N]</strong>.
const html = marked.parse(md)
  .replace(/<strong>\[(\d+)\]<\/strong>/g, '<span class="ref">\$1</span>');
const root = document.getElementById("content");
root.innerHTML = html;

// Mermaid: code.language-mermaid -> div.mermaid
root.querySelectorAll("pre > code.language-mermaid").forEach(c => {
  const d = document.createElement("div");
  d.className = "mermaid";
  d.textContent = c.textContent;
  c.closest("pre").replaceWith(d);
});

// story-diff: lift metadata caption, color +/- lines, render <!--ref:N-->
const esc = s => s.replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;");
root.querySelectorAll("pre > code.language-story-diff").forEach(c => {
  c.closest("pre").classList.add("story-diff");
  let cap = "";
  const body = [];
  for (const ln of c.textContent.split("\n")) {
    const m = ln.match(/^<!--\s*(\{.*\})\s*-->\$/);
    if (m) { try { cap = JSON.parse(m[1]).description || ""; } catch (e) {} continue; }
    body.push(ln);
  }
  const rendered = body.map(ln => {
    const cls = ln.startsWith("+") ? "add" : ln.startsWith("-") ? "del" : "";
    const t = esc(ln).replace(/&lt;!--ref:(\d+)--&gt;/g, '<span class="ref">\$1</span>');
    return cls ? '<span class="'+cls+'">'+t+'</span>' : t;
  }).join("\n");
  c.innerHTML = (cap ? '<span class="cap">'+esc(cap)+'</span>' : "") +
    '<span class="body">'+rendered+'</span>';
});

mermaid.initialize({ startOnLoad: false });
mermaid.run();
</script>
</body>
</html>
HTML

echo "$OUT"
