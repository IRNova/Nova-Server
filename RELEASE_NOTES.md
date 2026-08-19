# Nova Server 1.68.0

The panel tells you what an update changed.

## A note after an update, once

When a node updates, the next time you open its panel a short note says what
changed. It appears once for you and never again, and each administrator gets
their own: one person dismissing it does not dismiss it for everybody else on
the node.

A fresh install shows nothing. Somebody who has just installed Nova has not
lived through a change, and being told about one is noise.

## Every release, kept

What's new in the menu lists the releases, newest first, so the note is not the
only chance to read it. It goes back several versions, and each release adds to
it.

It is written in English, Persian and Russian, and it follows whichever language
the panel is set to.

## It works on a node that cannot reach the internet

The text ships inside the update itself rather than being fetched from
anywhere. A node behind a filter, or one with no route out at all, still
answers "what did this update do", which is a normal condition for these
servers rather than an unusual one.

## Upgrading

Update and restart. The note appears the next time you open the panel, and the
page is there whenever you want it.
