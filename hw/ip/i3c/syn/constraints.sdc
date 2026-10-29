# Copyright lowRISC contributors (OpenTitan project).
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Generic constraints file for simple testsynthesis flow
#
# Unlike most IP blocks, I3C is not single-clock: the Target half has no
# free-running clock and is driven by the bus, so SCL and SDA have to be
# declared as clocks on the module boundary. The bus timing itself is applied
# by the shared procedures, the same ones the toplevel uses.

# note that we do not fix hold timing in this flow
set SETUP_CLOCK_UNCERTAINTY 0.5

#####################
# main clock        #
#####################
set MAIN_CLK_PIN clk_i
set MAIN_RST_PIN rst_ni
# set main clock to 125 MHz
set MAIN_TCK  8.0
set_ideal_network ${MAIN_CLK_PIN}
set_ideal_network ${MAIN_RST_PIN}
set_clock_uncertainty ${SETUP_CLOCK_UNCERTAINTY} ${MAIN_CLK_PIN}

# other timing constraint in ns
set IN_DEL    1.0
set OUT_DEL   1.0
set DELAY     ${MAIN_TCK}

create_clock ${MAIN_CLK_PIN} -period ${MAIN_TCK}

#####################
# AON clock         #
#####################
# Only the register interface's reset-detector shadow registers use this.
set AON_CLK_PIN clk_aon_i
set AON_TCK 5000.0
set_ideal_network ${AON_CLK_PIN}
create_clock ${AON_CLK_PIN} -period ${AON_TCK}
set_clock_uncertainty ${SETUP_CLOCK_UNCERTAINTY} ${AON_CLK_PIN}

#####################
# I3C bus clocks    #
#####################
# The Target transceiver and the START/STOP detectors are clocked directly by
# the bus (i3c_input_buffers.sv). At block level the pads are outside the DUT,
# so the module's own cio_* ports stand in for them.
set I3C_CONSTRAINTS [file join [file dirname [info script]] i3c_constraints.tcl]
source ${I3C_CONSTRAINTS}

create_clock -name I3C_SCL_EXT -period $::i3c_cfg(scl_ext_period) [get_ports cio_scl_i]
create_clock -name I3C_SDA     -period $::i3c_cfg(scl_ext_period) [get_ports cio_sda_i]
set_clock_uncertainty ${SETUP_CLOCK_UNCERTAINTY} [get_clocks I3C_SCL_EXT]
set_clock_uncertainty ${SETUP_CLOCK_UNCERTAINTY} [get_clocks I3C_SDA]

# The bus is unrelated to clk_i and to itself; a single-clock group is
# asynchronous to every other clock.
set_clock_groups -name I3C_SCL_EXT_ASYNC -asynchronous -group [get_clocks I3C_SCL_EXT]
set_clock_groups -name I3C_SDA_ASYNC     -asynchronous -group [get_clocks I3C_SDA]

# Bus-relative I/O timing, from the I3C v1.2 push-pull parameters. The DUT is
# the whole device here, so tSCO is measured straight at the module boundary.
set I3C_HALF [expr $::i3c_cfg(scl_ext_period) / 2.0]
set_output_delay -max [expr ${I3C_HALF} - $::i3c_cfg(tsco_max)] \
    -clock I3C_SCL_EXT [get_ports {cio_sda_o cio_sda_en_o}] -add_delay
set_output_delay -min [expr -1.0 * $::i3c_cfg(thd_pp_tgt)] \
    -clock I3C_SCL_EXT [get_ports {cio_sda_o cio_sda_en_o}] -add_delay
set_input_delay -max [expr ${I3C_HALF} - $::i3c_cfg(tsu_pp)] \
    -clock I3C_SCL_EXT -clock_fall [get_ports cio_sda_i] -add_delay
set_input_delay -min [expr $::i3c_cfg(tcf) + 3.0] \
    -clock I3C_SCL_EXT -clock_fall [get_ports cio_sda_i] -add_delay

# Everything internal to the IP: the bus-to-core crossings, the clock-gating
# checks on the input buffers and the two skew budgets.
i3c_set_internal_paths [current_design] ${MAIN_CLK_PIN} ${MAIN_TCK}

#####################
# other I/O         #
#####################
set I3C_PORTS [remove_from_collection [all_inputs] \
    [get_ports [list ${MAIN_CLK_PIN} ${AON_CLK_PIN} cio_scl_i cio_sda_i]]]

# in to out
set_max_delay ${DELAY} -from [all_inputs] -to [all_outputs]
# in to reg / reg to out
set_input_delay ${IN_DEL} ${I3C_PORTS} -clock ${MAIN_CLK_PIN}
set_output_delay ${OUT_DEL} [all_outputs] -clock ${MAIN_CLK_PIN} -add_delay

#####################
# I/O drive/load    #
#####################

# attach load and drivers to IOs to get a more realistic estimate
set_driving_cell  -no_design_rule -lib_cell ${DRIVING_CELL} -pin ${DRIVING_CELL_PIN} [all_inputs]
set_load [load_of ${LOAD_CELL_LIB}/${LOAD_CELL}/${LOAD_CELL_PIN}] [all_outputs]

# set a nonzero critical range to be able to spot the violating paths better
# in the report
set_critical_range 0.5 ${DUT}

#####################
# Size Only Cells   #
#####################

set_size_only -all_instances [get_cells -h *u_size_only*] true
