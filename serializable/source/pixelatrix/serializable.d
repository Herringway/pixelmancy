module pixelatrix.serializable;
import siryul;

align(1) struct Serializable(T) {
	align(1):
	T data;
	@SerializationMethod
	string toBase64() const @safe {
		import std.base64 : Base64;
		return Base64.encode(data.raw[]);
	}
}
