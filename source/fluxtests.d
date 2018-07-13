import flux;

struct Foo {
	int c = 10;
}

struct Bar {
	float a;
	float b;
	Foo foo;
}

unittest {
	void fun(ref const(Foo) f) @safe {
	}
	FluxStore!Bar store;

	store.foo.subscribe(&fun);
}	
