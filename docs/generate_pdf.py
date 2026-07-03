#!/usr/bin/env python3
"""
Generate the project documentation PDF for the GCP three-tier platform.

Usage:
    python docs/generate_pdf.py

Produces: docs/Project-Documentation.pdf
Requires: reportlab  (pip install reportlab)
"""

import os
from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_JUSTIFY
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import cm, mm
from reportlab.platypus import (
    BaseDocTemplate, PageTemplate, Frame, Paragraph, Spacer, Table, TableStyle,
    PageBreak, ListFlowable, ListItem, KeepTogether, Flowable,
)

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "Project-Documentation.pdf")

# ---------------------------------------------------------------------------
# Palette
# ---------------------------------------------------------------------------
GCP_BLUE = colors.HexColor("#1a73e8")
GCP_DARK = colors.HexColor("#174ea6")
GCP_GREEN = colors.HexColor("#188038")
GCP_RED = colors.HexColor("#d93025")
GCP_YELLOW = colors.HexColor("#f9ab00")
GREY_BG = colors.HexColor("#f1f3f4")
GREY_LINE = colors.HexColor("#dadce0")
INK = colors.HexColor("#202124")
SUBTLE = colors.HexColor("#5f6368")

# ---------------------------------------------------------------------------
# Styles
# ---------------------------------------------------------------------------
styles = getSampleStyleSheet()


def style(name, **kw):
    styles.add(ParagraphStyle(name, **kw))


style("Cover", parent=styles["Title"], fontSize=30, leading=36, textColor=GCP_DARK,
      alignment=TA_CENTER, spaceAfter=10)
style("CoverSub", fontName="Helvetica", fontSize=14, leading=20, textColor=SUBTLE,
      alignment=TA_CENTER)
style("H1", fontName="Helvetica-Bold", fontSize=18, leading=22, textColor=GCP_DARK,
      spaceBefore=6, spaceAfter=10)
style("H2", fontName="Helvetica-Bold", fontSize=13.5, leading=17, textColor=INK,
      spaceBefore=12, spaceAfter=6)
style("H3", fontName="Helvetica-Bold", fontSize=11.5, leading=15, textColor=GCP_BLUE,
      spaceBefore=8, spaceAfter=4)
style("Body", parent=styles["BodyText"], fontName="Helvetica", fontSize=10,
      leading=14.5, textColor=INK, alignment=TA_JUSTIFY, spaceAfter=6)
style("Bul", parent=styles["BodyText"], fontName="Helvetica", fontSize=10,
      leading=14, textColor=INK, spaceAfter=2)
style("Small", fontName="Helvetica", fontSize=8.5, leading=11, textColor=SUBTLE)
style("TableCell", fontName="Helvetica", fontSize=8.5, leading=11, textColor=INK)
style("TableCellB", fontName="Helvetica-Bold", fontSize=8.5, leading=11, textColor=INK)
style("TableHead", fontName="Helvetica-Bold", fontSize=9, leading=11,
      textColor=colors.white)
style("Mono", fontName="Courier", fontSize=8.5, leading=12, textColor=INK,
      backColor=GREY_BG)
style("TOCItem", fontName="Helvetica", fontSize=10.5, leading=18, textColor=INK)


def P(text, s="Body"):
    return Paragraph(text, styles[s])


def cell(text, s="TableCell"):
    return Paragraph(text, styles[s])


def bullets(items, s="Bul"):
    return ListFlowable(
        [ListItem(P(i, s), leftIndent=6, value="•") for i in items],
        bulletType="bullet", start="•", leftIndent=12,
    )


