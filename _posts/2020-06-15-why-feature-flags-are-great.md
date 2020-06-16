---
layout: post
title: Why Feature Flags Are Great
categories: [Blog]
tags: [devops, software-development]
---

The rhythm that we develop software is at a high velocity, and as a software engineer I really like to take a step back and think about what works really well, and what doesn't work really well. In this blog post, I'm going to focus on a practice that falls in the former category: Feature flags. Here are a few reasons why I think they are a great thing.

## Validation in production

This is probably one of the bigger reasons that sticks out for me. It's a **really** great feeling to have your code baking in production with *no production workloads* hitting it. This slightly resembles testing in production (as long as it is done the right way).

A big benefit is that the code can live in production at little to no risk of affecting end users. This allows you to gain a higher level of confidence in the new feature's code paths.

## Enabling and disabling is just configuration

When your new feature's code has been living in production, you will be ready at some point to start directing user traffic to it (more details on that in the next point). The really great thing about lighting up code behind a feature flag is that it is a simple matter of flipping the switch (which typically looks like a single line of configuration).

And conversely, if (and when) your feature has negative impact and you need to get back to the last known good state, it is *much* easier to rollback a single line configuration option, instead of ripping out a massive feature that spans a large part of the codebase.

It's the difference between reverting this commit:

![Bad feature flags commit](/images/feature-flags-bad.png)

Or this commit:

![Good feature flags commit](/images/feature-flags-good.png)

## Easy canary rollouts

It's best when your lifecycle environments match as closely as possible to each other. So if the code drift between canary and production is minimal then you will have less surprises when it really matters. The nice thing about feature flags is that it allows you to have a canary rollout of just a feature flag change. Now the git diff between canary and production is that nice commit that we see above, instead of the massive one.

To add to the argument that it is good for canary, in many scenarios it allows you to redirect only a certain amount of traffic to the same bits. But in the case of a staged rollout, the onboarding traffic just has a feature flag set for canary users.

## Self-documenting behavior

Documentation is hard (but necessary!). One of the great side-effects of feature flags is that they are, by nature, self-documenting. Looking at what features are turned on gives you a good idea how the software is configured to run and what it is capable of.

I'm not arguing that feature flags eliminate the need for good documentation, but they are a great supplement for understanding what an implementation is doing.

## Summary

I'm a proponent of feature flags when developing big features in software. One of the great things with feature flags is that there is very little downside to the practice. Next time you are getting ready to write a software feature, consider putting it behind a flag!
