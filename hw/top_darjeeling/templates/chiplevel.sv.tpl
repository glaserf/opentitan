// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
${gencmd}
<%
import re
import topgen.lib as lib
from reggen.params import Parameter

from copy import deepcopy

# Provide shortcuts for some commonly used variables
pinmux = top['pinmux']
pinout = top['pinout']

feature_info = {}
cio_info = {}

def get_dio_sig(pinmux: {}, pad: {}):
  '''Get DIO signal associated with this pad or return None'''
  for sig in pinmux["ios"]:
    if sig["connection"] == "direct" and pad["name"] == sig["pad"]:
      return sig
  else:
    return None

# Modify the pad lists on the fly, based on target config
maxwidth = 0
muxed_pads = []
dedicated_pads = []
k = 0
for pad in pinout["pads"]:
  if pad["connection"] == "muxed":
    if pad["name"] not in target["pinout"]["remove_pads"]:
      maxwidth = max(maxwidth, len(pad["name"]))
      muxed_pads.append(pad)
  else:
    k = pad["idx"]
    if pad["name"] not in target["pinout"]["remove_pads"]:
      maxwidth = max(maxwidth, len(pad["name"]))
      dedicated_pads.append(pad)

for pad in target["pinout"]["add_pads"]:
  # Since these additional pads have not been elaborated in the merge phase,
  # we need to add their global index here.
  amended_pad = deepcopy(pad)
  amended_pad.update({"idx" : k})
  dedicated_pads.append(pad)
  k += 1
%>\
<%include file="/toplevel_snippets/info_dicts.tpl" args="top=top, feature_info=feature_info, cio_info=cio_info" />\

module chip_${top["name"]}_${target["name"]} #(
  parameter bit SecRomCtrl0DisableScrambling = 1'b0,
  parameter bit SecRomCtrl1DisableScrambling = 1'b0
) (
% if target["name"] == "verilator":
  // Clock and Reset
  input clk_i,
  input rst_ni
);
<%
  removed_port_names = []
%>\
% else:
<%
  removed_port_names = []
%>\
  // Dedicated Pads
% for pad in dedicated_pads:
<%
  sig = get_dio_sig(pinmux, pad)
  if pad["name"] in target["pinout"]["remove_ports"]:
    port_comment = "// Removed port: "
    removed_port_names.append(pad["name"])
  else:
    port_comment = ""
  if sig is not None:
    comment = "// Dedicated Pad for {}".format(sig["name"])
  else:
    comment = "// Manual Pad"
%>\
  ${port_comment}${pad["port_type"]} ${pad["name"]}, ${comment}
% endfor

  // Muxed Pads
% for pad in muxed_pads:
<%
  if pad["name"] in target["pinout"]["remove_ports"]:
    port_comment = "// Removed port: "
    removed_port_names.append(pad["name"])
  else:
    port_comment = ""
%>\
  ${port_comment}${pad["port_type"]} ${pad["name"]}${" " if loop.last else ","} // MIO Pad ${pad["idx"]}
% endfor
);
% endif

  import top_${top["name"]}_pkg::*;
  import prim_pad_wrapper_pkg::*;

% if target["pinmux"]["special_signals"]:
  ////////////////////////////
  // Special Signal Indices //
  ////////////////////////////

  % for entry in target["pinmux"]["special_signals"]:
<% param_name = (lib.Name.from_snake_case(entry["name"]) +
                 lib.Name(["pad", "idx"])).as_camel_case()
%>\
  localparam int ${param_name} = ${entry["idx"]};
  % endfor
