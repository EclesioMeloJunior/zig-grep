# zig-grep

- To execute this program make sure you have installed zig at version 0.9.1
- You should type `zig build run -- {pattern_here}` then it will search at `examples/file.txt` for the pattern you provided.

ex:

```
zig build run -- sit
```

- [x] Provide the file as an CLI parameter
  - You should provide the file in the absolute format, for example: `/User/some_user_name/Documents/file.txt`
- [ ] Ignore case sensitivy
- [ ] Increase test coverage
