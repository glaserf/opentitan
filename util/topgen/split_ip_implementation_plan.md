# Implementation plan: splitting IPs across two power domains

Companion to [split_ip_concept.md](split_ip_concept.md). That document defines *what* a split IP is; this one describes *how* to realize it in `reggen` and `topgen`, with concrete insertion points. All file/line references are to the current `split-ip-concept` branch and will drift — treat them as anchors, not gospel.

## Guiding decisions (from the concept discussion)

- **`partition` is intrinsic to the IP** → it is parsed and owned by `reggen` (identical for every instantiation) and forwarded to `topgen` as a read-only per-entry attribute. Precedent to mirror: `enabled_after_reset` on `Signal` (parsed in `reggen`, consumed in `merge.py`).
- **`domain` / `domain_secondary` are instance-level** → owned by `topgen` (a given IP type can land in different PDs at different tops), read from the module dict in `top_<top>.hjson`.
- **v1 enforces `domain != domain_secondary`** (same-PD deferred).
- **Tooling stays PD-agnostic**: reason only about `domain` / `domain_secondary`; never hard-code Aon/Main or a gating direction.
- The `<ip>_part_primary` / `<ip>_part_secondary` RTL modules and the `<ip>_p2s_t` / `<ip>_s2p_t` structs in `<ip>_pkg` are **designer-provided**, not generated.

## Where each step plugs into the existing flow

`topgen.py::_process_top` order: `extract_clocks` (1279) → block creation → `elaborate_instance` (1290) → `connect_clocks` (1295) → `validate_top` (1303) → `merge_top` (1307) → `complete_topcfg` → `create_alert_lpgs` (1739) → `autoconnect` (1745) → `elab_intermodule` (1748). This runs inside a convergence loop (~1710-1736), so **every new step must be idempotent**.

---

## Phase 0 — `reggen` schema (IP-level static structure)

**0a. `is_split_ip` flag.** `util/reggen/ip_block.py`: add to `OPTIONAL_FIELDS` (94-150), parse with `check_bool` (default `False`), add a dataclass field, thread through the constructor call (405-409) and `_asdict` (549-588).

**0b. `partition` on list entries.** Add an optional `partition` key (values `primary`/`secondary`, default `primary`; `param_list` also accepts `both`). Add a small shared validator (membership check; there is no enum checker in `reggen/lib.py`, so validate with `check_str` + explicit set membership, raising `ValueError`).

| List | Class / file | Change |
|---|---|---|
| CIO (`available_input/output/inout_list`) | `Signal` — `util/reggen/signal.py:19` | add `"partition"` to `check_keys` optional list (21); store `self.partition`; **extend `as_nwt_dict` (55-67) to emit it** (interrupts/alerts/CIOs reach `topgen` only through this method) |
| `interrupt_list` | `Interrupt(Signal)` — `util/reggen/interrupt.py:30` | inherit / add `"partition"` to optional list (33) |
| `alert_list` | `Alert(Signal)` — `util/reggen/alert.py:19` | add `"partition"` to the (currently empty) optional list (21) |
| `inter_signal_list` | `InterSignal` — `util/reggen/inter_signal.py:31` | add to optional list (35) **and** to `_asdict` (77-90) |
| `param_list` | `BaseParam` — `util/reggen/params.py` | add `'partition'` to `OPTIONAL_FIELDS` (15-28), parse in `_parse_parameter` (128-268), add to `BaseParam.as_dict` (47-55); accept `both` |

Inter-signals and params already reach `topgen` via wholesale `_asdict()` / `as_dict()`, so only their serializers need the key. Interrupts/alerts/CIOs need the `as_nwt_dict` change because that method currently emits only `name`/`width`/`type`.

