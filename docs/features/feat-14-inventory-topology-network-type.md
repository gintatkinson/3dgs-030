---
title: "Inventory Topology Network Type"
type: "feature"
issue_id: "68"
interface_type: "api"
generation_mode: "subagent"
spec_source: "Project Constitution"
schema_containers:
  - path: "nwit:/nw:networks/nw:network/nw:network-types/inventory-topology"
    node_type: container
---
# Feature: Inventory Topology Network Type

## Parent Epic
- [ ] #73 - [Network Inventory: Inventory Topology Mapping](https://github.com/gintatkinson/3dgs-030/blob/main/docs/epics/epic-06-inventory-topology-mapping.md) — Presence container signalling physical-layer augmentations for inventory mapping, port breakout, and link media classification.

## Description

The `inventory-topology` container is a presence container augmenting the `network-types` node of the base network topology model. Its presence indicates that the enclosing network contains physical-layer attributes — specifically the inventory mapping augmentations for nodes, links, and termination points defined in this module. When present, the network serves as the physical underlay for logical network topologies (Layer 2, Layer 3, TE, etc.). The container carries no leaf data nodes; its existence alone is the signal. All child augmentations (node, link, TP) are conditioned on the presence of this network type via their `when` expressions.

## UML Class Diagram

```mermaid
classDiagram
    class "Nw:networks" {
    }
    class "Nw:network" {
    }
    class "Nw:networkTypes" {
    }
    class InventoryTopology {
        <<presence>>
    }
    "Nw:networks" *-- "Nw:network" : network
    "Nw:network" *-- "Nw:networkTypes" : network-types
    "Nw:networkTypes" *-- InventoryTopology : inventory-topology
    note for InventoryTopology "Presence signals physical-layer topology with inventory mapping augmentations"
    note for InventoryTopology "When absent, child augmentations are not instantiated"
```

## Interface Requirements

### 1. Payload Schema

```json
{
  "ietf-network:networks": {
    "network": [
      {
        "network-id": "example:physical-underlay",
        "network-types": {
          "ietf-network-inventory-topology:inventory-topology": {}
        }
      }
    ]
  }
}
```

### 2. Validation & Constraints

- **Presence semantics**: The container has `presence` declared in the schema. Its existence in instance data signals that the network is a physical underlay topology. Absence means the network is abstract/logical.
- **No data leaves**: The container has no leaf or leaf-list nodes. Any payload data within this container in instance data is invalid.
- **Conditional activation**: All other augmentations in this module (node, link, TP) include a `when` expression (`'../nw:network-types/nwit:inventory-topology'`) that gates their instantiation. If `inventory-topology` is not present, the augmented containers under node, link, and termination-point are not instantiated.

### 3. Logical Operations & Interface Messages

- **Network type registration**: The container is set during network instance creation (via NETCONF edit-config or RESTCONF POST/PUT) to register the network as an inventory-topology type. It is read-write (config true).
- **Network type query**: The container is returned in GET/GET-CONFIG responses for networks of this type. Its presence can be used as a filter criterion (e.g., `network[network-types/inventory-topology]`).

### 4. Logical Exception States & Validation Failures

- **Invalid child data**: Attempting to set child data (leaves, leaf-lists) within the `inventory-topology` container SHALL be rejected with an `invalid-value` error per standard management protocol semantics.
- **Type mismatch on augmented children**: If child augmentations (e.g., `inventory-mapping-attributes` under node) are present in instance data but the `inventory-topology` container is absent, the augmented containers are invalid per their `when` constraint.

## Given-When-Then Acceptance Criteria

**Scenario: Register a network as inventory topology type**
- Given a network instance "physical-underlay" is being created
- When the `inventory-topology` presence container is included under `network-types`
- Then the network is classified as an inventory-topology network
- And the child inventory-mapping augmentations become eligible for instantiation

**Scenario: Network without inventory topology type cannot host inventory mappings**
- Given a network "logical-overlay" has `network-types` set to only "l3-unicast-topology"
- When an inventory-mapping-attributes container is attempted under a node of this network
- Then the operation is rejected per the `when` constraint `'../nw:network-types/nwit:inventory-topology'`
- And the augmented data is not stored

**Scenario: Presence container carries no child data**
- Given a valid inventory-topology network instance
- When a client attempts to set a child leaf within the `inventory-topology` container
- Then the server SHALL reject the operation with an appropriate error
- And the container remains empty of data leaves

**Scenario: Absence indicates non-physical network**
- Given a network is retrieved via GET
- When the `inventory-topology` container is absent from `network-types`
- Then the network is a logical or abstract topology
- And inventory-mapping augmentations are not instantiated under its nodes, links, or TPs

**Scenario: Query filter by network type**
- Given multiple networks exist, some with `inventory-topology` and some without
- When a query filters on `network[network-types/inventory-topology]`
- Then only networks containing the presence container are returned

**Scenario: Deletion of network type cascades to augmented children**
- Given a network with `inventory-topology` present and inventory-mapping-attributes containers populated under nodes/links/TPs
- When the `inventory-topology` container is deleted
- Then all child augmentations gated by the `when` expression are no longer valid
- And the server SHALL remove them or return validation errors on subsequent reads

## Specification Context (Verbatim)

From draft-ietf-ivy-network-inventory-topology, Section 4:

> The module augments the "ietf-network-topology" module as follows: Inventory mapping attributes for nodes, and termination points: The corresponding containers augments the topology module with the references to the base network inventory.

From the YANG module schema (Section 5):

```
augment "/nw:networks/nw:network/nw:network-types" {
  description
    "Introduces a new network type for inventory topology mapping.";
  container inventory-topology {
    presence
      "Indicates a physical network topology, containing
       physical-layer attributes including inventory mapping, port
       breakout capabilities, and link media types.";
    description
      "Container for the inventory-topology network type.
       When present, it signals that the network contains
       physical-layer augmentations as defined in this module.
       This network type is intended to serve as the underlay
       for logical network topologies (Layer 2, Layer 3,
       Traffic Engineering (TE), etc.).";
  }
}
```

From draft-ietf-ivy-network-inventory-topology, Section 1:

> This document defines a YANG data model that extends the network topology data model to map network topologies with inventories. The data model introduces the "inventory-topology" network type and augmentations for physical entity mappings and capabilities, which may be used by any overlay network topology for service provisioning validation, network maintenance, and capacity planning.

> Similar to the base inventory data model, the network inventory topology does not make any assumption about involved NEs and their roles in topologies. As such, the mapping data model can be applied independent of the network type (optical local loops, access network, core network, etc.) and application.

> Therefore, this YANG data model can be used to represent a physical network instance at the lowest underlay abstraction level. Alternatively, it can be used in conjunction with existing network topology models when they contain nodes, links, or termination points belonging to the lowest underlay level.

## Source References

Structural Schema: [ietf-network-inventory-topology@2026-06-25.yang](https://github.com/gintatkinson/3dgs-030/blob/main/schema/ietf-network-inventory-topology%402026-06-25.yang) (Clause: augment /nw:networks/nw:network/nw:network-types, container inventory-topology)
Normative Specification: [draft-ietf-ivy-network-inventory-topology-08](https://datatracker.ietf.org/doc/html/draft-ietf-ivy-network-inventory-topology) (Clause: Sections 1, 4, 5)

## Logical UI & Layout Bindings

- **Target LUI Component:** N/A (network type registration — backend/metadata, not directly rendered)
- **Target Layout Container ID:** N/A
- **Data Source Bindings:** schema:ietf-network-inventory-topology/inventory-topology (network-type presence signal)
