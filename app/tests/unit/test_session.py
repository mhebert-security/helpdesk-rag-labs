"""Unit tests for the session store."""

from src.session.store import SessionStore


def test_turns_are_stored_and_retrieved():
    """A turn appended to a session is returned by get_history."""
    store = SessionStore()
    store.append_turn("sess-1", "user", "hello")
    store.append_turn("sess-1", "assistant", "hi there")
    history = store.get_history("sess-1")
    assert history == [
        {"role": "user", "content": "hello"},
        {"role": "assistant", "content": "hi there"},
    ]


def test_two_sessions_are_isolated():
    """One session must not read another session's turns.

    INTENTIONAL FAILURE IN v0: the baseline store shares a single history
    across every session id, so this isolation guarantee does not hold yet.
    This test fails by design until lab 01 adds real per-session storage.
    """
    store = SessionStore()
    store.append_turn("alice", "user", "message for alice")
    store.append_turn("bob", "user", "message for bob")
    alice_history = [turn["content"] for turn in store.get_history("alice")]
    assert alice_history == ["message for alice"]
