#!/usr/bin/env python3

def print_hex(name, number):
    print(f"let {name} = \"{number.to_bytes(32, 'little').hex()}\"\n")

def print_scalar(name, scalar):
    mask = 2**52 - 1
    print(f"""let {name} = Scalar(
    {(scalar >> 0 * 52) & mask:#018x},
    {(scalar >> 1 * 52) & mask:#018x},
    {(scalar >> 2 * 52) & mask:#018x},
    {(scalar >> 3 * 52) & mask:#018x},
    {(scalar >> 4 * 52) & mask:#018x}
)
""")

def print_field_element(name, fe):
    mask = 2**51 - 1
    print(f"""let {name} = FieldElement(
    {(fe >> 0 * 51) & mask:#018x},
    {(fe >> 1 * 51) & mask:#018x},
    {(fe >> 2 * 51) & mask:#018x},
    {(fe >> 3 * 51) & mask:#018x},
    {(fe >> 4 * 51) & mask:#018x}
)
""")

def extended_gcd(a, b):
    if a == 0: return (b, 0, 1)
    g, y, x = extended_gcd(b % a, a)
    return (g, x - (b // a) * y, y)

def modular_inv(a, m):
    g, x, y = extended_gcd(a, m)
    assert g == 1
    return x % m


print("Scalars:")

order = 2**252 + 27742317777372353535851937790883648493
print_scalar("order", order)

print_scalar("montgomeryRadix",        2**260 % order)
print_scalar("montgomeryRadixSquared", 2**520 % order)

# order * orderFactor = -1 (mod 2^52)
orderFactor = (modular_inv(order, 2**52) * -1) % 2**52
print(f"let orderFactor = {orderFactor:#018x}\n")


print("\nFieldElements:\n")

p = 2**255 - 19

d = 37095705934669439343138083508754565189542113879843219016388785533085940283555
print_field_element("d", d)
print_field_element("twoD", (d * 2) % p)

print_field_element("minusOne", -1 % p)
print_field_element("oneMinusDSquared", (1 - d**2) % p)
print_field_element("dMinusOneSquared", (d - 1)**2 % p)

print_field_element("squareRootMinusOne", 19681161376707505956807079304988542015446066515923890162744021073123829784752)
print_field_element("squareRootATimesDMinusOne", 25063068953384623474111414158702152701244531502492656460079210482610430750235)
print_field_element("inverseSquareRootMinusOneMinusD", 54469307008909316920995813868745141605393597292927456921205312896311721017578)


print("\nTests:\n")

x = 14474011154664524427946373126085988481658748083205070504932198000989141204991
y = 6145104759870991071742105800796537629880401874866217824609283457819451087098

print_scalar("x", x)
print_hex("xBytes", x)
print_scalar("y", y)
print_scalar("x*y", (x * y) % order)

a = 2351415481556538453565687241199399922945659411799870114962672658845158063753
b = 4885590095775723760407499321843594317911456947580037491039278279440296187236

print_scalar("a", a)
print_hex("aBytes", a)
print_scalar("b", b)
print_hex("bBytes", b)
print_scalar("a+b", (a + b) % order)
print_scalar("a-b", (a - b) % order)

print_scalar("c", (2**512 - 1) % order)
