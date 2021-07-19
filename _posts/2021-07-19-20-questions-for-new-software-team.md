---
layout: post
title: 20 Questions a Software Engineer Should Ask When Joining a New Team
categories: [Blog]
tags: [software-development]
---

Different software development teams do things quite differently. Even within a single company, many of the variables can vary from team to team. As a software engineer, it is usually very exciting to start working with new people and on new software. On a personal note, I recently have started with a new team and on new (to me) software. Because this isn't a regular or frequent occurrence, I took the opportunity to really think about things that I needed to learn in the short term.

Here are the questions that I think software engineers should consider asking when joining a new software development team, grouped by categories.

## Technical

### 1. How do I locally build the software?

This is one of the first things you should learn. After all, you will be developing and running the software. Building is the first step!

### 2. How do I locally test the software?

CI pipelines are great to fine test errors, but to have a shorter inner dev loop cycle you want to be able to run tests on your machine as you develop to make sure that you are testing properly, but also checking for regressions. The pipeline should not be the first indication that you created or caused a failing test.

### 3. How do I setup my development environment?

Hopefully there are clear requirements in the team documentation, but you should know what different tools you need on your development machine so you can be a producing member of the team. Setting up the environment in one shot to handle 95% of the requirements is a lot better than the frustration of getting the errors and gradual dependencies as you start developing.

### 4. Where does the source code live?

Unless you are starting on a brand new team with software that hasn't been written yet, you will be working in a pre-existing code base. Where does the code live? How can I get the code on my local machine?

### 5. Where is the CI/CD pipeline and how does it work?

Hopefully are joining a team that ensures quality in the delivered product, and one of the most common tools for that is a CI/CD pipeline. Find out where it is and get a brief overview of how it works (could possibly be from just clicking around to understand things). Take a look at some of the more recent runs to see what steps are happening.

### 6. Where is the product backlog?

You will be working with the software in the present state, but it's good to know what the future state of the software should be. Give a quick browse of the backlog and see what some of the upcoming priorities for the product will be.

### 7. How does pre-production and production testing work?

Are there integration environments? Does this team do canary builds and deployments to test? Does this team subscribe to chaos engineering? Find out how this team ensures that their production software is and remains at a certain standard.

### 8. What is on-call like?

Is there on-call for this software? If so, what is the rotation? How often do incidents come in? Is there non-working hours requirements for on-call? How will I get notified when I am on-call? Usually you don't start a new team and get pushed right into the rotation, so over time you should get some of these answers before you start getting phone calls.

### 9. Where is the internal documentation?

Where does the team maintain their internal documentation? How is it broken up? Is it up-to-date?

## Collaboration

### 10. Who on the team is focusing on what?

Usually software teams have a handful of engineers. Sometimes every engineer is working on a single thing, but that's not typical. Sub-projects are usually being worked on by a single or a couple of engineers together. It's good to get an idea of the focus for the different programmers on the team so you have some awareness. Usually the standups will give you a pretty good idea of that over time.

### 11. What is the weekly cadence of the team?

Is there a daily standup? Weekly check-ins? It's good to know what a "typical" week looks like on your new team.

### 12. Who should I contact with "beginner" questions?

Usually when you start a new team you should be assigned an "onboarding buddy". Somebody that has been on the team and knows how things work. This is a *very* valuable thing, especially with the humble expectation that you know nothing (or close to nothing) about the new software and your questions can be very level 100. And that's good, normal, and expected. No shame with beginner questions, even if you are a senior-level engineer.

### 13. Who/what drives new features?

Does the product have a product manager? Is there an architect working with the engineers? It's good to know the upstream of ideas for feature requests. Even better, schedule some time with this person (or people) to understand what the near and distant future for the product looks like.

### 14. How does the team primarily communicate?

Do they use Slack? Teams? Or is most of the async communication through email? Engineers are usually talking throughout the day about questions and other types of discussions. Of course as a new member on the team, you'll want to plug yourself into these communication channels.

## External

### 15. How do we get customer feedback?

Is this open source software on GitHub? Are GitHub Issues the way we get feedback? Or is there a sales team that is our proxy from customers to the product team? Is there a different team for support that we can collect common customer pain points from? In other words, it's good to find out how we get user feedback: Whether it's through another platform, person, or team. After all, we write software for users.

### 16. What are the support agreements for our customers?

Is there an SLA that we are bound to? What exactly do we support for our user scenarios?

### 17. Where is the public/customer documentation?

This is an important one. Now matter how good the software is, the customer documentation should be accurate and up-to-date. Where can you browse that documentation? How does the documentation stay current? Who's responsibility is it? (Hopefully the answer is "everybody").

## Product focus

### 18. What are some high-level pain points for the software?

It's good to find out if right now there are some big issues that the software and team are dealing with. Is there some architectural problem that has caused other problems? Is there a security flaw that can be exploited? Is there a common customer issue that keeps coming up and needs to be addressed?

### 19. What is the focus from stakeholders?

Are there certain features in the software that key individuals or other teams want to see? Oftentimes these stakeholders can have a significant impact into the short and long term roadmap for the software. Understanding where their focus is can help visualize what might be coming soon.

### 20. What is the release cycle of the sofware?

It is good to know the cadence of how often and when the software is released to customers. Does the team continuously deploy multiple times a day? Or is there a release twice a year? Understanding this schedule of software release can give you a good idea of the software rhythm.

## Summary

Joining a new software team and working on a new technology is a **really exciting** time for most software engineers! A time of learning and mystery. Hopefully these questions can help expediate the onboarding process for you the next time you join a new team as well!
