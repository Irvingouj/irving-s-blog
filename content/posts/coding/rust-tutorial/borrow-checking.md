+++
title = 'Understanding The Ownership Model of Rust'
date = 2024-03-31T08:50:36-05:00
draft = false
+++

The Borrow Checker has always been the #1 enemy for programmers who are trying to learn Rust for the first time. In this post, I am going to provide a simple mental model to understand its usage and explain some concepts that are specific to Rust.

This article assumes that the audience has basic programming knowledge, including experience with C/C++ pointer and reference manipulations.

Let's dive in.

## Move and Consume

"Move", "Consume" are terms specific to Rust; we don't hear these words being used in any other language. In short, **a value is moved when it is assigned to another variable, and a value is consumed when it is passed into a function**. **A variable OWNS the value it gets assigned to** All variables subject to the ownership model. Let's examine a classic example:

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

In the above example, the value person is moved from `x` to the variable `y`. You can think of this as `x` **owns** the value of a person. If the person is **moved** to another variable, then `x` no longer has anything, hence we cannot use `x` ever again.

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

## Reference and Borrow
In system programming languages, we always have a way to obtain the address of our value, which is what we call a **reference**. In the above `Person` struct example, we do not necessarily need to consume the value `person`; we can alter our function signature to accomplish the same thing without consumption.

```rust
fn greet(person_param: &Person) {
    println!("Hello, {}! You are {} years old.", person_param.name, person_param.age);
}
```
In here, the symbol `&Person` represents a reference type to a person. The `&` is also a operator, it can be used on any value to create it's Reference type. For example
```rust
let person_reference = &person
```
`person_reference` is of type `&Person`, and it is exactly what the `greet` function is looking for.
We can invoke this function as many times as we want by using a reference. Because creating a reference is cheap and  In this case, we say the greet function **borrows** the value person.

```rust
fn main() {
    //...
    greet(&person); 
    greet(&person); 
}
```
The borrowing concept in Rust enforces the ownership rules at compile time, ensuring that data races and invalid memory references are prevented. Borrowing can be either immutable or mutable, with strict rules governing their usage.

One may talk about this topic goes all the way done to how computer works. For the sake of the introductive nature of this blog, we won't dig too deep.

## The Clone and Copy Trait
Trait is like a interface in Java or Typescript, which many differences, but let's foucus on the topic today. I will put up a different blog about Trait later.
One might noticed the following code works as well.
```
fn main() {
    //...
    let person_refernece= &person  
    greet(person_refernece); // we use the reference once
    greet(person_refernece); // we use the reference again.
}
```

Isn't it wired? You see, up there, in the second example, the variable is **consumed** and will throw a compile error, but here, the person_refence can be passed to the greet function twice without causing any problem.

The Secret is the **Copy** Trait. If you go to the offical documentation of Rust std, you will see that the reference implements the Copy Trait. That means it is automatically **copied** instead of **moved** every time we use it or assigne it to anohter variable.

In fact, all the primitive types implements the **Copy** trait. We could implement the **Copy** trait for our `Person` sturct as well.

```rust
#[derive(Debug,Clone,Copy)]
struct Person {
    name: String,
    age: u32,
}
```

One may find out this will not work as well, if you try to compile it, the compiler will tell you that the String type does not implement Copy. This is by design. You see, String a complicated data type, it is a value that can grow and shrink in size. It is also heap allocated, which means it is expensive to create. In many suituations, we need to double think weather or not we want to copy the string, be cause it could be distructively expensive for many applications.


