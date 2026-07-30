---
title: "Link Media Type Classification"
type: "feature"
issue_id: "70"
interface_type: "api"
generation_mode: "subagent"
spec_source: "Project Constitution"
schema_containers:
  - path: "nwit:/nw:networks/nw:network/nt:link/inventory-mapping-attributes"
    node_type: container
---
# Feature: Link Media Type Classification

## Parent Epic
- [ ] #73 - [Network Inventory: Inventory Topology Mapping](https://github.com/gintatkinson/3dgs-030/blob/main/docs/epics/epic-06-inventory-topology-mapping.md) — Container mapping topology links to physical media type via the link-type identityref hierarchy.

## Description

The `inventory-mapping-attributes` container augments the topology `link` with a lightweight physical media classifier — the `link-type` leaf. Its presence indicates a physical link at the lowest underlay abstraction level. The `link-type` leaf uses an extensible identity hierarchy (`link-type` as base) to classify the physical medium: `copper`, `fiber`, `coax`, `microwave`, `wlan`, `unknown`, and `leased-fiber` (derived from `fiber`). This serves as a lightweight discriminator that guides consumers to the appropriate specialized inventory model for detailed resource information — e.g., wired media map to passive network inventory, wireless to microwave/Wi-Fi inventory.

The container is conditioned on the network being of `inventory-topology` type via the `when` expression.

## UML Class Diagram

```mermaid
classDiagram
    class Nw_networks {
    }
    class Nw:network {
    }
    class Nt_link {
    }
    class InventoryMappingAttributes {
        +String linkType [0..1]
    }
    class LinkType {
        <<identity>>
        +String id [1]
    }
    class Copper {
        <<identity>>
    }
    class Fiber {
        <<identity>>
    }
    class Coax {
        <<identity>>
    }
    class Microwave {
        <<identity>>
    }
    class Wlan {
        <<identity>>
    }
    class Unknown {
        <<identity>>
    }
    class LeasedFiber {
        <<identity>>
    }
    "Nw_networks" *-- "Nw:network" : network
    "Nw:network" *-- "Nt_link" : link
    "Nt_link" *-- InventoryMappingAttributes : inventory-mapping-attributes
    InventoryMappingAttributes ..> LinkType : link-type (identityref)
    LinkType <|-- Copper
    LinkType <|-- Fiber
    LinkType <|-- Coax
    LinkType <|-- Microwave
    LinkType <|-- Wlan
    LinkType <|-- Unknown
    Fiber <|-- LeasedFiber
    note for InventoryMappingAttributes "Presence signals physical link at lowest underlay level"
    note for LinkType "Extensible base identity — specialized inventory models may define additional derived identities"
    note for LeasedFiber "Derived from fiber: third-party link with limited visibility into physical attributes"
```

## Interface Requirements

### 1. Payload Schema

```json
{
  "ietf-network:networks": {
    "network": [
      {
        "network-id": "example:campus-topology",
        "ietf-network-topology:link": [
          {
            "link-id": "example:Link-SW1-SW2",
            "source": {
              "source-node": "example:SW-1",
              "source-tp": "example:TP-SW1-P1"
            },
            "destination": {
              "dest-node": "example:SW-2",
              "dest-tp": "example:TP-SW2-P1"
            },
            "ietf-network-inventory-topology:inventory-mapping-attributes": {
              "link-type": "nwit:fiber"
            }
          }
        ]
      }
    ]
  }
}
```

### 2. Validation & Constraints

- **presence container**: When instantiated, signals that the link is a physical link at the lowest underlay abstraction level. When absent, the link is a logical/overlay link.
- **link-type** (String/Identityref, optional): Type `identityref` with base `link-type`. Must be one of the defined identities or a valid extension: `nwit:copper`, `nwit:fiber`, `nwit:coax`, `nwit:microwave`, `nwit:wlan`, `nwit:unknown`, `nwit:leased-fiber`.
- **when constraint**: `'../nw:network-types/nwit:inventory-topology'`. The container is only valid when the parent network's `network-types` includes the `inventory-topology` presence container.
- **Read-write (config true)**: The `link-type` may be set via automatic discovery or manual configuration.
- **Identity hierarchy extensibility**: The base `link-type` identity is extensible. Specialized inventory modules may define additional derived identities. An unknown or unrecognized type should use `unknown`.

### 3. Logical Operations & Interface Messages

- **GET / GET-CONFIG**: Returns the `inventory-mapping-attributes` container with the `link-type` value for links in inventory-topology networks.
- **EDIT-CONFIG / PUT / PATCH**: Allows setting or updating the `link-type` on a link.
- **DELETE**: Removing the container disassociates the link from physical media classification.

### 4. Logical Exception States & Validation Failures

- **Invalid identityref**: Setting `link-type` to a value not derived from `link-type` base SHALL be rejected with a type validation error.
- **when violation**: Attempting to set the container on a link in a non-inventory-topology network SHALL be rejected.
- **Unknown media fallback**: When the physical medium cannot be determined, `unknown` should be used rather than omitting the `link-type` leaf entirely (but the leaf remains optional per schema).

