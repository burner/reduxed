module flux;

import mutex : DummyMutex;

enum Flux;

private string buildExecuteCallString(Args...)() {
	import std.traits : isInstanceOf;
	import std.format : format;
	import observable;
	string ret = "args[0] = Fun(";
	size_t idx = 0;
	static foreach(arg; Args) {
		if(idx > 0) {
			ret ~= ", ";
		}
		static if(isInstanceOf!(Observable, arg)) {
			ret ~= format("cast(%s)args[%u]", arg.Type.stringof, idx);
		} else {
			ret ~= format("args[%u]", idx);
		}
		++idx;
	}
	ret ~= ");\nargs[0].publish();";
	return ret;
}

private string buildMutexArray(Args...)() {
	import std.traits : isInstanceOf;
	import std.format : format;
	import observable;
	string ret = "import std.algorithm.sorting : sort;\n";
	ret ~= format("Mutex*[%d] mutexes;\n", Args.length);
	ret ~= "size_t mutexIdx;\n";
	size_t idx = 0;
	static foreach(arg; Args) {{
		static if(isInstanceOf!(Observable, arg)) {
			ret ~= format("mutexes[mutexIdx++] = &(args[%u].mutex);\n", idx);
		}
		++idx;
	}}
	ret ~= "sort(mutexes[0 .. mutexIdx]);\n";
	return ret;
}

private string indentString(size_t indent) pure {
	string ret;
	foreach(it; 0 .. indent) {
		ret ~= "\t";
	}
	return ret;
}

private string buildStructImpl(S, size_t indent)() {
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

private string buildStruct(S)() {
	string ret = "struct Store {\n";
	ret ~= buildStructImpl!(S, 0);

	ret ~= "}\n";
	ret ~= "Store store;\n";
	ret ~= "alias store this;\n";
	return ret;
}

struct FluxStore(T,Mutex = DummyMutex) {
	import observable;

	pragma(msg, buildStruct!T());
	mixin(buildStruct!T());

	void execute(alias Fun, Args...)(ref Args args) {
		pragma(msg, buildMutexArray!Args());
		pragma(msg, buildExecuteCallString!Args());
		mixin(buildMutexArray!Args());
		//mixin(buildMutexArrayLock());
		foreach(Mutex* mu; mutexes[0 .. mutexIdx]) {
			mu.lock();
		}
		mixin(buildExecuteCallString!Args());
		foreach(Mutex* mu; mutexes[0 .. mutexIdx]) {
			mu.unlock();
		}
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
		int b;
		int a;
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
