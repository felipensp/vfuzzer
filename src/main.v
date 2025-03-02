module main

import os.cmdline
import os
import v.reflection

fn gen_func_name(func reflection.Function) string {
	return if func.mod_name !in ['', 'builtin'] {
		'${func.mod_name.all_after_last('.')}.${func.name}'
	} else {
		'${func.name}'
	}
}

fn case_01(func reflection.Function, fname string, params string, p_gen ParamGen) string {
	mut modifier := if func.return_typ.has_flag(.option) {
		'?'
	} else if func.return_typ.has_flag(.result) {
		'!'
	} else {
		''
	}
	mut out := ''
	out += p_gen.tmp_vars
	out += '\tunsafe {${fname}(${params})${modifier}'
	out += '}\n\tassert true\n'
	return out
}

fn case_02(func reflection.Function, fname string, params string, p_gen ParamGen) string {
	mut modifier := if func.return_typ.has_flag(.option) {
		'?'
	} else if func.return_typ.has_flag(.result) {
		'!'
	} else {
		''
	}
	mut out := ''
	out += '\tmut func := fn () ${modifier}bool {\n\t'
	out += p_gen.tmp_vars
	out += '\tunsafe {${fname}(${params})${modifier}'
	out += '}\n\t\treturn true\n\t}\n\tassert func()${modifier}\n'
	return out
}

fn case_03(func reflection.Function, fname string, params string, p_gen ParamGen) string {
	mut modifier := if func.return_typ.has_flag(.option) {
		'?'
	} else if func.return_typ.has_flag(.result) {
		'!'
	} else {
		''
	}
	mut out := ''
	out += '\tmut func := spawn fn () ${modifier}bool {\n\t'
	out += p_gen.tmp_vars
	out += '\t\tunsafe {${fname}(${params})${modifier}}\n'
	out += '\t\treturn true\n\t}()\n\tassert func.wait()${modifier}\n'
	return out
}

fn fuzzer_funcs() {
	funcs := reflection.get_funcs()

	mut p_gen := ParamGen{}

	ignore_funcs := ['bool', 'int', 'i64', 'i8', 'u8', 'u16', 'u32', 'u64', 'i16', 'f32', 'f64',
		'panic_option_not_set', 'panic_result_not_set', 'panic', 'panic_n', 'panic_n2',
		'execute_or_exit', 'execute_or_panic', 'panic_lasterr', 'execvp', 'execve', 'execute',
		'execute_opt', 'panic_error_number', 'fork', 'write_file', 'write_lines', 'write_file_array',
		'system', 'raw_execute', 'stdin', 'wait', 'ascii']
	deprecated := ['utf8_str_len', 'is_writable_folder']
	known_problems := ['read_file_array', 'get_lines', 'get_raw_lines', 'get_lines_joined',
		'get_line', 'input_password', 'fd_read', 'get_raw_stdin', 'fd_slurp']
	memory_fns := ['malloc', 'realloc_data', 'memdup', 'memdup_uncollectable', 'memdup_noscan',
		'malloc_noscan', 'fileno', 'vcalloc', 'vrealloc', 'v_realloc', 'vmemcpy', 'vmemset',
		'vmemmove', 'vmemcmp', 'malloc_uncollectable', 'vcalloc_noscan']
	mut count := 0

	mod_arg := cmdline.options_after(os.args, ['-m'])
	func_arg := cmdline.options_after(os.args, ['-p'])

	for i, func in funcs {
		if !func.is_pub || func.name in ignore_funcs || func.name in deprecated
			|| func.name in known_problems || func.receiver_typ != 0 || func.name in memory_fns {
			continue
		}

		fn_name := gen_func_name(func)
		if fn_name.starts_with('v.') || fn_name.starts_with('util.') {
			continue
		}

		if mod_arg.len != 0 && func.mod_name !in mod_arg {
			continue
		}

		if func_arg.len != 0 && '${func.mod_name}_${func.name}' !in func_arg {
			continue
		}

		mut out := 'module main\n'

		if func.mod_name !in ['', 'builtin'] {
			out += 'import ${func.mod_name}\n'
			if func.mod_name == 'strconv' {
				out += 'import strings\n'
			}
		}
		out += '\n'
		out += 'const arr_int = [0, 1, 2]!\n'
		out += 'const arr_uint = [u8(0), 1, 2]!\n'

		p_gen.init(func)
		for k, param in p_gen {
			func_test_name := '${i}_${k}'
			out += '\nfn test_${func_test_name}_simple() {\n'
			out += case_01(func, fn_name, param, p_gen)
			out += '}\n'
			out += '\nfn test_${func_test_name}_anon() {\n'
			out += case_02(func, fn_name, param, p_gen)
			out += '}\n'
			out += '\nfn test_${func_test_name}_spawn() {\n'
			out += case_03(func, fn_name, param, p_gen)
			out += '}\n'
		}
		if '-p' in os.args {
			println(out)
		} else {
			os.write_file('./tests/${func.mod_name}_${func.name}_test.v', out) or { panic(err) }
		}
		count++
	}

	if '-p' !in os.args {
		println('${count} tests generated')
	}
}

fn main() {
	fuzzer_funcs()
}
