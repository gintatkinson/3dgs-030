---
title: "Port Breakout Capability"
type: "feature"
issue_id: "72"
interface_type: "api"
generation_mode: "subagent"
spec_source: "Project Constitution"
schema_containers:
  - path: "nwit:/nw:networks/nw:network/nw:node/nt:termination-point/port-breakout"
    node_type: container
---
# Feature: Port Breakout Capability

## Parent Epic
- [ ] #73 - [Network Inventory: Inventory Topology Mapping](https://github.com/gintatkinson/3dgs-030/blob/main/docs/epics/epic-06-inventory-topology-mapping.md) — Read-only container listing breakout channels for partitioning-capable physical ports.

## Description

The `port-breakout` container augments the topology `termination-point` to expose the hardware-determined breakout capability of a physical port. It is a read-only (`config false`) presence container — only instantiated for termination points whose underlying physical port supports partitioning into multiple independent lower-speed channels (e.g., a 400 Gb/s DR4 port that can be split into four 100 Gb/s lanes). For non-breakout ports, the container is omitted, keeping the topology model minimal.

The `breakout-channel` list, keyed by `channel-id` (uint16), enumerates the independent lanes into which the port can be divided. Each breakout channel is an atomic resource element — one physical interface may consume one or more breakout channels, but a channel MUST NOT be associated with more than one physical interface. The channel list represents the intrinsic partitioning capability regardless of whether the port is currently configured as a trunk (single interface) or as breakout (multiple interfaces).

## UML Class Diagram

```mermaid
classDiagram
    class "Nw:networks" {
    }
    class "Nw:network" {
    }
    class "Nw:node" {
    }
    class "Nt:terminationPoint" {
    }
    class PortBreakout {
        <<presence, config=false>>
    }
    class BreakoutChannel {
        +Integer channelId [1]
    }
    "Nw:networks" *-- "Nw:network" : network
    "Nw:network" *-- "Nw:node" : node
    "Nw:node" *-- "Nt:terminationPoint" : termination-point
    "Nt:terminationPoint" *-- PortBreakout : port-breakout
    PortBreakout *-- BreakoutChannel : breakout-channel
    note for PortBreakout "Presence indicates hardware supports port partitioning (e.g., 400G to 4x100G)"
    note for PortBreakout "config false: hardware-determined state, not configurable"
    note for PortBreakout "Omitted entirely for non-breakout-capable ports"
    note for BreakoutChannel "Atomic resource element: one physical interface may consume one or more channels"
    note for BreakoutChannel "channel-id: uint16, unique within the parent port scope"
```

## Interface Requirements

### 1. Payload Schema

```json
{
  "ietf-network-topology:networks": {
    "network": [
      {
        "network-id": "example:underlay-topology-400g",
        "node": [
          {
            "node-id": "example:n1",
            "termination-point": [
              {
                "tp-id": "example:400g-1/0/1",
                "ietf-network-inventory-topology:inventory-mapping-attributes": {
                  "ne-ref": "example:NE-1",
                  "port-ref": "example:port-1"
                },
                "ietf-network-inventory-topology:port-breakout": {
                  "breakout-channel": [
                    { "channel-id": 1 },
                    { "channel-id": 2 },
                    { "channel-id": 3 },
                    { "channel-id": 4 }
                  ]
                }
              }
            ]
          }
        ]
      }
    ]
  }
}
```

### 2. Validation & Constraints

- **config false**: The `port-breakout` container and its `breakout-channel` list are read-only. Any write operation (edit-config, PUT, PATCH) targeting these nodes SHALL be rejected.
- **presence container**: Only instantiated when the underlying hardware supports channel breakout. Absence means the port is not breakout-capable.
- **breakout-channel** (list): Keyed by `channel-id`.
  - **channel-id** (Integer, mandatory, key): Type `uint16` (0..65535). Uniquely identifies the breakout channel within the scope of the parent port. No additional constraints on channel-id values beyond the uint16 range.
- **when constraint**: `'../../nw:network-types/nwit:inventory-topology'`. The container is only valid when the grandparent network is of inventory-topology type.
- **Atomic resource semantics**: One breakout channel MUST NOT be associated with more than one physical interface. One physical interface may be associated with one or more breakout channels.

### 3. Logical Operations & Interface Messages

- **GET**: Returns the `port-breakout` container if the TP's underlying port is breakout-capable. The response includes the full `breakout-channel` list with all channel IDs. If the port is not breakout-capable, the container is omitted from the response.
- **No write operations**: All write operations targeting `port-breakout` or `breakout-channel` SHALL be rejected with an appropriate access-denied error (the data is `config false`).

### 4. Logical Exception States & Validation Failures

- **Write attempt rejected**: Any attempt to create, modify, or delete `port-breakout` or `breakout-channel` entries via NETCONF/RESTCONF SHALL be denied with an `access-denied` error per RFC 8341 NACM or `invalid-value` per RFC 8040.
- **Duplicate channel-id**: The schema defines `channel-id` as the key, so duplicate entries are automatically prevented at the data model level.
- **Invalid channel-id type**: Values outside the `uint16` range (0..65535) SHALL be rejected by the type system.

