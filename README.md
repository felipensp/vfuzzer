# vfuzzer
V language fuzzing tool


### Usage

> Generating all tests on ./tests dir

`v . && ./vfuzzer && v test tests/`


> Generating specific func test and printing it out

```
$ ./vfuzzer strconv_format_fl_old -p
module main
import strconv
import strings

fn test_223_0() {
        unsafe { strconv.format_fl_old(1.12345, strconv.BF_param{})}
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