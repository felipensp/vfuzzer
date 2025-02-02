module main

import rand
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
		typeof[isize]().idx, typeof[i16]().idx, typeof[i32]().idx, typeof[i64]().idx,
		typeof[int]().idx {
			return ['-1', '0', int(0x7FFFFFFF).str(), int(0x80000000 - 1).str()]
		}
		typeof[u8]().idx, typeof[u16]().idx, typeof[u32]().idx, typeof[u64]().idx {
			return ['0', int(0x80000000 - 1).str()]
		}
		typeof[[]int]().idx, typeof[[]u8]().idx {
			return ['${reflection.type_name(arg.typ.idx())}{len:3}']
		}
		typeof[[]string]().idx {
			return ['["a", ""]', '...["a", ""]']
		}
		typeof[string]().idx {
			return ['"a"']
		}
		typeof[rune]().idx {
			return ['`a`, ``, `\0`']
		}
		typeof[f32]().idx, typeof[f64]().idx {
			return ['1.12345']
		}
		typeof[bool]().idx {
			return ['true', 'false']
		}
		typeof[byte]().idx, typeof[char]().idx {
			return ['0xff', '0x00']
		}
		typeof[[]voidptr]().idx, typeof[voidptr]().idx {
			return ['voidptr(0)', 'voidptr(-1)']
		}
		typeof[map[string]int]().idx {
			return ['{"a": 1}', '{"": 0}']
		}
		else {
			type_name := reflection.type_name(arg.typ.idx())
			return if type_name.starts_with('fn (') {
				params := type_name.all_after_last('(').all_before_last(')').split(',')
				arg_params := if params.len > 1 {
					'_, ' + params[1..].map('${it.to_lower()}_ int').join(',')
				} else {
					''
				}
				ret_type := type_name.all_after_last(')').trim_space().replace('R', 'int').replace('T',
					'int')
				ret_value := if ret_type == 'bool' {
					'true'
				} else if ret_type == 'int' {
					'0'
				} else {
					'${ret_type}{}'
				}
				[
					'fn (${arg_params}) ${ret_type} { return ${ret_value} }',
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
			p_args := p.gen(func.mod_name.all_after_last('.'), arg)
			arg_val := rand.element(p_args) or { panic(err) }
			if arg.typ.is_ptr() {
				tmp_var := 't${k}'
				if arg_val.ends_with('{}') || arg_val.starts_with('[]') {
					p.tmp_vars += '\tmut ${tmp_var} := ${arg_val}\n' // no cast
				} else {
					p.tmp_vars += '\tmut ${tmp_var} := ${reflection.type_name(arg.typ.idx())}(${arg_val})\n' // with cast
				}
				args << if arg.is_mut { 'mut ${tmp_var}' } else { tmp_var }
			} else {
				args << arg_val
			}
		}
		p.inputs << args.join(', ')
		break
	}
}
