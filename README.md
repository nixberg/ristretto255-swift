# Ristretto255

Swift implementation of [ristretto255](https://ristretto.group)
([Internet-Draft](https://tools.ietf.org/html/draft-hdevalence-cfrg-ristretto-01)).
Mostly a port of [curve25519-dalek](https://github.com/dalek-cryptography/curve25519-dalek). Experimental, do not use.

## Usage
### Key exchange
#### Alice:
```Swift
let secretAlice = Scalar.random()
let publicAlice = Element(generatorTimes: secretAlice)

let sharedSecret = secretAlice * publicBob
```
#### Bob:
```Swift
let secretBob = Scalar.random()
let publicBob = Element(generatorTimes: secretBob)

let sharedSecret = secretBob * publicAlice
```

### Schnorr signature
#### Alice:
```Swift
let secretStatic = Scalar.random()
let publicStatic = Element(generatorTimes: secretStatic)

let secretEphemeral = Scalar.random()
let publicEphemeral = Element(generatorTimes: secretEphemeral)

let c = Scalar(fromUniformBytes: hash(publicStatic.encoded(), publicEphemeral.encoded(), message))
let t = secretEphemeral + c * secretStatic
```
#### Bob:
```Swift
let c = Scalar(fromUniformBytes: hash(publicStatic.encoded(), publicEphemeral.encoded(), message))

let lhs = Element(generatorTimes: t)
let rhs = c * publicStatic + publicEphemeral

assert(lhs == rhs) // true
```
