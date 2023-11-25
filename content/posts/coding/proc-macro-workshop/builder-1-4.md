+++
title = 'Proc Macro Workshop Solution: Builder Tests 1 to 2'
date = 2023-11-25T16:24:38-05:00
+++

Hello everyone, this is a new series of blog posts on how I learned procedure macros through [the proc macro workshop](https://github.com/dtolnay/proc-macro-workshop) in Rust. Be aware my solutions are not the best; if you think there's a better solution, let me know.

## The Setup
The workshop provides a template with an unimplemented Builder Derive. Let's take a look:
```rs 
use proc_macro::TokenStream;

#[proc_macro_derive(Builder)]
pub fn derive(input: TokenStream) -> TokenStream {
    let _ = input;

    unimplemented!()
}
```

Our task is to complete this implementation so that it passes all tests from 1 to 9, requiring it to be compilable.

## Test 1 - 2
Test 1 requires following the template,remove the unimplemented! macro and ensuring the Builder derive compiles, even if it doesn't do anything:
```rs
#[derive(Builder)]
pub struct Command {
    executable: String,
    args: Vec<String>,
    env: Vec<String>,
    current_dir: String,
}

```
Simply returning a new TokenStream passes Test 1:
```rs
pub fn derive(input: TokenStream) -> TokenStream {
    let _ = input;
    TokenStream::new()
}
```

Test 2 involves writing procedural macros to implement the builder struct and the builder function for the Command struct:
```rs
use derive_builder::Builder;

#[derive(Builder)]
pub struct Command {
    executable: String,
    args: Vec<String>,
    env: Vec<String>,
    current_dir: String,
}

fn main() {
    let builder = Command::builder();
    let _ = builder;
}
```

Breaking it down, the first step is parsing the TokenStream into a struct for easier manipulation. We do this by:
```rs
let input_ast: DeriveInput = syn::parse(input).unwrap();
```
Note: It's okay to use unwrap in derive macros as it translates to a compiler error.

Next, let's examine `DeriveInput`:
```rs
#[cfg_attr(doc_cfg, doc(cfg(feature = "derive")))]
pub struct DeriveInput {
    pub attrs: Vec<Attribute>,
    pub vis: Visibility,
    pub ident: Ident,
    pub generics: Generics,
    pub data: Data,
}
```

`DeriveInput` consists of attributes, visibility, ident, generics, and data. For Test 2, we're mainly concerned with the `ident`. We create the Builder struct as follows:
```rs
let original_struct_name = input_ast.ident;
let builder_name = format!("{}Builder", original_struct_name.to_string());

println!("{}", builder_name);
```
Running cargo test prints `CommandBuilder`, as expected. To actually put the `CommandBuilder` in to the output token stream, we turn to the `quote` crate:

```rs
let original_struct_name = input_ast.ident;
let builder_name = format!("{}Builder", original_struct_name.to_string());
let builder_name_ident = Ident::new(&builder_name, original_struct_name.span());

let res = quote::quote!{
    struct #builder_name_ident;
};
println!("{}", res.to_string());

res.into()
```
Note that variables referred to with `#` in `quote!` blocks must be token streams or identifiers, so we create a new identifier here. 

Then, we implement the builder method for the original struct:
```rs
let res = quote::quote!{
    #[derive(Default)]
    pub struct #builder_name_ident;

    impl #original_struct_name {
        pub fn builder() -> #builder_name_ident {
            #builder_name_ident::default()
        }
    }
};
```

Given that `Command` is public, the builder must also be public. Using `cargo expand` (with a new test since I don't know how to expand a single file), we get:
```rs
use derive_builder::Builder;
pub struct Command {
    executable: String,
    args: Vec<String>,
    env: Vec<String>,
    current_dir: String,
}
pub struct CommandBuilder;
#[automatically_derived]
impl ::core::default::Default for CommandBuilder {
    #[inline]
    fn default() -> CommandBuilder {
        CommandBuilder {}
    }
}
impl Command {
    pub fn builder() -> CommandBuilder {
        CommandBuilder::default()
    }
}
```

This concludes the first step of our procedural macro journey for today.

