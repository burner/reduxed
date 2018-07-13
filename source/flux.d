module flux;

struct Flux(T) {
	import observable;

	static string indentString(size_t indent) pure {
		string ret;
		foreach(it; 0 .. indent) {
			ret ~= "\t";
		}
		return ret;
	}

	static string buildStructImpl(S, size_t indent)() {
		import std.traits : isBasicType;
		import std.format : format;

		string ret;
		if(indent) {
			ret = indentString(indent) ~ format("struct __Flux%s {\n", S.stringof);
		}

		static assert(is(S == struct));
		foreach(mem; __traits(allMembers, S)) {
			alias Type = typeof(__traits(getMember, S, mem));
			enum isStruct = is(Type == struct);
			static if(isStruct) {
				ret ~= buildStructImpl!(Type, indent + 1)();
			}
			static if(isStruct) {
				ret ~= indentString(indent + 1) ~ format("__Flux%s %s;\n", 
							Type.stringof, mem
						);
			} else {
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

	mixin(buildStruct!T());
	pragma(msg, buildStruct!T());
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
	struct Bar {
		float a;
		float b;
	}

	Flux!Bar store;
}	

unittest {
	void fun(ref const(float) f) @safe {
		int a = 10;
	}

	struct Foo {
		float c;
	}
	struct Bar {
		float a;
		float b;
		Foo foo;
	}

	Flux!Bar store;

	store.foo.c.subscribe(&fun);
}	
