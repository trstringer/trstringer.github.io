---
layout: post
title: Azure Consumption Summary from the Command Line
categories: [Blog]
tags: [azure]
---

I manage my own personal Azure subscription where I run workloads all the time. I like to keep a close eye on my consumption ($$$) to make sure I'm not overspending, and to see where the money is going.

The consumption analysis in the Azure Portal is great, but I live in the terminal and my preference is always to be able to do something from the command line. Plus, it's a lot quicker/easier to type a few characters than to open a browser window and click the mouse.

Because of this preference I created a small Python utility (and wrapper script) to give me a report summary right in my terminal!

![Azure consumption report](/images/az-consumption-report.png)

It gives a handful of useful information:

* The timeline that the data spans (and billing period)
* Total cost
* Cost breakdown by resource group
* Cost breakdown by resource type

To learn more or get it, please take a look at [az-consumption-summary (GitHub)](https://github.com/trstringer/az-consumption-summary) for installation and usage instructions!

If you run into any problems with it or have any feature requests, please [open up an issue in the repository](https://github.com/trstringer/az-consumption-summary/issues)!
