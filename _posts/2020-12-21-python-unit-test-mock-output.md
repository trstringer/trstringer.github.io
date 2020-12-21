---
layout: post
title: Change a Function's Output Based on Input Parameter Value in a Python Unit Test
categories: [Blog]
tags: [python]
---

When writing unit tests you always want to make sure you're testing the smallest unit possible. Oftentimes the code that we want to test is reaching out beyond the software itself: The two common ones are network and filesystem access. When creating and running unit tests, we typically don't want our code to reach out to *another* system.

So how can we make sure that function doesn't run, and we can just set it's output from within our unit tests?

## Mock the function

The way that we can "simulate" this behavior is to mock the function so that it actually *doesn't* extend beyond the software and stays local (and predictable).

Here's an example on how we could mock the `network_operation` function so it doesn't actually run an HTTP request and it **always** returns the same value, `"valid outout..."`:

**app.py**

```python
import requests

def network_operation(api_version: str):
    resp = requests.get(f"https://trstringer.com?api-version={api_version}")
    if resp.status_code != 200:
        raise requests.exceptions.HTTPError()

    return resp.text

def do_something(some_number: int, api_version: str):
    try:
        # Do a network operation that could fail
        network_output = network_operation(api_version=api_version)
        # ... process output ...
        return True
    except requests.exceptions.HTTPError:
        return False
```

**test_app.py**

```python
from unittest.mock import patch
from requests.exceptions import HTTPError
import app

@patch("app.network_operation")
def test_do_something(mock_network_operation):
    """Test the do_something function"""

    mock_network_operation.return_value = "valid output..."

    desired_output = True
    actual_output = app.do_something(
        some_number=3,
        api_version="2020-01-01"
    )
    assert actual_output == desired_output, f"Actual output {actual_output} did not match desired: {desired_output}"
```

We create a mock (that is scoped to the test function) by calling `patch("app.network_operation")` as a decorator. Now we are able to completely control the `network_operation` function and instead of running the original function, we can just change it's return value:

```python
mock_network_operation.return_value = "valid output..."
```

Now when `app.do_something` calls `app.network_operation`, the function won't run but it'll just always return the string `"valid output..."`.

## More mock control from parameter value

The above functionality utilizes [Mock.return_value](https://docs.python.org/3/library/unittest.mock.html#unittest.mock.Mock.return_value) and it is great, but there are going to be times when you need to have more control over what the mocked function returns based on parameter value.

What if you want to test out your code with a bad `api_version` that is passed to it? We can no longer rely on `Mock.return_value`, because we need some conditional logic now for `api_version`.

Say, for example, we know (and want to validate) that an `api_version` with a value of `"2020-01-01"` passed to `network_operation` will result in an `HTTPError`. We want to make sure our function `do_something` is handling this correctly. Likewise, we want to test what `do_something` does with a "good" `api_version`. We can achieve this by levaraging the [Mock.side_effect](https://docs.python.org/3/library/unittest.mock.html#unittest.mock.Mock.side_effect) feature. We can define a side effect function for our custom logic that mimics what `network_operation` would do based on `api_version`:

```python
def network_operation_side_effect(*args, **kwargs):
    if kwargs["api_version"] == "2020-01-01":
        raise HTTPError()
    return "valid output..."
```

Now in our unit tests we can set this function to be run (and return value to be conditionally set) for `network_operation`:

```python
@patch("app.network_operation")
def test_do_something_bad_api_version(mock_network_operation):
    """Test the do_something function"""

    def network_operation_side_effect(*args, **kwargs):
        if kwargs["api_version"] == "2020-01-01":
            raise HTTPError()
        return "valid output..."
    mock_network_operation.side_effect = network_operation_side_effect

    desired_output = False
    actual_output = app.do_something(
        some_number=3,
        api_version="2020-01-01"
    )
    assert actual_output == desired_output, f"Actual output {actual_output} did not match desired: {desired_output}"

@patch("app.network_operation")
def test_do_something_good_api_version(mock_network_operation):
    """Test the do_something function"""

    mock_network_operation.side_effect = network_operation_side_effect

    desired_output = True
    actual_output = app.do_something(
        some_number=3,
        api_version="2020-08-01"
    )
    assert actual_output == desired_output, f"Actual output {actual_output} did not match desired: {desired_output}"
```

In our unit tests, all we have to do is set `mock_network_operation.side_effect` to our new side effect function: `network_operation_side_effect`.

This allows us to have conditional and more granular control for the mocked function.

## Summary

Mocking is very important in testing as it allows us to reliably, securely, and efficiently test our code. Python gives a lot of tools for making complex testing scenarios quite simple. Happy testing!