% endif

  // DFT and Debug signal positions in the pinout.
  localparam pinmux_pkg::target_cfg_t PinmuxTargetCfg = '{
    // Pad types for attribute WARL behavior
    dio_pad_type: {
<%
  pad_attr = []
  for sig in list(reversed(top["pinmux"]["ios"])):
    if sig["connection"] != "muxed":
      pad_attr.append((sig['name'], sig["attr"]))
%>\
% for name, attr in pad_attr:
      ${attr}${" " if loop.last else ","} // DIO ${name}
% endfor
    },
    mio_pad_type: {
<%
  pad_attr = []
  for pad in list(reversed(pinout["pads"])):
    if pad["connection"] == "muxed":
      pad_attr.append(pad["type"])
%>\
% for attr in pad_attr:
      ${attr}${" " if loop.last else ","} // MIO Pad ${len(pad_attr) - loop.index - 1}
% endfor
    },
    // Pad scan roles
    dio_scan_role: {
<%
  scan_roles = []
  for sig in list(reversed(top["pinmux"]["ios"])):
    if sig["connection"] != "muxed":
      if len(sig['pad']) > 0:
        scan_string = lib.Name.from_snake_case('dio_pad_' + sig['pad'] + '_scan_role')
        scan_roles.append((f'scan_role_pkg::{scan_string.as_camel_case()}', sig['name']))
      else:
        scan_roles.append(('NoScan', sig['name']))
%>\
% for scan_role, name in list(scan_roles):
      ${scan_role}${"" if loop.last else ","} // DIO ${name}
% endfor
    },
    mio_scan_role: {
<%
  scan_roles = []
  for pad in list(reversed(pinout["pads"])):
    if pad["connection"] == "muxed":
      scan_string = lib.Name.from_snake_case('mio_pad_' + pad['name'] + '_scan_role')
      scan_roles.append(f'scan_role_pkg::{scan_string.as_camel_case()}')
%>\
% for scan_role in list(scan_roles):
      ${scan_role}${"" if loop.last else ","}
% endfor
    }
  };

  ////////////////////////
  // Signal definitions //
  ////////////////////////

  % if removed_port_names:
  // Net definitions for removed ports
  % endif
  % for port in removed_port_names:
  wire ${port};
  % endfor

  pad_attr_t [pinmux_reg_pkg::NMioPads-1:0] mio_attr;
  pad_attr_t [pinmux_reg_pkg::NDioPads-1:0] dio_attr;
  logic [pinmux_reg_pkg::NMioPads-1:0] mio_out;
  logic [pinmux_reg_pkg::NMioPads-1:0] mio_oe;
  logic [pinmux_reg_pkg::NMioPads-1:0] mio_in;
  logic [pinmux_reg_pkg::NMioPads-1:0] mio_in_raw;
  logic [${len(dedicated_pads)}-1:0] dio_in_raw;
  logic [pinmux_reg_pkg::NDioPads-1:0] dio_out;
  logic [pinmux_reg_pkg::NDioPads-1:0] dio_oe;
  logic [pinmux_reg_pkg::NDioPads-1:0] dio_in;

  logic unused_mio_in_raw;
  logic unused_dio_in_raw;
  assign unused_mio_in_raw = ^mio_in_raw;
  assign unused_dio_in_raw = ^dio_in_raw;

  // Manual pads
% for pad in dedicated_pads:
<%
  pad_prefix = pad["name"].lower()
%>\
% if not get_dio_sig(pinmux, pad):
  logic manual_in_${pad_prefix}, manual_out_${pad_prefix}, manual_oe_${pad_prefix};
% endif
% endfor

% for pad in dedicated_pads:
<%
  pad_prefix = pad["name"].lower()
%>\
% if not get_dio_sig(pinmux, pad):
  pad_attr_t manual_attr_${pad_prefix};
% endif
% endfor

% if target["pinout"]["remove_pads"]:
  /////////////////////////
  // Stubbed pad tie-off //
  /////////////////////////

  // Only signals going to non-custom pads need to be tied off.
  logic [${len(pinout["pads"])-1}:0] unused_sig;
% for pad in pinout["pads"]:
  % if pad["connection"] == 'muxed':
    % if pad["name"] in target["pinout"]["remove_pads"]:
  assign mio_in[${pad["idx"]}] = 1'b0;
  assign mio_in_raw[${pad["idx"]}] = 1'b0;
  assign unused_sig[${loop.index}] = mio_out[${pad["idx"]}] ^ mio_oe[${pad["idx"]}];
    % endif
  % else:
    % if pad["name"] in target["pinout"]["remove_pads"]:
<%
    ## Only need to tie off if this is not a custom pad.
    sig = get_dio_sig(pinmux, pad)
    if sig is not None:
      sig_index = lib.get_io_enum_literal(sig, 'dio')
