module flux;

struct Flux(S) {
}

unittest {
	struct SomeStore {
		int value = 10;
	}

	Flux!SomeStore f;
}
