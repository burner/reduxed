module observable;

private struct Observer(T) {
	void delegate(ref const(T)) @safe onMsg;
	void delegate() @safe onClose;
}

struct Observable(T) {
	import std.traits : isImplicitlyConvertible;
	Observer!(T)[void*] observer;

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

	void push(S)(auto ref const(S) value) @safe
			if(isImplicitlyConvertible!(S,T))
	{
		foreach(ref it; this.observer) {
			it.onMsg(value);
		}
	}
}

unittest {
	import std.functional : toDelegate;

	static void fun(ref const(int) f) @safe {
		import std.stdio : writeln;
		() @trusted {
			writeln(f);
		}();
	}

	Observable!int intOb;
	intOb.subscribe(toDelegate(&fun));

	intOb.push(10);
}
