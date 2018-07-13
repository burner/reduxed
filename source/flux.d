module flux;

enum Flux;

struct FluxStore(T) {
	import observable;

	pragma(msg, buildStruct!T());
	mixin(buildStruct!T());

	static string moduleNameFromString(string fully) {
		import std.string : lastIndexOf;
		const ptrdiff_t dot = fully.lastIndexOf('.');
		if(dot != -1) {
			return fully[0 .. dot];
		}
		return fully;
	}

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
				static if(!isBasicType!(Type)) {
					ret ~= indentString(indent + 1) 
							~ format("import %s;\n",
									moduleNameFromString(fullyQualifiedName!Type)
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

	FluxStore!Bar store;
}	
