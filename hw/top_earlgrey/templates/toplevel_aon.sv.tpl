// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
${gencmd}
<%
from collections import defaultdict
import topgen.lib as lib

## TODO
max_sigwidth = 2

num_im = 0
if isinstance(top["inter_signal"]["external"], dict):
    for x in top["inter_signal"]["external"].get("aon"):
        width = 1
        if "width" in x:
            width = (x["width"].default
                    if isinstance(x["width"], Parameter) else x["width"])
            num_im += width
%>\

module top_${top["name"]}_pd_aon #(
  // Auto-inferred parameters
% for m in lib.get_all_modules(top, phys_pd="aon"):
  % if not lib.is_inst(m):
<% continue %>
  % endif
  // parameters for ${m['name']}
  % for p_exp in [p for p in m["param_list"] if p.get("local") == "false" and p.get("expose") == "true" ]:
<%
    p_type = p_exp.get('type')
    p_type_word = p_type + ' ' if p_type else ''

    p_lhs = f'{p_type_word}{p_exp["name_top"]}'

    if 'unpacked_dimensions' in p_exp:
      p_lhs += p_exp['unpacked_dimensions']

    p_rhs = p_exp['default']

    params_follow = not loop.last or loop.parent.index < last_modidx_with_params
    comma_char = ',' if params_follow else ''
%>\
    % if 12 + len(p_lhs) + 3 + len(str(p_rhs)) + 1 < 100:
  parameter ${p_lhs} = ${p_rhs}${comma_char}
    % else:
  parameter ${p_lhs} =
      ${p_rhs}${comma_char}
    % endif
  % endfor
% endfor
) (

% if num_im != 0:

  // Inter-module Signal External type
  % for sig in top["inter_signal"]["external"]:
    % if isinstance(sig["width"], Parameter):
  ${lib.get_direction(sig)} ${lib.im_defname(sig)} [${sig["width"].name_top}-1:0] ${sig["signame"]},
    % else:
  ${lib.get_direction(sig)} ${lib.im_defname(sig)} ${lib.bitarray(sig["width"],1)} ${sig["signame"]},
    % endif
  % endfor

% endif

  input                      scan_rst_ni, // reset used for test mode
  input                      scan_en_i,
  input prim_mubi_pkg::mubi4_t scanmode_i   // lc_ctrl_pkg::On for Scan
);

  import tlul_pkg::*;
  import top_pkg::*;
  import tl_main_pkg::*;
  import top_${top["name"]}_pkg::*;
  // Compile-time random constants
  import top_${top["name"]}_rnd_cnst_pkg::*;

  // Local Parameters
% for m in lib.get_all_modules(top, phys_pd="aon"):
  % if not lib.is_inst(m):
<% continue %>
  % endif
<%
    localparams = [p for p in m["param_list"] if p.get("local") == "true" and p.get("expose") == "true"]
    if not len(localparams):
        continue
%>\
  // local parameters for ${m['name']}
  % for p_exp in localparams:
<%
    p_type = p_exp.get('type')
    p_type_word = p_type + ' ' if p_type else ''

    p_lhs = f'{p_type_word}{p_exp["name_top"]}'
    p_rhs = p_exp['default']
%>\
    % if 13 + len(p_lhs) + 3 + len(str(p_rhs)) + 1 < 100:
  localparam ${p_lhs} = ${p_rhs};
    % else:
  localparam ${p_lhs} =
      ${p_rhs};
    % endif
  % endfor
% endfor

  // Signals
% for m in lib.get_all_modules(top, phys_pd="aon"):
  % if not lib.is_inst(m):
<% continue %>
  % endif
<%
  block = name_to_block[m['type']]
  inouts, inputs, outputs = block.xputs
%>\
  // ${m["name"]}
  % for p_in in inputs + inouts:
  logic ${lib.bitarray(p_in.bits.width(), max_sigwidth)} cio_${m["name"]}_${p_in.name}_p2d;
  % endfor
  % for p_out in outputs + inouts:
  logic ${lib.bitarray(p_out.bits.width(), max_sigwidth)} cio_${m["name"]}_${p_out.name}_d2p;
  logic ${lib.bitarray(p_out.bits.width(), max_sigwidth)} cio_${m["name"]}_${p_out.name}_en_d2p;
  % endfor
% endfor


endmodule

