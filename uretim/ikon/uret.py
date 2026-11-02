#!/usr/bin/env python3
"""SpeedLab ikonu (2 · Lab kadranı) — taslak docs/superpowers/specs/2026-11-02-ikon-taslak.html `icon2`.

Üretir (uretim/ikon/cikti/):
  icon2.svg              tam ikon, 1024×1024
  AppIcon.png            tam ikon, opak sRGB (Assets AppIcon.appiconset'e kopyalanır)
  katman-*.png           Icon Composer katmanları (şeffaf zemin): zemin, cam, skala, dolum-ibre, gobek
  IkonKucuk.png          256 px şeffaf küçük logo (widget / paylaşım kartı)

Kullanım: python3 uretim/ikon/uret.py   (rsvg-convert gerekir: brew install librsvg)
"""
import math, os, subprocess, pathlib

OUT = pathlib.Path(__file__).parent / "cikti"
OUT.mkdir(exist_ok=True)

CX, CY, R = 512, 560, 400
START, SWEEP, FV = -135, 270, 0.68
LOGMAX = math.log10(1001)


def frac(v):
    return math.log10(v + 1) / LOGMAX


def ang(f):
    return (START + f * SWEEP - 90) * math.pi / 180


def pt(f, r):
    a = ang(f)
    return CX + r * math.cos(a), CY + r * math.sin(a)


def arc(f0, f1, r):
    x0, y0 = pt(f0, r)
    x1, y1 = pt(f1, r)
    la = 1 if (f1 - f0) * SWEEP > 180 else 0
    return f"M{x0:.2f} {y0:.2f}A{r} {r} 0 {la} 1 {x1:.2f} {y1:.2f}"


DEFS = """
<defs>
  <radialGradient id="r" cx=".5" cy=".35" r=".7">
    <stop offset="0" stop-color="#2a3270"/><stop offset="1" stop-color="#070a1c"/>
  </radialGradient>
  <linearGradient id="g" x1="0" y1="1" x2="1" y2="0">
    <stop offset="0" stop-color="#6366F1"/><stop offset=".5" stop-color="#3B82F6"/><stop offset="1" stop-color="#22d3ee"/>
  </linearGradient>
  <filter id="f" x="-60%" y="-60%" width="220%" height="220%"><feGaussianBlur stdDeviation="34"/></filter>
  <filter id="f2" x="-60%" y="-60%" width="220%" height="220%">
    <feGaussianBlur stdDeviation="12" result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge>
  </filter>
</defs>"""


def layer_zemin():
    return '<rect width="1024" height="1024" fill="url(#r)"/>'


def layer_cam():
    return f'<circle cx="{CX}" cy="{CY}" r="470" fill="rgba(255,255,255,0.035)" stroke="rgba(255,255,255,0.08)" stroke-width="4"/>'


def layer_skala():
    parts = [f'<path d="{arc(0, 1, R)}" fill="none" stroke="rgba(255,255,255,0.10)" stroke-width="30" stroke-linecap="round"/>']
    for i in range(37):
        f = i / 36
        major = i % 6 == 0
        x0, y0 = pt(f, R - 50)
        x1, y1 = pt(f, R - (100 if major else 76))
        lit = f <= FV
        col = "rgba(34,211,238,0.95)" if lit else "rgba(255,255,255,0.28)"
        parts.append(f'<line x1="{x0:.1f}" y1="{y0:.1f}" x2="{x1:.1f}" y2="{y1:.1f}" stroke="{col}" stroke-width="{12 if major else 6}" stroke-linecap="round"/>')
    return "\n".join(parts)


def layer_dolum_ibre():
    parts = [
        f'<path d="{arc(0, FV, R)}" fill="none" stroke="url(#g)" stroke-width="30" stroke-linecap="round" opacity=".6" filter="url(#f)"/>',
        f'<path d="{arc(0, FV, R)}" fill="none" stroke="url(#g)" stroke-width="30" stroke-linecap="round"/>',
        f'<path d="{arc(FV - .06, FV, R)}" fill="none" stroke="#fff" stroke-width="30" stroke-linecap="round" opacity=".9" filter="url(#f2)"/>',
    ]
    nx, ny = pt(FV, R - 70)
    parts.append(f'<line x1="{CX}" y1="{CY}" x2="{nx:.1f}" y2="{ny:.1f}" stroke="#22d3ee" stroke-width="30" stroke-linecap="round" opacity=".55" filter="url(#f)"/>')
    parts.append(f'<line x1="{CX}" y1="{CY}" x2="{nx:.1f}" y2="{ny:.1f}" stroke="#fff" stroke-width="16" stroke-linecap="round"/>')
    return "\n".join(parts)


def layer_gobek():
    return (f'<circle cx="{CX}" cy="{CY}" r="52" fill="#0b0f26" stroke="#22d3ee" stroke-width="14"/>'
            f'<circle cx="{CX}" cy="{CY}" r="16" fill="#22d3ee"/>')


LAYERS = [("zemin", layer_zemin), ("cam", layer_cam), ("skala", layer_skala), ("dolum-ibre", layer_dolum_ibre), ("gobek", layer_gobek)]


def svg(body):
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">{DEFS}\n{body}\n</svg>'


def render(svg_path, png_path, size=1024):
    subprocess.run(["rsvg-convert", "-w", str(size), "-h", str(size), "-o", str(png_path), str(svg_path)], check=True)


# Tam ikon
full = OUT / "icon2.svg"
full.write_text(svg("\n".join(fn() for _, fn in LAYERS)), encoding="utf-8")
render(full, OUT / "AppIcon.png")

# Katmanlar (şeffaf)
for name, fn in LAYERS:
    p = OUT / f"katman-{name}.svg"
    p.write_text(svg(fn()), encoding="utf-8")
    render(p, OUT / f"katman-{name}.png")

# Küçük logo: zemin yok, skala+dolum+ibre+göbek
small = OUT / "IkonKucuk.svg"
small.write_text(svg("\n".join(fn() for n, fn in LAYERS if n not in ("zemin", "cam"))), encoding="utf-8")
render(small, OUT / "IkonKucuk.png", 256)

# AppIcon alfa kanalını düşür (App Store opak ister)
subprocess.run(["sips", "-s", "format", "png", str(OUT / "AppIcon.png"), "--out", str(OUT / "AppIcon.png")], check=True, capture_output=True)
print("üretildi:", sorted(p.name for p in OUT.iterdir()))