## Given-When-Then Acceptance Criteria

**Scenario: Classify a fiber link**
- Given network "underlay" is of type `inventory-topology`
- When a link "Link-SW1-SW2" has `inventory-mapping-attributes` with `link-type` set to `nwit:fiber`
- Then the link is classified as a fiber-based physical link
- And consumers know to consult the passive network inventory model for detailed fiber attributes

**Scenario: Classify a leased fiber link**
- Given two devices are connected via a leased fiber from a third-party operator
- When `link-type` is set to `nwit:leased-fiber`
- Then the identity is valid (derived from `nwit:fiber`)
- And consumers understand that detailed physical attributes are typically not visible to the lessee

**Scenario: Classify a copper link**
- Given a link uses copper-based Ethernet cabling
- When `link-type` is set to `nwit:copper`
- Then the link is classified as copper-based
- And wired media classification guides to appropriate inventory model

**Scenario: Classify a microwave wireless link**
- Given a link uses microwave radio transmission
- When `link-type` is set to `nwit:microwave`
- Then the link is classified as microwave-based
- And consumers are directed to the microwave topology data model (RFC 9656) for detailed attributes

**Scenario: Classify an IEEE 802.11 wireless link**
- Given a link uses Wi-Fi (IEEE 802.11)
- When `link-type` is set to `nwit:wlan`
- Then the link is classified as WLAN-based

**Scenario: Classify a coaxial cable link**
- Given a link uses coaxial cable
- When `link-type` is set to `nwit:coax`
- Then the link is classified as coax-based

**Scenario: Fallback to unknown link type**
- Given a physical link's media type cannot be determined
- When `link-type` is set to `nwit:unknown`
- Then the identity is valid as a fallback
- And the link is still marked as physical (presence container exists) but unclassified

**Scenario: Reject invalid identityref value**
- Given a link in an inventory-topology network
- When a client attempts to set `link-type` to a value not derived from the base `link-type` identity
- Then the server SHALL reject the operation with a type validation error

**Scenario: Logical link has no media type classification**
- Given a link in an inventory-topology network
- When no `inventory-mapping-attributes` container is present on the link
- Then the link is interpreted as a logical/overlay link
- And no physical media type is asserted

**Scenario: when constraint prevents classification on non-inventory network**
- Given a network "l3-overlay" has no `inventory-topology` type
- When a client attempts to add `inventory-mapping-attributes` with `link-type` to a link in "l3-overlay"
- Then the server SHALL reject the operation per the `when` expression

## Specification Context (Verbatim)

From draft-ietf-ivy-network-inventory-topology, Section 4.1:

> This document adds a lightweight "link-type" leaf to the topology link mapping to enable basic physical media classification. "link-type": An identityref indicating the link media type. Examples of wired link types are "copper", "fiber", or "coax". For wireless media, values such as "microwave", or "wlan" may be used. See also RFC 9656 for more detailed microwave radio attributes.

> The "link-type" serves as a lightweight discriminator that guides to the appropriate specialized inventory model for detailed resource information. For example, wired media ("fiber" or "copper") typically references a passive network inventory model such as the one defined in draft-ygb-ivy-passive-network-inventory.

From the YANG module schema (Section 5):

```
identity link-type {
  description "Base identity for classifying the physical media type of a link at the inventory topology layer.";
}
identity copper { base link-type; description "Copper-based physical link."; }
identity fiber { base link-type; description "Fiber-based physical link."; }
identity coax { base link-type; description "Coaxial cable-based physical link."; }
identity microwave { base link-type; description "Microwave-based wireless link."; }
identity wlan { base link-type; description "IEEE 802.11 wireless link."; }
identity unknown { base link-type; description "Unknown link media type fallback."; }
identity leased-fiber { base fiber; description "Leased fiber link."; }

augment "/nw:networks/nw:network/nt:link" {
  when '../nw:network-types/nwit:inventory-topology';
  container inventory-mapping-attributes {
    presence "Indicates a physical link, at the lowest underlay abstraction level.";
    leaf link-type {
      type identityref { base link-type; }
      description "Classification of the link media type at the topology layer.";
    }
  }
}
```

## Source References

Structural Schema: [ietf-network-inventory-topology@2026-06-25.yang](https://github.com/gintatkinson/3dgs-030/blob/main/schema/ietf-network-inventory-topology%402026-06-25.yang) (Clause: identity link-type hierarchy, augment /nw:networks/nw:network/nt:link, container inventory-mapping-attributes, leaf link-type)
Normative Specification: [draft-ietf-ivy-network-inventory-topology-08](https://datatracker.ietf.org/doc/html/draft-ietf-ivy-network-inventory-topology) (Clause: Sections 4.1, 5, Appendix A)

## Logical UI & Layout Bindings

- **Target LUI Component:** PropertyGrid (detail view for selected topology link)
- **Target Layout Container ID:** properties_view
- **Data Source Bindings:** schema:ietf-network-inventory-topology/link/inventory-mapping-attributes/link-type
