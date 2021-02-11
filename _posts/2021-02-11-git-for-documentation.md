---
layout: post
title: 8 Reasons Why I Like git Repositories for Documentation (Personal and Team)
categories: [Blog]
tags: [software-development]
---

Writing code is hard. So is writing documentation. And I am a [big fan of creating your own documentation](https://trstringer.com/be-good-at-referencing/).

At this point in my life I've been writing documentation for a long time, both in a team and also for myself. I've used it all: Everything from wikis to note-taking software. For some time now, I've settled on simple and basic git repositories to store my notes and I have a handful of good reasons why.

*Note: When I talk about writing "documentation for myself", I mean for-my-eyes-only, not to be shared or read by others. This is usually just technical things for me, but this could be absolutely anything. My "notes".*

## 1. Write once, read many times

Many software applications for taking notes make it super easy to just dump data. A lot of times, I would find myself copy/pasting things into a notebook and move on without a second thought. Image? Copy it there. URL? Just add it to that page. It became very easy to have mental diarrhea in my notes. For "current me", that made sense. But I'd find myself coming back to these notes a week, month, or year later and it hardly made sense. It definitely lacked any good organization or consistency.

Note-taking is a generally chaotic practice. But by having to write in markdown and commit my notes to a git repo (with helper aliases to make it quicker), it forces me to be a little more thoughtful. After all, the point of notes is to write them once but read them many times. So I'm choosing an approach that makes writing them *maybe* a little longer, but reading is a much better experience.

There's no such thing as a "quick" note. Quick means disorganized, misplaced, or lacking in context. Quick notes are not good for future-you.

## 2. Require PRs and code reviews (team)

For team documentation, it is important that it is treated like code. You should have to open up a pull request and have it reviewed/approved by other team members before it is merged in. Why?

1. The words you write might make sense to you, but not others
1. You might be placing this documentation in the wrong place
1. It could be duplicate (or semi-duplicate) docs
1. Documentation styling should have consistency (and it isn't easy to lint docs)

## 3. Markdown is nice

In my experience, markdown is the perfect balance between outputing beautiful documents but also allowing for quick and easy writing. It is very natural with little mental obstacles.

## 4. Stored where you want (personal)

Only want your docs locally? Keep your git repo local. Get a browser plugin that can render markdown and that's all you need.

Want a backup or redundancy? Or do you want to be able to view your notes from anywhere you have a browser? You can create a private GitHub repo to store your docs. More on that below.

## 5. Online git services

There are a handful of great git services out there: GitHub, GitLab, Azure DevOps, and more. Having your notes git repo live remotely has a few really great benefits. The first one being is a redundant copy of your notes. So in the event something happens to your local machine, your notes are stored safely somewhere else.

The other benefit is that almost all modern git services show markdown really nicely. You aren't forced to consume your notes in markdown format in your text editor. I have a bookmark in my browser toolbar for the entry point to my notes and read them all directly through the browser.

## 6. Just a text editor

This one is big for me. I don't like depending on much software. The benefit to this approach is that all you need is a text editor and `git`. No fancy/expensive/unsupported software to deal with.

## 7. Searching is easy

Because it is just a bunch of text files, searching is easy. One of my big complaints about note-taking software is the searching functionality:

- What kind of string searching does it do? Was that a fuzzy search?
- How did it sort my search results?

We've all been searching through files for awhile now, so just continue to do what you're comfortable with and know. Outside of my editor, I can search for text with `grep -r "search_text" .`. Or if I want to search for a filename: `find . -name *search_text*`. My text editor of choice is Vim, so in it I can search with `:vim /search_text/ **/*`. Quick, easy, and I've been doing this kind of searching for awhile.

## 8. Versioning

One of the big benefits of git is its capability for versioning. By utilizing versioning, you can see the state of your notes in the past. And example of this is that my "to do" list is in my git repo. To know what I was working on 2 months ago all I need to do is a git checkout and it's there.

## Summary

Using git repos for my notes (and team notes) has proven to be very benefitial to me for the above reasons. Hopefully this will make you think about a similar solution!
