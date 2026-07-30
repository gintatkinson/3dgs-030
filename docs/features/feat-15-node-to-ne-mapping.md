---
title: "Node-to-Network-Element Inventory Mapping"
type: "feature"
issue_id: "69"
interface_type: "api"
generation_mode: "subagent"
spec_source: "Project Constitution"
schema_containers:
  - path: "nwit:/nw:networks/nw:network/nw:node/inventory-mapping-attributes"
    node_type: container
---
# Feature: Node-to-Network-Element Inventory Mapping

## Parent Epic
- [ ] #73 - [Network Inventory: Inventory Topology Mapping](https://github.com/gintatkinson/3dgs-030/blob/main/docs/epics/epic-06-inventory-topology-mapping.md) — Container mapping topology nodes to physical network elements via ne-ref leaf.

## Description

The `inventory-mapping-attributes` container augments the topology `node` with a reference to the corresponding Network Element (NE) in the base network inventory. Its presence indicates the node is a physical node (mapped to an NE); absence indicates an abstract or logical node. The mapping is established via the `ne-ref` leaf, which is a leafref to the `ne-id` key of a network-element in the `ietf-network-inventory` module. This establishes a 1:1 mapping between the logical topology node and its physical NE in the inventory.

The container is conditioned on the network being of `inventory-topology` type via a `when` expression (`'../nw:network-types/nwit:inventory-topology'`).

## UML Class Diagram



## Interface Requirements

### 1. Payload Schema

```json
{
  "ietf-network:networks": {
    "network": [
      {
        "network-id": "example:campus-topology",
        "node": [
          {
            "node-id": "example:SW-1",
            "ietf-network-inventory-topology:inventory-mapping-attributes": {
              "ne-ref": "example:NE-SW1"
            }
          }
        ]
      }
    ]
  }
}
```

### 2. Validation & Constraints

- **presence container**: When instantiated, signals that the node is a physical topology node mapped to an NE. When absent, the node is an abstract/logical node.
- **ne-ref** (String, optional): Type `nwi:ne-ref`, a leafref to `nwi:ne-id`. Must reference a valid `ne-id` in `/nwi:network-inventory/nwi:network-elements/nwi:network-element`. The mapping is 1:1 — each topology node maps to at most one NE.
- **when constraint**: `'../nw:network-types/nwit:inventory-topology'`. The container is only valid when the parent network's `network-types` includes the `inventory-topology` presence container.
- **Read-write (config true)**: The mapping may be set via automatic discovery or manual configuration (e.g., for CPE outside management domain, leased lines, planned resources per Section 6 of the spec).

### 3. Logical Operations & Interface Messages

- **GET / GET-CONFIG**: Returns the `inventory-mapping-attributes` container with the `ne-ref` value for nodes in inventory-topology networks.
- **EDIT-CONFIG / PUT / PATCH**: Allows setting or updating the `ne-ref` on a node to establish or modify the inventory mapping.
- **DELETE**: Removing the `inventory-mapping-attributes` container (or its `ne-ref` leaf) disassociates the node from any physical NE, reverting it to an abstract node.

### 4. Logical Exception States & Validation Failures

- **Dangling reference**: If `ne-ref` points to a non-existent `ne-id`, the reference is invalid. The schema's `require-instance` (default `true` for type `leafref`) will enforce referential integrity.
- **when violation**: Attempting to set `inventory-mapping-attributes` on a node belonging to a non-inventory-topology network SHALL be rejected.
- **Multi-mapping**: Setting two nodes to the same `ne-ref` value is permitted by the schema (no `unique` constraint) but semantically represents a distributed NE mapped to multiple topology nodes.

## Given-When-Then Acceptance Criteria

**Scenario: Map a physical node to its network element**
- Given a network "physical-underlay" is of type `inventory-topology`
- When the `inventory-mapping-attributes` container is created under node "SW-1" with `ne-ref` set to "NE-SW1"
- Then the topology node "SW-1" is associated 1:1 with network element "NE-SW1"
- And the mapping is retrievable via GET

