---
layout: post
title: Output Multiline Strings in GitHub Actions
categories: [Blog]
tags: [devops, github]
---

It is common in a pipeline to have operational steps share data. Typically that's in the form of an **output** from one step, and an **input** to another step. With GitHub Actions, this might be trickier than expected if you are working with multiline strings. Let's take a look at a few points.

## Single line output

When dealing with single line output, we can leverage the `set-output` syntax for a job step:

{% raw %}
```yaml
on:
  push:
    branch:
      - '*'

jobs:
  test_strings:
    name: test strings
    runs-on: ubuntu-latest
    steps:
      - name: create string
        run: |
          MY_STRING="hello world"
          echo "::set-output name=content::$MY_STRING"
        id: my_string
      - name: display string
        run: |
          echo "The string is: ${{ steps.my_string.outputs.content }}"
```
{% endraw %}

{% raw %}
To **output** this data, we echo the format string with  `::set-output name=<output_name>::<output_content>`. And to consume this data as **input** we can reference it with `${{ steps.<step_id>.outputs.<output_name> }}`. This works as expected:
{% endraw %}

![Single line output from GitHub Actions](/images/github-actions-1.png)

## Multiline output (failed attempt)

With the multiline output, you might be tempted to try the following similar approach to single line strings:

{% raw %}
```yaml
    steps:
      - name: create string
        run: |
          MY_STRING=$(cat << EOF
          first line
          second line
          third line
          EOF
          )
          echo "::set-output name=content::$MY_STRING"
        id: my_string
      - name: display string
        run: |
          echo "The string is: ${{ steps.my_string.outputs.content }}"
```
{% endraw %}

With this form, only the **first line** of the output would be transferred (which is very likely the undesired behavior):

![Failed multiline output from GitHub Actions](/images/github-actions-2.png)

That is because the `set-output` notation only works on single line input. So how do we get around this behavior and transfer multiline output to different steps?

## Option 1 - string substitution

One of the ways that we can circumvent this problem is to change this multiline string to a single line string, just like the first example. This solution was highlighted in [this community post](https://github.community/t/set-output-truncates-multiline-strings/16852). We can escape a few characters on **output** that the runners will then expand on **input**:

{% raw %}
```yaml
    steps:
      - name: create string
        run: |
          MY_STRING=$(cat << EOF
          first line
          second line
          third line
          EOF
          )
          MY_STRING="${MY_STRING//'%'/'%25'}"
          MY_STRING="${MY_STRING//$'\n'/'%0A'}"
          MY_STRING="${MY_STRING//$'\r'/'%0D'}"
          echo "::set-output name=content::$MY_STRING"
        id: my_string
      - name: display string
        run: |
          echo "The string is: ${{ steps.my_string.outputs.content }}"
```
{% endraw %}

The part of this solution to focus on is that we're substituting the `%`, `\n`, and `\r` characters:

```
MY_STRING="${MY_STRING//'%'/'%25'}"
MY_STRING="${MY_STRING//$'\n'/'%0A'}"
MY_STRING="${MY_STRING//$'\r'/'%0D'}"
```

This is essentially turning this multiline string into a single line string with substitution. We get the desired data transfer:

![Failed multiline output from GitHub Actions](/images/github-actions-3.png)

## Option 2 - environment variable

Another solution is to instead to pass the multiline string through an environment variable. The way to do that is through pushing the raw data through `$GITHUB_ENV`. Take note here how literal we need to be:

{% raw %}
```yaml
    steps:
      - name: create string
        run: |
          MY_STRING=$(cat << EOF
          first line
          second line
          third line
          EOF
          )
          echo "MY_STRING<<EOF" >> $GITHUB_ENV
          echo "$MY_STRING" >> $GITHUB_ENV
          echo "EOF" >> $GITHUB_ENV
        id: my_string
      - name: display string
        run: |
          echo "The string is: ${{ env.MY_STRING }}"
```
{% endraw %}

With this approach we completely deviate from the `set-output` notation and instead use environment variables. Here we want to focus on this:

```
echo "MY_STRING<<EOF" >> $GITHUB_ENV
echo "$MY_STRING" >> $GITHUB_ENV
echo "EOF" >> $GITHUB_ENV
```

{% raw %}
We're constructing a [here document](https://tldp.org/LDP/abs/html/here-docs.html) and pushing it incrementally to `$GITHUB_ENV`. By doing this, we are then able to reference this multiline string that is stored in the environment variable as **input** with `${{ env.<environment_variable> }}` (in this example it is `${{ env.MY_STRING }}`). The behavior is as desired:
{% endraw %}

![Failed multiline output from GitHub Actions](/images/github-actions-4.png)

## Summary

Illustrated here are two ways you can approach passing multiline data between GitHub Actions steps. Using environment variables is more elegant in my opinion because it is much easier to remember than the string substitution (which would most likely be a copy/paste solution). Hopefully this blog post has helped clear up any confusion!
