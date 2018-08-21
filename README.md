reduxed
=======

A library implementing the redux/flux pattern for the D Progamming Language.

```D
// Define your store as a struct
struct Bar {
	int b;
	int a;
}

// Create the store
FluxStore!Bar store;
// set store init values
store.a = 1;
store.b = 2;

int a = 1337;

// We use this function to observe Bar.a
void fun(ref const(int) f) @safe {
	a = f;
}

// Here we subscribe to Bar.a
// Whenever Bar.a changes "fun" gets called
store.a.subscribe(&fun);

// This function is used to change the value
static int increment(int a, int b) pure {
	return a + b; 
}

// Here we call increment with the values of store.a and store.b
// the effect is equal to
// store.a = increment(store.a, store.b);
store.execute!(increment)(store.a, store.b);

assert(store.a.value == 3);
assert(a == 3);
```
