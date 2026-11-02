# Copyright lowRISC contributors (OpenTitan project).
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# I3C timing constraints, shared by the ASIC (SDC) and the FPGA (XDC) flows.
#
# The I3C IP shares one SCL/SDA pad pair for Controller and Target roles:
#
#  - The Controller is synchronous to clk_i and *generates* SCL. With
#    HalfCycleScl set, SCL is `state_q[ST_SCL] | gen_hc_scl.scl_n`, i.e., a
#    posedge flop OR'ed with a negedge flop (i3c_controller_trx.sv).
#  - The Target has no free-running clock. It is clocked by the bus itself:
#    SCL and its inverse for SDR/HDR-DDR data, SDA and its inverse for
#    START/STOP detection (i3c_input_buffers.sv, four clock trees).
#
# Each pad therefore carries two mutually exclusive SCL *sources*: One from our
# Controller, and one from an external Active Controller; the Target is timed
# against the external one.
# The generated SCL is stopped before it reaches the Target clockt rees, because
# this path would leave and re-enter the chip through the pad and with the
# resulting skews making timing closure impossible.
#
# Timing is per MIPI I3C Basic v1.2 (+ Errata 01), Tables 48-50 and Figures
# 73/80/81. In SDR the Target launches SDA on the falling SCL edge and samples
# on the rising edge, but both of its shift registers sample unconditionally and
# the output enable toggles on both edges, so both edges are referenced even in
# pure SDR; HDR-DDR adds data on both edges.
#
# Usage:
#   set ::i3c_cfg(reg_q_pin) {q_reg[%d]/Q} ;# netlist naming; defaults are ASIC
#   set ::i3c_cfg(board_dly_max) 2.0       ;# override any default below
#   source .../i3c_constraints.tcl
#   i3c_pinmux_case_analysis $u_pinmux { {38 38 19} {39 39 18} ... }
#   i3c_constrain $inst IOB10 IOB9 I3C0 $clk_pin $clk_name $clk_period
#   i3c_summary
#
# All delay values are in nanoseconds.
#
# Note: Whenever a pattern in the commands below matches nothing, all tools
# (Vivado + ASIC) silently return an empty collection instead of throwing an
# error. This then leads to downstream errors when those empty collections are
# handed to commands such as create_clock.
# All of this makes sdc debugging notouriosly tedious and error-prone.
#
# This file therefore wraps the bare sdc commands into `i3c_get_pins`,
# `i3c_get_cells`, and similar. The calls to these carry a human-readable label
# which gets recorded if the requested pattern does not match. On a match, a
# counter is increased.
# i3c_summary then prints both the lables of all commands with no match as well
# as the number of successfully applied commands.

#############################
# Configuration             #
#############################

if {![info exists ::i3c_cfg]} {
  array set ::i3c_cfg {}
}

# Only set a default if the caller has not already chosen a value.
proc i3c_cfg_default {key value} {
  if {![info exists ::i3c_cfg($key)]} {
    set ::i3c_cfg($key) $value
  }
}

## Bus timing, from the I3C Basic v1.2 specification.
# Table 50: fSCL max 12.9 MHz. This bounds an externally driven SCL; our own
# Controller's SCL is derived from clk_i instead (see i3c_create_clocks).
i3c_cfg_default scl_ext_period 77.5
# Table 50: tSCO, SCL in to SDA out for a Target, max 20 ns. This is our own
# obligation when acting as a Target.
i3c_cfg_default tsco_max 20.0
# What a remote Target may take before it presents read data. Devices slower
# than 20 ns must advertise it in the BCR, so 20 ns is the compliant bound.
i3c_cfg_default tsco_ext_max 20.0
# Table 50: tSU_PP / Table 49: tSU_OD, SDA setup, min 3 ns.
i3c_cfg_default tsu_pp 3.0
# Table 50: tHD_PP, min 0 for a Target, tCR/tCF + 3 ns for a Controller.
i3c_cfg_default thd_pp_tgt 0.0
# Table 50 note 5 caps tCR/tCF at 60 ns; integration_notes.md requires <= 8 ns
# to reach the full 12.5 MHz signalling rate.
i3c_cfg_default tcr 8.0
i3c_cfg_default tcf 8.0

## Whether to model the I3C bus I/O timing at all. With this off, only the bus
## clocks, the pinmux case analysis and the internal budgets are applied: the
## logic is still timed, but the interface is not held to the specification.
## Turn it off for a target that physically cannot meet the specification and
## is only used for functional bring-up.
## TODO: This is currently true for CW340 due to SDA and SCL going through
## pinmux. Ensure bus delays work once the sparse pinmux lands.
i3c_cfg_default bus_io_delays 1