%>\
      % if sig is not None:
  assign dio_in[${lib.get_io_enum_literal(sig, 'dio')}] = 1'b0;
  assign unused_sig[${loop.index}] = dio_out[${sig_index}] ^ dio_oe[${sig_index}];
      % endif
    % endif
  % endif
% endfor
%endif

  //////////////////////
  // Padring Instance //
  //////////////////////

% if target["name"] == "verilator":
  // Padring substitute for the Verilator simulation top. The flat
  // per-peripheral `cio_*` pad signals live inside `u_padring` (see
  // padring_verilator.sv) and are driven and observed by the testbench DPI
  // models through hierarchical references.
  padring_verilator u_padring (
    .mio_in_o  (mio_in ),
    .mio_out_i (mio_out),
    .mio_oe_i  (mio_oe ),
    .mio_attr_i(mio_attr),

    .dio_in_o (dio_in ),
    .dio_out_i(dio_out),
    .dio_oe_i (dio_oe )
  );
% else:
  // AST control signals needed in the padring, driven by top_${top["name"]}
  ast_pkg::ast_clks_t ast_base_clks;
  prim_mubi_pkg::mubi4_t scanmode;

  padring #(
    // Padring specific counts may differ from pinmux config due
    // to custom, stubbed or added pads.
    .NDioPads(${len(dedicated_pads)}),
    .NMioPads(${len(muxed_pads)}),
    .PhysicalPads(1),
    .NIoBanks(int'(IoBankCount)),
    .DioScanRole ({
% for pad in list(reversed(dedicated_pads)):
      scan_role_pkg::${lib.Name.from_snake_case('dio_pad_' + pad["name"] + '_scan_role').as_camel_case()}${"" if loop.last else ","}
% endfor
    }),
    .MioScanRole ({
% for pad in list(reversed(muxed_pads)):
      scan_role_pkg::${lib.Name.from_snake_case('mio_pad_' + pad["name"] + '_scan_role').as_camel_case()}${"" if loop.last else ","}
% endfor
    }),
    .DioPadBank ({
% for pad in list(reversed(dedicated_pads)):
      ${lib.Name.from_snake_case('io_bank_' + pad["bank"]).as_camel_case()}${" " if loop.last else ","} // ${pad['name']}
% endfor
    }),
    .MioPadBank ({
% for pad in list(reversed(muxed_pads)):
      ${lib.Name.from_snake_case('io_bank_' + pad["bank"]).as_camel_case()}${" " if loop.last else ","} // ${pad['name']}
% endfor
    }),
\
\
    .DioPadType ({
% for pad in list(reversed(dedicated_pads)):
      ${pad["type"]}${" " if loop.last else ","} // ${pad['name']}
% endfor
    }),
    .MioPadType ({
% for pad in list(reversed(muxed_pads)):
      ${pad["type"]}${" " if loop.last else ","} // ${pad['name']}
% endfor
    })
  ) u_padring (
  // This is only used for scan and DFT purposes
    .clk_scan_i   ( ast_base_clks.clk_sys ),
    .scanmode_i   ( scanmode              ),
    .dio_in_raw_o ( dio_in_raw ),
    // Chip IOs
    .dio_pad_io ({
% for pad in list(reversed(dedicated_pads)):
  % if re.match(r"`INOUT_A?", pad["port_type"]):
`ifdef ANALOGSIM
      '0,
`else
      ${pad["name"]}${"" if loop.last else ","}
`endif
  % else:
      ${pad["name"]}${"" if loop.last else ","}
  % endif
% endfor
    }),

    .mio_pad_io ({
% for pad in list(reversed(muxed_pads)):
  % if re.match(r"`INOUT_A?", pad["port_type"]):
`ifdef ANALOGSIM
      '0,
`else
      ${pad["name"]}${"" if loop.last else ","}
`endif
  % else:
      ${pad["name"]}${"" if loop.last else ","}
  % endif
% endfor
    }),

    // Core-facing
% for port in ["in_o", "out_i", "oe_i", "attr_i"]:
    .dio_${port} ({
  % for pad in list(reversed(dedicated_pads)):
  <%
    sig = get_dio_sig(pinmux, pad)
  %>\
    % if sig is None:
      manual_${port[:-2]}_${pad["name"].lower()}${"" if loop.last else ","}
    % else:
      dio_${port[:-2]}[${lib.get_io_enum_literal(sig, 'dio')}]${"" if loop.last else ","}
    % endif
  % endfor
      }),
% endfor

% for port in ["in_o", "out_i", "oe_i", "attr_i", "in_raw_o"]:
<%
    sig_name = 'mio_' + port[:-2]
    indices = list(reversed(list(pad['idx'] for pad in muxed_pads)))
%>\
    .mio_${port} (${lib.make_bit_concatenation(sig_name, indices, 6)})${"" if loop.last else ","}
% endfor
  );
% endif

  //////////////////////////////////
  // Manual Pad / Signal Tie-offs //
  //////////////////////////////////

  assign manual_out_por_n = 1'b0;
  assign manual_oe_por_n = 1'b0;

  assign manual_out_otp_ext_volt = 1'b0;
  assign manual_oe_otp_ext_volt = 1'b0;

  // These pad attributes currently tied off permanently (these are all input-only pads).
  assign manual_attr_por_n = '0;
  assign manual_attr_otp_ext_volt = '0;

  logic unused_manual_sigs;
  assign unused_manual_sigs = ^{
    manual_in_otp_ext_volt
  };

  ////////////////////////////////
  // JTAG Pad / Signal Tie-offs //
  ////////////////////////////////

  // The JTAG TAP lives inside top_${top["name"]}. The JTAG pad signals are
  // forwarded there and the TDO response is driven back onto the pad.
  assign manual_out_jtag_tck     = '0;
  assign manual_out_jtag_tms     = '0;
  assign manual_out_jtag_trst_n  = '0;
  assign manual_out_jtag_tdi     = '0;
  assign manual_oe_jtag_tck      = '0;
  assign manual_oe_jtag_tms      = '0;
  assign manual_oe_jtag_trst_n   = '0;
  assign manual_oe_jtag_tdi      = '0;
  assign manual_attr_jtag_tck    = '0;
  assign manual_attr_jtag_tms    = '0;
  assign manual_attr_jtag_trst_n = '0;
  assign manual_attr_jtag_tdi    = '0;
  assign manual_attr_jtag_tdo    = '0;

  logic unused_manual_jtag_sigs;
  assign unused_manual_jtag_sigs = ^{
    manual_in_jtag_tdo
  };

  /////////////////////////////////////////////
  // top_${top["name"]}: power domains + AST //
  /////////////////////////////////////////////
  top_${top["name"]}_${target["name"]} #(
    .SecRomCtrl0DisableScrambling(SecRomCtrl0DisableScrambling),
    .SecRomCtrl1DisableScrambling(SecRomCtrl1DisableScrambling),
    .PinmuxAonTargetCfg(PinmuxTargetCfg)
  ) top_${top["name"]} (
% if target["name"] == "verilator":
    // Clock and reset
    .clk_i,
    .rst_ni,

% endif
    // Multiplexed I/O to/from padring
    .mio_in_i  (mio_in  ),
    .mio_out_o (mio_out ),
    .mio_oe_o  (mio_oe  ),
    .dio_in_i  (dio_in  ),
    .dio_out_o (dio_out ),
    .dio_oe_o  (dio_oe  ),
    .mio_attr_o(mio_attr),
    .dio_attr_o(dio_attr),

% if target["name"] != "verilator":
    // AST control signals consumed by the padring
    .ast_base_clks_o(ast_base_clks),
    .scanmode_o     (scanmode     ),

% endif
    // JTAG interface
    .jtag_tck_i   (manual_in_jtag_tck   ),
    .jtag_tms_i   (manual_in_jtag_tms   ),
    .jtag_trst_n_i(manual_in_jtag_trst_n),
    .jtag_tdi_i   (manual_in_jtag_tdi   ),
    .jtag_tdo_o   (manual_out_jtag_tdo  ),
    .jtag_tdo_oe_o(manual_oe_jtag_tdo   )\
% if target["name"] == "asic":
,

    // External POR
    .manual_in_por_n_i(manual_in_por_n),

    // Direct connection to the chip pad
    .OTP_EXT_VOLT(OTP_EXT_VOLT)\
% endif

  );

endmodule
