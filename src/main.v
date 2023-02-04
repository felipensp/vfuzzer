module main

import os
import v.reflection

fn gen_func_name(func reflection.Function) string {
	return if func.mod_name !in ['', 'builtin'] {
		'${func.mod_name.all_after_last('.')}.${func.name}'
	} else {
		'${func.name}'
	}
}

fn fuzzer_funcs() {
	funcs := reflection.get_funcs()

	mut p_gen := ParamGen{}

	ignore_funcs := ['bool', 'int', 'i64', 'i8', 'u8', 'u16', 'u32', 'u64', 'i16', 'f32', 'f64',
		'panic_option_not_set', 'panic_result_not_set', 'panic', 'execute_or_exit',
		'execute_or_panic']
	deprecated := ['utf8_str_len', 'is_writable_folder']
	known_problems := ['read_file_array']
	mut count := 0

	for i, func in funcs {
		if !func.is_pub || func.name in ignore_funcs || func.name in deprecated
			|| func.name in known_problems || func.receiver_typ != 0 {
			continue
		}

		fn_name := gen_func_name(func)
		if fn_name.starts_with('v.') || fn_name.starts_with('util.') {
			continue
		}

		if os.args.len > 1 && os.args[1] != '${func.mod_name}_${func.name}' {
			continue
		}

		mut out := 'module main\n'

		if func.mod_name !in ['', 'builtin'] {
			out += 'import ${func.mod_name}\n'
			if func.mod_name == 'strconv' {
				out += 'import strings\n'
			}
		}

		p_gen.init(func)
		for k, param in p_gen {
			func_test_name := '${i}_${k}'
			out += '\nfn test_${func_test_name}() {\n'
			out += p_gen.tmp_vars
			out += '\tunsafe { ${fn_name}(${param})'
			if func.return_typ.has_flag(.option) {
				out += '?'
			} else if func.return_typ.has_flag(.result) {
				out += '!'
			}
			out += '}\n\tassert true\n'
			out += '}\n\n'
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
