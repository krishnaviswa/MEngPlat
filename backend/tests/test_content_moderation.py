from app.services.content_moderation import contains_disallowed_language


def test_clean_review_is_allowed():
    assert contains_disallowed_language("Loved the coffee and friendly staff") is False


def test_obscene_word_is_flagged():
    assert contains_disallowed_language("This place is shit") is True


def test_substring_inside_normal_word_is_not_flagged():
    assert contains_disallowed_language("The cockpit seating was tight") is False
