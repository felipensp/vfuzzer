# vfuzzer
V language fuzzing tool


### Usage

#### Genearting all tests

`v . && ./vfuzzer && v test tests/`

> Generates all tests on ./tests dir

### Generating specific func test

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

`$ ./vfuzzer strconv_format_fl_old -p > a_test.v`

#### Running test

```
$ v test a_test.v
---- Testing... --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 OK    3104.007 ms /home/felipe/github/vfuzzer/a_test.v
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Summary for all V _test.v files: 1 passed, 1 total. Runtime: 3107 ms, on 1 job.
```