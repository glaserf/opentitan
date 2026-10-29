## Copyright lowRISC contributors (OpenTitan project).
## Licensed under the Apache License, Version 2.0, see LICENSE for details.
## SPDX-License-Identifier: Apache-2.0

## I3C constraints for the CW341 board.
##
## This is a separate file, and declared as file_type SDC so that Edalize reads
## it with `read_xdc -unmanaged`, because it calls the procedures defined in
## hw/ip/i3c/syn/i3c_constraints.tcl. Vivado's managed XDC parser rejects
## user-defined commands with "[Designutils 20-1307] ... is not supported in
## the xdc constraint file" and then continues, which would silently drop every
## I3C constraint. clocks_cw341.xdc stays managed because reading it unmanaged
## makes its set_clock_sense constraints fail: Vivado defers those to
## implementation when the file is managed, but executes them immediately when
## it is not.
##
## Read after clocks_cw341.xdc, which creates clk_io and defines the shared
## instance variables this file uses.

## Netlist naming. Vivado spells all of these differently from the ASIC tools,
## and a wrong spelling matches nothing silently, so each one is set here.
set ::i3c_cfg(reg_q_pin)    {q_reg[%d]/Q}
set ::i3c_cfg(pad_attr_pin) {mio_pad_attr_q_reg[%d][%s]/Q}
set ::i3c_cfg(buf_in_pin)   I
set ::i3c_cfg(buf_out_pin)  O
set ::i3c_cfg(sync_flop)    {u_sync_1/q_o_reg[*]}

## I3C
# Both I3C instances are constrained by the shared procedures in
# hw/ip/i3c/syn/i3c_constraints.tcl, which the FuseSoC core reads immediately
# before this file. The I3C v1.2 timing numbers and the reasoning behind the
# clock structure live there; only the board-specific choices are made here.
#
# Pads, used in both directions:
#   I3C0: SCL = IOB10 (MIO pad 19), SDA = IOB9  (MIO pad 18)
#   I3C1: SCL = IOB11 (MIO pad 20), SDA = IOB12 (MIO pad 21)
# Only these pads are analyzed; software may still select others.
#
# Entries are {peripheral_input peripheral_output mio_pad}. The reset detectors
# observe the same pads through their own peripheral inputs (50-53) and have no
# peripheral output of their own.
i3c_pinmux_case_analysis ${u_pinmux} {
    {38 38 19}
    {39 39 18}
    {40 40 20}
    {41 41 21}
    {50  - 19}
    {51  - 18}
    {52  - 20}
    {53  - 21}
}

# Do not hold the bus interface to the I3C specification on this board. SCL and
# SDA reach the IP through the pinmux, and measurement on a routed CW340 build
# shows that cannot work: the SCL input clock tree alone costs 19.1ns, and the
# Target's SDA output path back out through the pinmux output mux takes 44.1ns,
# 93% of it routing. That is a tSCO of about 63ns against the 20ns the
# specification allows. The FPGA build is for functional bring-up, so the
# clocks, the pinmux case analysis and the internal budgets are applied, but
# the I/O delays are not.
set ::i3c_cfg(bus_io_delays) 0

# The Controller derives SCL from the peripheral clock, the same origin the SPI
# host uses above. On this board clk_io is 24 MHz rather than the 96 MHz the IP
# is parameterized for, so the generated SCL is correspondingly slower; the
# waveform in clk_io cycles is unchanged.
set i3c_clk_pin    ${u_clkmgr}/u_clk_io_peri_cg/gen_gate.u_bufgce/O
set i3c_clk_period 41.667
# clk_aon is 250 kHz on this board.
set i3c_aon_period 4000.0

i3c_constrain ${u_i3c0} IOB10 IOB9  I3C0 ${i3c_clk_pin} clk_io ${i3c_clk_period}
i3c_constrain ${u_i3c1} IOB11 IOB12 I3C1 ${i3c_clk_pin} clk_io ${i3c_clk_period}

# The reset detectors are the secondary partitions, on the AON clock. i3c0's
# sits in the AON power domain, i3c1's in the Main domain.
i3c_constrain_rstdet ${u_i3c0_rstdet} I3C0 clk_io clk_aon ${i3c_aon_period}
i3c_constrain_rstdet ${u_i3c1_rstdet} I3C1 clk_io clk_aon ${i3c_aon_period}

i3c_summary


## Clock groups
# Each instance's bus clocks group themselves, in i3c_create_clocks. The
# generated SCL that would have to join clk_io's group is not created here,
# because the bus I/O timing is not modelled on this board.
