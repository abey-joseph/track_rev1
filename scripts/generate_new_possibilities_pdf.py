#!/usr/bin/env python3
"""Generate a PDF report with new product possibilities for Track.

This script is intentionally self-contained and uses no third-party packages.
It writes the final artifact to output/pdf/track_new_possibilities.pdf.
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
import textwrap


PAGE_WIDTH = 595.0
PAGE_HEIGHT = 842.0


@dataclass(frozen=True)
class Color:
    r: float
    g: float
    b: float


PALETTE = {
    "bg": Color(0.98, 0.97, 0.95),
    "ink": Color(0.11, 0.15, 0.19),
    "muted": Color(0.37, 0.42, 0.47),
    "teal": Color(0.10, 0.39, 0.40),
    "teal_light": Color(0.86, 0.93, 0.92),
    "sand": Color(0.93, 0.89, 0.79),
    "sage": Color(0.85, 0.91, 0.85),
    "rose": Color(0.96, 0.87, 0.86),
    "gold": Color(0.83, 0.63, 0.21),
    "white": Color(1.0, 1.0, 1.0),
}


def pdf_escape(text: str) -> str:
    return (
        text.replace("\\", "\\\\")
        .replace("(", "\\(")
        .replace(")", "\\)")
    )


def chars_for_width(width: float, font_size: float) -> int:
    return max(18, int(width / (font_size * 0.53)))


class Canvas:
    def __init__(self) -> None:
        self.commands: list[str] = []
        self.rect(0, 0, PAGE_WIDTH, PAGE_HEIGHT, PALETTE["bg"])

    def _pdf_y(self, top: float, height: float = 0) -> float:
        return PAGE_HEIGHT - top - height

    def rect(self, left: float, top: float, width: float, height: float, fill: Color) -> None:
        self.commands.append(
            f"{fill.r:.3f} {fill.g:.3f} {fill.b:.3f} rg "
            f"{left:.2f} {self._pdf_y(top, height):.2f} {width:.2f} {height:.2f} re f"
        )

    def line(
        self,
        x1: float,
        top1: float,
        x2: float,
        top2: float,
        color: Color,
        width: float = 1.0,
    ) -> None:
        self.commands.append(
            f"{color.r:.3f} {color.g:.3f} {color.b:.3f} RG {width:.2f} w "
            f"{x1:.2f} {self._pdf_y(top1):.2f} m {x2:.2f} {self._pdf_y(top2):.2f} l S"
        )

    def text(
        self,
        left: float,
        top: float,
        text: str,
        *,
        font: str = "F1",
        size: float = 11,
        color: Color | None = None,
    ) -> None:
        fill = color or PALETTE["ink"]
        baseline = self._pdf_y(top) - size
        self.commands.append(
            "BT "
            f"/{font} {size:.2f} Tf "
            f"{fill.r:.3f} {fill.g:.3f} {fill.b:.3f} rg "
            f"1 0 0 1 {left:.2f} {baseline:.2f} Tm "
            f"({pdf_escape(text)}) Tj ET"
        )

    def paragraph(
        self,
        left: float,
        top: float,
        width: float,
        text: str,
        *,
        font: str = "F1",
        size: float = 11,
        leading: float = 15,
        color: Color | None = None,
    ) -> float:
        wrapped = textwrap.wrap(
            text,
            width=chars_for_width(width, size),
            break_long_words=False,
            break_on_hyphens=False,
        )
        for index, line in enumerate(wrapped):
            self.text(left, top + index * leading, line, font=font, size=size, color=color)
        return len(wrapped) * leading

    def bullets(
        self,
        left: float,
        top: float,
        width: float,
        items: list[str],
        *,
        size: float = 11,
        leading: float = 15,
        color: Color | None = None,
    ) -> float:
        y = top
        body_width = width - 18
        for item in items:
            wrapped = textwrap.wrap(
                item,
                width=chars_for_width(body_width, size),
                break_long_words=False,
                break_on_hyphens=False,
            )
            self.text(left, y, "-", font="F2", size=size, color=color)
            for index, line in enumerate(wrapped):
                self.text(
                    left + 14,
                    y + index * leading,
                    line,
                    font="F1",
                    size=size,
                    color=color,
                )
            y += max(1, len(wrapped)) * leading + 5
        return y - top

    def tag(
        self,
        left: float,
        top: float,
        label: str,
        width: float,
        fill: Color,
        *,
        font: str = "F2",
        size: float = 10,
        color: Color | None = None,
    ) -> None:
        self.rect(left, top, width, 22, fill)
        self.text(left + 10, top + 6, label, font=font, size=size, color=color or PALETTE["ink"])

    def stream(self) -> bytes:
        return "\n".join(self.commands).encode("ascii")


class PDFDocument:
    def __init__(self) -> None:
        self.objects: list[bytes] = []

    def add_object(self, data: bytes) -> int:
        self.objects.append(data)
        return len(self.objects)

    def set_object(self, object_id: int, data: bytes) -> None:
        self.objects[object_id - 1] = data

    def build(self, pages: list[Canvas], output_path: Path) -> None:
        font_regular = self.add_object(
            b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>"
        )
        font_bold = self.add_object(
            b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >>"
        )
        font_oblique = self.add_object(
            b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Oblique >>"
        )

        pages_id = self.add_object(b"<< /Type /Pages /Kids [] /Count 0 >>")
        page_ids: list[int] = []

        for page in pages:
            content = page.stream()
            content_id = self.add_object(
                (
                    f"<< /Length {len(content)} >>\nstream\n".encode("ascii")
                    + content
                    + b"\nendstream"
                )
            )
            page_id = self.add_object(
                (
                    f"<< /Type /Page /Parent {pages_id} 0 R "
                    f"/MediaBox [0 0 {PAGE_WIDTH:.2f} {PAGE_HEIGHT:.2f}] "
                    f"/Resources << /Font << /F1 {font_regular} 0 R "
                    f"/F2 {font_bold} 0 R /F3 {font_oblique} 0 R >> >> "
                    f"/Contents {content_id} 0 R >>"
                ).encode("ascii")
            )
            page_ids.append(page_id)

        kids = " ".join(f"{page_id} 0 R" for page_id in page_ids)
        self.set_object(
            pages_id,
            f"<< /Type /Pages /Kids [{kids}] /Count {len(page_ids)} >>".encode("ascii"),
        )
        catalog_id = self.add_object(
            f"<< /Type /Catalog /Pages {pages_id} 0 R >>".encode("ascii")
        )

        output = bytearray(b"%PDF-1.4\n%\xe2\xe3\xcf\xd3\n")
        offsets = [0]
        for index, obj in enumerate(self.objects, start=1):
            offsets.append(len(output))
            output.extend(f"{index} 0 obj\n".encode("ascii"))
            output.extend(obj)
            output.extend(b"\nendobj\n")

        xref_offset = len(output)
        output.extend(f"xref\n0 {len(self.objects) + 1}\n".encode("ascii"))
        output.extend(b"0000000000 65535 f \n")
        for offset in offsets[1:]:
            output.extend(f"{offset:010d} 00000 n \n".encode("ascii"))

        output.extend(
            (
                f"trailer\n<< /Size {len(self.objects) + 1} /Root {catalog_id} 0 R >>\n"
                f"startxref\n{xref_offset}\n%%EOF\n"
            ).encode("ascii")
        )

        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_bytes(output)


def add_footer(page: Canvas, page_number: int) -> None:
    page.line(48, 790, 547, 790, PALETTE["teal_light"], width=1.2)
    page.text(
        48,
        800,
        "Track - New Product Possibilities",
        font="F3",
        size=9,
        color=PALETTE["muted"],
    )
    page.text(525, 800, str(page_number), font="F2", size=9, color=PALETTE["muted"])


def render_opportunity_card(
    page: Canvas,
    *,
    top: float,
    accent: Color,
    title: str,
    impact: str,
    effort: str,
    summary: str,
    fit: str,
) -> None:
    page.rect(48, top, 499, 198, PALETTE["white"])
    page.rect(48, top, 8, 198, accent)
    page.text(70, top + 20, title, font="F2", size=18)
    page.tag(70, top + 46, f"Impact: {impact}", 118, PALETTE["sand"])
    page.tag(196, top + 46, f"Effort: {effort}", 118, PALETTE["sage"])
    page.text(70, top + 84, "What it unlocks", font="F2", size=11, color=PALETTE["teal"])
    page.paragraph(70, top + 101, 455, summary, size=11, leading=15)
    page.text(70, top + 147, "Why it fits Track now", font="F2", size=11, color=PALETTE["teal"])
    page.paragraph(70, top + 164, 455, fit, size=11, leading=15, color=PALETTE["muted"])


def cover_page() -> Canvas:
    page = Canvas()
    page.rect(0, 0, PAGE_WIDTH, 158, PALETTE["teal"])
    page.rect(0, 158, PAGE_WIDTH, 14, PALETTE["gold"])
    page.text(48, 44, "Track", font="F2", size=34, color=PALETTE["white"])
    page.text(
        48,
        88,
        "New product possibilities grounded in the current codebase",
        font="F1",
        size=16,
        color=PALETTE["white"],
    )
    page.text(
        48,
        116,
        "Prepared on April 9, 2026 from a repo scan of the habits, money, insights, and dashboard surfaces.",
        font="F3",
        size=11,
        color=PALETTE["white"],
    )

    page.rect(48, 208, 499, 124, PALETTE["white"])
    page.text(70, 230, "Executive Summary", font="F2", size=18)
    page.paragraph(
        70,
        260,
        455,
        (
            "Track already has the right base for a differentiated product: a real habits loop, "
            "a credible money tracker, local-first data, and early insight scaffolding. The biggest "
            "opportunity is not more isolated CRUD. It is turning Track into a proactive personal "
            "operating system that interprets behavior and suggests the next action."
        ),
        size=11,
        leading=15,
    )

    page.rect(48, 356, 238, 218, PALETTE["teal_light"])
    page.text(66, 380, "What already looks strong", font="F2", size=16)
    page.bullets(
        66,
        410,
        198,
        [
            "Habits already support streaks, measurable logs, detailed pages, and dashboard summaries.",
            "Money already has accounts, categories, currencies, bookmarks, transfers, and recent-activity surfaces.",
            "The architecture is clean, local-first, and ready for more derived intelligence without breaking the domain boundaries.",
        ],
        size=10.5,
        leading=14,
    )

    page.rect(309, 356, 238, 218, PALETTE["rose"])
    page.text(327, 380, "Where the whitespace is", font="F2", size=16)
    page.bullets(
        327,
        410,
        198,
        [
            "Insights, analysis, and budgets are routed and partially modeled, but still mostly placeholders in the UI.",
            "The app does not yet connect habits and money into one narrative or one decision surface.",
            "Retention features are still reactive; the product records behavior well, but it does not coach recovery or planning yet.",
        ],
        size=10.5,
        leading=14,
    )

    page.rect(48, 604, 499, 138, PALETTE["white"])
    page.text(70, 628, "Product Thesis", font="F2", size=18)
    page.paragraph(
        70,
        658,
        455,
        (
            "The clearest way to make Track feel different is to connect habits, money, and insights around one daily question: "
            "what should the user do next? The dashboard should become the answer, not just a summary."
        ),
        size=12,
        leading=17,
    )

    add_footer(page, 1)
    return page


def opportunities_page_one() -> Canvas:
    page = Canvas()
    page.rect(0, 0, PAGE_WIDTH, 86, PALETTE["teal"])
    page.text(48, 28, "Highest-Leverage Possibilities", font="F2", size=24, color=PALETTE["white"])
    page.text(
        48,
        58,
        "These are the best near- and mid-term bets based on what is already built.",
        font="F1",
        size=11,
        color=PALETTE["white"],
    )

    render_opportunity_card(
        page,
        top=110,
        accent=PALETTE["gold"],
        title="1. Daily Brief + AI Coach",
        impact="Very High",
        effort="Medium",
        summary=(
            "Create a morning and evening brief that blends habits due today, safe-to-spend guidance, notable anomalies, "
            "and one recommended action. This should feel like opinionated coaching, not generic chat."
        ),
        fit=(
            "The dashboard, AI insight card, and local insights table already point in this direction. "
            "Caching scored insights locally keeps the feature fast, explainable, and resilient offline."
        ),
    )
    render_opportunity_card(
        page,
        top=326,
        accent=PALETTE["teal"],
        title="2. Real Budgets + Safe to Spend",
        impact="Very High",
        effort="Medium",
        summary=(
            "Turn the current budget scaffolding into a live system with category limits, burn-rate tracking, "
            "remaining-per-day guidance, rollover behavior, and near-limit nudges."
        ),
        fit=(
            "Budget routes and schema already exist, so this is one of the fastest ways to convert placeholder surface area "
            "into daily value that users immediately understand."
        ),
    )
    render_opportunity_card(
        page,
        top=542,
        accent=PALETTE["gold"],
        title="3. Recurring Money Automation",
        impact="High",
        effort="Medium",
        summary=(
            "Add recurring bills, salary, subscriptions, and transaction templates or rules so manual entry drops over time. "
            "The goal is to make the money side reliable enough for stronger forecasting and insights."
        ),
        fit=(
            "The current money model is already deeper than the habits placeholder screens. Automation compounds the value "
            "of accounts, categories, bookmarks, and transfers without changing the core mental model."
        ),
    )

    add_footer(page, 2)
    return page


def opportunities_page_two() -> Canvas:
    page = Canvas()
    page.rect(0, 0, PAGE_WIDTH, 86, PALETTE["teal"])
    page.text(48, 28, "More Possibilities", font="F2", size=24, color=PALETTE["white"])
    page.text(
        48,
        58,
        "These ideas extend the product from tracker to operating system.",
        font="F1",
        size=11,
        color=PALETTE["white"],
    )

    render_opportunity_card(
        page,
        top=110,
        accent=PALETTE["teal"],
        title="4. Cross-Feature Goals",
        impact="High",
        effort="Medium-High",
        summary=(
            "Let users define outcomes that combine habits and money, such as 'Run 12 times and save $200 for race month'. "
            "Show one progress card fed by multiple data streams."
        ),
        fit=(
            "This is the cleanest way to unify the app's two strongest pillars. It gives the product a narrative layer "
            "without forcing a complex social graph or external integrations first."
        ),
    )
    render_opportunity_card(
        page,
        top=326,
        accent=PALETTE["gold"],
        title="5. Analysis Builder / Insight Marketplace",
        impact="Medium-High",
        effort="High",
        summary=(
            "Offer reusable analyses such as 'coffee spend drift', 'habit consistency by weekday', or "
            "'high-spend weeks after low-sleep weeks'. Start with templates, then allow custom pinning."
        ),
        fit=(
            "The analysis and insight routes are already reserved. Local-first storage makes recurring derived reports cheap, "
            "and the product can gradually expose more power without becoming a blank analytics canvas."
        ),
    )
    render_opportunity_card(
        page,
        top=542,
        accent=PALETTE["teal"],
        title="6. Recovery System for Broken Streaks",
        impact="Medium",
        effort="Low-Medium",
        summary=(
            "Detect slumps early, suggest a lighter temporary target, and help users restart after misses. "
            "That changes Track from an app that rewards perfection into one that protects momentum."
        ),
        fit=(
            "Reminder fields, target values, and measurable logs already exist in the habit model. This feature improves retention "
            "without requiring a net-new feature pillar."
        ),
    )

    add_footer(page, 3)
    return page


def roadmap_page() -> Canvas:
    page = Canvas()
    page.rect(0, 0, PAGE_WIDTH, 86, PALETTE["teal"])
    page.text(48, 28, "Recommended Sequence", font="F2", size=24, color=PALETTE["white"])
    page.text(
        48,
        58,
        "Build trust and daily habit before chasing the broadest platform ambition.",
        font="F1",
        size=11,
        color=PALETTE["white"],
    )

    blocks = [
        (
            112,
            PALETTE["sand"],
            "Now",
            [
                "Ship real budgets with safe-to-spend math and near-limit nudges.",
                "Add recurring transactions and high-speed transaction templates.",
                "Lay the Daily Brief foundation with one insight card and one recommended action.",
            ],
        ),
        (
            272,
            PALETTE["sage"],
            "Next",
            [
                "Expand the brief into a proper insight engine with confidence, expiry, and dismissal states.",
                "Add recovery flows for broken streaks and confidence-building nudges.",
                "Launch cross-feature goal cards to connect money and habits around outcomes.",
            ],
        ),
        (
            432,
            PALETTE["rose"],
            "Later",
            [
                "Open up analysis templates and eventually a light custom builder.",
                "Explore premium exports, advanced forecasting, and team or household layers only after the single-user loop is strong.",
                "Use integrations as accelerants, not as the first source of product differentiation.",
            ],
        ),
    ]

    for top, fill, title, items in blocks:
        page.rect(48, top, 499, 126, fill)
        page.text(70, top + 20, title, font="F2", size=18)
        page.bullets(70, top + 50, 455, items, size=11, leading=15)

    page.rect(48, 590, 242, 148, PALETTE["white"])
    page.text(68, 614, "Positioning Note", font="F2", size=16)
    page.paragraph(
        68,
        642,
        200,
        (
            "Do not start with generic AI chat. The stronger move is an opinionated dashboard that explains what changed, "
            "why it matters, and what to do next."
        ),
        size=10.5,
        leading=14,
    )

    page.rect(305, 590, 242, 148, PALETTE["white"])
    page.text(325, 614, "Best Single Bet", font="F2", size=16)
    page.paragraph(
        325,
        642,
        200,
        (
            "Combine Daily Brief + Safe to Spend first. That pairing is understandable, defensible, and visible every day. "
            "It also creates the best foundation for a premium tier later."
        ),
        size=10.5,
        leading=14,
    )

    page.text(
        48,
        760,
        "Repo cues used for this recommendation included the existing habits and money pages, the dashboard shell, and the scaffolded insights, analysis, and budget surfaces.",
        font="F3",
        size=9.5,
        color=PALETTE["muted"],
    )

    add_footer(page, 4)
    return page


def main() -> None:
    output_path = Path("output/pdf/track_new_possibilities.pdf")
    pages = [
        cover_page(),
        opportunities_page_one(),
        opportunities_page_two(),
        roadmap_page(),
    ]
    doc = PDFDocument()
    doc.build(pages, output_path)
    print(output_path)


if __name__ == "__main__":
    main()
