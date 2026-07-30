---
title: "Termination-Point-to-Port Inventory Mapping"
type: "feature"
issue_id: "71"
interface_type: "api"
generation_mode: "subagent"
spec_source: "Project Constitution"
schema_containers:
  - path: "nwit:/nw:networks/nw:network/nw:node/nt:termination-point/inventory-mapping-attributes"
    node_type: container
---
# Feature: Termination-Point-to-Port Inventory Mapping

## Parent Epic
- [ ] #73 - [Network Inventory: Inventory Topology Mapping](https://github.com/gintatkinson/3dgs-030/blob/main/docs/epics/epic-06-inventory-topology-mapping.md) — Container mapping termination points to physical port components via the nwi:port-ref grouping.

## Description

The `inventory-mapping-attributes` container augments the topology `termination-point` with references to the corresponding physical port component in the base network inventory. Its presence indicates the termination point is a physical TP mapped to a port component; absence indicates a logical TP. The mapping uses the `nwi:port-ref` grouping, which provides both `ne-ref` (reference to the parent NE) and `port-ref` (leafref to the port component within that NE). This establishes a 1:1 mapping between the logical TP and its physical port component, enabling services like SAP-to-physical-port correlation for capacity verification.

The container is conditioned on the network being of `inventory-topology` type via the `when` expression.

## UML Class Diagram

