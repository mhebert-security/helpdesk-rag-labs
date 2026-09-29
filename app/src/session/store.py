"""In-memory chat history store.

v0 deliberately isolates nothing. Every session_id reads and writes one
shared history, so a caller who supplies any session id can see every other
session's turns. There is no expiry and no tenant binding either. Lab 01
replaces this with genuine per-session storage.
"""

from __future__ import annotations


class SessionStore:
    """Stores chat turns in memory, keyed nominally by session id."""

    def __init__(self) -> None:
        # One shared list for every session. session_id is accepted for
        # interface compatibility but is not used to isolate sessions. This
        # is the vulnerable baseline this lab proves before hardening.
        self._history: list[dict] = []

    def get_history(self, session_id: str) -> list[dict]:
        """Return the turn history for a session.

        v0 returns the same shared history for every session id, so sessions
        are not isolated from one another.
        """
        return self._history

    def append_turn(self, session_id: str, role: str, content: str) -> None:
        """Append one turn to the session history."""
        self._history.append({"role": role, "content": content})
