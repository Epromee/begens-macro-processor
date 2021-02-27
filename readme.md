# BEGENS

## WTF?

Begens (Beyond Generic Sql) is a TSQL macro processor. You feed it your TSQL code with macro-definitions, and it yields you good old TSQL back.

## Why do I need it?

To write some types of queries for your godblessed enterprise database faster.

## How to use it?

Check examples.sql and be happy.

## How to _not_ use it:

Current version is unstable, use it on your own risk. I don't recommend to macroprocess code which does sensitive changes (like, "drop everything" DDL - unless you really sure), because it might be executed incorrectly.
