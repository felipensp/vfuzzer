# vfuzzer
V language fuzzing tool


### Usage

> Generating all tests on ./tests dir and running vtest on them

`$ v . && ./vfuzzer && v test tests/`


> Generating specific func test and printing it out

`$ ./vfuzzer builtin_copy -p`
```V
module main

fn test_6_0() {
        mut t0 := []u8{}
        unsafe { copy(mut t0, []u8{})}
        assert true
}

```

> Saving generated test to file

`$ ./vfuzzer strconv_format_fl_old -p > a_test.v`

> Running test with vtest

```
$ v test a_test.v
---- Testing... --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 OK    3104.007 ms /home/felipe/github/vfuzzer/a_test.v
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Summary for all V _test.v files: 1 passed, 1 total. Runtime: 3107 ms, on 1 job.
```