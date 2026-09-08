module IdrisCompatibility

export
choice : Nat -> Nat
choice value = value

export
one_of : Nat -> Nat
one_of value = S value

joined→⇒←≤name : Nat
joined→⇒←≤name = 40

export
compatibility_value : Number
compatibility_value = OneMore (choice joined→⇒←≤name)