```mermaid
classDiagram
    class Nw_networks {
    }
    class Nw_network {
    }
    class Nw_node {
    }
    class Nt_terminationPoint {
    }
    class InventoryMappingAttributes {
        +String neRef [0..1]
        +String portRef [0..1]
    }
    class PortRef {
        <<grouping>>
        +String neRef [0..1]
        +String portRef [0..1]
    }
    "Nw_networks" *-- "Nw_network" : network
    "Nw_network" *-- "Nw_node" : node
    "Nw_node" *-- "Nt_terminationPoint" : termination-point
    "Nt_terminationPoint" *-- InventoryMappingAttributes : inventory-mapping-attributes
    InventoryMappingAttributes ..> PortRef : uses (nwi:port-ref)
    note for InventoryMappingAttributes "Presence signals physical TP mapped to a port component"
    note for InventoryMappingAttributes "port-ref - leafref to port component within parent NE"
    note for InventoryMappingAttributes "ne-ref - reference to NE hosting the port"
    note for InventoryMappingAttributes "when - ../../nw -network-types/nwit -inventory-topology"
```

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
            "ietf-network-topology:termination-point": [
              {
                "tp-id": "example:TP-SW1-P1",
                "ietf-network-inventory-topology:inventory-mapping-attributes": {
                  "ne-ref": "example:NE-SW1",
                  "port-ref": "/nwi:network-inventory/nwi:network-elements/nwi:network-element[ne-id='example:NE-SW1']/nwi:components/nwi:component[component-id='eth-port-1']"
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

- **presence container**: When instantiated, signals that the termination point is a physical TP mapped to a port component. When absent, the TP is a logical TP.
- **ne-ref** (String, optional): Type `nwi:ne-ref`, a leafref to `nwi:ne-id`. References the network element hosting the port component.
- **port-ref** (String, optional): Type `leafref` referencing a `component-id` within the parent NE's component list. The leafref path is `/nwi:network-inventory/nwi:network-elements/nwi:network-element/nwi:components/nwi:component/nwi:component-id`.
- **when constraint**: `'../../nw:network-types/nwit:inventory-topology'`. The container is only valid when the grandparent network's `network-types` includes the `inventory-topology` container.
- **Read-write (config true)**: The mapping may be set via automatic discovery or manual configuration (CPE, leased lines, planned resources).

### 3. Logical Operations & Interface Messages

- **GET / GET-CONFIG**: Returns the `inventory-mapping-attributes` container with `ne-ref` and `port-ref` values for TPs in inventory-topology networks.
- **EDIT-CONFIG / PUT / PATCH**: Allows setting or updating `ne-ref` and `port-ref` on a termination point.
- **DELETE**: Removing the container disassociates the TP from any physical port component, reverting it to a logical TP.

### 4. Logical Exception States & Validation Failures

- **Dangling port-ref**: If `port-ref` points to a non-existent component within the referenced NE, referential integrity is violated and the server SHALL reject.
- **ne-ref / port-ref mismatch**: If `ne-ref` points to NE-A but `port-ref` resolves to a component under NE-B, the mapping is logically inconsistent. Schema-level enforcement depends on the leafref path constraint.
- **when violation**: Attempting to set the container on a TP in a non-inventory-topology network SHALL be rejected.

## Given-When-Then Acceptance Criteria

**Scenario: Map a termination point to a physical port component**
- Given network "underlay" is of type `inventory-topology` and NE "NE-SW1" has a component "eth-port-1"
- When a TP "TP-SW1-P1" has `inventory-mapping-attributes` with `ne-ref` "NE-SW1" and `port-ref` pointing to "eth-port-1"
- Then the TP is associated 1:1 with the physical port component "eth-port-1"
- And the mapping enables physical resource verification for service attachment points

**Scenario: Logical TP has no inventory mapping**
- Given an inventory-topology network
- When a termination point has no `inventory-mapping-attributes` container
- Then the TP is interpreted as a logical termination point
- And no port component mapping is asserted

**Scenario: Enforce referential integrity on port-ref**
- Given a port component "fake-port" does not exist under NE "NE-SW1"
- When a client attempts to set `port-ref` to a leafref path referencing "fake-port"
- Then the server SHALL reject the operation with a referential integrity error

**Scenario: SAP-to-physical-port correlation for capacity check**
- Given a service orchestrator queries SAPs and retrieves candidate termination points
- When each TP's `inventory-mapping-attributes` is consulted to resolve the physical `port-ref`
- Then the orchestrator can verify whether the underlying physical port has adequate capacity
- And if capacity is insufficient, an alternate SAP mapping to a different port is selected

**Scenario: when constraint prevents mapping on non-inventory network**
- Given a network "l3-overlay" has no `inventory-topology` type
- When a client attempts to add `inventory-mapping-attributes` to a TP in "l3-overlay"
- Then the server SHALL reject the operation per the `when` expression

**Scenario: Remove port mapping from a TP**
- Given TP "TP-SW1-P1" has `inventory-mapping-attributes` with resolved `port-ref`
- When the `inventory-mapping-attributes` container is deleted
- Then the TP becomes a logical TP with no physical port association
- And subsequent GET requests omit the container

## Specification Context (Verbatim)

From draft-ietf-ivy-network-inventory-topology, Section 3.1:

> The inventory topology data model provides a physical port reference (port-ref) that enables correlation between logical topology entities and physical inventory components. During service provisioning, the SAP's parent-termination-point can be associated with the inventory topology's port-ref to locate the underlying physical resource.

> During service provisioning, the orchestrator can issue a query using the SAP data model (e.g., obtaining a list of SAPs across multiple PEs as shown in Appendix A of RFC 9408), and then uses the inventory topology data model to identify the physical port underlying each candidate SAP. Specifically, the "parent-termination-point" of a SAP is mapped to the corresponding "port-ref" in the inventory topology, allowing the orchestrator to locate the physical resource.

> If the physical port underlying a candidate SAP has insufficient resources (e.g., port speed fully utilized), the orchestrator can select an alternate SAP that maps to a different port with adequate capacity.

From the YANG module schema (Section 5):

```
augment "/nw:networks/nw:network/nw:node/nt:termination-point" {
  when '../../nw:network-types/nwit:inventory-topology';
  container inventory-mapping-attributes {
    presence "If present, it indicates this is a physical termination point (TP), which maps to a port component. If not present, it indicates it is a logical TP.";
    uses nwi:port-ref {
      refine "port-ref" {
        description "Reference to the physical port component in the network inventory. This reference establishes a 1:1 mapping between the logical TP and its physical port component.";
      }
    }
  }
}
```

## Source References

Structural Schema: [ietf-network-inventory-topology@2026-06-25.yang](https://github.com/gintatkinson/3dgs-030/blob/main/schema/ietf-network-inventory-topology%402026-06-25.yang) (Clause: augment /nw:networks/nw:network/nw:node/nt:termination-point, container inventory-mapping-attributes, uses nwi:port-ref)
Normative Specification: [draft-ietf-ivy-network-inventory-topology-08](https://datatracker.ietf.org/doc/html/draft-ietf-ivy-network-inventory-topology) (Clause: Sections 3.1, 4, 5, Appendix A)

## Logical UI & Layout Bindings

- **Target LUI Component:** PropertyGrid (detail view for selected termination point)
- **Target Layout Container ID:** properties_view
- **Data Source Bindings:** schema:ietf-network-inventory-topology/termination-point/inventory-mapping-attributes/{ne-ref, port-ref}