## Board and pad delays. Set these to the real numbers for the system.
# Pad-to-pad wiring (t3 and t7 of specification Figure 73).
i3c_cfg_default board_dly_max 2.0
i3c_cfg_default board_dly_min 0.1
# Extra budget for our own pad cells, for flows where the pad is a black box
# without timing. Leave at 0 when STA already models the pad, which is the
# normal case for both a foundry pad library and an FPGA IOBUF.
i3c_cfg_default pad_out_dly_max 0.0
i3c_cfg_default pad_out_dly_min 0.0
i3c_cfg_default pad_in_dly_max 0.0
i3c_cfg_default pad_in_dly_min 0.0

## Controller SCL waveform, in edges of the clk_i source clock.
# i3c_timing_pkg::tm_params() turns the target SCL period (TPERIOD_SDR0 = 80 ns)
# and high interval (TDIGH = 36 ns) into clk_i cycle counts. At ClkFreq = 96 MHz
# this yields tchh=2, tchs=1, hcext=1, tclh=3, tcls=2 (the package stores them
# pre-decremented for down-counting). SCL is high for tchh+tchs = 3 cycles and
# the half-cycle extension holds it high half a cycle longer, so the period is
# 8 cycles with a 3.5 cycle high phase and a 4.5 cycle low phase.
# Counting source clock transitions, edge 1 is the first rising edge, edge 8 the
# falling edge 3.5 cycles later and edge 17 the rising edge 8 cycles later.
# Software can slow SCL down through the CTRL_TIME_* registers; this models the
# fastest case, which is the one that has to close.
i3c_cfg_default scl_edges {1 8 17}

## Where the Controller samples SDA, in clk_i cycles, for each of its capture
## points. The Controller samples with clk_i, so each capture point needs a
## multicycle that matches the state it is captured in
## (i3c_controller_trx.sv): Without one, STA pairs the SCL edge with the nearest
## clk_i edge and reports violations the design cannot meet.
# Read data, end of State_ClkLoAwaitD: the clk_i edge on which SCL rises again.
i3c_cfg_default ctrl_rx_cycles 5
# HDR-DDR even bits, end of State_ClkHiAwaitD, launched by the rising edge.
i3c_cfg_default ctrl_rx_ddr_cycles 3
# SDR read T-bit, end of State_ClkLoSampleD, earlier than the read data.
i3c_cfg_default ctrl_tbit_cycles 3
# Arbitration and IBI, end of State_ArbClkHiHoldD. Also launched by the rising
# edge, but captured a cycle before the HDR-DDR data, so it needs its own.
i3c_cfg_default ctrl_arb_cycles 2
# The Controller drives SDA tcls cycles ahead of the SCL edge that the far end
# samples on, so the launch edge is earlier than the one STA would pick.
i3c_cfg_default ctrl_tx_cycles 2

## Internal paths.
# Budget for clk_i <-> bus clock domain crossings, as a fraction of the clk_i
# period. Only applied by i3c_set_cdc_bounds, which belongs in the check-only
# flow: in the synthesis SDC the asynchronous clock groups would override it.
i3c_cfg_default cdc_fraction 0.9
# Allowed skew between the SCL clock tree and the buffered SDA data it samples
# (i3c_input_buffers.sv, TODO #31335), and between the two flops forming the
# Controller's SCL output (integration_notes.md:51).
i3c_cfg_default sda_skew_max 1.0
i3c_cfg_default scl_out_skew_max 1.0
# Window the START/STOP detectors have to resolve a bus condition in. SDA and
# SCL are asynchronous to each other, so these clock-as-data paths get an
# explicit bound rather than a clock relationship. Table 49: tCAS min 38.4 ns,
# tCBP min tCAS/2.
i3c_cfg_default start_stop_max 19.2

