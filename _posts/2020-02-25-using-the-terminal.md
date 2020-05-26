---
layout: post
title: 7 Reasons to Use the Terminal
tags: [linux]
categories: [Blog]
---

Many programmers and engineers understandably find the terminal to be an unapproachable environment for productivity. And for good reason: There is a learning curve with the terminal before you can be extra productive.

I think it is worth the time investment because once you get beyond that learning curve your efficiency, accuracy, and engineering discipline are maximized. Here are several reasons why...

## 1. Reproducibility

You can save a few-liners in the terminal to a shell script and you can "replay" that action infinitely, always knowing that it'll do the exact same thing. Point-and-click on a GUI is best served from memory. And our memories are not as reliable as computer storage.

## 2. You can type faster than you can click

Maybe the first time you want to do something, it could be faster to use the mouse to navigate through. But for a familiar action either through the GUI or terminal, typing is going to be much quicker.

## 3. Maximize collaboration

Want to show a teammate or friend what exactly you did? It's easy to send the commands you typed in the terminal through email. They have to only copy/paste and they can reproduce your exact actions. Mix in a GUI, and now you're doing things like trying to explain which button to click, sending screenshots, or recording your screen. None of that is fun, and it is *very* prone to error.

*This is even more important for remote workers that don't have the ability to stare over your shoulder and look at your screen while you do something at your desk.*

## 4. Single layer of interactivity

Usually with a GUI you have to click through multiple layers to finally get to the action you finally want to accomplish. Many times CLIs (command-line interfaces) give you a single layer. Put another way, one line in the terminal usually means many clicks in the GUI.

## 5. It's the way of the server

You might have a nice desktop environment that gives you ability to use the GUI to configure your system. But the minute you need to work on a server, it's SSH in the terminal. Having a terminal-first workflow makes working on a server much more comfortable and easier.

*This is also a good reason (among many good reasons) to get familiar and efficient with a terminal-based editor, like Vim.*

## 6. It's the entrypoint for shell scripting

I write shell scripts for everything that I don't want to repeat twice. This might be for something important like building software, but could be something as trivial as getting the current weather today. Working in the terminal is the start to writing shell scripts.

## 7. History

Many (all?) shells keep track of your history. As a Bash user, it's common for me to interact with `history` in a few different ways. Beyond dumping history with the bin, you can also do many *extremely* efficient things like `CTRL+R` reverse history search, and just start typing your search string. I can't count how many times daily I use `!!` to repeat the last command, or `!$` to repeat the last string of the last command. These simple tricks keep your workflow quick so that it can keep up with your brain. Rarely do I use the up arrow to scroll through history. Most GUIs lack any form of history, making you wonder exactly what you clicked yesterday evening before your stopped work for the day.

## Conclusion

Before you point and click on a GUI, ask yourself if this task is possible in the terminal (maybe it isn't. I don't do frontend things, and I can understand not all engineers even could work in the terminal). If it is, try it in the terminal. Not just once, but a few times, for a few days/weeks. I think you might see the benefits that I do daily.

Enjoy!
