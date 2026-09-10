## Signals and truth table
Note: I3C "specific", i.e., assumes that there is a pull-up device on the bus.
O / OE / PPnOD / En are (envisioned) output signals of the I3C IP. Pad is the piece of metal that the bond wire gets attached to.

|          | O (data) |    OE    |   PPnOD  |    En    |   Pad    |
|----------|:--------:|:--------:|:--------:|:--------:|:--------:|
| OD - 1   |    1     |    0     |     0    |     1    |  Weak-1  |
| OD - 0   |    0     |    1     |     0    |     1    | Strong-0 |
| PP - 1   |    1     |    1     |     1    |     1    | Strong-1 |
| PP - 0   |    0     |    1     |     1    |     1    | Strong-0 |
| No drive |    x     |    0     |     0    |     0    |  Weak-1  |

## Background / Rationale
Pad cells combine all of the above signals through a (hopefully glitch-free) logic function into individual gate control signals for the PMOS and NMOS transistors which eventually drive the P(ad) inout towards the outside world.
To achieve dynamic control for combined receive and transmit operation, for the latter in both open-drain (OD) and push-pull (PP) mode, it is enough to make sure that both FETs stay OFF in the following cases:

1. We do not want to transmit any data whatsoever (receive/observe)
2. We want to put an open-drain "high" onto the bus

The key observation is that these two are electrically identical. The "driving" of the OD-one is merely the result of the presence of pull-up resistors _somewhere_ on the bus. Note that these are not controlled by any of the signals above. Further note that there is no such thing as an "open-drain zero" that would be different from a push-pull zero: They are identical. In both cases, the NMOS in the pad cell actively (strong) drives P(ad) to zero/ground.

## Use cases

Note: While practically all digital CMOS pad cells feature an O (data) and OE (output-enable) port, a port to control the drive mode is often not available. To achieve the behavior described above, any of the following strategies work:

1. **Only use O and OE. Disregard PPnOD and En** This is the most common case and should be compatible with any pad cell. A "disabled" driver is simply achieved by "driving" an OD-one onto the bus.
2. **Only use O and PPnOD. Tie OE high at the pad cell. Disregard En** Alternatively to 1., this achieves electrically the same by "always enabling" the output, but switching the drive mode. The inactive non-driving state is again achieved through an OD-one which turns both FETs off as explained above.
3. **Same as 2. but additionally connect the OE port of the pad to En** Additional safe guard against accidentally driving anything onto the bus when we should not.

