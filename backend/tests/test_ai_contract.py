"""The AIProvider contract, and the sentiment coercion that protects reviews."""

import pytest

from app.models import Sentiment
from app.services.ai.base import AIProvider, coerce_sentiment, coerce_topic_sentiment
from app.services.ai.providers.mock import MockAIProvider


class TestCoerceSentiment:
    """Regression tests for the bug that destroyed reviews.

    routers/reviews.py passed the model's raw string into Sentiment(...). Any
    value outside the three exact lowercase tokens raised ValueError, which
    propagated out of the request handler, rolled back the session in get_db,
    and took the customer's not-yet-committed review with it. The mock provider
    masked this by only ever emitting the three exact strings a real model does
    not reliably produce.
    """

    @pytest.mark.parametrize(
        ("raw", "expected"),
        [
            ("positive", "positive"),
            ("neutral", "neutral"),
            ("negative", "negative"),
            # Capitalisation is the single most common real-world variation.
            ("Positive", "positive"),
            ("NEGATIVE", "negative"),
            ("  Neutral  ", "neutral"),
            # Values outside the enum entirely.
            ("mixed", "neutral"),
            ("very negative", "negative"),
            ("mostly positive", "positive"),
            ("unknown", "neutral"),
            # Absent or malformed output.
            ("", "neutral"),
            (None, "neutral"),
            (0, "neutral"),
            ([], "neutral"),
        ],
    )
    def test_coerces_to_a_valid_enum_value(self, raw, expected):
        assert coerce_sentiment(raw) == expected

    @pytest.mark.parametrize(
        "raw",
        ["Positive", "MIXED", "", None, "very negative", "n/a", "🙂", 42],
    )
    def test_result_always_constructs_a_Sentiment(self, raw):
        """The actual failure condition: Sentiment(...) must never raise."""
        assert Sentiment(coerce_sentiment(raw)) in Sentiment


class TestCoerceTopicSentiment:
    """S-049: the topic-aggregate sentiment domain is deliberately 3-value
    (positive|negative|mixed), not the DB Sentiment enum -- "mixed" is a
    sharper signal for a topic than "neutral" is for a single review. Same
    never-raise non-negotiable as coerce_sentiment.
    """

    @pytest.mark.parametrize(
        ("raw", "expected"),
        [
            ("positive", "positive"),
            ("negative", "negative"),
            ("mixed", "mixed"),
            ("Positive", "positive"),
            ("NEGATIVE", "negative"),
            ("  Mixed  ", "mixed"),
            ("mostly positive", "positive"),
            ("very negative", "negative"),
            # Ambiguous/unrecognized free-form output defaults to "mixed",
            # not "neutral" -- there is no neutral in this domain.
            ("neutral", "mixed"),
            ("unknown", "mixed"),
            ("", "mixed"),
            (None, "mixed"),
            (0, "mixed"),
            ([], "mixed"),
        ],
    )
    def test_coerces_to_the_three_value_domain(self, raw, expected):
        assert coerce_topic_sentiment(raw) == expected

    @pytest.mark.parametrize(
        "raw",
        ["Positive", "NEGATIVE", "", None, "very mixed signals", "n/a", "🙂", 42, {"a": 1}],
    )
    def test_never_raises(self, raw):
        assert coerce_topic_sentiment(raw) in {"positive", "negative", "mixed"}


class TestProviderContract:
    def test_provider_name_is_required(self):
        with pytest.raises(TypeError, match="provider_name"):

            class Nameless(AIProvider):
                async def analyze_review_text(self, text, context=None): ...
                async def analyze_image(self, image_url, context=None): ...
                async def generate_merchant_summary(self, reviews, context=None): ...

    def test_intermediate_bases_may_opt_out(self):
        class SharedBase(AIProvider, abstract=True):
            """A shared base is not itself a usable provider."""

        assert not getattr(SharedBase, "provider_name", None)

    def test_incomplete_provider_cannot_be_instantiated(self):
        class Partial(AIProvider):
            provider_name = "partial"

            async def analyze_review_text(self, text, context=None): ...

        with pytest.raises(TypeError, match="abstract"):
            Partial()


class TestMockProvider:
    async def test_reports_itself_in_call_metadata(self):
        provider = MockAIProvider()

        review = await provider.analyze_review_text("Great and friendly service")
        image = await provider.analyze_image("/uploads/x.jpg")
        summary = await provider.generate_merchant_summary([{"sentiment": "positive"}])

        for result in (review, image, summary):
            assert result.meta.provider == "mock"
            # Nothing has degraded -- mock is the configured provider here, not
            # a fallback. The gateway is what sets this flag.
            assert result.meta.degraded is False

    @pytest.mark.parametrize(
        "text",
        ["dirty slow rude", "great excellent amazing", "", "a" * 5000, "🙂🙂🙂"],
    )
    async def test_sentiment_is_always_persistable(self, text):
        result = await MockAIProvider().analyze_review_text(text)
        assert Sentiment(result.sentiment) in Sentiment

    async def test_merchant_summary_carries_raw_response(self):
        """MerchantSummaryResult was the only result type missing this field."""
        result = await MockAIProvider().generate_merchant_summary([{"sentiment": "positive"}])
        assert result.raw_response