**Scenario: Abstract node has no inventory mapping**
- Given a network "physical-underlay" is of type `inventory-topology`
- When a node "virtual-node" has no `inventory-mapping-attributes` container
- Then the node is interpreted as an abstract/logical node
- And no NE reference is asserted for this node

**Scenario: Enforce referential integrity on ne-ref**
- Given a network element "NE-FAKE" does not exist in the inventory
- When a client attempts to set `ne-ref` to "NE-FAKE"
- Then the server SHALL reject the operation with a referential integrity error
- And the mapping is not stored

**Scenario: when constraint prevents mapping on non-inventory network**
- Given a network "l3-topology" has network-type "l3-unicast-topology" but NOT `inventory-topology`
- When a client attempts to add `inventory-mapping-attributes` to a node in "l3-topology"
- Then the server SHALL reject the operation per the `when` expression
- And an appropriate validation error is returned

**Scenario: Remove inventory mapping from a node**
- Given node "SW-1" has `inventory-mapping-attributes` with `ne-ref` "NE-SW1"
- When the `inventory-mapping-attributes` container is deleted from node "SW-1"
- Then the node becomes abstract (no physical NE mapping)
- And subsequent GET requests do not include the inventory-mapping-attributes container

**Scenario: Distributed NE across multiple topology nodes**
- Given a network element "NE-dual" exists in the inventory
- When topology nodes "node-A" and "node-B" both have `ne-ref` set to "NE-dual"
- Then both nodes reference the same physical NE
- And the schema permits this (no uniqueness constraint on ne-ref across nodes)

## Specification Context (Verbatim)

From draft-ietf-ivy-network-inventory-topology, Section 5 (YANG module):

```
augment "/nw:networks/nw:network/nw:node" {
  when '../nw:network-types/nwit:inventory-topology';
  description
    "Augments the network topology node with inventory mapping
     attributes. This enables correlation between the logical node
     and its physical network element.";
  container inventory-mapping-attributes {
    presence
      "If present, it indicates this is a physical node, which
       maps to a network element. If not present, it indicates it
       is an abstract node.";
    description
      "Container for inventory mapping attributes of a node.";
    leaf ne-ref {
      type nwi:ne-ref;
      description
        "Reference to the NE in the inventory that corresponds to
         this topology node.

         This reference establishes a 1:1 mapping between the
         logical node and its physical NE.";
    }
  }
}
```

From draft-ietf-ivy-network-inventory-topology, Section 6:

> For typical operations such as service provisioning and network planning, the model offers read-only query access to authoritative mappings between logical topology and physical inventory. The inventory-mapping-attributes containers are defined as read-write (config true) to accommodate cases where automatic discovery is not possible, including: Customer-premises equipment (CPE) outside the operator's management domain, Leased lines and third-party transport resources, Planned or hypothetical resources for future deployment. In these cases, the operator manually configures the mapping to maintain accurate topology-to-inventory correlation.

## Source References

Structural Schema: [ietf-network-inventory-topology@2026-06-25.yang](https://github.com/gintatkinson/3dgs-030/blob/main/schema/ietf-network-inventory-topology%402026-06-25.yang) (Clause: augment /nw:networks/nw:network/nw:node, container inventory-mapping-attributes, leaf ne-ref)
Normative Specification: [draft-ietf-ivy-network-inventory-topology-08](https://datatracker.ietf.org/doc/html/draft-ietf-ivy-network-inventory-topology) (Clause: Sections 4, 5, 6)

## Logical UI & Layout Bindings

- **Target LUI Component:** PropertyGrid (detail view for selected topology node)
- **Target Layout Container ID:** properties_view
- **Data Source Bindings:** schema:ietf-network-inventory-topology/network(node)/inventory-mapping-attributes/ne-ref
