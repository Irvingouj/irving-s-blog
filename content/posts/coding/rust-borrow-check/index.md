+++
title = 'Understanding The Ownership Model of Rust'
date = 2024-03-31T08:50:36-05:00
draft = false
+++

# Not Yet Finishied

The Borrow Checker has always been the #1 enemy for programmers who are trying to learn Rust for the first time. In this post, I am going to provide a simple mental model to understand its usage and explain some concepts that are specific to Rust.

This article assumes that the audience has basic programming knowledge, including experience with C/C++ pointer and reference manipulations.

Let's dive in.

## Move, Consume, and Borrow

"Move", "Consume", and "Borrow" are terms specific to Rust; we don't hear these words being used in any other language. In short, **a value is moved when it is assigned to another variable, and a value is consumed when it is passed into a function**. Let's examine a classic example:

```rust
fn main() {
    let x = 5;
    let y = x; // x is moved to y
    println!("x: {}", x); // This will cause a compile-time error
    println!("y: {}", y); // This will print the value of y
}
```

In the above example, the value 5 is moved from `x` to the variable `y`. You can think of this as `x` **owns** the value 5. If 5 is moved to another variable, then `x` no longer has anything, hence we cannot use `x` ever again.

Let's look at an example of consumption.

```rust
struct Person {
    name: String,
    age: u32,
}

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

In this example, the `person` variable is **consumed** or **borrowed** by the `greet` function. You can think of it as **move** as well. It is as if the value `person` is **moved** into `person_param` in the `greet` function. In fact, that is what the compiler will tell you as well.

Interestingly, if this concept is called borrow, we can absolutely ask the function to give it back (return it). 

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

## Reference
In system programming languages, we always have a way to obtain the address of our value, which is what we call a **reference**. In the above `Person` struct example, we do not necessarily need to consume the value `person`; we can alter our function signature to accomplish the same thing without consumption.

```rust
fn greet(person_param: &Person) {
    println!("Hello, {}! You are {} years old.", person_param.name, person_param.age);
}
```

And we can invoke this function as many times as we want by using a reference.

```rust
fn main() {
    //...
    greet(&person); // person is borrowed
    greet(&person); // person is borrowed again
}
```
The borrowing concept in Rust enforces the ownership rules at compile time, ensuring that data races and invalid memory references are prevented. Borrowing can be either immutable or mutable, with strict rules governing their usage.

## Mutable References

While immutable references allow you to borrow a value without taking ownership, mutable references let you not only borrow the value but also modify it. However, Rust enforces a strict rule: you can have either one mutable reference or any number of immutable references to a particular piece of data at a time, but never both. This rule ensures data safety and concurrency safety.

```rust
fn main() {
    let mut person = Person {
        name: String::from("Alice"),
        age: 30,
    };

    change_age(&mut person);
    println!("{} is now {} years old.", person.name, person.age);
}

fn change_age(person: &mut Person) {
    person.age += 1;
}
```

This code snippet demonstrates how to borrow a mutable reference to the `person` variable and then modify its `age` field within the `change_age` function. Notice the use of `&mut` to signify a mutable reference.

## The `Copy` and `Clone` Traits

When dealing with types that do not implement the `Copy` trait, such as `String` or custom structs, Rust moves the ownership by default. However, primitive types like integers implement the `Copy` trait, meaning they are automatically copied when assigned to another variable or passed to a function.

For types that do not implement `Copy`, you can use the `Clone` trait to explicitly create a copy of the value.

```rust
fn main() {
    let original = String::from("Hello, Rust!");
    let clone = original.clone(); // Explicitly create a copy

    println!("Original: {}", original);
    println!("Clone: {}", clone);
}
```

This example shows how to clone a `String`, allowing both `original` and `clone` to be used independently.

## Understanding Lifetimes

A more advanced aspect of Rust's ownership system is lifetimes, which are implicit in most cases but can be explicitly annotated in function signatures and struct definitions to ensure that references do not outlive the data they point to.

```rust
fn longest<'a>(x: &'a str, y: &'a str) -> &'a str {
    if x.len() > y.len() { x } else { y }
}
```

This function signature with lifetimes `'a` indicates that the return value will live as long as the shortest of the input references.

## Conclusion

Rust's ownership model, including the concepts of borrowing, the `Copy` and `Clone` traits, and lifetimes, offers a powerful toolset for managing memory safely and efficiently without a garbage collector. Understanding these concepts is crucial for mastering Rust and writing efficient, safe code. The borrow checker may seem like an obstacle at first, but it's a valuable ally in preventing bugs and ensuring your code is sound.

Remember, mastering Rust's ownership model takes time and practice. Keep experimenting with these concepts, and soon you'll find them second nature.
