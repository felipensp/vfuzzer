module main

import v.reflection

fn gen_func_name(func reflection.Function) string {
	return if func.mod_name !in ['', 'builtin'] { '${func.mod_name.all_after_last('.')}.${func.name}' } else { '${func.name}' }
}

fn fuzzer_funcs() {
	funcs := reflection.get_funcs()
	mut mods := []string{}
	mut out := 'module main\n'
	mut out2 := ''

	ignore_funcs := ['bool', 'int', 'i64', 'i8', 'u8', 'u16', 'u32', 'u64', 'i16', 'f32', 'f64', 'panic_option_not_set', 'panic_result_not_set', 'panic', 'execute_or_exit', 'execute_or_panic']
	deprecated := ['utf8_str_len', 'is_writable_folder']
	known_problems := ['read_file_array']
	
	for i, func in funcs {
		if func.args.len != 1 || func.args[0].typ != typeof[string]().idx {
			continue
		}

		if !func.is_pub || func.name in ignore_funcs || func.name in deprecated || func.name in known_problems || func.receiver_typ != 0 {
			continue
		}

		fn_name := gen_func_name(func)	
		if fn_name.starts_with('v.') || fn_name.starts_with('util.') {
			continue
		}

		if func.mod_name !in ['', 'builtin'] {
			if func.mod_name !in mods {
				mods << func.mod_name
			}
		}

		out2 += 'fn test_${i}() {\n'
		out2 += '\tunsafe { ${fn_name}("abc")'
		if func.return_typ.has_flag(.option) {
			out2 += '?'
		} else if func.return_typ.has_flag(.result) {
			out2 += '!'
		}
		out2 += '}\n\tassert true\n'
		out2 += '}\n\n'
	}

	out += mods.map('import ${it}').join('\n')
	out += '\n'
	out += out2
	println(out)		
}

fn main() {
	fuzzer_funcs()
}
