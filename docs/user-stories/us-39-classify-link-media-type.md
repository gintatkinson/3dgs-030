---
title: "Classify Link Media Type for Physical Media Discrimination"
type: "user-story"
generation_mode: "subagent"
issue_id: "76"
spec_source: "draft-ietf-ivy-network-inventory-topology-08 Section 4.1 and Appendix A"
---

# User Story: Classify Link Media Type for Physical Media Discrimination

## Parent Epic
- [ ] #73 - [Network Inventory: Inventory Topology Mapping](https://github.com/gintatkinson/3dgs-030/blob/main/docs/epics/epic-06-inventory-topology-mapping.md) (the link-type identity hierarchy under link inventory-mapping-attributes is the media classification mechanism)

## Domain Object Mapping
- **Primary Domain Objects:** `InventoryMappingAttributes` (presence container under `nt:link`), `link-type` (identityref leaf with base `LinkType`), `LinkType` (base identity), `Copper`, `Fiber`, `Coax`, `Microwave`, `Wlan`, `Unknown`, `LeasedFiber` (derived identities), `Nt:link` (augmented topology link)
- **Actor/Role:** Network Operator (system or engineer classifying the physical media type of underlay links to guide consumers to the appropriate specialized inventory model)

## BDD Scenario (OOA/OOD Realization)
**As a** Network Operator
**I want to** classify the physical media type of a topology link using the `link-type` identityref leaf
**So that** specialized inventory models (passive network inventory for wired media, microwave/Wi-Fi inventory for wireless) can be selected for detailed resource analysis

**Given** two switches "SW-1" and "SW-2" are connected by a fiber optic cable
**When** the Network Operator sets `link-type` to `nwit:fiber` on the link connecting "SW-1" to "SW-2"
**Then** the link is classified as a fiber physical medium
**And** consumers are guided to the passive network inventory model for detailed fiber attributes (strand count, connector type, attenuation)

**Given** a link between microwave towers "MW-1" and "MW-2"
**When** the Network Operator sets `link-type` to `nwit:microwave` on that link
**Then** the link is classified as a microwave wireless medium
**And** consumers are guided to the microwave topology model (RFC 9656) for detailed radio attributes (frequency, modulation, capacity)

**Given** an operator cannot determine the physical medium of a discovered link
**When** the Network Operator sets `link-type` to `nwit:unknown`
**Then** the link is marked with the fallback identity, acknowledging the medium is indeterminate
**And** no specialized inventory model guidance is provided

**Given** a link's physical medium is fiber but the fiber is leased from a third-party operator
**When** the Network Operator sets `link-type` to `nwit:leased-fiber`
**Then** the link is classified as a leased fiber with limited visibility into the underlying physical attributes
**And** consumers expect the passive inventory model to have reduced detail for this link

**Given** a link has no `inventory-mapping-attributes` container present
**When** the Network Operator queries the link type
**Then** the link is identified as a logical/overlay link with no physical media classification

## Compliance Verification Table

| Rule | Status |
|------|--------|
| Lifeline aliasing (name : Classifier) | PASS |
| Open return arrows (`-->`) used | PASS |
| Return value assignment signatures | PASS |
| Given-When-Then BDD scenarios present | PASS |
| Mermaid blocks properly closed | PASS |
| No semicolons in Note statements | PASS |
| Combined fragment guards in square brackets | PASS |
| Helper/Calculator delegation for computations | PASS |

## UML Sequence Diagram
```mermaid
sequenceDiagram
    autonumber
    actor operator as "operator : Actor"
    participant link as "link : Link"
    participant linkInvMapping as "linkInvMapping : InventoryMappingAttributes"
    participant linkTypeLeaf as "linkTypeLeaf : LinkType"
    participant passiveInventory as "passiveInventory : PassiveInventory"

    operator->>link: classifyLinkMedia(linkId: String, mediaType: String)
    link->>linkInvMapping: setLinkType(mediaType: String)
    linkInvMapping->>linkTypeLeaf: validateIdentity(mediaType: String)
    linkTypeLeaf-->linkInvMapping: isValid : Boolean
    alt [isValid is true]
        linkInvMapping-->link: linkTypeSet : Status
        alt [mediaType is fiber or copper or coax]
            operator->>passiveInventory: requestPassiveInventoryDetails(linkId: String)
            passiveInventory-->operator: passiveDetails : PassiveInventoryRecord
            note over operator: Wired media routed to passive network inventory model
        else [mediaType is microwave]
            note over operator: Wireless media routed to microwave topology model (RFC 9656)
        else [mediaType is unknown]
            note over operator: No specialized inventory model guidance available
        end
    else [isValid is false]
        linkInvMapping-->operator: invalidIdentity : Error
        note over operator: Identity must derive from base link-type or be a recognized extension
    end
```

## Operational Context
From draft-ietf-ivy-network-inventory-topology-08, Section 4.1:
> "link-type": An identityref indicating the link media type. Examples of wired link types are "copper", "fiber", or "coax". For wireless media, values such as "microwave", or "wlan" may be used.

> The "link-type" serves as a lightweight discriminator that guides to the appropriate specialized inventory model for detailed resource information. For example, wired media ("fiber" or "copper") typically references a passive network inventory model such as the one defined in [I-D.ygb-ivy-passive-network-inventory].

From Appendix A: JSON example demonstrates the `link-type` set to `"fiber"` on a link connecting SW-1 to SW-2.

From the YANG module schema, Section 5: Eight identities defined: `link-type` (base), `copper`, `fiber`, `coax`, `microwave`, `wlan`, `unknown`, `leased-fiber` (derived from `fiber`). The base identity is extensible.

## Required Features Matrix
- [ ] #70 - [Link Media Type Classification](https://github.com/gintatkinson/3dgs-030/blob/main/docs/features/feat-16-link-media-type-classification.md) (the `link-type` identityref leaf within the link `inventory-mapping-attributes` container is the mechanism for physical media discrimination and specialized inventory model routing)

## Source References
Structural Schema: [ietf-network-inventory-topology@2026-06-25.yang](https://github.com/gintatkinson/3dgs-030/blob/main/schema/ietf-network-inventory-topology%402026-06-25.yang) (Clause: augment /nw:networks/nw:network/nt:link, container inventory-mapping-attributes, leaf link-type, identity hierarchy)
Normative Specification: [draft-ietf-ivy-network-inventory-topology-08](https://datatracker.ietf.org/doc/html/draft-ietf-ivy-network-inventory-topology) (Clause: Sections 4.1, 5, Appendix A)

> [!WARNING]
> **Mermaid Block Closing Constraints & Code Fence Integrity:**
> - Every Mermaid diagram MUST be strictly closed with ``` on a new line. Leaking Mermaid blocks or stray/unclosed code fences will fail downstream validation checks.
> - **Semicolon Restriction**: Do NOT use semicolons (`;`) in sequence diagram `Note` statements or message text statements. Semicolons are not allowed. Replace any semicolons with commas, dashes, or spaces.
