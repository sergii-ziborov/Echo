"""Add or change player text in Shared/Localization/Localizable.xcstrings.

Every line ships in English and Russian under a stable key. Use this module
instead of editing the catalog by hand, so both languages always take the
same parameters and Russian counts get all four plural forms:

    import sys; sys.path.insert(0, "scripts")
    from l10n import load, save, put, put_plural

    cat = load()
    put(cat, "lab.toast.needMore", "Need more points", "Нужно больше очков")
    put_plural(cat, "lab.charges",
               {"one": "%lld charge", "other": "%lld charges"},
               {"one": "%lld заряд", "few": "%lld заряда", "many": "%lld зарядов", "other": "%lld заряда"})
    save(cat)

Integers are %lld, text is %@, and a literal percent sign is %%. Russian
lines address the player without a gender: make the Signal the subject.
"""
import json
import os
import re

CATALOG = os.path.join(os.path.dirname(__file__), "..", "Shared", "Localization", "Localizable.xcstrings")


def load(path=CATALOG):
    with open(path, encoding="utf-8") as file:
        return json.load(file)


def save(catalog, path=CATALOG):
    with open(path, "w", encoding="utf-8") as file:
        json.dump(catalog, file, ensure_ascii=False, indent=2, sort_keys=True)
        file.write("\n")


def _unit(value):
    return {"stringUnit": {"state": "translated", "value": value}}


def specifiers(text):
    """The format parameters of a line, in a comparable order."""
    return sorted(re.findall(r"%(?:\d+\$)?(?:lld|ld|d|@|\.?\d*f|lf)", text))


def put(catalog, key, en, ru, comment=None):
    """One line in both languages; their parameters must match."""
    if not en or not ru:
        raise ValueError(f"{key}: both languages are required")
    if specifiers(en) != specifiers(ru):
        raise ValueError(f"{key}: parameters differ {specifiers(en)} vs {specifiers(ru)}")
    entry = {"extractionState": "manual", "localizations": {"en": _unit(en), "ru": _unit(ru)}}
    if comment:
        entry["comment"] = comment
    catalog["strings"][key] = entry


def put_plural(catalog, key, en, ru, comment=None):
    """A counted line: English one/other, Russian one/few/many/other."""
    if set(en) != {"one", "other"} or set(ru) != {"one", "few", "many", "other"}:
        raise ValueError(f"{key}: English needs one/other, Russian one/few/many/other")
    shapes = {tuple(specifiers(text)) for text in [*en.values(), *ru.values()]}
    if len(shapes) != 1:
        raise ValueError(f"{key}: plural forms take different parameters {shapes}")
    entry = {"extractionState": "manual", "localizations": {
        "en": {"variations": {"plural": {form: _unit(text) for form, text in en.items()}}},
        "ru": {"variations": {"plural": {form: _unit(text) for form, text in ru.items()}}},
    }}
    if comment:
        entry["comment"] = comment
    catalog["strings"][key] = entry
