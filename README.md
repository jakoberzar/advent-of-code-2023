# Advent of Code 2023

My solutions for Advent of Code 2023. This year I am learning Zig. I might also do some OCaml if I feel like it.

| Day | Nickname              | Zig | OCaml |
| --- | --------------------- | --- | ----- |
| 1   | Trebuchet             | ✔️  |       |
| 2   | Cube Game             | ✔️  |       |
| 3   | Engine Schematic Grid | ✔️  |       |
| 4   | Scratchcards          | ✔️  |       |
| 5   | Almanac               | ✔️  |       |
| 6   | Boat Racing           | ✔️  |       |
| 7   | Poker                 | ✔️  |       |
| 8   | Map Cycles            | ✔️  |       |
| 9   | Sequences             | ✔️  |       |
| 10  | Pipes                 | ✔️  |       |
| 11  | Galaxies              | ✔️  |       |
| 12  | Hot Springs           | ✔️  |       |
| 13  |                       |     |       |
| 14  |                       |     |       |
| 15  | Hashmap               | ✔️  |       |
| 16  |                       |     |       |
| 17  |                       |     |       |
| 18  |                       |     |       |
| 19  |                       |     |       |
| 20  |                       |     |       |
| 21  |                       |     |       |
| 22  |                       |     |       |
| 23  |                       |     |       |
| 24  |                       |     |       |
| 25  |                       |     |       |

## Script for starting a new day

```bash
./new_day.sh <day_name>
```

## Zig

### Setting up

This was compiled with Zig version `0.12.0-dev.1768+39a966b0a`.

Due to @embedFile restrictions, create a symlink to the inputs folder: `ln -s $PWD/inputs zig/input`

### Running code

For development
`zig run zig/day01.zig`

For optimized build

```bash
zig build-exe -O ReleaseFast -femit-bin=build/day01 zig/day01.zig
# Benchmark
hyperfine -w 3 -r 10 -N build/day01
```

### Testing code

`zig test zig/day01.zig`

## Other language candidates

- OCaml for some practice
- Go to see what not caring about code style feels like
- Kotlin for some more Android practice
- Rust to be happy and refresh knowledge
- Dart to see what it's like and learn Flutter