## Netlist naming. The tools disagree on all of this and a wrong spelling
## matches nothing silently, so it is configuration. The defaults are for the
## Cadence/Synopsys ASIC flows; the FPGA flow overrides them.
# Bit of a prim_subreg: the module output pin.
i3c_cfg_default reg_q_pin {q[%d]}
# Bit of the packed pad attribute register, by pad index and field name.
i3c_cfg_default pad_attr_pin {mio_pad_attr_q_reg[%d][%s]/q}
# Buffer pins. A clock has to be created on a pin, stopping a clock takes pins,
# and a buffer is not a sequential cell so it is not a valid path startpoint
# either, which is why its output is named here as well.
i3c_cfg_default buf_in_pin A
i3c_cfg_default buf_out_pin Y
# Path from a prim_flop_2sync instance down to its first-stage flop cells.
# These do not follow the `_reg` convention that inferred flops do.
i3c_cfg_default sync_flop {u_sync_1/*flop*}

# Timing exceptions accept sequential cells as well as pins, and a cell has the
# same name in every tool while its pins do not (d/D, q/Q, Y/O), so flops are
# selected as cells below. The patterns are qualified with `_reg` because an
# unqualified wildcard also picks up the tool-generated muxes that share the
# signal name, which are not valid path endpoints.
# Annoyingly, one invalid object often aborts the whole constraint call,
# and not as a catchable Tcl error.

#############################
# Helpers                   #
#############################

# Lookups that found nothing, reported by i3c_summary.
set ::i3c_misses {}
set ::i3c_applied 0

proc i3c_miss {desc pattern} {
  lappend ::i3c_misses "${desc}  (no match: ${pattern})"
}

# get_pins that accounts for a pattern matching nothing. Never filters on
# attributes: the attribute names and the case of their values differ between
# tools, and a bad filter does not return an empty collection but an error that
# some tools then feed into the constraint as a bogus object. Naming the pin
# explicitly through the cfg templates achieves the same selection portably.
proc i3c_get_pins {desc pattern} {
  set pins [get_pins -quiet $pattern]
  if {[llength $pins] == 0} {
    i3c_miss $desc $pattern
  }
  return $pins
}

proc i3c_get_cells {desc pattern} {
  set cells [get_cells -quiet $pattern]
  if {[llength $cells] == 0} {
    i3c_miss $desc $pattern
  }
  return $cells
}

# Apply set_case_analysis to a pin if it exists, reporting a miss otherwise.
# Returns 1 if applied. Some attribute bits are legitimately absent because the
# technology's WARL mask removes them, so callers that expect that pass
# `optional`.
proc i3c_case_if_present {value pattern {optional 0}} {
  set pins [get_pins -quiet $pattern]
  if {[llength $pins] == 0} {
    if {!$optional} {
      i3c_miss "set_case_analysis ${value}" $pattern
    }
    return 0
  }
  set_case_analysis $value $pins
  incr ::i3c_applied
  return 1
}

proc i3c_case_reg {base width value} {
  for {set bit 0} {$bit < $width} {incr bit} {
    i3c_case_if_present [expr {($value >> $bit) & 1}] \
        "${base}/[format $::i3c_cfg(reg_q_pin) $bit]"
  }
}

# True if the running tool provides `cmd`, used to keep this file portable
# between Vivado and the ASIC tools.
proc i3c_has_command {cmd} {
  return [expr {[llength [info commands $cmd]] > 0}]
}

# Apply a constraint, reporting rather than aborting when the netlist does not
# have the expected structure.
proc i3c_try {desc script} {
  if {[catch {uplevel 1 $script} err]} {
    lappend ::i3c_misses "${desc}  (error: ${err})"
  }
}

# Report what was applied and what was not. Call once after the i3c_constrain
# calls. A miss is not fatal on its own - some are expected - but it is never
# silent, which can make sdc debugging very hard.
proc i3c_summary {} {
  puts "i3c_constraints: applied ${::i3c_applied} case-analysis constraints"
  if {[llength $::i3c_misses] == 0} {
    puts "i3c_constraints: all lookups matched"
    return
  }
  puts "i3c_constraints: WARNING: [llength $::i3c_misses] lookup(s) matched nothing:"
  foreach m $::i3c_misses {
    puts "i3c_constraints:   ${m}"
  }
}

#############################
# Pinmux case analysis      #
#############################

# Pin the pinmux selects so that each I3C signal has exactly one pad, in both
# directions, and so no other muxed pad's clock reaches the I3C clock trees.
# This is independent of where the I3C instances sit in the hierarchy.
#
#   pinmux       path to the pinmux instance
#   assignments  list of {periph_in_idx periph_out_idx pad_idx}, where
#                periph_out_idx may be `-` for an input-only peripheral such as
#                the reset detector's SCL/SDA observation inputs.
#
# Mux encodings (pinmux.sv):
#   mio_mux         = {mio_in, 1'b1, 1'b0}        -> insel  = pad_idx + 2
#   periph_data_mux = {periph_to_mio_i, 0, 1, 0}  -> outsel = periph_out + 3
proc i3c_pinmux_case_analysis {pinmux assignments} {
  set pads {}
  foreach entry $assignments {
    lassign $entry periph_in periph_out pad
    lappend pads $pad

    # Input: the peripheral input reads this pad.
    i3c_case_reg "${pinmux}/u_reg/u_mio_periph_insel_${periph_in}" 6 [expr {$pad + 2}]
    # Output: this pad is driven by the peripheral output, where there is one.
    if {$periph_out ne "-"} {
      i3c_case_reg "${pinmux}/u_reg/u_mio_outsel_${pad}" 7 [expr {$periph_out + 3}]
    }
  }

  foreach pad [lsort -unique -integer $pads] {
    # Take the functional branch of the sleep retention mux in front of the
    # output select (pinmux.sv).
    set sleep_reg [expr {$pad < 32 ? "u_mio_pad_sleep_status_0_en_${pad}"
                                   : "u_mio_pad_sleep_status_1_en_${pad}"}]
    i3c_case_if_present 0 \
        "${pinmux}/u_reg/${sleep_reg}/[format $::i3c_cfg(reg_q_pin) 0]"

    # Pad attributes that would otherwise make the pad non-unate or cut the
    # signal (prim_pad_wrapper.sv):
    #   invert        XORs both the input and the output
    #   virt_od_en    makes the output enable depend on the output data
    #   input_disable turns the input buffer off
    # Which of these exist depends on the technology's WARL mask, so a missing
    # one is reported but not treated as an error.
    set applied {}
    foreach attr {invert virt_od_en input_disable} {
      if {[i3c_case_if_present 0 \
               "${pinmux}/[format $::i3c_cfg(pad_attr_pin) $pad $attr]" 1]} {
        lappend applied $attr
      }
    }
    if {[llength $applied] == 0} {
      i3c_miss "MIO pad ${pad} attributes" \
          "${pinmux}/[format $::i3c_cfg(pad_attr_pin) $pad invert]"
    }
    puts "i3c_constraints: MIO pad ${pad} attributes pinned: [join $applied { }]"
  }
}

#############################
# Clocks                    #
#############################

# Create the bus clocks for one I3C instance.
#
#   inst       path to the i3c primary partition instance
#   scl_port   chip port carrying SCL
#   sda_port   chip port carrying SDA
#   prefix     clock name prefix, e.g. I3C0
#   clk_pin    pin carrying the IP's clk_i, used as the generated clock source
#   clk_name   name of the clock on clk_pin, used as the master clock
proc i3c_create_clocks {inst scl_port sda_port prefix clk_pin clk_name} {
  set inbufs ${inst}/u_core/u_targ_inbufs

  # An external Active Controller drives SCL; we are a Target. 12.9 MHz is the
  # Table 50 maximum, including the short bursts caused by jitter and skew.
  create_clock -name ${prefix}_SCL_EXT -period $::i3c_cfg(scl_ext_period) \
      [get_ports $scl_port] -add

  # SDA clocks the Target's START/STOP detectors (i3c_target_trx.sv). It is
  # declared on the input of its clock buffer rather than on the pad, because
  # SDA is only a clock inside the Target, and because a port that carries a
  # clock cannot also take the input delays that SDA needs as data.
  set sda_clk_pin [i3c_get_pins "${prefix} SDA clock buffer input" \
      ${inbufs}/u_sda0_clk/u_buf/*/$::i3c_cfg(buf_in_pin)]
  if {[llength $sda_clk_pin]} {
    create_clock -name ${prefix}_SDA -period $::i3c_cfg(scl_ext_period) \
        $sda_clk_pin -add
    set_clock_groups -name ${prefix}_SDA_ASYNC -asynchronous \
        -group [get_clocks ${prefix}_SDA]
  }

  # Our own Controller drives SCL, derived from clk_i. Only one of the two can
  # be driving the pad, so they are physically exclusive. This clock exists to
  # give the Controller's own SDA timing a reference, so it is only needed when
  # the bus I/O timing is modelled.
  if {$::i3c_cfg(bus_io_delays)} {
    create_generated_clock -name ${prefix}_SCL_INT -source [get_pins $clk_pin] \
        -edges $::i3c_cfg(scl_edges) -master_clock [get_clocks $clk_name] \
        [get_ports $scl_port] -add

    set_clock_groups -name ${prefix}_SCL_SRC -physically_exclusive \
        -group [get_clocks ${prefix}_SCL_EXT] \
        -group [get_clocks ${prefix}_SCL_INT]

    # Our own SCL leaves and re-enters the chip through the pad, so whenever
    # the Controller drives the bus, the Target is clocked by a copy of clk_i
    # that has made a full pad-board-pad round trip. STA relates the two and
    # charges the round trip as skew, which breaks setup and hold at the same
    # time. Stopping the clock at the Target buffer inputs does not prevent
    # this: `set_sense -stop_propagation` is accepted but the paths remain.
    # Instead, cut these paths here by setting false paths between all bus
    # clocked flops and clk_i of the Controller.
    #
    # Only the bus-clocked logic is cut. The Controller's own paths to and from
    # the pads end there rather than at these flops, so they stay timed.
    i3c_try "cut the ${prefix} SCL loopback" {
      set bus_flops {}
      foreach blk {u_targ_trx u_patt_det} {
        set cells [get_cells -quiet ${inst}/u_core/${blk}/*_reg*]
        if {[llength $cells]} {
          lappend bus_flops $cells
        }
      }
      foreach cells $bus_flops {
        set_false_path -from [get_clocks $clk_name] -to $cells
        set_false_path -from $cells -to [get_clocks $clk_name]
      }
    }
  }

  # A bus driven from outside has no relationship to anything else in the
  # design. A single-clock group is asynchronous to every other clock.
  #
  # SCL_INT is deliberately NOT grouped here: it is generated from clk_i and
  # must stay related to it, otherwise the Controller's own output and input
  # paths would be cut. The caller has to add it to the group that holds clk_i
  # (see i3c_scl_int_clock).
  set_clock_groups -name ${prefix}_SCL_EXT_ASYNC -asynchronous \
      -group [get_clocks ${prefix}_SCL_EXT]
}

# Name of the generated clock that has to join the clk_i clock group at top
# level, or an empty string when the bus I/O timing is not modelled and the
# clock was therefore never created.
proc i3c_scl_int_clock {prefix} {
  if {!$::i3c_cfg(bus_io_delays)} {
    return ""
  }
  return ${prefix}_SCL_INT
}

#############################
# I/O delays                #
#############################

# Constrain SDA against SCL for one I3C instance, in both roles and on both
# clock edges. The reference point is the chip port, which is where the
# specification defines its timing.
proc i3c_set_io_delays {inst scl_port sda_port prefix clk_name} {
  if {!$::i3c_cfg(bus_io_delays)} {
    puts "i3c_constraints: ${prefix}: bus I/O timing not modelled"
    return
  }
  set sda [get_ports $sda_port]

  # External budget seen from our port, in each direction.
  set out_max [expr {$::i3c_cfg(board_dly_max) + $::i3c_cfg(pad_out_dly_max)}]
  set out_min [expr {$::i3c_cfg(board_dly_min) + $::i3c_cfg(pad_out_dly_min)}]
  set in_max  [expr {$::i3c_cfg(board_dly_max) + $::i3c_cfg(pad_in_dly_max)}]
  set in_min  [expr {$::i3c_cfg(board_dly_min) + $::i3c_cfg(pad_in_dly_min)}]

  ## Target role: the bus is driven by an external Active Controller, so the
  ## timing is relative to SCL_EXT.
  set scl_clk ${prefix}_SCL_EXT
  set half [expr {$::i3c_cfg(scl_ext_period) / 2.0}]

  # Output. Our tSCO obligation is measured from the SCL edge at the pad, so
  # the required time has to land tSCO after that edge. With the capture edge
  # half a period away, that is an output delay of (half period - tSCO).
  # The board delay is added on top, which tightens our own budget by that
  # amount rather than leaving it to the far end: deliberately conservative,
  # and it costs nothing when board_dly_max is set to the real number.
  set tgt_out_max [expr {$half - $::i3c_cfg(tsco_max) + $out_max}]
  # Hold. The far end must still see SDA tHD_PP after its capture edge, so the
  # earliest our output may change is tHD_PP after that edge, less whatever the
  # board already delays it by. tHD_PP is 0 for a Target, so this is normally
  # just the (negative) board minimum.
  set tgt_out_min [expr {$::i3c_cfg(thd_pp_tgt) - $out_min}]
  # Input. A remote Controller presents SDA tSU_PP before the edge that
  # samples it and holds it tHD_PP = tCF/tCR + 3 ns afterwards.
  set tgt_in_max [expr {$half - $::i3c_cfg(tsu_pp) + $in_max}]
  set tgt_in_min_f [expr {$::i3c_cfg(tcf) + 3.0 + $in_min}]
  set tgt_in_min_r [expr {$::i3c_cfg(tcr) + 3.0 + $in_min}]

  # Both Target shift registers sample SDA on every edge and the output enable
  # select toggles on both edges, so both references are needed even in SDR.
  set_output_delay -max $tgt_out_max -clock $scl_clk $sda -add_delay
  set_output_delay -min $tgt_out_min -clock $scl_clk $sda -add_delay
  set_output_delay -max $tgt_out_max -clock $scl_clk -clock_fall $sda -add_delay
  set_output_delay -min $tgt_out_min -clock $scl_clk -clock_fall $sda -add_delay

  set_input_delay -max $tgt_in_max -clock $scl_clk -clock_fall $sda -add_delay
  set_input_delay -min $tgt_in_min_f -clock $scl_clk -clock_fall $sda -add_delay
  set_input_delay -max $tgt_in_max -clock $scl_clk $sda -add_delay
  set_input_delay -min $tgt_in_min_r -clock $scl_clk $sda -add_delay

  ## Controller role. SDA is launched and captured by clk_i, but the bus timing
  ## is relative to the SCL we generate, so SCL_INT is the reference.
  set scl_clk ${prefix}_SCL_INT

  # Output: the remote Target needs tSU_PP of setup before the capturing edge
  # and tHD_PP of hold after it, so the hold number is positive for the same
  # reason as on the Target side above.
  set ctrl_out_max [expr {$::i3c_cfg(tsu_pp) + $out_max}]
  set ctrl_out_min_f [expr {$::i3c_cfg(tcf) + 3.0 - $out_min}]
  set ctrl_out_min_r [expr {$::i3c_cfg(tcr) + 3.0 - $out_min}]
  set_output_delay -max $ctrl_out_max -clock $scl_clk $sda -add_delay
  set_output_delay -min $ctrl_out_min_r -clock $scl_clk $sda -add_delay
  set_output_delay -max $ctrl_out_max -clock $scl_clk -clock_fall $sda -add_delay
  set_output_delay -min $ctrl_out_min_f -clock $scl_clk -clock_fall $sda -add_delay

  # The RTL moves SDA a whole tcls ahead of the edge the far end samples on,
  # whereas STA would launch from the last clk_i edge before that edge.
  set tx $::i3c_cfg(ctrl_tx_cycles)
  set_multicycle_path -setup $tx -start -from [get_clocks $clk_name] \
      -to [get_clocks $scl_clk] -through $sda
  set_multicycle_path -hold [expr {$tx - 1}] -start -from [get_clocks $clk_name] \
      -to [get_clocks $scl_clk] -through $sda

  # Input: a remote Target answers at most tSCO after the SCL edge. Both edges
  # launch data: the falling edge for SDR and the odd HDR-DDR bits, the rising
  # edge for the even HDR-DDR bits.
  set ctrl_in_max [expr {$::i3c_cfg(tsco_ext_max) + $in_max}]
  set ctrl_in_min [expr {$::i3c_cfg(thd_pp_tgt) + $in_min}]
  set_input_delay -max $ctrl_in_max -clock $scl_clk -clock_fall $sda -add_delay
  set_input_delay -min $ctrl_in_min -clock $scl_clk -clock_fall $sda -add_delay
  set_input_delay -max $ctrl_in_max -clock $scl_clk $sda -add_delay
  set_input_delay -min $ctrl_in_min -clock $scl_clk $sda -add_delay

  # The Controller samples with clk_i, not with SCL, and `rx_advance`
  # (i3c_controller_trx.sv) captures SDA in four different states. Each sits a
  # different number of clk_i cycles after the SCL edge that launched the data,
  # so one blanket multicycle would only be correct for the read data and too
  # loose for the rest.
  #
  # Two of the four are covered by edge: everything launched by the falling
  # edge, and everything launched by the rising edge. The remaining two are
  # captured earlier than their edge-mate, so they get an exception of their
  # own, aimed at the endpoint; a `-to <cell>` exception is more specific than
  # a `-to <clock>` one and takes precedence.
  #
  #   state                launch       capture   cycles
  #   State_ClkLoAwaitD    fall 3.5T    8T        ctrl_rx_cycles
  #   State_ClkHiAwaitD    rise 0       3T        ctrl_rx_ddr_cycles
  #   State_ClkLoSampleD   fall 3.5T    6T        ctrl_tbit_cycles
  #   State_ArbClkHiHoldD  rise 0       2T        ctrl_arb_cycles
  #
  # The capture instants come from the state durations: `cnt` is loaded from
  # phase_cycles(state_q) on leaving a state, so each state lasts the *previous*
  # state's parameter.
  set rx $::i3c_cfg(ctrl_rx_cycles)
  set_multicycle_path -setup $rx -end -fall_from [get_clocks $scl_clk] \
      -to [get_clocks $clk_name] -through $sda
  set_multicycle_path -hold [expr {$rx - 1}] -end -fall_from [get_clocks $scl_clk] \
      -to [get_clocks $clk_name] -through $sda

  # HDR-DDR even bits, captured at the end of State_ClkHiAwaitD, i.e. while SCL
  # is still high, which is only 3.5 cycles long.
  set ddr $::i3c_cfg(ctrl_rx_ddr_cycles)
  set_multicycle_path -setup $ddr -end -rise_from [get_clocks $scl_clk] \
      -to [get_clocks $clk_name] -through $sda
  set_multicycle_path -hold [expr {$ddr - 1}] -end -rise_from [get_clocks $scl_clk] \
      -to [get_clocks $clk_name] -through $sda

  # The SDR read T-bit is captured earlier than the read data, at the end of
  # State_ClkLoSampleD, so the blanket read-data multicycle would let it arrive
  # two cycles late.
  set tbit [i3c_get_cells "${prefix} SDR T-bit sample" \
      ${inst}/u_core/u_ctrl_trx/sdr_tbit_targ_q_reg*]
  if {[llength $tbit]} {
    set tb $::i3c_cfg(ctrl_tbit_cycles)
    set_multicycle_path -setup $tb -end -fall_from [get_clocks $scl_clk] \
        -to $tbit
    set_multicycle_path -hold [expr {$tb - 1}] -end -fall_from [get_clocks $scl_clk] \
        -to $tbit
  }

  # Arbitration and IBI are captured at the end of State_ArbClkHiHoldD, a cycle
  # before the HDR-DDR data, so the rising-edge multicycle above would let them
  # arrive a cycle late.
  set arb [i3c_get_cells "${prefix} arbitration sample" \
      ${inst}/u_core/u_ctrl_trx/arb_q_reg*]
  if {[llength $arb]} {
    set ab $::i3c_cfg(ctrl_arb_cycles)
    set_multicycle_path -setup $ab -end -rise_from [get_clocks $scl_clk] \
        -to $arb
    set_multicycle_path -hold [expr {$ab - 1}] -end -rise_from [get_clocks $scl_clk] \
        -to $arb
  }
}

#############################
# Internal paths            #
#############################

# Structural constraints inside one I3C instance. These belong in the synthesis
# SDC; the domain-crossing bounds do not, see i3c_set_cdc_bounds.
proc i3c_set_internal_paths {inst clk_name clk_period} {
  set inbufs ${inst}/u_core/u_targ_inbufs

  foreach buf {u_scl_buf u_scl_inv u_sda0_clk u_sda0_clk_n} {
    # The Target input buffers gate the bus clocks with a plain AND/OR
    # (i3c_clock_buf_en.sv) rather than an integrated clock gate. The enable
    # only changes while the bus is idle (i3c_target_rst.sv), so the gating
    # check is not meaningful.
    if {[i3c_has_command set_disable_clock_gating_check]} {
      i3c_try "clock gating check on ${buf}" {
        set cells [get_cells -quiet ${inbufs}/${buf}/u_mux/*]
        if {[llength $cells]} {
          set_disable_clock_gating_check $cells
        }
      }
    }
    # Never take the scan branch of the clock mux in functional analysis, so
    # the scan clock does not appear on the bus clock trees.
    i3c_case_if_present 0 ${inbufs}/${buf}/u_mux/sel_i 1
  }

  # Keep the quasi-static buffer enable out of timing.
  i3c_try "target buffer enable" {
    set en_q [i3c_get_cells "${inst} buffer enable" \
        ${inst}/u_core/u_targ_rst/buf_en_q_reg*]
    if {[llength $en_q]} {
      set_false_path -from $en_q
    }
  }

#############################
# Domain crossings          #
#############################

# Bounds for the crossings between the bus clocks and clk_i. Call this from the
# check-only flow, which times the routed design with the groups removed. The
# set_clock_groups -async on SCL_EXT and SDA would otherwise take precedence and
# make the set_max_delay below useless.
proc i3c_set_cdc_bounds {inst clk_period} {
  set cdc_max [expr {$clk_period * $::i3c_cfg(cdc_fraction)}]

  # Bus clocks to and from clk_i. Every crossing uses either prim_flop_2sync or
  # the toggle handshake in i3c_sync_data, so bounding the data path is enough.
  foreach sync {
    u_core/u_sync_ctrl
    u_core/u_sync_targ
    u_core/u_reg_sync
    u_core/u_target/u_in_sync
    u_core/u_target/u_edge_det
    u_core/u_target/u_trx_rxd_sync
    u_core/u_target/u_targ_txc_sync
    u_core/u_target/u_arb_sync
    u_core/u_target/gen_targ_txd_sync[*].u_targ_txd_sync
  } {
    i3c_try "CDC bound on ${sync}" {
      set endpoints [i3c_get_cells "${inst}/${sync} synchronizer" \
          ${inst}/${sync}/$::i3c_cfg(sync_flop)]
      if {[llength $endpoints]} {
        set_max_delay $cdc_max -to $endpoints
      }
    }
  }

  # i3c_sync_data carries its payload combinationally alongside the toggle, so
  # the data has to be bounded too (i3c_sync_data.sv).
  i3c_try "CDC bound on i3c_sync_data payloads" {
    set sync_data [get_cells -quiet \
        ${inst}/u_core/u_target/*sync*/dst_data_q_reg*]
    if {[llength $sync_data]} {
      set_max_delay $cdc_max -to $sync_data
    }
  }

  # The Target transceiver's reset is released by a clk_i flop into the
  # SCL/SDA domains (i3c_core.sv).
  i3c_try "transceiver reset bound" {
    set rst_src [i3c_get_cells "${inst} transceiver reset source" \
        ${inst}/u_core/u_targ_rst_src/*reg*]
    if {[llength $rst_src]} {
      set_max_delay $cdc_max -from $rst_src
    }
  }

  # Quasi-static device address and group address configuration, written while
  # the Target is disabled (i3c_target_trx.sv, TODO #31065). These are
  # hierarchical pins on the transceiver boundary, which are not valid
  # endpoints, so bound whatever passes through them instead.
  foreach cfg_pin {targ_dev_i grp_addr_i addr_blocked_i mask_blocked_i} {
    i3c_try "quasi-static ${cfg_pin}" {
      set pins [get_pins -quiet ${inst}/u_core/u_targ_trx/${cfg_pin}*]
      if {[llength $pins]} {
        set_max_delay $cdc_max -through $pins
      }
    }
  }

  # The START/STOP detectors are clocked by SDA and take SCL as their data
  # (i3c_target_trx.sv). SDA and SCL are separate asynchronous clocks, so this
  # clock-as-data path has to be bounded explicitly. The specification allows
  # tCAS after a START before the first SCL edge, and tCBP before a STOP, which
  # is the window the detectors have to resolve in.
  foreach det {stop_det start_det rep_start_det rep_start_pre} {
    i3c_try "START/STOP detector ${det}" {
      set det_d [i3c_get_cells "${inst} ${det}" \
          ${inst}/u_core/u_targ_trx/${det}_reg*]
      if {[llength $det_d]} {
        set_max_delay $::i3c_cfg(start_stop_max) -to $det_d
      }
    }
  }
}

#############################
# Reset detector            #
#############################

# Constrain the secondary partition, which holds the Target Reset Detector.
# It observes the same pads as the primary partition through its own pinmux
# inputs, has its own SCL/SDA clock trees, and crosses into the AON clock
# rather than clk_i.
#
#   inst       path to the i3c_part_secondary instance
#   prefix     clock name prefix of the instance it belongs to, e.g. I3C0
#   clk_name   name of the main clock of the primary partition (`clk_i`)
#   aon_clk    name of the AON clock
#   aon_period period of the AON clock, for the crossing bounds
#
# Note that for i3c0 the two partitions sit in different power domains and use
# different AON resets, so the request and response between are across both a
# reset domain as well as a clock domain crossing.
proc i3c_constrain_rstdet {inst prefix clk_name aon_clk aon_period} {
  set det ${inst}/u_reset_detector
  set inbufs ${det}/u_targ_inbufs

  # The detector has its own SDA clock buffer, separate from the primary
  # partition's, so the clock declared there does not reach it. SCL needs no
  # equivalent because it is declared on the pad and so reaches both.
  set sda_clk_pin [i3c_get_pins "${prefix} rstdet SDA clock buffer input" \
      ${inbufs}/u_sda0_clk/u_buf/*/$::i3c_cfg(buf_in_pin)]
  if {[llength $sda_clk_pin]} {
    create_clock -name ${prefix}_RSTDET_SDA -period $::i3c_cfg(scl_ext_period) \
        $sda_clk_pin -add
    set_clock_groups -name ${prefix}_RSTDET_SDA_ASYNC -asynchronous \
        -group [get_clocks ${prefix}_RSTDET_SDA]
  }

  # The generated SCL reaches the detector through the pad as well, so it needs
  # the same loopback cut as the Target; see i3c_create_clocks.
  if {$::i3c_cfg(bus_io_delays)} {
    i3c_try "cut the ${prefix} rstdet SCL loopback" {
      set cells [get_cells -quiet ${det}/*_reg*]
      if {[llength $cells]} {
        set_false_path -from [get_clocks $clk_name] -to $cells
        set_false_path -from $cells -to [get_clocks $clk_name]
      }
    }
  }

  # Only three of the buffers are used: the detector leaves the inverted SCL
  # and the buffered SDA data outputs open, so those are trimmed.
  foreach buf {u_scl_buf u_sda0_clk u_sda0_clk_n} {
    if {[i3c_has_command set_disable_clock_gating_check]} {
      i3c_try "${prefix} rstdet gating check on ${buf}" {
        set cells [get_cells -quiet ${inbufs}/${buf}/u_mux/*]
        if {[llength $cells]} {
          set_disable_clock_gating_check $cells
        }
      }
    }
    # The secondary partition ties scanmode off, so the mux may already be
    # trimmed; pin it where it survives.
    i3c_case_if_present 0 ${inbufs}/${buf}/u_mux/sel_i 1
  }

  # The detector samples SCL with SDA-clocked flops and SDA with an SCL-clocked
  # flop, and derives its resets from both. Those are clock-as-data paths
  # between two asynchronous bus clocks, so they get the same explicit window as
  # the Target's START/STOP detectors.
  foreach node {rst_cnt cnt_met poss_reset_pend poss_reset_start reset_detected
                wake_up_q target_reset_q chip_reset_q} {
    i3c_try "${prefix} rstdet ${node}" {
      set cells [get_cells -quiet ${det}/${node}_reg*]
      if {[llength $cells]} {
        set_max_delay $::i3c_cfg(start_stop_max) -to $cells
      }
    }
  }

  # Crossings to and from the AON clock: the configuration in, the detection
  # result out. The reference is the AON period, not clk_i.
  set cdc_max [expr {$aon_period * $::i3c_cfg(cdc_fraction)}]
  foreach sync {u_cfg_sync u_out_sync} {
    i3c_try "${prefix} rstdet ${sync}" {
      set endpoints [i3c_get_cells "${prefix} rstdet ${sync}" \
          ${det}/${sync}/$::i3c_cfg(sync_flop)]
      if {[llength $endpoints]} {
        set_max_delay $cdc_max -to $endpoints
      }
    }
  }

  # The enable is quasi-static and comes from the primary partition, which for
  # i3c0 is in a different power domain.
  i3c_try "${prefix} rstdet enable" {
    set en [get_pins -quiet ${det}/enable_i]
    if {[llength $en]} {
      set_max_delay $cdc_max -through $en
    }
  }
}

#############################
# Entry point               #
#############################

# Remembers the SCL port per instance, so that the internal constraints can
# reference the chip port rather than a hierarchical pin, which is not a valid
# timing endpoint.
array set ::i3c_scl_port {}

# Constrain one I3C primary partition end to end.
proc i3c_constrain {inst scl_port sda_port prefix clk_pin clk_name clk_period} {
  set ::i3c_scl_port($inst) $scl_port
  i3c_create_clocks $inst $scl_port $sda_port $prefix $clk_pin $clk_name
  i3c_set_io_delays $inst $scl_port $sda_port $prefix $clk_name
  i3c_set_internal_paths $inst $clk_name $clk_period
}
