module main

import v.reflection

struct ParamGen {
mut:
	idx      int
	inputs   []string
	tmp_vars string
	current  string
}

fn (mut p ParamGen) next() ?string {
	return if p.idx < p.inputs.len {
		p.idx++
		p.inputs[p.idx - 1]
	} else {
		none
	}
}

fn (mut p ParamGen) gen(mod_name string, arg reflection.FunctionArg) []string {
	match arg.typ.idx() {
		typeof[isize]().idx, typeof[u8]().idx, typeof[u16]().idx, typeof[u32]().idx,
		typeof[u64]().idx, typeof[i16]().idx, typeof[i32]().idx, typeof[i64]().idx,
		typeof[int]().idx {
			return ['0', '1', '2']
		}
		typeof[[]string]().idx {
			return ['["a"]']
		}
		typeof[string]().idx {
			return ['"a"', '"b"', '"c"']
		}
		typeof[rune]().idx {
			return ['`a`']
		}
		typeof[f32]().idx, typeof[f64]().idx {
			return ['1.12345']
		}
		typeof[bool]().idx {
			return ['true', 'false']
		}
		typeof[byte]().idx, typeof[char]().idx {
			return ['0xff']
		}
		typeof[[]voidptr]().idx, typeof[voidptr]().idx {
			return ['voidptr(0)']
		}
		typeof[map[string]int]().idx {
			return ['{"a": 1}']
		}
		else {
			type_name := reflection.type_name(arg.typ.idx())
			return if type_name.starts_with('fn (') {
				[
					'${type_name.replace('(string)', '(_)').replace('(int)', '(_)').replace('(T)',
						'(_)')} {}',
				]
			} else if type_name == 'T' {
				['0']
			} else if type_name == '[]T' {
				['[]int{len:10}']
			} else if type_name == '[][]T' {
				['[][]int{len:10}']
			} else {
				out := if !arg.typ.is_ptr() && arg.is_mut { 'mut ' } else { '' }
				if type_name == 'Builder' {
					['${out}strings.Builder{}']
				} else {
					mod := if mod_name in ['builtin', ''] { '' } else { '${mod_name}.' }
					if type_name.starts_with('[]') {
						[
							out + type_name.all_before_last(']') +
								']${mod}${type_name.replace('[]', '')}{}',
						]
					} else {
						['${out}${mod}${type_name}{}']
					}
				}
			}
		}
	}
}

fn (mut p ParamGen) init(func reflection.Function) {
	p.idx = 0
	p.inputs = []string{}
	for {
		mut args := []string{}
		p.tmp_vars = ''
		for k, arg in func.args {
			arg_val := p.gen(func.mod_name.all_after_last('.'), arg).first()
			if arg.typ.is_ptr() {
				tmp_var := 't${k}'
				p.tmp_vars += '\tmut ${tmp_var} := ${arg_val}\n'
				args << if arg.is_mut { 'mut ${tmp_var}' } else { tmp_var }
			} else {
				args << arg_val
			}
		}
		p.inputs << args.join(', ')
		break
	}
}
