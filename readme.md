# A helpful tool for SML development

## Building

1. Have MLton
2. Have smlpkg
3. ```bash
   $ smlpkg sync
   ```
4. ```bash
   $ make build
   ```

## Use

### Templating
- I found myself often wasting time getting project \
 structure setup for interactive development

- ```bash
  $ snack --init
  ```
  - right now the only template is cli, compiler coming soon.

- This will setup a basic makefile project using mlton/mlkit with \
  mlb file in the root of /src

- ```bash
  $ snack --watch PATH
  ```
- Enables recompile on file save. Mlton isn't the fastest but it works
