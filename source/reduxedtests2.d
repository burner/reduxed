module reduxedtest2;

import reduxed;

/* In this example we want to treat `Foo` as one unit, not as a nesting of
individual values.
We do this by using the `@Reduxed` UDA on it in `struct Bar`.
*/
struct Foo {
	float fa;
	float fb;
}

struct Bar {
	int b;
	int a;

	@Reduxed
	Foo foo;
}

unittest {
	import std.math : approxEqual;

	// Create the store
	Store!Bar store;

	// set store init values
	store.a = 1;
	store.b = 2;
	store.foo = Foo(1.0, 2.0);

	Foo result;

	// We use this function to observe Bar.foo
	void fun(ref const(Foo) foo) @safe {
		// we set result to test it later
		result = foo;
	}

	store.foo.subscribe(&fun);

	// This function is used to change the value
	static Foo increment(Foo foo) pure {
		return Foo(foo.fa + 1.0, foo.fb + 2.0);
	}

	// call the reducer
	store.execute!(increment)(store.foo);

	assert(approxEqual(result.fa, 2.0));
	assert(approxEqual(result.fb, 4.0));
}	