## Given-When-Then Acceptance Criteria

**Scenario: Retrieve breakout channels for a 400G DR4 port**
- Given a termination point "400g-1/0/1" represents a 400 Gb/s DR4 port capable of splitting to four 100G lanes
- When the `port-breakout` container is retrieved via GET
- Then the `breakout-channel` list contains exactly four entries with channel-ids 1, 2, 3, 4
- And each channel represents an independent atomic lane

**Scenario: Non-breakout port omits the container**
- Given a termination point "10g-1/0/5" represents a standard 10G port without breakout capability
- When the TP's data is retrieved via GET
- Then the `port-breakout` container is absent from the response
- And the TP is represented as a simple non-breakout port

**Scenario: Reject write operation on read-only breakout data**
- Given a termination point "400g-1/0/1" has `port-breakout` populated
- When a client attempts to add or remove a `breakout-channel` entry via EDIT-CONFIG
- Then the server SHALL reject the operation
- And the breakout channels remain unchanged (hardware-determined state)

**Scenario: Breakout channels are unique within the parent port**
- Given a port has breakout capability
- When the `breakout-channel` list is instantiated
- Then each entry has a unique `channel-id` (enforced by the list key)
- And no two channels share the same identifier

**Scenario: channel-id is a valid uint16**
- Given a breakout-capable port
- When `channel-id` values are assigned by the hardware/controller
- Then each channel-id must be an unsigned 16-bit integer (0..65535)
- And values outside this range are rejected by the type system

**Scenario: Trunk vs breakout configuration does not affect listing**
- Given a breakout-capable port is currently configured as a trunk (single interface)
- When the `port-breakout` container is retrieved
- Then the `breakout-channel` list still reflects the port's intrinsic partitioning capability
- And the listing is independent of the current operational mode

**Scenario: when constraint prevents instantiation on non-inventory network**
- Given a TP belongs to a network without `inventory-topology` type
- When data is retrieved for that TP
- Then the `port-breakout` container is not instantiated per the `when` expression

**Scenario: Channel atomicity constraint**
- Given a breakout channel "channel-id 3" is consumed by physical interface "eth-1/0/1:3"
- When a controller attempts to associate the same channel with a second physical interface
- Then this is invalid per the specification: one breakout channel MUST NOT be associated with more than one physical interface

## Specification Context (Verbatim)

From draft-ietf-ivy-network-inventory-topology, Section 4.2:

> High-density Ethernet ports (e.g., 400 Gb/s DR4) can be split into multiple independent lower-speed channels. The breakout channels represent the intrinsic capability of the port to be partitioned, regardless of whether the port is currently configured as a trunk or as a breakout port.

> A trunk port is associated with exactly one physical interface. A breakout port is a port that is decomposed into two or more physical interfaces; those interfaces may run at the same or different speeds and may consume the same or a different number of breakout channels.

> The container "port-breakout" is added under the termination-point augmentation. It lists the logical channels into which the single physical port can be divided. Only termination-points whose parent port is breakout-capable need to instantiate the container; otherwise the container is omitted, keeping the topology model minimal for the common non-breakout case.

> Breakout channel is an atomic resource element obtained by partitioning a breakout port. One physical interface may be associated with one or more breakout channels, but one breakout channel MUST NOT be associated with more than one physical interface.

From the YANG module schema (Section 5):

```
container port-breakout {
  presence "Indicates the port supports channel breakout.";
  config false;
  description "Breakout capability of the physical port represented by this TP. One TP maps to one physical port; channels are listed here.";
  list breakout-channel {
    key "channel-id";
    description "List of breakout channels available on this port.";
    leaf channel-id {
      type uint16;
      description "Unique identifier for the breakout channel within the scope of the parent port.";
    }
  }
}
```

From draft-ietf-ivy-network-inventory-topology, Section 6:

> The following nodes are read-only (config false) as they represent hardware-determined state: port-breakout: Hardware capability determined by physical port characteristics.

## Source References

Structural Schema: [ietf-network-inventory-topology@2026-06-25.yang](https://github.com/gintatkinson/3dgs-030/blob/main/schema/ietf-network-inventory-topology%402026-06-25.yang) (Clause: augment /nw:networks/nw:network/nw:node/nt:termination-point, container port-breakout, list breakout-channel, leaf channel-id)
Normative Specification: [draft-ietf-ivy-network-inventory-topology-08](https://datatracker.ietf.org/doc/html/draft-ietf-ivy-network-inventory-topology) (Clause: Sections 4.2, 5, 6, Appendix B)

## Logical UI & Layout Bindings

- **Target LUI Component:** PropertyGrid (read-only detail for breakout-capable termination point)
- **Target Layout Container ID:** properties_view
- **Data Source Bindings:** schema:ietf-network-inventory-topology/termination-point/port-breakout/breakout-channel[@channel-id]