# ---------------------------------------------------------------------------
# Architecture diagram (drawn flowable)
# ---------------------------------------------------------------------------
class ArchitectureDiagram(Flowable):
    """A detailed VPC network schematic with color-coded traffic-flow lines."""

    def __init__(self, width=17 * cm, height=21.5 * cm):
        super().__init__()
        self.width = width
        self.height = height

    # -- primitives ---------------------------------------------------------
    def _box(self, c, x, y, w, h, title, subs=None, fill=GCP_BLUE,
             tcol=colors.white, fs=8.5, sfs=6.6, dash=False, radius=5):
        c.saveState()
        c.setFillColor(fill)
        c.setStrokeColor(fill if not dash else SUBTLE)
        if dash:
            c.setDash(3, 2)
            c.setLineWidth(1)
        c.roundRect(x, y, w, h, radius, fill=(0 if dash else 1),
                    stroke=1)
        c.setDash()
        cx = x + w / 2
        c.setFillColor(tcol)
        c.setFont("Helvetica-Bold", fs)
        c.drawCentredString(cx, y + h - fs - 3, title)
        if subs:
            c.setFont("Helvetica", sfs)
            for i, s in enumerate(subs):
                c.drawCentredString(cx, y + h - fs - 6 - (i + 1) * (sfs + 2.2), s)
        c.restoreState()

    def _arrowhead(self, c, x, y, ang, color, size=5):
        import math
        c.saveState()
        c.setFillColor(color)
        c.translate(x, y)
        c.rotate(math.degrees(ang))
        p = c.beginPath()
        p.moveTo(0, 0)
        p.lineTo(-size, size * 0.55)
        p.lineTo(-size, -size * 0.55)
        p.close()
        c.drawPath(p, fill=1, stroke=0)
        c.restoreState()

    def _flow(self, c, pts, color, width=1.3, dash=None, arrow=True):
        import math
        c.saveState()
        c.setStrokeColor(color)
        c.setLineWidth(width)
        c.setLineCap(1)
        c.setLineJoin(1)
        if dash:
            c.setDash(*dash)
        path = c.beginPath()
        path.moveTo(*pts[0])
        for pt in pts[1:]:
            path.lineTo(*pt)
        c.drawPath(path, stroke=1, fill=0)
        c.setDash()
        c.restoreState()
        if arrow:
            (x1, y1), (x2, y2) = pts[-2], pts[-1]
            self._arrowhead(c, x2, y2, math.atan2(y2 - y1, x2 - x1), color)

    def _badge(self, c, x, y, n, color, r=6.5):
        c.saveState()
        c.setFillColor(color)
        c.circle(x, y, r, fill=1, stroke=0)
        c.setFillColor(colors.white)
        c.setFont("Helvetica-Bold", 8)
        c.drawCentredString(x, y - 2.9, str(n))
        c.restoreState()

    def _label(self, c, x, y, text, color=INK):
        c.saveState()
        c.setFont("Helvetica-Bold", 6.4)
        w = c.stringWidth(text, "Helvetica-Bold", 6.4) + 4
        c.setFillColor(colors.white)
        c.rect(x - w / 2, y - 3.2, w, 9, fill=1, stroke=0)
        c.setFillColor(color)
        c.drawCentredString(x, y, text)
        c.restoreState()

    def _cloud(self, c, cx, cy, text):
        c.saveState()
        c.setStrokeColor(SUBTLE)
        c.setFillColor(colors.HexColor("#e8f0fe"))
        c.setLineWidth(1)
        for dx, dy, r in [(-26, 0, 15), (-6, 6, 17), (16, 2, 15),
                          (28, -4, 12), (0, -6, 18)]:
            c.circle(cx + dx, cy + dy, r, fill=1, stroke=0)
        c.setFillColor(INK)
        c.setFont("Helvetica-Bold", 8.5)
        c.drawCentredString(cx, cy - 2, text)
        c.restoreState()

    # -- layout -------------------------------------------------------------
    def draw(self):
        c = self.canv
        k = cm

        mx = 5.55 * k                     # main column centre
        # main edge boxes
        ex, ew = 2.0 * k, 7.1 * k
        # subnet band geometry
        sbx, sbw = 1.45 * k, 8.2 * k
        # MIG inner box
        migx, migw = 2.7 * k, 5.8 * k
        # right services column
        rx0, rw = 11.05 * k, 5.5 * k
        rxc = rx0 + rw / 2

        # ---- Internet + Admin (top) ----
        self._cloud(c, mx, 20.7 * k, "Internet / Users")
        self._box(c, rx0, 20.1 * k, rw, 1.05 * k, "Operators / Admins",
                  ["identity-based access"], fill=INK)

        # ---- Edge (outside VPC) ----
        self._box(c, ex, 18.55 * k, ew, 1.05 * k, "Cloud Armor  —  Edge WAF",
                  ["OWASP CRS · rate limiting · adaptive L7 DDoS"], fill=GCP_RED)
        self._box(c, ex, 17.05 * k, ew, 1.05 * k, "Global HTTPS Load Balancer",
                  ["managed TLS 1.2+ · HTTP→HTTPS · Cloud CDN"], fill=GCP_BLUE)

        # ---- VPC boundary ----
        vpc_x, vpc_y, vpc_w, vpc_h = 0.75 * k, 1.15 * k, 9.15 * k, 15.4 * k
        c.saveState()
        c.setStrokeColor(GCP_DARK)
        c.setDash(4, 3)
        c.setLineWidth(1.3)
        c.setFillColor(colors.HexColor("#f7faff"))
        c.roundRect(vpc_x, vpc_y, vpc_w, vpc_h, 8, fill=1, stroke=1)
        c.setDash()
        c.setFillColor(GCP_DARK)
        c.setFont("Helvetica-Bold", 8)
        c.drawString(vpc_x + 6, vpc_y + vpc_h - 12, "VPC  ·  three-tier-vpc  (custom-mode)")
        c.restoreState()

        def subnet_band(y, h, label):
            c.saveState()
            c.setStrokeColor(GCP_GREEN)
            c.setDash(2, 2)
            c.setFillColor(colors.HexColor("#eef7ee"))
            c.roundRect(sbx, y, sbw, h, 4, fill=1, stroke=1)
            c.setDash()
            c.setFillColor(GCP_GREEN)
            c.setFont("Helvetica-Bold", 6.8)
            c.drawString(sbx + 5, y + h - 9, label)
            c.restoreState()

        # Frontend subnet
        subnet_band(13.35 * k, 2.15 * k, "Frontend subnet  10.0.1.0/24")
        self._box(c, migx, 13.55 * k, migw, 1.15 * k,
                  "Frontend MIG (Shielded VMs)",
                  ["autoscale 2–20 · tag: frontend"], fill=GCP_GREEN)

        # Internal LB
        self._box(c, 3.7 * k, 12.05 * k, 3.7 * k, 0.9 * k,
                  "Internal TCP Load Balancer", None, fill=GCP_BLUE, fs=7.5)

        # Backend subnet
        subnet_band(9.5 * k, 2.15 * k, "Backend subnet  10.0.2.0/24")
        self._box(c, migx, 9.7 * k, migw, 1.15 * k,
                  "Backend MIG (Shielded VMs)",
                  ["autoscale 2–16 · tag: backend"], fill=GCP_GREEN)

        # Database subnet
        subnet_band(5.15 * k, 3.05 * k, "Database subnet  10.0.3.0/24")
        c.saveState()
        c.setFillColor(SUBTLE)
        c.setFont("Helvetica-Oblique", 6.3)
        c.drawCentredString((migx + migw / 2), 7.55 * k,
                            "Private Services Access (VPC peering)")
        c.restoreState()
        self._box(c, migx, 5.45 * k, migw, 1.35 * k, "Cloud SQL",
                  ["private IP · CMEK · HA · SSL-only · PITR"], fill=GCP_DARK)

        # Cloud Router + NAT
        self._box(c, 1.45 * k, 2.0 * k, 3.0 * k, 1.0 * k,
                  "Cloud Router + NAT", ["controlled egress"], fill=GCP_YELLOW,
                  tcol=INK, fs=7.2)

        # ---- Right services column ----
        self._box(c, rx0, 14.35 * k, rw, 1.05 * k, "Identity-Aware Proxy",
                  ["IAP TCP forwarding · SSH:22"], fill=colors.HexColor("#a142f4"))
        self._box(c, rx0, 12.75 * k, rw, 1.05 * k, "Cloud KMS — CMEK",
                  ["keys rotated every 90 days"], fill=GCP_DARK)
        self._box(c, rx0, 11.15 * k, rw, 1.05 * k, "Secret Manager",
                  ["DB password · CMEK"], fill=GCP_DARK)
        self._box(c, rx0, 8.9 * k, rw, 1.75 * k, "Monitoring · Logging · Audit",
                  ["alerts · flow logs", "audit → GCS (CMEK,", "retention-locked)"],
                  fill=GCP_BLUE, fs=7.6)

        # ================= TRAFFIC FLOWS =================
        # 1. HTTPS ingress (blue solid)
        self._flow(c, [(mx, 20.0 * k), (mx, 19.6 * k)], GCP_BLUE)
        self._flow(c, [(mx, 18.55 * k), (mx, 18.1 * k)], GCP_BLUE)
        self._flow(c, [(mx, 17.05 * k), (mx, 15.5 * k)], GCP_BLUE)
        self._badge(c, mx, 16.85 * k, 1, GCP_BLUE)
        self._label(c, mx - 1.45 * k, 16.85 * k, "HTTPS 443", GCP_BLUE)

        # 2. Frontend -> internal LB -> backend (green solid)
        self._flow(c, [(mx, 13.55 * k), (mx, 12.95 * k)], GCP_GREEN)
        self._flow(c, [(mx, 12.05 * k), (mx, 11.65 * k)], GCP_GREEN)
        self._badge(c, mx, 13.25 * k, 2, GCP_GREEN)
        self._label(c, mx - 1.45 * k, 13.25 * k, "app :8080", GCP_GREEN)

        # 3. Backend -> Cloud SQL (purple solid)
        self._flow(c, [(mx, 9.7 * k), (mx, 8.2 * k)], colors.HexColor("#8430ce"))
        self._badge(c, mx, 8.95 * k, 3, colors.HexColor("#8430ce"))
        self._label(c, mx + 1.5 * k, 8.95 * k, "SQL / SSL", colors.HexColor("#8430ce"))

        # 4. Egress via NAT (orange dashed)
        orange = colors.HexColor("#e8710a")
        self._flow(c, [(sbx, 10.2 * k), (1.1 * k, 10.2 * k), (1.1 * k, 2.9 * k),
                       (1.45 * k, 2.9 * k)], orange, dash=(3, 2))
        self._flow(c, [(2.95 * k, 2.0 * k), (2.95 * k, 1.15 * k),
                       (2.95 * k, 0.55 * k)], orange, dash=(3, 2))
        self._label(c, 2.95 * k, 0.72 * k, "→ Internet", orange)
        self._badge(c, 1.1 * k, 6.4 * k, 4, orange)

        # 5. Admin via IAP (red dashed)
        red = GCP_RED
        self._flow(c, [(rxc, 20.1 * k), (rxc, 15.4 * k)], red, dash=(3, 2))
        self._flow(c, [(rx0, 14.9 * k), (8.5 * k, 14.15 * k)], red, dash=(3, 2))
        self._flow(c, [(rx0, 14.55 * k), (8.5 * k, 10.4 * k)], red, dash=(3, 2))
        self._badge(c, rxc, 17.6 * k, 5, red)
        self._label(c, rxc, 16.7 * k, "SSH via IAP", red)

        # 6. Telemetry / logs (grey dotted)
        grey = SUBTLE
        self._flow(c, [(8.5 * k, 13.9 * k), (10.4 * k, 13.9 * k),
                       (10.4 * k, 10.3 * k), (rx0, 10.0 * k)], grey,
                   width=1.0, dash=(1, 2))
        self._flow(c, [(8.5 * k, 10.05 * k), (10.6 * k, 10.05 * k),
                       (10.6 * k, 9.9 * k), (rx0, 9.7 * k)], grey,
                   width=1.0, dash=(1, 2))
        self._badge(c, 10.4 * k, 12.0 * k, 6, grey)

        # CMEK association (thin dotted, no arrow)
        self._flow(c, [(rx0, 12.9 * k), (8.5 * k, 6.1 * k)],
                   GCP_DARK, width=0.7, dash=(1, 2.5), arrow=False)

        # ---- Legend ----
        lx, ly, lw, lh = rx0, 1.4 * k, rw, 6.9 * k
        c.saveState()
        c.setStrokeColor(GREY_LINE)
        c.setFillColor(colors.white)
        c.roundRect(lx, ly, lw, lh, 4, fill=1, stroke=1)
        c.setFillColor(INK)
        c.setFont("Helvetica-Bold", 8)
        c.drawString(lx + 6, ly + lh - 13, "Traffic Flows")
        legend = [
            (1, GCP_BLUE, "solid", "HTTPS ingress (user → app)"),
            (2, GCP_GREEN, "solid", "Internal LB (front → back)"),
            (3, colors.HexColor("#8430ce"), "solid", "Database (SSL, private)"),
            (4, colors.HexColor("#e8710a"), "dash", "Egress via Cloud NAT"),
            (5, GCP_RED, "dash", "Admin SSH via IAP"),
            (6, SUBTLE, "dot", "Telemetry / audit logs"),
        ]
        yy = ly + lh - 30
        for n, col, kind, txt in legend:
            c.saveState()
            c.setStrokeColor(col)
            c.setLineWidth(1.6)
            if kind == "dash":
                c.setDash(3, 2)
            elif kind == "dot":
                c.setDash(1, 2)
            c.line(lx + 8, yy + 3, lx + 30, yy + 3)
            c.setDash()
            c.restoreState()
            self._badge(c, lx + 19, yy + 3, n, col, r=5.5)
            c.setFillColor(INK)
            c.setFont("Helvetica", 6.9)
            c.drawString(lx + 36, yy, txt)
            yy -= 17
        c.setFillColor(SUBTLE)
        c.setFont("Helvetica-Oblique", 6.2)
        c.drawString(lx + 6, ly + 8, "CMEK on disks, SQL, secrets, logs")
        c.restoreState()


