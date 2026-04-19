## Copyright lowRISC contributors (OpenTitan project).
## Licensed under the Apache License, Version 2.0, see LICENSE for details.
## SPDX-License-Identifier: Apache-2.0
<%page args="top, phys_pd"/>\
% for name, plic in top["plic_info"].items():
<% prefix = "_" + name if len(top["plic_info"]) > 1 else "" %>\
% if plic["phys_pd"] == phys_pd:
  % for pd in top["power"]["physical"]:
<% if pd == phys_pd: continue %>\
<% pd_len = plic["count_pd"][pd] - 1 %>\
    % if pd_len >= 0:
  input  logic [${pd_len}:0] intr_vector${prefix}_pd_${pd}_i,
    % endif
  % endfor
% else:
<% pd_len = plic["count_pd"][phys_pd] - 1 %>\
  % if pd_len >= 0:
  output logic [${pd_len}:0] intr_vector${prefix}_o,
  % endif
% endif
% endfor