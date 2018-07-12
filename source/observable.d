module observable;

private struct Observer(T) {
	void delegate(ref const(T)) @safe onMsg;
	void delegate() @safe onClose;
}

struct Observable(T) {
	import std.traits : isImplicitlyConvertible;
	Observer!(T)[void*] observer;

	~this() @safe {
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
		this.observer[cast(void*)onMsg.ptr] = ob;
	}

	void unSubscribe(void delegate(ref const(T)) @safe onMsg) @safe pure {
		if(onMsg.ptr in this.observer) {
			this.observer.remove(onMsg.ptr);
		}
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
	bool b;

	void fun(ref const(int) f) @safe {
	}

	void fun2() @safe {
		b = true;
	}

	{
		Observable!int ob;
		ob.subscribe(&fun, &fun2);
		ob.push(10);
	}

	assert(b);
}