# ---------------------------------------------------------------------------
# Game-hosting schematic (reuses ArchitectureDiagram primitives)
# ---------------------------------------------------------------------------
class GameServerDiagram(ArchitectureDiagram):
    """Schematic of the dedicated game-server VM and the two app stacks."""

    def __init__(self, width=17 * cm, height=10.4 * cm):
        Flowable.__init__(self)
        self.width = width
        self.height = height

    def draw(self):
        c = self.canv
        k = cm
        purple = colors.HexColor("#a142f4")
        cm_green = colors.HexColor("#188038")

        # Internet + downward flow into the firewall.
        self._cloud(c, 5.4 * k, 9.6 * k, "Internet / Users")

        # Firewall band.
        self._box(c, 0.6 * k, 8.15 * k, 10.8 * k, 0.62 * k,
                  "Firewall  —  allow 80 · 443 · 8080 (internet)   |   22 (IAP only)",
                  None, fill=GCP_YELLOW, tcol=INK, fs=7.4)

        # VM container.
        vx, vy, vw, vh = 0.6 * k, 0.7 * k, 10.8 * k, 6.9 * k
        c.saveState()
        c.setStrokeColor(GCP_DARK)
        c.setDash(4, 3)
        c.setLineWidth(1.2)
        c.setFillColor(colors.HexColor("#f7faff"))
        c.roundRect(vx, vy, vw, vh, 7, fill=1, stroke=1)
        c.setDash()
        c.setFillColor(GCP_DARK)
        c.setFont("Helvetica-Bold", 7.6)
        c.drawString(vx + 7, vy + vh - 12,
                     "dev-game-server VM  ·  e2-standard-2  ·  public IP  ·  Shielded  ·  CMEK disk")
        c.restoreState()

        # WorkAdventure stack.
        self._box(c, 1.1 * k, 1.3 * k, 4.7 * k, 5.0 * k, "WorkAdventure",
                  ["Traefik  :80 / :443", "→ Let's Encrypt via sslip.io",
                   "play · back · map-storage", "uploader · icon · redis",
                   "(Docker Compose)"],
                  fill=GCP_BLUE, fs=9.5, sfs=6.8)

        # Cloud-Morph stack.
        self._box(c, 6.2 * k, 1.3 * k, 4.6 * k, 5.0 * k, "Cloud-Morph",
                  ["Go server  :8080  (WebRTC)", "nat1to1ip = public IP",
                   "Wine 'appvm' container", "streaming Minesweeper",
                   "(Docker + Wine)"],
                  fill=cm_green, fs=9.5, sfs=6.8)

        # Right column: operators, IAP, host/security notes.
        self._box(c, 11.9 * k, 8.15 * k, 4.5 * k, 0.62 * k,
                  "Operators / Admins", None, fill=INK, fs=8)
        self._box(c, 11.9 * k, 6.75 * k, 4.5 * k, 0.92 * k,
                  "Identity-Aware Proxy", ["SSH :22 (no public SSH)"],
                  fill=purple, fs=8, sfs=6.2)

        nx, ny, nw, nh = 11.9 * k, 1.3 * k, 4.5 * k, 5.0 * k
        c.saveState()
        c.setStrokeColor(GREY_LINE)
        c.setFillColor(colors.white)
        c.roundRect(nx, ny, nw, nh, 5, fill=1, stroke=1)
        c.setFillColor(INK)
        c.setFont("Helvetica-Bold", 8)
        c.drawString(nx + 7, ny + nh - 13, "Infra extensions")
        notes = [
            "• new game-server module",
            "• static external IP",
            "• firewall 80/443 + IAP SSH",
            "• additional_web_ports=[8080]",
            "• CMEK boot disk (disk key)",
            "• OS Login, Shielded VM",
            "• sslip.io → real TLS cert",
            "• outside the MIG tiers",
        ]
        c.setFont("Helvetica", 6.9)
        for i, n in enumerate(notes):
            c.drawString(nx + 8, ny + nh - 30 - i * 12, n)
        c.restoreState()

        # Flows.
        self._flow(c, [(5.4 * k, 9.0 * k), (5.4 * k, 8.79 * k)], GCP_BLUE)
        self._flow(c, [(3.9 * k, 8.15 * k), (3.4 * k, 6.3 * k)], GCP_BLUE)
        self._label(c, 2.4 * k, 6.75 * k, "HTTPS", GCP_BLUE)
        self._flow(c, [(7.6 * k, 8.15 * k), (8.5 * k, 6.3 * k)], cm_green)
        self._label(c, 9.3 * k, 6.75 * k, ":8080", cm_green)
        self._flow(c, [(14.15 * k, 8.15 * k), (14.15 * k, 7.67 * k)], GCP_RED, dash=(3, 2))
        self._flow(c, [(11.9 * k, 7.1 * k), (10.8 * k, 5.2 * k)], GCP_RED, dash=(3, 2))


