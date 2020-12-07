---
layout: post
title: Go's append Behavior and Potentially Unintended Side Effects
categories: [Blog]
tags: [golang]
---

When working with Go, a very common operation is to add an element (or multiple elements) to a [slice](https://blog.golang.org/slices-intro) with `append`. But if you don't know the true nature of `append`, it could surprise you!

## Appending to a slice

Say you have a slice of type `int`:

```go
A := []int{4, 1, 9}
```

Let's do a couple of things:

1. Create a new slice `B` which should be the first two elements of `A` (`A[:2]` can accomplish this) and an additional `int`
1. Create a new slice `C` which will be `A` (entirely) and an additional element

```go
B := append(A[:2], 13)
C := append(A, 25)

fmt.Printf("A: %v\n", A)
fmt.Printf("B: %v\n", B)
fmt.Printf("C: %v\n", C)
```

`B` is a pretty easy guess, as expected:

```text
B: [4 1 13]
```

But what do you think `A` is? A reasonable guess would be that `A` is unchanged at `[4 1 9]`.

And what about `C`? Another reasonable guess would be that `C` is `[4 1 9 25]`. But let's see the real output:

```text
A: [4 1 13]
B: [4 1 13]
C: [4 1 13 25]
```

If you're looking at that output and wondering why it looks like that, you're not alone. You may be thinking, **why did `A` mutate?** And **why did `C` get the appended item from `B`?** Great questions!

To understand this behavior, you must first understand what exactly a slice is. For an in-depth look, read the above link. But the important parts are that a slice is a "window" into an underlying array. There are a few attributes of a slice that are important to understand: **length** and **capacity**. Length is the length of the slice itself, but capacity is how large the underlying array is.

Now knowing that, let's look at the definition of [`append`](https://golang.org/pkg/builtin/#append):

> The append built-in function appends elements to the end of a slice. **If it has sufficient capacity, the destination is resliced to accommodate the new elements. If it does not, a new underlying array will be allocated.** Append returns the updated slice.

I have bolded the important part here that explains this behavior. In short, if the underlying array has capacity to fit the appended element(s) then it will be mutated. If there is not enough space, a new array will be created.

## Appending within the capacity limits

Let's see another example:

```go
D := make([]int, 3, 4)
for i := 0; i < len(D); i++ {
    D[i] = i
}
fmt.Printf("D = %v, len = %d, cap = %d\n", D, len(D), cap(D))

E := append(D, 3)
fmt.Printf("D: %v\n", D)
fmt.Printf("E: %v\n", E)

fmt.Println("Setting a different value for E...")
E[0] = 4
fmt.Printf("D: %v\n", D)
fmt.Printf("E: %v\n", E)
```

The output here might surprise you if you didn't know the behavior of `append`:

```text
D = [0 1 2], len = 3, cap = 4
D: [0 1 2]
E: [0 1 2 3]
Setting a different value for E...
D: [4 1 2]
E: [4 1 2 3]
```

After the `append`, both `D` and `E` seem like what you would expect. But by changing an element in `E`, you are also changing an element in `D`. This shows that `D` and `E` are both pointing to the same underlying array. We can verify that as well:

```go
fmt.Printf("D: %p\n", D)
fmt.Printf("E: %p\n", E)
fmt.Println()
for idx := range D {
    fmt.Printf("&D[%d] = %p\n", idx, &D[idx])
}
fmt.Println()
for idx := range E {
    fmt.Printf("&E[%d] = %p\n", idx, &E[idx])
}
```

We can see that `E` is pointing to the same elements that `D` is:

```text
D: 0xc0000be000
E: 0xc0000be000

&D[0] = 0xc0000be000
&D[1] = 0xc0000be008
&D[2] = 0xc0000be010

&E[0] = 0xc0000be000
&E[1] = 0xc0000be008
&E[2] = 0xc0000be010
&E[3] = 0xc0000be018
```

This is all because the underlying array of `D` was able to fit the output of the `append`, therefore it mutated it.

If we were to change the allocation of `D` so that it's capacity is only three, this would all change:

```go
D := make([]int, 3, 3)
```

*Note: This could've been also written as `make([]int, 3)`. If you omit the capacity, `make` will use the length for the capacity.*

```text
D = [0 1 2], len = 3, cap = 3
D: [0 1 2]
E: [0 1 2 3]
Setting a different value for E...
D: [0 1 2]
E: [4 1 2 3]

D: 0xc000018420
E: 0xc00001c2a0

&D[0] = 0xc000018420
&D[1] = 0xc000018428
&D[2] = 0xc000018430

&E[0] = 0xc00001c2a0
&E[1] = 0xc00001c2a8
&E[2] = 0xc00001c2b0
&E[3] = 0xc00001c2b8
```

Because the underlying array of `D` had only a capacity of three, `append` needed an underlying array with a capacity of four, so it had to create a new array. Now `D` and `E` point to completely different data.

## Take control with copy

As we can see above, this behavior changes depending on the underlying array. How can you take control of this? The short answer is with a combination of `make` and [`copy`](https://golang.org/pkg/builtin/#copy):

```go
D := make([]int, 3, 4)
E := make([]int, len(D))
for i := 0; i < len(D); i++ {
    D[i] = i
}
copy(E, D)
fmt.Printf("D = %v, len = %d, cap = %d\n", D, len(D), cap(D))

E = append(E, 3)
fmt.Printf("D: %v\n", D)
fmt.Printf("E: %v\n", E)

fmt.Println("Setting a different value for E...")
E[0] = 4
fmt.Printf("D: %v\n", D)
fmt.Printf("E: %v\n", E)

fmt.Printf("D: %p\n", D)
fmt.Printf("E: %p\n", E)
fmt.Println()
for idx := range D {
    fmt.Printf("&D[%d] = %p\n", idx, &D[idx])
}
fmt.Println()
for idx := range E {
    fmt.Printf("&E[%d] = %p\n", idx, &E[idx])
}
```

```text
D = [0 1 2], len = 3, cap = 4
D: [0 1 2]
E: [0 1 2 3]
Setting a different value for E...
D: [0 1 2]
E: [4 1 2 3]
D: 0xc000018420
E: 0xc00001c2a0

&D[0] = 0xc000018420
&D[1] = 0xc000018428
&D[2] = 0xc000018430

&E[0] = 0xc00001c2a0
&E[1] = 0xc00001c2a8
&E[2] = 0xc00001c2b0
&E[3] = 0xc00001c2b8
```

By allocating `E` to be the same length as `D` and then doing `copy(E, D)`, we can work *only* in the context of `E` with our append, guaranteeing that `D` remains unchanged:

```go
E = append(E, 3)
```

Now we can make sure we aren't mutating the original underlying array and possibly having those unintended side effects!