**0c. `clocking_secondary`.** `util/reggen/ip_block.py`: parse via `Clocking.from_raw` into a new optional dataclass field; register in `OPTIONAL_FIELDS`; thread constructor + `_asdict`. Add a `get_secondary_clock()` on `IpBlock` analogous to `get_primary_clock()`; note `Clocking.from_raw` enforces *exactly one* primary (104-106) — the secondary partition's clocking is a **separate** `Clocking` object, so that invariant is unaffected. Each `ClockingItem` already carries its own `reset`, so `clocking_secondary` fully describes both the secondary partition's clocks **and** resets — there is no separate `reset_secondary` key (mirrors how the primary partition's resets come from `clocking`). May be empty/absent when the secondary partition needs no clock/reset. Only meaningful when `is_split_ip`; validate that in topgen.

---

## Phase 1 — `topgen` validation + flat→nested normalization

**1a. Normalization (earliest step).** Add `normalize_partition_connections(topcfg)` run **before** `extract_clocks` (topgen.py:1279) and before `validate_top`. For each module instance, rewrite `reset_connections`, `clock_srcs`, `clock_group` so downstream code always indexes by partition:
- non-split (flat) → `{primary: <flat_value>}`
- split → require the nested `{primary: ..., secondary: ...}` form (error otherwise)

Must run before `validate_reset` (validate.py:1050-1054), which mutates `reset_connections` in place. Must be idempotent (convergence loop).

**1b. `util/topgen/validate.py`.**
- `module_optional` (267-326): add `domain_secondary`. `is_split_ip` is forwarded from the block during elaboration → add it to `module_added` (328-334) so `check_keys` accepts it.
- `check_power_domains` (1184-1203): require `domain_secondary` iff `is_split_ip`, forbid otherwise; validate membership in `top['power']['domains']`; assert `domain != domain_secondary` (v1).
- `validate_reset` (1017-1097) / `validate_clock` (1104-1147) / `check_clocks_resets` (931-975): branch on `is_split_ip` to validate each partition's connection sub-dict against **that partition's** PD (primary→`domain`, secondary→`domain_secondary`), including the per-connection `reset['domain']` check (1062-1065).

---

## Phase 2 — partition→domain resolution in `merge.py`

Add a helper `partition_domain(module, partition)` → `module['domain_secondary'] if partition == 'secondary' else module['domain']`.

- `elaborate_instance` (64-289): forward `is_split_ip` onto the instance dict; `partition` already rides along on `param_list` (`as_dict`, 109) and `inter_signal_list` (`_asdict`, 195).
- `amend_interrupt` (domain stamp at 1144), `amend_alert` (1492-1541 / `commit_alert_connections` m_domain at 1305), `amend_pinmux_io` (domain stamps at 1828/1852/1863): today set `domain = module domain`. Make each **partition-aware** — `domain = partition_domain(module, entry.partition)` — relying on the `partition` now carried by `as_nwt_dict` (Phase 0b). Once each object's `domain` reflects its partition's PD, all existing per-domain filtering keeps working unchanged.

---

## Phase 3 — clocking / reset / LPG per partition

- `extract_clocks` (659-758): for a split IP, run the clock-group elaboration **twice** — primary using `clock_srcs[primary]` / `clock_group[primary]` / `domain`, secondary using `clock_srcs[secondary]` / `clock_group[secondary]` / `domain_secondary` and the block's `clocking_secondary`. Produce a nested `clock_connections` `{primary, secondary}`. Use `lib.get_clock_prefixes(top, <partition PD>)`.
- `connect_clocks` (761-846): iterate `clocking` **and** `clocking_secondary`.
- `amend_resets` (849-928): iterate `reset_connections` per partition (loop at 887-892); call `top_resets.add_reset_domain(reset['name'], reset['domain'])` with the partition's PD; use the secondary clock's reset (`get_secondary_clock()`) for the secondary partition.
- `create_alert_lpgs` (942-...): **generalize the single-primary-clock assumption.** Today it uses one `block.get_primary_clock()` + the module's single reset/clock. For a split IP, compute an LPG per partition (primary via `get_primary_clock()`, secondary via `get_secondary_clock()` with the secondary clock group + reset + `domain_secondary`), and let each alert's `partition` select which partition's LPG it joins. This is the most involved single change.

---

## Phase 4 — intra-IP structs + intermodule signalling

- **Inject the `p2s`/`s2p` link** as an inter-module connection so the existing multi-PD machinery builds the crossing. Add a step (mirroring `autoconnect`, `intermodule.py:211`) **before** `elab_intermodule` (topgen.py:1748) that, for each split-IP instance, calls `add_intermodule_connection` (`intermodule.py:83-120`) for the two directions. Model them as two `uni` inter-module signals with `package = <ip>_pkg`, `struct = <ip>_p2s` / `<ip>_s2p`, endpoints tagged with the owning partition's PD, so `handle_multi_pd_intersig` (`intermodule.py:393`) auto-creates the chip-level signal + PD-level ports.
- **Partition-aware `domain` tagging** for the IP's own `inter_signal_list`: `get_signame_chip` assigns `domain` from `module.get('domain')` (`intermodule.py:331`). For split IPs this must come from the signal's `partition` instead (via `partition_domain`), so an inter-signal owned by the secondary partition is exposed from `domain_secondary`. Per the concept, inter-signals never route through the `p2s`/`s2p` structs.

---

## Phase 5 — `lib.py` filtering helpers

Change single-`domain` matches to "does this module have a partition in this PD?" (`m['domain'] == domain or m.get('domain_secondary') == domain`):
- `get_all_modules` (583-587) — the primary emission driver; returns the one module dict in **both** PD passes.
- `find_modules` (999-1020), `idx_of_last_module_with_params` (567-580), `num_rom_ctrl` (986-996).
- `get_clock_prefixes` (668-685) / `get_reset_prefixes` (717-734): pick the prefix from the **partition** being emitted, not the module's single domain.
- `get_intermodule_list` (447) / `get_intermodule_ports` (454): unchanged once signal definitions are tagged with the owning partition's PD (Phase 4).

Add `get_module_partition(m, domain)` → `'primary'`/`'secondary'` for the templates.

---

## Phase 6 — templates

- `util/topgen/templates/toplevel_snippets/module_instantiations.tpl`: after the `get_all_modules(top, domain)` match (17), compute `partition = lib.get_module_partition(m, domain)`. Emit `u_${m["name"]}_part_${partition}` of module type `${m["type"]}_part_${partition}`. Index `m["clock_connections"][partition]` / `m["reset_connections"][partition]`. For interrupts (78-93), alerts (97-103), CIOs (107-120), and inter-module signals (124-145), **skip entries whose `partition` != current partition**.
- `port_intermodule_signals.tpl` / `intermodule_signals.tpl`: already filter by signal `domain`; work unchanged once signals are partition-tagged (Phase 4).
- The `p2s`/`s2p` ports emit automatically through the injected inter-module connection + existing inter-PD snippets (`chiplevel_snippets/intermodule_portmap.tpl`).

---

## Phase 7 — pilot IP + end-to-end verification

1. **Pick a pilot split IP** (decision needed — candidates depend on which currently-Aon IP has logic that can move to Main). Provide hand-written `<ip>_part_primary.sv` / `<ip>_part_secondary.sv` and `<ip>_pkg` with `p2s_t`/`s2p_t`.
2. Add `is_split_ip: true`, per-entry `partition` tags, and `clocking_secondary` (carrying the secondary partition's clocks and resets) to the IP hjson.
3. Instantiate in `hw/top_earlgrey/data/top_earlgrey.hjson` with `domain` / `domain_secondary` and nested `reset_connections` / `clock_srcs` / `clock_group`.
4. Run `topgen` and inspect the generated `toplevel.sv` / `toplevel_aon.sv`: primary sub-instance in the primary PD top, secondary in the secondary PD top, `reg_top` in primary, `p2s`/`s2p` crossing via chip-level ports, correct per-partition clock/reset connections and alert LPGs.

### Verification
- **Unit**: run the `reggen`/`topgen` Python tests (`util/reggen`, `util/topgen` test suites); add cases for `partition` parsing/defaulting, `both` on params, `is_split_ip` requiring `domain_secondary`, and flat→nested normalization idempotency.
- **Backwards-compat**: regenerate all existing tops (`make -C hw ...` / the topgen regen flow) and confirm a **no-op diff** for non-split IPs (proves flat→nested normalization is transparent).
- **Generation**: for the pilot, diff generated RTL and eyeball the PD placement, inter-PD ports, and LPGs as above.
- **Lint**: Verilator/ascentlint on the regenerated top to confirm the split instances elaborate and the cross-PD ports connect.
