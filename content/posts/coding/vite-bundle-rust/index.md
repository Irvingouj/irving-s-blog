+++
title = 'Bundling WASM into a Single Javascript File'
date = 2023-11-20
draft = false
+++

## Introduction
Navigating the complexities of Javascript build systems can be challenging, especially when integrating WASM with JS/TS files. This post demonstrates how to bundle a WASM project into a single JS file, simplifying sharing and deployment.

## Set up
Ensure you have `cargo`, `wasm-pack`, and `npm` installed.

Start by creating a new Rust project:
```
cargo new rust-bundle-example --lib
```

Your folder should now look like this:
```
Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
d-----        11/20/2023   5:57 PM                pkg
d-----        11/20/2023   5:56 PM                src
d-----        11/20/2023   5:57 PM                target
-a----        11/20/2023   5:56 PM             20 .gitignore
-a----        11/20/2023   5:56 PM           3216 Cargo.lock
-a----        11/20/2023   5:56 PM            242 Cargo.toml
```

Next, create a simple WASM library. Run:
```
cargo install wasm-bindgen
```
Then, modify your `Cargo.toml` as follows:
``` toml

[lib]
crate-type = ['cdylib']
```
In `lib.rs`, create a function and annotate it with `wasm-bindgen`:

``` rust
use wasm_bindgen::prelude::wasm_bindgen;

#[wasm_bindgen]
pub fn add(left: usize, right: usize) -> usize {
    left + right
}
```

Build the project:
```
wasm-pack build
```

A successful build will create a `./pkg` folder.

Now, set up the bundler using Vite:
```
npm init -y
npm install vite --save-dev
```

### The Key Settings
Use [vite-plugin-wasm](https://www.npmjs.com/package/vite-plugin-wasm) and install it with:
```
npm i vite-plugin-wasm; npm i vite-plugin-top-level-await
```

Create `vite.config.ts` and configure it:
```ts
import { defineConfig } from 'vite'
import wasm from "vite-plugin-wasm";
import topLevelAwait from "vite-plugin-top-level-await";

export default defineConfig({
    build:{
        lib:{
            entry: './pkg/rust_bundle_example.js',
            name: 'bundle-wasm-example',
            formats: ['es'],
        }
    },
    plugins: [wasm(), topLevelAwait()]
})
```
Also, update your `package.json`:
```
 "type": "module",
```

Run `npx vite build`. This generates a `dist` folder containing `rust-bundle-example.js`.

For type wrapping, consider using `vite-plugin-dts`.

### Conclusion

Bundling WASM into a JavaScript file simplifies deployment, but it uses base64 encoding, which may load slower than a plain .wasm file. For large projects, consider using .wasm files directly. For performance reference, check out [IronRDP](https://github.com/Devolutions/IronRDP), which employs a similar technique.

