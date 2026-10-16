import json
import os
import re
import sys

from pypdf import PdfReader


# Los PDF no tienen una estructura universal. Estas reglas solo aceptan señales
# relativamente claras y dejan la última palabra al usuario en el Catálogo.
CATEGORY_ALIASES = {
    "objeto": "Objeto", "object": "Objeto", "weapon": "Objeto",
    "armor": "Objeto", "armour": "Objeto", "item": "Objeto",
    "raza": "Raza", "race": "Raza", "linaje": "Raza", "ancestry": "Raza",
    "clase": "Clase", "class": "Clase",
    "conjuro": "Conjuro", "spell": "Conjuro",
    "monstruo": "Enemigo", "monster": "Enemigo", "criatura": "Enemigo",
    "creature": "Enemigo", "enemigo": "Enemigo",
    "regla": "Regla", "rule": "Regla", "rules": "Regla",
}


def _clean_line(line: str) -> str:
    return re.sub(r"\s+", " ", line).strip(" \t-–—:;|")


def _valid_name(value: str) -> bool:
    if not (2 <= len(value) <= 120):
        return False
    lowered = value.lower()
    return not any(token in lowered for token in ("página", "page", "contenido", "contents"))


def _first_title(lines: list[str]) -> str:
    for line in lines[:12]:
        candidate = _clean_line(line)
        if _valid_name(candidate) and len(candidate.split()) <= 10:
            return candidate
    return ""


def _infer_category(text: str) -> str | None:
    lowered = text.lower()
    if re.search(r"\b(clase de armadura|armor class|puntos de golpe|hit points)\b", lowered):
        return "Enemigo"
    if re.search(r"\b(tiempo de lanzamiento|casting time|nivel de conjuro|spell level)\b", lowered):
        return "Conjuro"
    if re.search(r"\b(rasgos raciales|racial traits|aumento de puntuación|ability score increase)\b", lowered):
        return "Raza"
    if re.search(r"\b(rasgos de clase|class features|dado de golpe|hit dice)\b", lowered):
        return "Clase"
    if re.search(r"\b(peso|weight|daño|damage|rareza|rarity)\b", lowered):
        return "Objeto"
    return None


def extract_suggestions(text: str, page: int) -> list[dict]:
    lines = [_clean_line(line) for line in text.splitlines()]
    lines = [line for line in lines if line]
    suggestions: list[dict] = []
    seen: set[tuple[str, str]] = set()

    # Formato más fiable: "Conjuro: Bola de fuego" o "Raza — Elfo".
    prefix = re.compile(
        r"^(objeto|object|weapon|armor|armour|item|raza|race|linaje|ancestry|"
        r"clase|class|conjuro|spell|monstruo|monster|criatura|creature|enemigo|"
        r"regla|rule|rules)\s*[:\-–—]+\s*(.+)$",
        re.IGNORECASE,
    )
    for line_index, line in enumerate(lines):
        match = prefix.match(line)
        if not match:
            continue
        category = CATEGORY_ALIASES[match.group(1).lower()]
        name = _clean_line(match.group(2))
        key = (category, name.lower())
        if _valid_name(name) and key not in seen:
            seen.add(key)
            notes = " ".join(lines[line_index + 1:line_index + 9])[:2000]
            suggestions.append({"category": category, "name": name, "page": page, "notes": notes})

    # Formato de dos líneas: un encabezado de categoría y luego el nombre.
    for line_index, line in enumerate(lines[:-1]):
        category = CATEGORY_ALIASES.get(line.lower().rstrip("s")) or CATEGORY_ALIASES.get(line.lower())
        if not category:
            continue
        name = _clean_line(lines[line_index + 1])
        key = (category, name.lower())
        if _valid_name(name) and key not in seen:
            seen.add(key)
            notes = " ".join(lines[line_index + 2:line_index + 10])[:2000]
            suggestions.append({"category": category, "name": name, "page": page, "notes": notes})

    # Fichas de criatura/conjuro habituales no siempre incluyen el encabezado.
    inferred = _infer_category(text)
    title = _first_title(lines)
    key = (inferred or "", title.lower())
    if inferred and _valid_name(title) and key not in seen:
        suggestions.append({"category": inferred, "name": title, "page": page, "notes": " ".join(lines[1:14])[:2000]})

    return suggestions[:8]


def main() -> int:
    if len(sys.argv) != 3:
        return 2
    source, destination = sys.argv[1], sys.argv[2]
    reader = PdfReader(source)
    pages = []
    suggestions = []
    for number, page in enumerate(reader.pages, start=1):
        try:
            text = page.extract_text() or ""
        except Exception:
            text = ""
        pages.append({"page": number, "text": text})
		# Se limita por página; la app aplicará un segundo límite global y permitirá
		# revisar/editar cada propuesta antes de considerarla contenido definitivo.
        suggestions.extend(extract_suggestions(text, number))
    metadata = reader.metadata or {}
    payload = {
        "title": str(metadata.get("/Title") or os.path.splitext(os.path.basename(source))[0]),
        "source_path": os.path.abspath(source),
        "page_count": len(reader.pages),
        "pages": pages,
        "suggestions": suggestions[:160],
    }
    os.makedirs(os.path.dirname(destination), exist_ok=True)
    with open(destination, "w", encoding="utf-8") as stream:
        json.dump(payload, stream, ensure_ascii=False)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
