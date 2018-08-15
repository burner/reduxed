module flux;

enum Flux;

struct FluxStore(T) {
	import observable;

	pragma(msg, buildStruct!T());
	mixin(buildStruct!T());

	static string indentString(size_t indent) pure {
		string ret;
		foreach(it; 0 .. indent) {
			ret ~= "\t";
		}
		return ret;
	}

	static string buildStructImpl(S, size_t indent)() {
		import std.traits : isBasicType, hasUDA, fullyQualifiedName;
		import std.format : format;

		string ret;
		if(indent) {
			ret = indentString(indent) ~ format("struct __Flux%s {\n", S.stringof);
		}

		static assert(is(S == struct));
		foreach(mem; __traits(allMembers, S)) {
			alias Type = typeof(__traits(getMember, S, mem));
			enum isStruct = is(Type == struct);
			static if(isStruct && hasUDA!(Type,Flux)) {
				ret ~= buildStructImpl!(Type, indent + 1)();
				ret ~= indentString(indent + 1) ~ format("__Flux%s %s;\n", 
							Type.stringof, mem
						);
			} else {
				import std.traits : moduleName;
				static if(!isBasicType!(Type)) {
					ret ~= indentString(indent + 1) 
							~ format("import %s;\n",
									moduleName!(Type)
								);
				}
				ret ~= indentString(indent + 1) ~ format("Observable!(%s) %s;\n", 
							Type.stringof, mem
						);
			}
		}

		if(indent) {
			ret ~= indentString(indent) ~ "}\n";
		}

		return ret;
	}

	static string buildStruct(S)() {
		string ret = "struct Store {\n";
		ret ~= buildStructImpl!(S, 0);

		ret ~= "}\n";
		ret ~= "Store store;\n";
		ret ~= "alias store this;\n";
		return ret;
	}

	static string buildExecuteCallString(Args...)() {
		import std.traits : isInstanceOf;
		import std.format : format;
		string ret = "args[0] = Fun(";
		size_t idx = 0;
		static foreach(arg; Args) {{
			if(idx > 0) {
				ret ~= ", ";
			}
			static if(isInstanceOf!(Observable, arg)) {
				ret ~= format("cast(%s)args[%u]", arg.Type.stringof, idx);
			} else {
				ret ~= format("args[%u]", idx);
			}
			++idx;
		}}
		ret ~= ");\nargs[0].publish();";
		return ret;
	}

	void execute(alias Fun, Args...)(ref Args args) {
		pragma(msg, buildExecuteCallString!Args());
		mixin(buildExecuteCallString!Args());
	}

}

unittest {
	import observable;
	struct Bar {
		Observable!float a;
		Observable!float b;
	}

	struct Foo {
		Observable!int a;
		Observable!int b;

		Bar bar;
	}

	struct Flux {
		Foo foo;
	}

	void fun(ref const(float) f) @safe {
		int a = 10;
	}

	Flux f;

	f.foo.bar.a.subscribe(&fun);
}

unittest {
	import std.format : format;
	struct Bar {
		int a;
		int b;
	}

	static int increment(int a, int b) {
		return a + b; 
	}

	FluxStore!Bar store;
	store.a = 1;
	store.b = 2;

	int a = 1337;

	void fun(ref const(int) f) @safe {
		a = f;
	}

	store.a.subscribe(&fun);

	store.execute!(increment)(store.a, store.b);
	assert(store.a.value == 3, format("%s", store.a.value));
	assert(a == 3, format("%s", a));
}	
