EXERCISES = [
    {
        "slug": "squat",
        "display_name": "Squat",
        "camera_views": ["side", "front"],
    },
    {
        "slug": "pushup",
        "display_name": "Push-up",
        "camera_views": ["side"],
    },
]

EXERCISE_SLUGS = [exercise["slug"] for exercise in EXERCISES]

_EXERCISE_NAMES = {
    exercise["slug"]: exercise["display_name"]
    for exercise in EXERCISES
}


def get_exercise_name(slug):
    return _EXERCISE_NAMES.get(slug, slug)


def is_supported_exercise(slug):
    return slug in _EXERCISE_NAMES
