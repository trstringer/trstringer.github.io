---
layout: post
title: Adding Tests to Go Project Templates
categories: [Blog]
tags: [golang]
---

I recently blogged about [Go project templates](https://trstringer.com/go-project-templates/) and how you can use some boilerplate to quickly get up and running with your new Go program. It's also a pretty common thing to write CLIs in Go, and I have an available [Go template for a simple CLI](https://github.com/trstringer/go-template-cli-simple).

Up until now, something was missing in that template to make it even _easier_ to get Go-ing on a CLI... tests! It's no shock to anybody these days that we should be writing tests, and all types of them. In most cases, unit and end-to-end (e2e) tests are what you're looking for. It isn't a trivial thing to add the necessary code for these tests, especially e2e tests. So I wanted these to be baked into my Go project template.

## Unit tests

It was pretty easy to add boilerplate for unit tests (thanks to Go's great tooling). I added a sample `main_test.go` file which includes a single test function. I'm a big fan of table driven tests, so this function has a couple of test cases.

```go
package main

import "testing"

func TestMessageWithExclamation(t *testing.T) {
	testCases := []struct {
		name           string
		input          string
		useExclamation bool
		expected       string
	}{
		{
			name:           "without_exclamation",
			input:          "test",
			useExclamation: false,
			expected:       "test",
		},
		{
			name:           "with_exclamation",
			input:          "test",
			useExclamation: true,
			expected:       "test!",
		},
	}

	for _, testCase := range testCases {
		t.Run(testCase.name, func(t *testing.T) {
			actual := messageExclamation(testCase.input, testCase.useExclamation)
			if actual != testCase.expected {
				t.Fatalf("expected %q but got %q", testCase.expected, actual)
			}
		})
	}
}
```

While that's a good starting point, I like to use `make` as my build interface. And this includes running my tests:

```make
.PHONY: test
test:
	go test -v ./...
```

## e2e tests

Go has lots of opinions and guardrails for unit tests, but that isn't the case for e2e tests (and for good reason). So there's a little bit of my personal preference in this implementation. I like to use shell scripts for my e2e tests because:

1. They are quick to write.
1. e2e tests should be small and simple, and shell scripts shine here.
1. The shell is usually where Go applications (like CLIs or webservers) are run, so it feels normal to write the tests in a similar form.

I create a root `e2e` dir to contain all of these tests in an obvious way. Here's my template structure:

```
./e2e
├── run.sh
├── test_01_no_params.sh
└── test_02_with_message.sh
```

The `run.sh` script is the entrypoint to my e2e tests and essentially just runs all shell scripts that match `test_*.sh` in that directory. It does some coordination and output handling to make it more elegant:

```bash
#!/bin/bash

echo "Running e2e tests..."

FAILURES=""
for TEST_FILE in ./e2e/test_*.sh; do
    echo
    echo "🧪 Running test '$TEST_FILE'"

    "$TEST_FILE"
    if [[ "$?" -ne 0 ]]; then
        FAILURES="${FAILURES}  ⛔ ${TEST_FILE}\n"
    fi
done

if [[ -n "$FAILURES" ]]; then
    echo
    echo "Failed tests:"
    printf "$FAILURES"
    exit 1
fi

echo "🎉 All tests passed!"
```

All this is doing is looping through all `test_*.sh` scripts and running them. It checks their output and if the tests themselves have failed then it makes a note of them for reporting when all the tests are run. There are a few subtle things to notice here. You'll see that I don't stop the e2e testing when a single test fails. _Usually_ you want to run _all_ tests to completion and then report on the cumulative results. If you just stop at the first failure, then once you fix that another test can fail causing a long resolution. If you instead run all tests and see all tests have failed, then you can dramatically shorten the time it takes to fix all of them.

Another thing to note, this is just a project template. You can add some logic here for more application-specific requirements. For instance, if your application is meant to run in a Kubernetes cluster, you probably are testing locally with kind or something similar. Environment provisioning (and teardown) likely would happen in this `run.sh` script. An instance where you might want to short-circuit the failure of the tests is if you want to preserve some resources (e.g. local Kubernetes cluster) with the failed test for local troubleshooting. Here's likely where you would add that wiring and customization (usually with environment variables as hooks).

The individual tests themselves are even simpler. They are very much custom to your software and requirements, but here's the first one in my template:

```bash
#!/bin/bash

echo "💡 Check the output when running the CLI with no parameters. It should"
echo "   return a hard-coded 'hello world'."
echo

EXPECTED="hello world"
ACTUAL=$(./dist/go-template-cli-simple)
if [[ "$?" -ne 0 ]]; then
    echo "🔴 Unexpected non-zero return code"
    exit 1
fi
if [[ "$ACTUAL" != "$EXPECTED" ]]; then
    echo "🔴 Expected '${EXPECTED}' but got '${ACTUAL}'"
    exit 1
fi
```

The implementation details you'll likely throw away for your own e2e tests, but I like to structure tests in this way:

1. Display a quick description of what you expect the test to do. Combing through thousands of lines of e2e results in your CI/CD pipeline will be less obvious what has failed, so this description can help quickly clarify what behavior exactly has an issue.
1. I like to then call the CLI and store that in `ACTUAL`, and also storing what `EXPECTED` is. Keeping this at the beginning makes it obvious and self-documenting code.
1. Usually you want to check that your application actually completed successfully before testing the output, so I check for a non-zero return code.
1. Finally, check the output. In the case of a CLI, you might be checking stdout like here or you might be checking for some environment mutation. At any rate, this is where you want to make your check.

Finally, like with unit tests, I want to make this easily called with `make e2e`:

```make
.PHONY: e2e
e2e: build
	./e2e/run.sh
```

And that's it!

## In action

Let's see this template and these tests used in action, and just how quickly you're up and running with creating your own custom application logic and tests.

First I want to pull down the template into my new (not-yet-created) application.

```
$ gonew github.com/trstringer/go-template-cli-simple trstringer.com/hello-universe
gonew: initialized trstringer.com/hello-universe in ./hello-universe
```

Now I want to go into the root dir and run setup to scrub all the template leftovers out of it:

```
$ cd ./hello-universe
$ make setup
Running initial setup...
Setup complete!
```

And that's it! Now let's see my unit tests:

```
$ make test
go test -v ./...
=== RUN   TestMessageWithExclamation
=== RUN   TestMessageWithExclamation/without_exclamation
=== RUN   TestMessageWithExclamation/with_exclamation
--- PASS: TestMessageWithExclamation (0.00s)
    --- PASS: TestMessageWithExclamation/without_exclamation (0.00s)
    --- PASS: TestMessageWithExclamation/with_exclamation (0.00s)
PASS
ok  	trstringer.com/hello-universe/cmd	(cached)
```

And now let's run those e2e tests!

```
$ make e2e
mkdir -p ./dist
go build -o ./dist/hello-universe ./cmd
./e2e/run.sh
Running e2e tests...

🧪 Running test './e2e/test_01_no_params.sh'
💡 Check the output when running the CLI with no parameters. It should
   return a hard-coded 'hello world'.


🧪 Running test './e2e/test_02_with_message.sh'
💡 Check the output when running the CLI with a message. It should
   return that message.

🎉 All tests passed!
```

## Summary

Great! That just took a few seconds to set this up, and now I have the base code to not only write my software but also to start quickly and easily adding my tests!
