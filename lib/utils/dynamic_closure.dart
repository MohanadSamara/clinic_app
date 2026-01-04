// Dynamic closure utility for clinic app
// Creates a closure that takes an Object and returns a String by calling context[property](obj)

typedef StringClosure = String Function(Object);

StringClosure createDynamicClosure(dynamic context, String property) {
  return (Object obj) => context[property](obj).toString();
}
