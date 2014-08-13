#### 0.0.3 (2014-06-28)

*   Fix bug where transactions wouldn't be cleared if an error was raised while processing an after_commit hook.

#### 0.0.2 (2014-06-25)

*   Initial release. Very simple, just runs after_commit hooks that were declared in a subtransaction when that subtransaction ends.
