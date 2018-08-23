import reduxed;

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
	Store!Bar store;

	store.foo.subscribe(&fun);
}	

unittest {
	class Fun {
		int localInt;

		void callback(ref const(int) a) @safe {
			this.localInt = a;
		}
	}

	struct StoreType {
		int a;
	}

	static int increment(int old) {
		return old + 1;
	}

	auto f = new Fun();
	assert(f.localInt == 0);

	Store!StoreType store;
	store.a.subscribe(&f.callback);

	foreach(i; 1 .. 10) {
		store.execute!(increment)(store.a);
		assert(f.localInt == i);
	}
}
