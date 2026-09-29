from msm_playerdata import coerce_wire_types


class ModValidationError(Exception):
    pass


MONSTER_CATALOG_REQUIRED_FIELDS = ("common_name", "genes", "graphic", "entity_id")
ISLAND_REQUIRED_FIELDS = ("island_type",)


def validate_monster_catalog_entry(definition):
    missing = [f for f in MONSTER_CATALOG_REQUIRED_FIELDS if f not in definition]
    if missing:
        raise ModValidationError(
            f"monster catalog entry missing required fields: {missing }"
        )
    if not isinstance(definition.get("graphic"), dict) or not definition["graphic"].get(
        "file"
    ):
        raise ModValidationError(
            "monster catalog entry needs graphic.file pointing at an existing shipped asset key"
        )

    return coerce_wire_types(definition)


def validate_island_entry(definition):
    missing = [f for f in ISLAND_REQUIRED_FIELDS if f not in definition]
    if missing:
        raise ModValidationError(f"island entry missing required fields: {missing }")
    return coerce_wire_types(definition)