# ---------------------------------------------------------------------------
# Reusable table helper
# ---------------------------------------------------------------------------
def make_table(header, rows, col_widths, head_color=GCP_DARK, zebra=True):
    data = [[cell(h, "TableHead") for h in header]]
    for r in rows:
        data.append([cell(str(x)) for x in r])
    t = Table(data, colWidths=col_widths, repeatRows=1)
    st = [
        ("BACKGROUND", (0, 0), (-1, 0), head_color),
        ("GRID", (0, 0), (-1, -1), 0.5, GREY_LINE),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 5),
        ("RIGHTPADDING", (0, 0), (-1, -1), 5),
        ("TOPPADDING", (0, 0), (-1, -1), 4),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
    ]
    if zebra:
        for i in range(1, len(data)):
            if i % 2 == 0:
                st.append(("BACKGROUND", (0, i), (-1, i), GREY_BG))
    t.setStyle(TableStyle(st))
    return t


# ---------------------------------------------------------------------------
# Page furniture (header/footer)
# ---------------------------------------------------------------------------
DOC_TITLE = "GCP Three-Tier Platform"
DOC_SUB = "Architecture & Security Compliance Documentation"


def on_page(canvas, doc):
    canvas.saveState()
    w, h = A4
    if doc.page > 1:
        canvas.setStrokeColor(GREY_LINE)
        canvas.setLineWidth(0.5)
        canvas.line(2 * cm, h - 1.5 * cm, w - 2 * cm, h - 1.5 * cm)
        canvas.setFont("Helvetica", 8)
        canvas.setFillColor(SUBTLE)
        canvas.drawString(2 * cm, h - 1.35 * cm, DOC_TITLE)
        canvas.drawRightString(w - 2 * cm, h - 1.35 * cm, DOC_SUB)
        canvas.line(2 * cm, 1.4 * cm, w - 2 * cm, 1.4 * cm)
        canvas.drawString(2 * cm, 1.0 * cm, "Confidential — Internal Use")
        canvas.drawRightString(w - 2 * cm, 1.0 * cm, "Page %d" % doc.page)
    canvas.restoreState()


