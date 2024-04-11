+++
title = 'Understanding The Ownership Model of Rust'
date = 2024-03-31T08:50:36-05:00
draft = false
+++

The Borrow Checker has always been the #1 enemy for programmers who are trying to learn Rust for the first time. In this post, I will provide a simple mental model to understand its usage and explain some concepts that are specific to Rust.

This article assumes that the audience has basic programming knowledge, including experience with C/C++ pointer and reference manipulations.

Let's dive in.

## Move and Consume

"Move" and "Consume" are terms specific to Rust; we don't hear these words being used in any other language. In short, **a value is moved when it is assigned to another variable, and a value is consumed when it is passed into a function**. **A variable OWNS the value it gets assigned to**. All variables are subject to the ownership model. Let's examine a classic example:

```rust
#[derive(Debug)]
struct Person {
    name: String,
    age: u32,
}
fn main() {
    let x = Person {
        name: String::from("John"),
        age: 30,
    };
    let y = x; // x is moved to y
    println!("x: {:?}", x); // This will cause a compile-time error
    println!("y: {:?}", y); // This will print the value of y
}
```

In the above example, the Person value is moved from `x` to the variable `y`. You can think of this as `x` **owns** the Person value. If the Person is **moved** to another variable, then `x` no longer has anything, hence we cannot use `x` ever again.

Let's look at an example of **consume**.

```rust
fn main() {
    let person = Person {
        name: String::from("John"),
        age: 30,
    };

    greet(person); // person is consumed
    greet(person); // This will cause a compile-time error
}

fn greet(person_param: Person) {
    println!("Hello, {}! You are {} years old.", person_param.name, person_param.age);
}
```

In this example, the `person` variable is **consumed** by the `greet` function. You can think of it as **move** as well. It is as if the value `person` is **moved** into `person_param` in the `greet` function. In fact, that is what the compiler will tell you as well.

Also, we can ask the function to return it to help us regain the ownership of a value.

```rust
fn main() {
    let person = Person {
        name: String::from("John"),
        age: 30,
    };

    let person_that_has_been_borrowed = greet(person); // person is borrowed and returned
    greet(person_that_has_been_borrowed); // we can use person again
}

fn greet(person_param: Person) -> Person {
    println!("Hello, {}! You are {} years old.", person_param.name, person_param.age);
    person_param
}
```

One might find this quite frustrating, as in fact, are we going to return the variable every time we use it if we want to use it again? This seems unnecessary.

Your critique is absolutely valid. This is not how one should write their code. Rust provides two better ways to handle this. First, using references under the borrowing rules, and second, the `Copy` and `Clone` traits.

## Reference and Borrow
In system programming languages, we always have a way to obtain the address of our value, which is what we call a **reference**. In the above `Person` struct example, we do not necessarily need to consume the value `person`; we can alter our function signature to accomplish the same thing without consumption.

```rust
fn greet_reference(person_param: &Person) {
    println!("Hello, {}! You are {} years old.", person_param.name, person_param.age);
}
```
In here, the symbol `&Person` represents a reference type to a person. The `&` is also an operator; it can be used on any value to create its Reference type. For example,
```rust
let person_reference = &person;
```
`person_reference` is of type `&Person`, and it is exactly what the `greet` function is looking for.
We can invoke this function as many times as we want by using a reference. Because creating a reference is cheap. In this case, we say the greet function **borrows** the value person.

```rust
fn main() {
    //...
    greet_reference(&person); 
    greet_reference(&person); 
}
```
The borrowing concept in Rust enforces the ownership rules at compile time, ensuring that data races and invalid memory references are prevented. Borrowing can be either immutable or mutable, with strict rules governing their usage.

One may talk about this topic all the way down to how computers work. For the sake of the introductory nature of this blog, we won't dig too deep.

## The Clone and Copy Trait
A trait is like an interface in Java or TypeScript, with many differences, but let's focus on the topic today. I will put up a different blog about Trait later.
One might have noticed the following code works as well.
``` rust
fn main() {
    //...
    let person_reference = &person  
    greet_reference(person_reference); // we use the reference once
    greet_reference(person_reference); // we use the reference again.
}
```

Isn't it weird? You see, up there, in the second example, the variable is **consumed** and will throw a compile error, but here, the person_reference can be passed to the greet function twice without causing any problem.

The Secret is the **Copy** Trait. If you go to the official documentation of Rust std, you will see that the reference implements the Copy Trait. That means it is automatically **copied** instead of **moved** every time we use it or assign it to another variable.

In fact, all the primitive types implement the **Copy** trait, and **A struct can implement Copy if and only if all of its components implement Copy**. Our `Person` struct cannot, and will never be able to implement Copy nor can we derive it. If you try to derive it like the following, the compiler will complain about `name: String` does not implement Copy.

```rust
#[derive(Debug, Clone, Copy)]
struct Person {
    name: String, //<< --------------- does not compile here
    age: u32,
}
```

You see, String is a complicated data type; it is a value that can grow and shrink in size. It is heap allocated, which means it is expensive to create and copy around. So is Vec and other heap allocated or partly heap allocated data types.

Note that you cannot even implement `Copy` trait manually, as Copy is just a marker trait, meaning it does not have any function associated with it.

However, one could indeed derive the `Clone`. `Clone` allows you to explicitly clone your value, which may or may not be expensive. Rust does not allow you to reimplement `Copy`, but you can implement `Clone` in whatever way you want. Here's an example
```rust
#[derive(Debug, Clone)]
struct Person {
    name: String, 
    age: u32,
}
```

and when you want to use it, simply call clone every time.

```rust
fn main() {
    let person = Person {
        name: String::from("John"),
        age: 30,
    };

    let person_clone = person.clone();
    greet(person_clone);
    greet(person);
}

fn greet(person_param: Person) {
    // .. consumes Person
}
```

## Take Advantage of Ownership Models
There are design patterns that can only be used with Rust by taking advantage of the ownership model.

Think about a situation like this. You have two functions, `step1` and `step2`, where you want the user to call your functions in order, and call `step2` only once. You can achieve it by using an empty struct.
```rust
pub struct Step1Finished;
pub fn step1() -> Step1Finished {
    //...
    Step1Finished //<< --- This is return statement in Rust in case you don't know
}

pub fn step2(_: Step1Finished) {
    // do the rest for step 2.
}
```
Since step2 takes the ownership of `Step1Finished`, the Rust ownership rule will guarantee that `step2` must be called with a `step1` in advance, and a `step1` can only be followed by a `step2`, not a `step3` or `step4`.

## Conclusion
In conclusion, Rust's variable is an **owner** to a value. You may `move` the value to another variable, `consume` it in a function and give or not give it back later. You may also `borrow` it, use its reference for different things, and you can derive `Copy` or `Clone` traits wherever appropriate to use the same value in different places.

As a side note, this blog does not introduce anything about mutibility. It is another important topic and work hand in hand with ownership models. We will talk about it in later chapter.