---
layout: post
title: Go Slices - Passing By Reference or Value?
categories: [Blog]
tags: [golang]
---

Go is a powerful language, and most parts of it are very intuitive. But one of the things that can cause some confusion for many Go programmers (especially those new to the language) is how slices are handled. A **slice** is a dynamic reference to an underlying fixed-size array. In Go, we almost always work directly with slices instead of arrays.

When working with slices, though, it can be *extremely* confusing to understanding how it works when passing them. Is it by reference? Is it by value? Especially coming from other languages, this can really cause some serious cognitive issues. For instances, what do you think the output of the following code is?

```go
func addNum(nums []int, newNum int) {
	nums = append(nums, newNum)
	fmt.Printf("addNum nums %v\n", nums)
}

func main() {
	nums := []int{1, 2, 3}
	fmt.Printf("  main nums %v\n", nums)
	addNum(nums, 4)
	fmt.Printf("  main nums %v\n", nums)
}
```

If you guessed that the slice wouldn't be mutated, you'd be correct!

```
  main nums [1 2 3]
addNum nums [1 2 3 4]
  main nums [1 2 3]
```

If you understand the [behavior of `append`](https://trstringer.com/golang-append/), though, you might be suspecting that `addNums` is uncovering that:

```go
func addNum(nums []int, newNum int) {
	fmt.Printf("addr %p\n", nums)
	nums = append(nums, newNum)
	fmt.Printf("addr %p\n", nums)
}
```

You'll see that a new underlying array was allocated because there was not enough capacity:

```
addr 0xc0000b4000
addr 0xc0000bc000
```

So let's work with a slice that has enough capacity to fit the original and final slice contents:

```go
func addNum(nums []int, newNum int) {
	fmt.Printf("addr %p len %d cap %d\n", nums, len(nums), cap(nums))
	nums = append(nums, newNum)
	fmt.Printf("addr %p len %d cap %d\n", nums, len(nums), cap(nums))
	fmt.Printf("addNum nums %v\n", nums)
}

func main() {
	nums := make([]int, 0, 4)
	nums = append(nums, 1, 2, 3)

	fmt.Printf("addr %p len %d cap %d\n", nums, len(nums), cap(nums))
	fmt.Printf("  main nums %v\n", nums)

	addNum(nums, 4)

	fmt.Printf("addr %p len %d cap %d\n", nums, len(nums), cap(nums))
	fmt.Printf("  main nums %v\n", nums)
}
```

The output might be confusing!

```
addr 0xc0000201e0 len 3 cap 4
  main nums [1 2 3]
addr 0xc0000201e0 len 3 cap 4
addr 0xc0000201e0 len 4 cap 4
addNum nums [1 2 3 4]
addr 0xc0000201e0 len 3 cap 4
  main nums [1 2 3]
```

We just proved that the address of the underlying array remains the same: `0xc0000201e0`. And we even proved that in `addNums` when we do the append, we are reusing that same underlying array and growing len to meet the capacity. Yet whenever we return back to `main` we see that the `nums` slice still doesn't include the added element.

This is because in Go **a slice header is passed by value** even though it includes a **reference to the underlying array**. The slice header consists of three pieces of data:

* Array address (reference) - Address of the first slice element (`&nums[0]`)
* Slice length - `len(nums)`
* Slice capacity - `cap(nums)`

Like all things passed as value, when it is mutated in `addNums` (the length changed because of the append) that mutation does not get reflected back in `main` because it was a value, not a reference.

This blog post wouldn't be complete without showing you *how* to modify a slice in this manner. The answer is to use a slice pointer:

```go
func addNum(nums *[]int, newNum int) {
	*nums = append(*nums, newNum)
	fmt.Printf("addNum nums %v\n", *nums)
}

func main() {
	nums := []int{1, 2, 3}

	fmt.Printf("  main nums %v\n", nums)
	addNum(&nums, 4)
	fmt.Printf("  main nums %v\n", nums)
}
```

And the output shows that our slice was mutated and persisted:

```
  main nums [1 2 3]
addNum nums [1 2 3 4]
  main nums [1 2 3 4]
```

Hopefully this blog post has helped clarify what I would consider is one of the more confusing aspects of Go!
