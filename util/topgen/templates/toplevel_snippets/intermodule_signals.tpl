## Copyright lowRISC contributors (OpenTitan project).
## Licensed under the Apache License, Version 2.0, see LICENSE for details.
## SPDX-License-Identifier: Apache-2.0
<%import topgen.lib as lib%>\
<%from reggen.params import Parameter%>\
<%page args="top, domain"/>\
<%unused_resets = lib.get_unused_resets(top)%>\
<%
  unused_im_defs, undriven_im_defs = lib.get_dangling_im_def(
    [d for d in top["inter_signal"]["definitions"] if d["domain"] == domain])
%>\
## Inter-module Definitions
<%
  im_list = lib.get_intermodule_list(top, domain)
  im_groups = {}
  for sig in im_list:
    m = sig.get('inst_name', '')
    if m not in im_groups:
      im_groups[m] = []
    im_groups[m].append(sig)
%>\
% if im_list:
  // Define inter-module signals
% endif
% for i, (mod, group) in enumerate(im_groups.items()):
  % if i > 0:

  % endif
<%
  col_type  = [lib.im_defname(s) for s in group]
  col_width = []
  for s in group:
    if isinstance(s["width"], Parameter):
      col_width.append("[{}-1:0]".format(s["width"].name_top))
    elif s["width"] > 1:
      col_width.append("[{}:0]".format(s["width"] - 1))
    else:
      col_width.append("")
  w_type  = max(len(t) for t in col_type)
  w_width = max(len(w) for w in col_width)
  formatted = []
  for t, w, s in zip(col_type, col_width, group):
    if w_width > 0:
      formatted.append("{} {} {};".format(
        t.ljust(w_type), w.rjust(w_width), s["signame"]))
    else:
      formatted.append("{} {};".format(t.ljust(w_type), s["signame"]))
%>\
  % for line in formatted:
  ${line}
  % endfor
% endfor

## Mixed connection to port
## Index greater than 0 means a port is assigned to an inter-module array
## whereas an index of 0 means a port is directly driven by a module
<%
  port_pairs = []
  for port in lib.get_intermodule_ports(top, domain):
    if port['conn_type'] and isinstance(port['index'], list):
      for idx_port, idx in enumerate(port['index']):
        if port['direction'] == 'in':
          port_pairs.append(
            ("{}[{}]".format(port['netname'], idx),
             "{}[{}]".format(port['signame'], idx_port)))
        else:
          port_pairs.append(
            ("{}[{}]".format(port['signame'], idx_port),
             "{}[{}]".format(port['netname'], idx)))
    elif port['conn_type'] and port['index'] != -1:
      if port['direction'] == 'in':
        port_pairs.append(
          ("{}[{}]".format(port['netname'], port['index']),
           port['signame']))
      else:
        port_pairs.append(
          (port['signame'],
           "{}[{}]".format(port['netname'], port['index'])))
    elif port['conn_type']:
      if port['direction'] == 'in':
        port_pairs.append((port['netname'], port['signame']))
      else:
        port_pairs.append((port['signame'], port['netname']))
  w_lhs = max((len(lhs) for lhs, rhs in port_pairs), default=0)
%>\
% if port_pairs:
  // Create mixed connections to ports
% endif
% for lhs, rhs in port_pairs:
  assign ${lhs.ljust(w_lhs)} = ${rhs};
% endfor

## Partial inter-module definition tie-off
% if len(unused_im_defs) > 0:
  // Dummy signal definitions for unused partial inter-module signals
% for sig in unused_im_defs:
<%
  width = sig['width'].default if isinstance(sig['width'], Parameter) else sig['width']
%>\
  % for idx in range(sig['end_idx'], width):
  ${lib.im_defname(sig)} unused_${sig["signame"]}${idx};
  % endfor
% endfor

% endif\

% if len(unused_im_defs) > 0:
  // Assign unused partial inter-module signals
% for sig in unused_im_defs:
<%
  width = sig['width'].default if isinstance(sig['width'], Parameter) else sig['width']
%>\
  % for idx in range(sig['end_idx'], width):
  assign unused_${sig["signame"]}${idx} = ${sig["signame"]}[${idx}];
  % endfor
% endfor

% endif\

% if len(undriven_im_defs) > 0:
  // Assign undriven partial inter-module signals
% for sig in undriven_im_defs:
<%
  width = sig['width'].default if isinstance(sig['width'], Parameter) else sig['width']
%>\
  % for idx in range(sig['end_idx'], width):
  assign ${sig["signame"]}[${idx}] = ${sig["default"]};
  % endfor
% endfor
% endif\