def build():
    doc = BaseDocTemplate(
        OUT, pagesize=A4,
        leftMargin=2 * cm, rightMargin=2 * cm,
        topMargin=2 * cm, bottomMargin=1.8 * cm,
        title="GCP Three-Tier Platform Documentation",
        author="Platform Engineering",
    )
    frame = Frame(doc.leftMargin, doc.bottomMargin,
                  doc.width, doc.height, id="main")
    doc.addPageTemplates([PageTemplate(id="all", frames=[frame], onPage=on_page)])

    e = []  # story

    # ---- Cover ----
    e.append(Spacer(1, 3.5 * cm))
    e.append(P("Google Cloud Platform", "CoverSub"))
    e.append(Spacer(1, 0.2 * cm))
    e.append(P("Three-Tier Application Platform", "Cover"))
    e.append(Spacer(1, 0.3 * cm))
    e.append(P("Architecture &amp; Security Compliance Documentation", "CoverSub"))
    e.append(Spacer(1, 1.2 * cm))

    meta = Table([
        ["Document", "Project Design, Compliance & Deployment Reference"],
        ["Version", "3.0 (Modular, Hardened, Deployed & Validated)"],
        ["Platform", "Google Cloud Platform"],
        ["IaC", "Terraform (8 modules)"],
        ["Status", "Deployed to GCP; smoke-tested with live workloads"],
        ["Classification", "Confidential — Internal Use"],
    ], colWidths=[4 * cm, 9 * cm])
    meta.setStyle(TableStyle([
        ("FONTNAME", (0, 0), (0, -1), "Helvetica-Bold"),
        ("FONTNAME", (1, 0), (1, -1), "Helvetica"),
        ("FONTSIZE", (0, 0), (-1, -1), 10),
        ("TEXTCOLOR", (0, 0), (0, -1), GCP_DARK),
        ("TEXTCOLOR", (1, 0), (1, -1), INK),
        ("LINEBELOW", (0, 0), (-1, -1), 0.4, GREY_LINE),
        ("TOPPADDING", (0, 0), (-1, -1), 6),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
        ("ALIGN", (0, 0), (0, -1), "LEFT"),
    ]))
    e.append(meta)
    e.append(Spacer(1, 2.5 * cm))
    e.append(P("Compliance frameworks referenced: CIS GCP Foundations Benchmark v2.0, "
               "ISO/IEC 27001:2022, SOC 2 (Trust Services Criteria), PCI-DSS v4.0.",
               "Small"))
    e.append(PageBreak())

    # ---- TOC ----
    e.append(P("Table of Contents", "H1"))
    toc = [
        "1.  Executive Summary",
        "2.  Architecture Overview",
        "3.  Module Design",
        "4.  Network Architecture",
        "5.  Identity &amp; Access Management",
        "6.  Data Protection &amp; Encryption",
        "7.  Edge Security (Cloud Armor / WAF)",
        "8.  Logging, Monitoring &amp; Audit",
        "9.  Security Compliance Mapping",
        "10. Deployment Guide",
        "11. Operations, HA &amp; Disaster Recovery",
        "12. Risk Register &amp; Roadmap",
        "13. Game Hosting — Infrastructure Extensions",
        "14. Deployed Game Platforms (WorkAdventure &amp; Cloud-Morph)",
        "15. Deployment Notes &amp; Operational Lessons",
    ]
    for t in toc:
        e.append(P(t, "TOCItem"))
    e.append(PageBreak())

    # ---- 1. Executive Summary ----
    e.append(P("1. Executive Summary", "H1"))
    e.append(P(
        "This document describes the architecture and security posture of a "
        "three-tier application platform deployed on Google Cloud Platform (GCP) "
        "and provisioned entirely through modular Terraform. The platform separates "
        "the presentation (frontend), application (backend) and data (database) tiers "
        "into isolated network segments, each with dedicated identity, autoscaling and "
        "health management, fronted by a global HTTPS load balancer protected by a "
        "Cloud Armor Web Application Firewall."))
    e.append(P(
        "The design was refactored from a flat, single-directory Terraform "
        "configuration into seven reusable modules, and hardened to meet "
        "production-grade security and compliance objectives. Encryption with "
        "customer-managed keys (CMEK), least-privilege identity, private-only data "
        "access, default-deny networking, and centralized audit logging are applied "
        "throughout."))
    e.append(P("Key outcomes", "H3"))
    e.append(bullets([
        "<b>Modular &amp; reusable:</b> a single generic compute module powers both "
        "application tiers; environments are driven by tfvars (dev/prod).",
        "<b>Encryption everywhere:</b> CMEK on disks, Cloud SQL, Secret Manager and the "
        "log archive bucket, with automatic 90-day key rotation.",
        "<b>Reduced attack surface:</b> no public IPs on instances, IAP-only SSH, "
        "default-deny firewall, and private-only Cloud SQL.",
        "<b>Edge protection:</b> Cloud Armor with OWASP Core Rule Set, per-client rate "
        "limiting and adaptive (ML) layer-7 DDoS defense.",
        "<b>Provable compliance:</b> controls mapped to CIS GCP, ISO 27001, SOC 2 and "
        "PCI-DSS (Section 9).",
        "<b>Deployed &amp; validated:</b> provisioned to a live GCP project and smoke-tested "
        "with real workloads — nginx, Jenkins-in-Docker, and two containerised game "
        "platforms on a dedicated VM (Sections 13–14).",
    ]))
    e.append(P("Notable fixes applied during hardening", "H3"))
    e.append(bullets([
        "Added <b>Cloud NAT</b> — the original design had neither public IPs nor NAT, so "
        "instances could not reach the internet to patch.",
        "Implemented <b>Cloud Armor</b>, which the original README described but never "
        "actually deployed.",
        "Removed a <b>duplicate KMS data source</b> that caused the original code to fail "
        "<font face='Courier'>terraform validate</font>.",
        "Replaced blanket <font face='Courier'>cloud-platform</font> trust with "
        "least-privilege IAM roles and enforced Shielded VM + OS Login.",
    ]))
    e.append(PageBreak())

    # ---- 2. Architecture Overview ----
    e.append(P("2. Architecture Overview", "H1"))
    e.append(P(
        "Traffic flows from the internet through Cloud Armor and the global HTTPS load "
        "balancer to the frontend managed instance group. The frontend reaches the "
        "backend only through an internal load balancer; the backend reaches Cloud SQL "
        "only over a private, peered network path. Instances have no public IP and use "
        "Cloud NAT for controlled egress."))
    e.append(Spacer(1, 0.3 * cm))
    e.append(ArchitectureDiagram())
    e.append(PageBreak())

    # ---- 3. Module Design ----
    e.append(P("3. Module Design", "H1"))
    e.append(P(
        "The configuration is composed from the following modules under "
        "<font face='Courier'>modules/</font>. The composition root "
        "(<font face='Courier'>main.tf</font>) wires them together and expresses "
        "explicit dependencies (for example, API enablement before resource creation, "
        "and KMS IAM grants before Cloud SQL creation)."))
    e.append(make_table(
        ["Module", "Responsibility", "Primary Security Controls"],
        [
            ["project-services", "Enable required Google APIs with a propagation wait",
             "Minimal explicit API set"],
            ["networking", "VPC, per-tier subnets, firewall, Cloud NAT, private services access",
             "Default-deny ingress, flow logs, IAP-only SSH, Private Google Access, NAT egress"],
            ["security", "CMEK key ring &amp; keys, per-tier service accounts, Cloud Armor",
             "Key rotation, least-privilege IAM, OWASP WAF, adaptive DDoS, rate limiting"],
            ["compute", "Reusable tier: instance template, MIG, autoscaler, health check",
             "Shielded VM, CMEK disks, no public IP, OS Login, blocked project SSH keys"],
            ["load-balancer", "External global HTTPS LB + internal LB",
             "Managed TLS, MODERN policy (TLS 1.2+), HTTP→HTTPS redirect, Armor attach"],
            ["database", "Cloud SQL primary/replicas + password secret",
             "Private IP, CMEK, SSL-only, PITR, deletion protection, hardened flags"],
            ["monitoring", "Alerts, notification channel, audit archive",
             "Audit log sink to CMEK bucket, DATA_READ/WRITE audit logging"],
            ["game-server", "Dedicated single-host VM for stateful container workloads",
             "Shielded VM, CMEK disk, IAP-only SSH, static IP, scoped web ports"],
        ],
        [3 * cm, 6 * cm, 8 * cm],
    ))
    e.append(Spacer(1, 0.3 * cm))
    e.append(P("Composition &amp; dependency ordering", "H3"))
    e.append(bullets([
        "project-services → (networking, security) → compute tiers → "
        "load-balancer → database → monitoring.",
        "The database waits on both the private-services peering connection and the "
        "Cloud SQL service agent's CMEK grant to avoid race conditions.",
    ]))
    e.append(PageBreak())

    # ---- 4. Network Architecture ----
    e.append(P("4. Network Architecture", "H1"))
    e.append(P("Subnets (custom-mode VPC, regional)", "H3"))
    e.append(make_table(
        ["Tier", "Subnet", "CIDR", "Public IP", "Egress"],
        [
            ["Frontend", "&lt;env&gt;-frontend-subnet", "10.0.1.0/24", "None", "Cloud NAT"],
            ["Backend", "&lt;env&gt;-backend-subnet", "10.0.2.0/24", "None", "Cloud NAT"],
            ["Database", "&lt;env&gt;-database-subnet", "10.0.3.0/24", "None (private IP)", "n/a"],
        ],
        [2.6 * cm, 5.4 * cm, 3 * cm, 3 * cm, 3 * cm],
    ))
    e.append(Spacer(1, 0.3 * cm))
    e.append(P("Firewall rules (default-deny posture, all logged)", "H3"))
    e.append(make_table(
        ["Rule", "Direction", "Source", "Target", "Ports", "Action"],
        [
            ["deny-all-ingress", "Ingress", "0.0.0.0/0", "all", "all", "DENY (65534)"],
            ["allow-frontend-from-lb", "Ingress", "GFE ranges", "tag: frontend", "80,443", "ALLOW"],
            ["allow-backend-from-frontend", "Ingress", "tag: frontend", "tag: backend", "8080,8443", "ALLOW"],
            ["allow-iap-ssh", "Ingress", "35.235.240.0/20", "frontend,backend", "22", "ALLOW"],
            ["allow-health-checks", "Ingress", "130.211.0.0/22, 35.191.0.0/16", "frontend,backend", "80,443,8080,8443", "ALLOW"],
        ],
        [4 * cm, 2 * cm, 3.4 * cm, 2.6 * cm, 2.6 * cm, 2.4 * cm],
    ))
    e.append(Spacer(1, 0.3 * cm))
    e.append(bullets([
        "<b>No SSH from the internet</b> — administrative access is via Identity-Aware "
        "Proxy TCP forwarding only.",
        "<b>Public clients never reach the VMs directly</b> — only Google Front End / "
        "health-check ranges may reach the frontend; end users transit the load balancer.",
        "<b>VPC Flow Logs</b> enabled on every subnet; <b>Private Google Access</b> lets "
        "private instances reach Google APIs without egress to the internet.",
        "<b>Cloud SQL</b> is reachable only through Private Services Access (VPC peering); "
        "no public IP is assigned.",
    ]))
    e.append(PageBreak())

    # ---- 5. IAM ----
    e.append(P("5. Identity &amp; Access Management", "H1"))
    e.append(P(
        "Each tier runs under a dedicated service account granted only the roles it "
        "needs. Legacy broad access scopes are replaced with fine-grained IAM roles. "
        "Human access to instances requires OS Login and IAP."))
    e.append(make_table(
        ["Principal", "Roles", "Rationale"],
        [
            ["frontend-sa", "logging.logWriter, monitoring.metricWriter, monitoring.viewer",
             "Emit logs/metrics only; no data access"],
            ["backend-sa", "+ cloudsql.client, secretmanager.secretAccessor",
             "Connect to Cloud SQL &amp; read the DB password secret"],
            ["Cloud SQL agent", "cloudkms.cryptoKeyEncrypterDecrypter (SQL key)",
             "Envelope-encrypt the database with CMEK"],
            ["Secret Mgr agent", "cloudkms.cryptoKeyEncrypterDecrypter (secret key)",
             "Encrypt secrets with CMEK"],
            ["Compute agent", "cloudkms.cryptoKeyEncrypterDecrypter (disk key)",
             "Encrypt boot disks with CMEK"],
        ],
        [3.4 * cm, 6.6 * cm, 7 * cm],
    ))
    e.append(Spacer(1, 0.2 * cm))
    e.append(bullets([
        "Principle of least privilege enforced per tier.",
        "No user-managed service-account keys are created; workloads use attached "
        "identities.",
        "OS Login centralizes SSH authorization in IAM and ties access to org identity.",
    ]))
    e.append(PageBreak())

    # ---- 6. Data Protection ----
    e.append(P("6. Data Protection &amp; Encryption", "H1"))
    e.append(P(
        "All data at rest is encrypted with customer-managed keys (CMEK) in Cloud KMS, "
        "created in the deployment region and rotated automatically. Data in transit is "
        "protected by TLS at the edge and enforced SSL to the database."))
    e.append(make_table(
        ["Asset", "At Rest", "In Transit", "Key / Rotation"],
        [
            ["Compute boot disks", "CMEK", "n/a", "disk key / 90 days"],
            ["Cloud SQL", "CMEK", "SSL enforced (ENCRYPTED_ONLY)", "sql key / 90 days"],
            ["Secret Manager", "CMEK", "TLS (API)", "secret key / 90 days"],
            ["Audit log bucket", "CMEK", "TLS (API)", "storage key / 90 days"],
            ["External traffic", "n/a", "TLS 1.2+ (MODERN policy)", "Google-managed cert"],
        ],
        [4 * cm, 3 * cm, 5.5 * cm, 4.5 * cm],
    ))
    e.append(Spacer(1, 0.2 * cm))
    e.append(bullets([
        "KMS crypto keys carry <font face='Courier'>prevent_destroy</font> to guard "
        "against accidental key loss (and data loss).",
        "The database password is randomly generated and stored only in CMEK-encrypted "
        "Secret Manager — never in plaintext state output.",
        "Cloud SQL enforces <font face='Courier'>ssl_mode = ENCRYPTED_ONLY</font> and "
        "IAM database authentication.",
    ]))
    e.append(PageBreak())

    # ---- 7. Edge Security ----
    e.append(P("7. Edge Security (Cloud Armor / WAF)", "H1"))
    e.append(P(
        "The external backend service is protected by a Cloud Armor security policy "
        "attached at the global load balancer. The policy combines OWASP Core Rule Set "
        "signatures, per-client rate limiting, and adaptive layer-7 DDoS defense."))
    e.append(make_table(
        ["Priority", "Rule", "Action"],
        [
            ["1000", "SQL injection (sqli-v33-stable)", "deny(403)"],
            ["1001", "Cross-site scripting (xss-v33-stable)", "deny(403)"],
            ["1002", "Local/Remote file inclusion (lfi/rfi)", "deny(403)"],
            ["1003", "Remote code execution (rce-v33-stable)", "deny(403)"],
            ["2000", "Per-IP rate limit (throttle/ban)", "rate_based_ban → deny(429)"],
            ["—", "Adaptive Protection (L7 DDoS ML)", "auto-detect"],
            ["MAX", "Default", "allow"],
        ],
        [2.5 * cm, 9.5 * cm, 5 * cm],
    ))
    e.append(PageBreak())

    # ---- 8. Logging/Monitoring ----
    e.append(P("8. Logging, Monitoring &amp; Audit", "H1"))
    e.append(bullets([
        "<b>Cloud Audit Logs:</b> Admin Activity plus DATA_READ and DATA_WRITE data-access "
        "logs enabled for all services.",
        "<b>Log sink:</b> all <font face='Courier'>cloudaudit.googleapis.com</font> logs "
        "exported to a dedicated, versioned, retention-locked GCS bucket encrypted with CMEK.",
        "<b>VPC Flow Logs</b> and <b>firewall logging</b> provide network visibility.",
        "<b>Load balancer and health-check logging</b> enabled at 100% sample rate.",
        "<b>Cloud Monitoring:</b> high-CPU alert policy with email notification channel; "
        "auto-close after 30 minutes.",
        "<b>Cloud SQL Query Insights</b> enabled for performance and anomaly analysis.",
    ]))
    e.append(P(
        "The retention-locked bucket supports tamper-evident, WORM-style audit retention "
        "(default 365 days in prod), satisfying evidence-retention requirements for the "
        "frameworks in Section 9.", "Body"))
    e.append(PageBreak())

    # ---- 9. Compliance mapping ----
    e.append(P("9. Security Compliance Mapping", "H1"))

    e.append(P("9.1 CIS Google Cloud Platform Foundations Benchmark", "H2"))
    e.append(make_table(
        ["CIS Ref", "Control", "Implementation"],
        [
            ["2.x", "Logging &amp; monitoring", "Audit log sink, data-access logs, flow logs"],
            ["3.1", "Default network not used", "Custom-mode VPC, no default network"],
            ["3.6/3.7", "No open SSH/RDP to 0.0.0.0/0", "IAP-only SSH; default-deny ingress"],
            ["3.9", "VPC Flow Logs enabled", "Enabled on all subnets"],
            ["4.x", "VM hardening", "Shielded VM, OS Login, no public IP, serial off"],
            ["6.x", "Cloud SQL hardening", "Private IP, SSL-only, CMEK, secure flags"],
            ["1.x", "IAM least privilege", "Per-tier SAs, scoped roles, no SA keys"],
        ],
        [2.2 * cm, 5.3 * cm, 9.5 * cm],
        head_color=GCP_BLUE,
    ))

    e.append(P("9.2 ISO/IEC 27001:2022 (Annex A)", "H2"))
    e.append(make_table(
        ["Control", "Theme", "Implementation"],
        [
            ["A.5.15", "Access control", "Least-privilege IAM, IAP, OS Login"],
            ["A.8.24", "Use of cryptography", "CMEK at rest, TLS in transit, key rotation"],
            ["A.8.20", "Network security", "Segmented subnets, default-deny firewall, NAT"],
            ["A.8.16", "Monitoring activities", "Audit logs, alerts, flow logs"],
            ["A.8.15", "Logging", "Centralized, CMEK, retention-locked archive"],
            ["A.8.7", "Protection against malware", "WAF/Cloud Armor OWASP rules"],
        ],
        [2.2 * cm, 4.3 * cm, 10.5 * cm],
        head_color=GCP_GREEN,
    ))

    e.append(P("9.3 SOC 2 (Trust Services Criteria)", "H2"))
    e.append(make_table(
        ["TSC", "Criterion", "Implementation"],
        [
            ["CC6.1", "Logical access", "IAM least privilege, IAP, service accounts"],
            ["CC6.6", "Boundary protection", "WAF, LB, default-deny firewall, private DB"],
            ["CC6.7", "Encryption of data", "CMEK at rest; TLS/SSL in transit"],
            ["CC7.2", "Detection &amp; monitoring", "Audit logs, alerts, adaptive DDoS"],
            ["A1.1", "Availability", "Regional HA (MIG + Cloud SQL REGIONAL), autoscaling"],
        ],
        [2.2 * cm, 4.3 * cm, 10.5 * cm],
        head_color=GCP_YELLOW,
    ))

    e.append(P("9.4 PCI-DSS v4.0 (illustrative)", "H2"))
    e.append(make_table(
        ["Req", "Requirement", "Implementation"],
        [
            ["1", "Network security controls", "Segmentation, default-deny, private DB"],
            ["3", "Protect stored data", "CMEK encryption; secrets in Secret Manager"],
            ["4", "Encrypt transmission", "TLS 1.2+ at edge; SSL-only to DB"],
            ["6", "Secure systems/software", "WAF, hardened images, IaC review"],
            ["8", "Identify &amp; authenticate", "IAM, OS Login, IAM DB auth"],
            ["10", "Log &amp; monitor access", "Audit logs to WORM archive; monitoring"],
        ],
        [1.8 * cm, 5 * cm, 10.2 * cm],
        head_color=GCP_RED,
    ))
    e.append(P("Mappings are indicative of control coverage provided by the "
               "infrastructure layer; full certification requires organizational "
               "controls, evidence collection and independent assessment.", "Small"))
    e.append(PageBreak())

    # ---- 10. Deployment ----
    e.append(P("10. Deployment Guide", "H1"))
    e.append(P("Prerequisites", "H3"))
    e.append(bullets([
        "Terraform &gt;= 1.3.0 and the Google Cloud SDK authenticated "
        "(<font face='Courier'>gcloud auth application-default login</font>).",
        "A GCP project with billing enabled and appropriate admin permissions.",
        "A GCS bucket for remote state (recommended; versioned + CMEK).",
    ]))
    e.append(P("Steps", "H3"))
    for label, code in [
        ("Initialize (prod remote state)",
         "terraform init -backend-config=environments/prod.gcs.tfbackend"),
        ("Plan", "terraform plan  -var-file=environments/prod.tfvars"),
        ("Apply", "terraform apply -var-file=environments/prod.tfvars"),
        ("Destroy (non-prod)", "terraform destroy -var-file=environments/dev.tfvars"),
    ]:
        e.append(P(label, "Bul"))
        e.append(Table([[cell(code, "Mono")]], colWidths=[16 * cm],
                       style=TableStyle([
                           ("BACKGROUND", (0, 0), (-1, -1), GREY_BG),
                           ("BOX", (0, 0), (-1, -1), 0.5, GREY_LINE),
                           ("LEFTPADDING", (0, 0), (-1, -1), 6),
                           ("TOPPADDING", (0, 0), (-1, -1), 5),
                           ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
                       ])))
        e.append(Spacer(1, 0.15 * cm))
    e.append(P("Environments are parameterized via <font face='Courier'>environments/"
               "*.tfvars</font>. Prod enables HTTPS (managed cert), Cloud CDN, regional "
               "HA Cloud SQL, read replicas and deletion protection.", "Body"))
    e.append(PageBreak())

    # ---- 11. Operations ----
    e.append(P("11. Operations, HA &amp; Disaster Recovery", "H1"))
    e.append(P("High availability", "H3"))
    e.append(bullets([
        "Regional managed instance groups spread across three zones with autoscaling "
        "and auto-healing.",
        "Cloud SQL <font face='Courier'>REGIONAL</font> availability (synchronous standby) "
        "in prod; optional read replicas.",
        "Global HTTPS load balancer with health-checked backends and Cloud CDN.",
    ]))
    e.append(P("Backup &amp; recovery", "H3"))
    e.append(bullets([
        "Automated Cloud SQL backups (retained 30 in prod) plus binary-log "
        "point-in-time recovery.",
        "Versioned, retention-locked audit archive bucket.",
        "Rolling, zero-downtime instance-template updates (PROACTIVE, surge, "
        "substitute).",
    ]))
    e.append(P("Administrative access", "H3"))
    e.append(Table([[cell(
        "gcloud compute ssh &lt;instance&gt; --zone &lt;zone&gt; --tunnel-through-iap",
        "Mono")]], colWidths=[16 * cm], style=TableStyle([
            ("BACKGROUND", (0, 0), (-1, -1), GREY_BG),
            ("BOX", (0, 0), (-1, -1), 0.5, GREY_LINE),
            ("LEFTPADDING", (0, 0), (-1, -1), 6),
            ("TOPPADDING", (0, 0), (-1, -1), 5),
            ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
        ])))
    e.append(PageBreak())

    # ---- 12. Risk register ----
    e.append(P("12. Risk Register &amp; Roadmap", "H1"))
    e.append(P("The current baseline addresses the major infrastructure risks. The "
               "following items are recommended to reach a fully certified posture:"))
    e.append(make_table(
        ["Area", "Recommendation", "Priority"],
        [
            ["Perimeter", "Adopt VPC Service Controls to prevent data exfiltration", "High"],
            ["Org policy", "Enforce org policies (no external IP, restrict SA key creation, uniform bucket access)", "High"],
            ["Supply chain", "Enable Binary Authorization for container workloads", "Medium"],
            ["Threat detection", "Enable Security Command Center Premium", "High"],
            ["Egress", "Tighten Cloud NAT to specific subnets; add egress firewall rules", "Medium"],
            ["Secrets", "Rotate DB credentials automatically via scheduled function", "Medium"],
            ["CI/CD", "Add tfsec/Checkov + OPA policy gates to the pipeline", "Medium"],
            ["State", "Confirm remote state bucket has versioning, CMEK and restricted IAM", "High"],
        ],
        [3 * cm, 11 * cm, 2 * cm],
        head_color=GCP_DARK,
    ))
    e.append(PageBreak())

    # ---- 13. Game Hosting — Infrastructure Extensions ----
    e.append(P("13. Game Hosting — Infrastructure Extensions", "H1"))
    e.append(P(
        "The platform was deployed to a live GCP project and validated end-to-end by "
        "running real workloads across every tier (Table 13.1), including two interactive "
        "game platforms. Rather than repurpose the autoscaled tiers, the infrastructure "
        "was extended with a dedicated, single-host game server in the same project and "
        "VPC — keeping the hardened tiers stateless and untouched."))
    e.append(P("Table 13.1 — Deployed workloads", "H3"))
    e.append(make_table(
        ["Host / Tier", "Workload", "Access", "Status"],
        [
            ["Frontend MIG", "nginx static site", "Global HTTPS LB (public IP)", "Live — 200"],
            ["Backend MIG", "Jenkins CI + Docker Engine", "Internal LB :8080, IAP SSH", "Healthy"],
            ["Game server VM", "WorkAdventure (7-container stack)", "https://&lt;ip&gt;.sslip.io", "Live — 7/7"],
            ["Game server VM", "Cloud-Morph (Go + Wine)", "http://&lt;ip&gt;:8080", "Live"],
            ["Database", "Cloud SQL MySQL 8.0 (private, CMEK)", "Backend tier only", "RUNNABLE"],
        ],
        [2.8 * cm, 5.8 * cm, 4.6 * cm, 2.8 * cm],
        head_color=GCP_GREEN,
    ))
    e.append(Spacer(1, 0.2 * cm))
    e.append(P("Why a dedicated VM instead of the MIG tiers", "H3"))
    e.append(bullets([
        "Both games are <b>stateful, single-host</b> stacks (Traefik sessions, Redis, a "
        "Wine container). An autoscaled, round-robin MIG would split state across "
        "replicas and wipe it on every roll/auto-heal.",
        "They require a <b>stable public IP and inbound 80/443/8080</b>; the MIG tiers "
        "have no public IP and are reachable only through load balancers.",
        "Isolation preserves the production tiers' posture (no public IP, IAP-only SSH).",
    ]))
    e.append(Spacer(1, 0.25 * cm))
    e.append(P("Figure 13.1 — Game server architecture", "H3"))
    e.append(GameServerDiagram())
    e.append(PageBreak())

    e.append(P("Terraform changes made to accommodate the games", "H2"))
    e.append(P(
        "All additions are gated behind <font face='Courier'>enable_game_server</font> "
        "(off by default) so the core three-tier platform is unaffected when games are "
        "not deployed."))
    e.append(make_table(
        ["Change", "What it does / why"],
        [
            ["New game-server module", "Dedicated Compute Engine VM (Shielded, CMEK disk, OS Login) that runs Docker Compose apps; kept separate from the compute/MIG module."],
            ["Static external IP", "google_compute_address — stable public address needed for DNS (sslip.io) and Let's Encrypt HTTP-01 validation."],
            ["Web firewall rule (80, 443)", "Allows public HTTP/HTTPS to the VM (tag game-server); WorkAdventure's Traefik terminates TLS."],
            ["additional_web_ports variable", "Opens extra ports (8080 for Cloud-Morph) without editing the module — set via game_server_extra_ports."],
            ["IAP SSH firewall rule", "Admin SSH to the VM via IAP range (35.235.240.0/20) only; no public SSH."],
            ["enable_game_server toggle", "count-based optional deployment; the games add nothing when disabled."],
            ["storage + IAP APIs enabled", "storage.googleapis.com (audit-bucket agent) and iap.googleapis.com (SSH tunnel) added to project-services."],
            ["CMEK disk reuse", "The VM's boot disk uses the security module's disk key, consistent with tier hardening."],
        ],
        [4.3 * cm, 11.7 * cm],
        head_color=GCP_BLUE,
    ))
    e.append(PageBreak())

    # ---- 14. Deployed Game Platforms ----
    e.append(P("14. Deployed Game Platforms", "H1"))

    e.append(P("14.1  WorkAdventure", "H2"))
    e.append(P(
        "WorkAdventure is a web-based virtual world (a 2D metaverse) with "
        "proximity audio/video over WebRTC. It was deployed as a multi-container stack via "
        "Docker Compose using prebuilt images, fronted by Traefik with automatic TLS."))
    e.append(make_table(
        ["Container", "Role"],
        [
            ["reverse-proxy (Traefik)", "Ingress on 80/443, path-based routing, Let's Encrypt (HTTP-01) TLS termination"],
            ["play", "Serves the game client (HTML/JS/WASM); WebSocket entry point for players"],
            ["back", "Shares room/world state between connected users"],
            ["map-storage", "Serves and edits maps (protected by basic authentication)"],
            ["uploader", "Stores chat file uploads (Redis-backed)"],
            ["icon", "Fetches favicons for websites embedded in iframes"],
            ["redis", "Scripting-API variables and uploader storage"],
        ],
        [3.6 * cm, 12.4 * cm],
        head_color=GCP_GREEN,
    ))
    e.append(P("Deploy flow", "H3"))
    e.append(bullets([
        "The startup script installs Docker, derives the domain as "
        "<font face='Courier'>&lt;ip&gt;.sslip.io</font> from the instance's external IP, "
        "writes an <font face='Courier'>.env</font> (DOMAIN, random SECRET_KEY, ACME_EMAIL, "
        "map-storage basic-auth) and runs <font face='Courier'>docker compose up -d</font>.",
        "Traefik obtains a Let's Encrypt certificate for the sslip.io name via the HTTP-01 "
        "challenge on port 80 — hence the need for a real DNS name and open 80.",
        "Outcome: <font face='Courier'>https://&lt;ip&gt;.sslip.io</font> serves the world "
        "over valid TLS (verified), so WebRTC audio/video functions.",
    ]))
    e.append(PageBreak())

    e.append(P("14.2  Cloud-Morph", "H2"))
    e.append(P(
        "Cloud-Morph streams a Windows desktop application to the browser over WebRTC. A "
        "Go server handles signaling and streaming while the application itself runs under "
        "Wine inside a Docker container. Minesweeper (bundled with the repo) is the "
        "smoke-test application."))
    e.append(make_table(
        ["Component", "Role"],
        [
            ["Go server (:8080)", "HTTP + WebRTC signaling; captures the app's video/audio, streams it, relays input"],
            ["syncwine image", "Docker image with Wine + Xvfb + ffmpeg + the input bridge (syncinput.exe)"],
            ["appvm container", "Runs the Windows app (Minesweeper) under Wine, headless on Xvfb display :99"],
            ["nat1to1ip", "WebRTC 1:1 NAT hint set to the VM's public IP so ICE candidates are reachable"],
        ],
        [3.6 * cm, 12.4 * cm],
        head_color=GCP_GREEN,
    ))
    e.append(P("Deploy flow", "H3"))
    e.append(bullets([
        "The repo requires <b>Go 1.24+</b>; the official Go toolchain is installed (Debian's "
        "1.19 is too old) and the server is compiled with <font face='Courier'>go build</font>.",
        "The <font face='Courier'>syncwine</font> Wine image is built once; the Go server "
        "launches the <font face='Courier'>appvm</font> container and serves the client on "
        "<font face='Courier'>:8080</font> (opened via additional_web_ports).",
        "Outcome: <font face='Courier'>http://&lt;ip&gt;:8080</font> streams Minesweeper "
        "(verified). In this smoke test Cloud-Morph is HTTP-only; for production it would "
        "also sit behind Traefik/TLS.",
    ]))
    e.append(PageBreak())

    # ---- 15. Deployment Notes & Operational Lessons ----
    e.append(P("15. Deployment Notes &amp; Operational Lessons", "H1"))
    e.append(P(
        "Deploying to a real (fresh, quota-limited) project surfaced several issues that "
        "were resolved and folded back into the modules. They are recorded here for "
        "operability and to inform future environments."))
    e.append(make_table(
        ["Symptom", "Root cause", "Resolution"],
        [
            ["Instances could not fetch packages", "No public IP and no NAT", "Added Cloud NAT + Cloud Router for controlled egress"],
            ["Startup scripts failed (exit 127)", "CRLF line endings authored on Windows", "Strip CR via replace(); .gitattributes enforces LF"],
            ["Cloud Armor apply failed", "New project SECURITY_POLICIES quota = 0", "Cloud Armor made optional (enable_cloud_armor); request quota to enable"],
            ["Autoscaler apply failed", "Regional INSTANCES quota = 8", "Right-sized dev autoscaling; request quota to scale"],
            ["GCS CMEK grant failed", "Storage service agent not yet created", "Use google_storage_project_service_account data source + ordering"],
            ["Jenkins never started", "apt repo unsigned; package unavailable", "Run Jenkins as a Docker container (jenkins/jenkins:lts-jdk17)"],
            ["Backend tier auto-heal looped", "Health check hit / (403) while Jenkins serves 8080", "Health path /login + longer initial delay"],
            ["Cloud-Morph build failed", "Debian Go 1.19 shadowed required Go 1.24 on PATH", "Prepend official Go; purge apt Go; GOTOOLCHAIN=local"],
        ],
        [4 * cm, 5.5 * cm, 6.5 * cm],
        head_color=GCP_RED,
    ))
    e.append(Spacer(1, 0.2 * cm))
    e.append(P("Operational access model", "H3"))
    e.append(bullets([
        "<b>Terraform auth:</b> the provider authenticates with a short-lived token from "
        "the operator's gcloud session (<font face='Courier'>GOOGLE_OAUTH_ACCESS_TOKEN</font>), "
        "avoiding long-lived service-account keys.",
        "<b>Instance access:</b> all SSH is via Identity-Aware Proxy TCP forwarding "
        "(no public SSH). An <font face='Courier'>~/.ssh/config</font> ProxyCommand entry "
        "enables <font face='Courier'>ssh &lt;instance&gt;</font> and VS Code Remote-SSH.",
        "<b>Immutability:</b> MIG instances are ephemeral — durable changes are made to "
        "the Terraform templates and rolled, never by mutating live VMs.",
    ]))
    e.append(Spacer(1, 0.4 * cm))
    e.append(P("Document generated for the modular, hardened, deployed Terraform baseline. "
               "Regenerate with <font face='Courier'>python docs/generate_pdf.py</font> "
               "after infrastructure changes.", "Small"))

    doc.build(e)
    print("Wrote", OUT)


if __name__ == "__main__":
    build()
