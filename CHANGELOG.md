#### 0.0.4 (Unreleased)

*   When declaring an after_commit callback within another after_commit callback, it is now processed immediately rather than being added to the queue. This may not be expected behavior for some cases, but is consistent with the notion of treating the period immediately after a subtransaction ends as being outside of any transaction for testing purposes.

#### 0.0.3 (2014-06-28)

*   Fix bug where transactions wouldn't be cleared if an error was raised while processing an after_commit hook.

#### 0.0.2 (2014-06-25)

*   Initial release. Very simple, just runs after_commit hooks that were declared in a subtransaction when that subtransaction ends.
