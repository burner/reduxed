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

	void execute(string obj, alias Fun)() {
		import std.format : format;
		mixin(format("this.%s.setValue(Fun(this.%s.getValue()));", obj, obj));
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

int increment(int a) {
	return a + 1;
}

unittest {
	struct Bar {
		float a;
		int b;
	}

	FluxStore!Bar store;

	void fun(ref const(float) f) @safe {
		int a = 10;
	}

	store.a.subscribe(&fun);

	store.execute!("b", increment)();
	assert(store.b.getValue() == 1);
}	
