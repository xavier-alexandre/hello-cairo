# Hello Cairo

https://starknet.io/docs/hello_cairo

## Build

```shell
cairo-compile XXX.cairo --out XXX_compiled.json
```

## Run

```shell
cairo-run \
  --print_output \
  --layout=small \
  --print_info --relocate_prints \
  --profile_output profile.pb.gz \
  --program=XXX_compiled.json
```

## Debugging / Profiling

https://starknet.io/docs/how_cairo_works/debugging_tricks.html#debugging-tricks

Using Go:

```
go tool pprof --web profile.pb.gz
```

Or using this Docker image:

```
docker run --net=host -v$PWD:/tmp starkwarelibs/pprof profile.pb.gz
```
