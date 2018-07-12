module observable;

private struct Observer(T) {
	void delegate(ref const(T)) @safe onMsg;
	void delegate() @safe onClose;
}

struct Observable(T) {
	import std.traits : isImplicitlyConvertible;
	Observer!(T)[void*] observer;

	~this() @safe {
		import std.stdio;
		foreach(ref it; this.observer) {
			if(it.onClose) {
				it.onClose();
			}
		}
	}

	@property size_t length() const @safe pure nothrow @nogc {
		return this.observer.length;
	}

	void subscribe(void delegate(ref const(T)) @safe onMsg) @safe pure {
		this.subscribe(onMsg, null);
	}

	void subscribe(void delegate(ref const(T)) @safe onMsg, 
			void delegate() @safe onClose) @safe pure
	{
		Observer!T ob;
		ob.onMsg = onMsg;
		ob.onClose = onClose;
		() @trusted { 
			assert(onMsg.funcptr);
			this.observer[cast(void*)onMsg.funcptr] = ob;
		}();
	}

	void unSubscribe(void delegate(ref const(T)) @safe onMsg) @safe pure {
		() @trusted { 
			if(onMsg.funcptr in this.observer) {
					assert(onMsg.funcptr);
					this.observer.remove(cast(void*)onMsg.funcptr);
			}
		}();
	}

	void push(S)(auto ref const(S) value) @safe
			if(isImplicitlyConvertible!(S,T))
	{
		foreach(ref it; this.observer) {
			it.onMsg(value);
		}
	}
}

unittest {
	int globalInt = 0;

	void fun(ref const(int) f) @safe {
		globalInt = f;
	}

	Observable!int intOb;
	assert(intOb.length == 0);
	intOb.subscribe(&fun);
	assert(intOb.length == 1);
	intOb.push(10);
	assert(globalInt == 10);
	intOb.push(globalInt);
	assert(globalInt == 10);
	intOb.unSubscribe(&fun);
	assert(intOb.length == 0);
}

unittest {
	import std.conv : to;
	bool b;

	void fun(ref const(int) f) @safe {
		int a = 10;
	}

	void fun1(ref const(int) f) @safe {
		int c = 10;
	}

	void fun2() @safe {
		b = true;
	}

	{
		Observable!int ob;
		ob.subscribe(&fun, &fun2);
		ob.subscribe(&fun1);
		assert(ob.length == 2, to!string(ob.length));
		ob.push(10);
	}

	assert(b);
}
