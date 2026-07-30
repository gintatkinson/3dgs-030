---
title: "Shared Type Registry — RFC 9911 Common YANG Data Types"
type: "shared-type-registry"
generation_mode: "utility-module-catalog"
spec_source: "RFC 9911 — Common YANG Data Types"
schema_modules:
  - ietf-yang-types@2025-12-22.yang
  - ietf-inet-types@2025-12-22.yang
normative_specification: "RFC 9911 (obsoletes RFC 6991)"
normative_specification_url: "https://www.rfc-editor.org/rfc/rfc9911.txt"
schema_directory: "schema/"
issue_id: null
---

# Shared Type Registry — RFC 9911 Common YANG Data Types

> **Purpose:** This registry catalogs all typedefs from the RFC 9911 utility modules `ietf-yang-types` and `ietf-inet-types`. These modules contain **zero containers, lists, config nodes, RPCs, or notifications** — they are pure type libraries. Downstream functional modules MUST reference these shared DataTypes / UML Primitives rather than redefining them.

## Module 1: `ietf-yang-types` (prefix: `yang`)

**Namespace:** `urn:ietf:params:xml:ns:yang:ietf-yang-types`
**Schema file:** `schema/ietf-yang-types@2025-12-22.yang`
**Total typedefs:** 33

### 1.1 Counters and Gauges

| Type Name | UML Primitive | Base Type | Constraints | Default | Description | Normative Reference |
|---|---|---|---|---|---|---|
| `yang:counter32` | Integer | `uint32` | Range: 0..4294967295; monotonically increasing, wraps at max | none | Non-negative integer that monotonically increases, wraps from 2^32-1 to zero. No defined initial value. Not for config nodes. | RFC 2578 (SMIv2 Counter32) |
| `yang:zero-based-counter32` | Integer | `counter32` | Range: 0..4294967295; monotonically increasing, wraps at max | `"0"` | Counter32 with defined initial value of zero. Set to 0 on creation, increases monotonically thereafter. | RFC 4502 (ZeroBasedCounter32 TC) |
| `yang:counter64` | Integer | `uint64` | Range: 0..18446744073709551615; monotonically increasing, wraps at max | none | Non-negative integer that monotonically increases, wraps from 2^64-1 to zero. No defined initial value. Not for config nodes. | RFC 2578 (SMIv2 Counter64) |
| `yang:zero-based-counter64` | Integer | `counter64` | Range: 0..18446744073709551615; monotonically increasing, wraps at max | `"0"` | Counter64 with defined initial value of zero. Set to 0 on creation, increases monotonically thereafter. | RFC 2856 (ZeroBasedCounter64 TC) |
| `yang:gauge32` | Integer | `uint32` | Range: 0..4294967295; may increase or decrease, clamped at limits | none | Non-negative integer that can increase/decrease. Latches at maximum when exceeded, latches at minimum when undershot. | RFC 2578 (SMIv2 Gauge32) |
| `yang:gauge64` | Integer | `uint64` | Range: 0..18446744073709551615; may increase or decrease, clamped at limits | none | Non-negative 64-bit integer that can increase/decrease. Latches at bounds. | RFC 2856 (CounterBasedGauge64 TC) |

### 1.2 Identifier Types

| Type Name | UML Primitive | Base Type | Constraints | Default | Description | Normative Reference |
|---|---|---|---|---|---|---|
| `yang:object-identifier` | String | `string` | Pattern: `'(([0-1](\.[1-3]?[0-9]))\|(2\.(0\|([1-9][0-9]*))))(\.(0\|([1-9][0-9]*)))*'` — first sub-id restricted to 0/1/2; second sub-id 0..39 if first is 0/1; at least 2 sub-ids required; individual sub-id max 2^32-1 | none | Administratively assigned names in a registration-hierarchical-name tree (ASN.1 OID). Dot-separated non-negative integers. Superset of SMIv2 OBJECT IDENTIFIER (no 128 sub-id limit). | ISO 9834-1 |
| `yang:object-identifier-128` | String | `object-identifier` | Pattern: `'[0-9]*(\.[0-9]*){1,127}'` — restricted to 128 sub-identifiers | none | Object identifier restricted to exactly 128 sub-identifiers (equivalent to SMIv2 OBJECT IDENTIFIER). | RFC 2578 (SMIv2) |

### 1.3 Date and Time

| Type Name | UML Primitive | Base Type | Constraints | Default | Description | Normative Reference |
|---|---|---|---|---|---|---|
| `yang:date-and-time` | String | `string` | Pattern: `'[0-9]{4}-(1[0-2]\|0[1-9])-(0[1-9]\|[1-2][0-9]\|3[0-1])T(0[0-9]\|1[0-9]\|2[0-3]):[0-5][0-9]:([0-5][0-9]\|60)(\.[0-9]+)?(Z\|[\+\-]((1[0-3]\|0[0-9]):([0-5][0-9])\|14:00))?'` — ISO 8601 profile per RFC 3339 sec 5.6 + RFC 9557 sec 2; leap seconds allowed (seconds=60); no negative years; time-offset `Z` = UTC with unknown local TZ; `+00:00` = UTC with local TZ reference point UTC | none | Timestamp with date, time, optional fractional seconds, and optional time zone offset. Compatible with XML schema dateTime (except negative years and `Z`/`+00:00` semantics). | ISO 8601; RFC 3339; RFC 9557; RFC 2579; XSD-TYPES |
| `yang:date` | String | `string` | Pattern: `'[0-9]{4}-(1[0-2]\|0[1-9])-(0[1-9]\|[1-2][0-9]\|3[0-1])(Z\|[\+\-]((1[0-3]\|0[0-9]):([0-5][0-9])\|14:00))?'` — no negative years; time-offset `Z` = UTC unknown local TZ; `+00:00` = UTC local TZ ref UTC | none | Time-interval of 24 hours (a calendar day) with optional time zone offset. Compatible with XML schema date (except negative years). | RFC 3339; RFC 9557; XSD-TYPES |
| `yang:date-no-zone` | String | `date` | Pattern: `'[0-9]{4}-(1[0-2]\|0[1-9])-(0[1-9]\|[1-2][0-9]\|3[0-1])'` — no time zone offset allowed | none | Calendar date without time zone offset information. | (derived from `yang:date`) |
| `yang:time` | String | `string` | Pattern: `'(0[0-9]\|1[0-9]\|2[0-3]):[0-5][0-9]:([0-5][0-9]\|60)(\.[0-9]+)?(Z\|[\+\-]((1[0-3]\|0[0-9]):([0-5][0-9])\|14:00))?'` — hours 00..23; minutes 00..59; seconds 00..59 or 60 (leap second); optional sub-second fraction; optional time zone offset | none | Instance of time of zero duration that recurs every day, with optional time zone offset. Leap seconds allowed. Compatible with XML schema time. | RFC 3339; RFC 9557; XSD-TYPES |
| `yang:time-no-zone` | String | `time` | Pattern: `'(0[0-9]\|1[0-9]\|2[0-3]):[0-5][0-9]:([0-5][0-9]\|60)(\.[0-9]+)?'` — no time zone offset allowed | none | Time without time zone offset information. | (derived from `yang:time`) |
| `yang:hours32` | Integer | `int32` | Range: -2147483648..2147483647 hours (repr. range: [-89478485d 08:00:00, 89478485d 07:00:00]); units: hours | none | Signed time period measured in hours. Should be range-restricted (`0..max`) for non-negative only. | (RFC 9911) |
| `yang:minutes32` | Integer | `int32` | Range: -2147483648..2147483647 minutes (repr. range: [-1491308d 2:08:00, 1491308d 2:07:00]); units: minutes | none | Signed time period measured in minutes. Should be range-restricted (`0..max`) for non-negative only. | (RFC 9911) |
| `yang:seconds32` | Integer | `int32` | Range: -2147483648..2147483647 seconds (repr. range: [-24855d 03:14:08, 24855d 03:14:07]); units: seconds | none | Signed time period measured in seconds. Should be range-restricted (`0..max`) for non-negative only. | (RFC 9911) |
| `yang:centiseconds32` | Integer | `int32` | Range: -2147483648..2147483647 centiseconds (10^-2 s) (repr. range: [-248d 13:13:56, 248d 13:13:56]); units: centiseconds | none | Signed time period measured in 10^-2 seconds. Equivalent to SMIv2 TimeInterval TC. Should be range-restricted for non-negative only. | (RFC 9911) |
| `yang:milliseconds32` | Integer | `int32` | Range: -2147483648..2147483647 milliseconds (10^-3 s) (repr. range: [-24d 20:31:23, 24d 20:31:23]); units: milliseconds | none | Signed time period measured in 10^-3 seconds. Should be range-restricted for non-negative only. | (RFC 9911) |
| `yang:microseconds32` | Integer | `int32` | Range: -2147483648..2147483647 microseconds (10^-6 s) (repr. range: [-00:35:47, 00:35:47]); units: microseconds | none | Signed time period measured in 10^-6 seconds. Should be range-restricted for non-negative only. | (RFC 9911) |
| `yang:microseconds64` | Integer | `int64` | Range: -9223372036854775808..9223372036854775807 microseconds (10^-6 s) (repr. range: [-106751991d 04:00:54, 106751991d 04:00:54]); units: microseconds | none | Signed 64-bit time period measured in microseconds. Should be range-restricted for non-negative only. | (RFC 9911) |
| `yang:nanoseconds32` | Integer | `int32` | Range: -2147483648..2147483647 nanoseconds (10^-9 s) (repr. range: [-00:00:02, 00:00:02]); units: nanoseconds | none | Signed time period measured in 10^-9 seconds. Should be range-restricted for non-negative only. | (RFC 9911) |
| `yang:nanoseconds64` | Integer | `int64` | Range: -9223372036854775808..9223372036854775807 nanoseconds (10^-9 s) (repr. range: [-106753d 23:12:44, 106752d 0:47:16]); units: nanoseconds | none | Signed 64-bit time period measured in nanoseconds. Should be range-restricted for non-negative only. | (RFC 9911) |
| `yang:timeticks` | Integer | `uint32` | Range: 0..4294967295 (modulo 2^32); represents hundredths of a second between two epochs | none | Non-negative integer representing modulo 2^32 hundredths of a second between two reference epochs. Reference epochs must be defined by the using schema node. | RFC 2578 (SMIv2 TimeTicks) |
| `yang:timestamp` | Integer | `timeticks` | Range: 0..4294967295; value of associated timeticks node at a specific occurrence; zero if occurrence was before last timeticks reset; resets when timeticks wraps (497+ days) | none | Snapshot of an associated timeticks node at a specific event occurrence. Associated timeticks node MUST be specified in the description of any using node. | RFC 2579 (SMIv2 TimeStamp TC) |

### 1.4 Address Types

| Type Name | UML Primitive | Base Type | Constraints | Default | Description | Normative Reference |
|---|---|---|---|---|---|---|
| `yang:phys-address` | String | `string` | Pattern: `'([0-9a-fA-F]{2}(:[0-9a-fA-F]{2})*)?'` — even-length colon-separated hex octets; canonical lowercase | none | Media- or physical-level address as colon-separated hexadecimal octets. Variable length. | RFC 2579 (SMIv2 PhysAddress TC) |
| `yang:mac-address` | String | `string` | Pattern: `'[0-9a-fA-F]{2}(:[0-9a-fA-F]{2}){5}'` — exactly 6 octets (48-bit); canonical lowercase | none | IEEE 802 48-bit MAC address. Does not support non-48-bit MAC addresses (use `phys-address` for those). | IEEE 802; RFC 2579 (SMIv2 MacAddress TC) |

### 1.5 XML Types

| Type Name | UML Primitive | Base Type | Constraints | Default | Description | Normative Reference |
|---|---|---|---|---|---|---|
| `yang:xpath1.0` | String | `string` | No additional constraints; using schema node MUST specify XPath context in its description | none | XPATH 1.0 expression string. XPath evaluation context must be documented by the using schema node. | XPATH 1.0 |

### 1.6 String Types

| Type Name | UML Primitive | Base Type | Constraints | Default | Description | Normative Reference |
|---|---|---|---|---|---|---|
| `yang:hex-string` | String | `string` | Pattern: `'([0-9a-fA-F]{2}(:[0-9a-fA-F]{2})*)?'` — even-length colon-separated hex octets; canonical lowercase | none | Arbitrary hexadecimal string with colons separating each octet. | (RFC 6991) |
| `yang:uuid` | String | `string` | Pattern: `'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}'` — RFC 9562 format; canonical lowercase; example: `f81d4fae-7dec-11d0-a765-00a0c91e6bf6` | none | Universally Unique Identifier (UUID) in RFC 9562 string representation. | RFC 9562 |
| `yang:dotted-quad` | String | `string` | Pattern: `'(([0-9]\|[1-9][0-9]\|1[0-9][0-9]\|2[0-4][0-9]\|25[0-5])\.){3}([0-9]\|[1-9][0-9]\|1[0-9][0-9]\|2[0-4][0-9]\|25[0-5])'` — four decimal octets 0..255 separated by `.` | none | Unsigned 32-bit number in dotted-quad notation (e.g., `192.0.2.1`). | (RFC 6991) |
| `yang:language-tag` | String | `string` | No pattern; must be well-formed BCP 47 (RFC 5646) language tag; canonical lowercase; implementations MAY restrict to validating processor limits | none | BCP 47 language tag. Values must be well-formed per RFC 5646. Aligned with SMIv2 LangTag TC. | RFC 5646; RFC 5131 |

### 1.7 YANG Types

| Type Name | UML Primitive | Base Type | Constraints | Default | Description | Normative Reference |
|---|---|---|---|---|---|---|
| `yang:yang-identifier` | String | `string` | Length: `"1..max"`; Pattern: `'[a-zA-Z_][a-zA-Z0-9\-_.]*'` — starts with alpha or underscore, followed by alpha/numeric/underscore/hyphen/dot | none | YANG identifier per RFC 7950 section 14 (YANG 1.1 identifier rule). In YANG 1.0 context, excludes identifiers starting with 'xml' (case-insensitive). | RFC 7950; RFC 6991; RFC 6020 |

---

## Module 2: `ietf-inet-types` (prefix: `inet`)

**Namespace:** `urn:ietf:params:xml:ns:yang:ietf-inet-types`
**Schema file:** `schema/ietf-inet-types@2025-12-22.yang`
**Total typedefs:** 27

### 2.1 Protocol Field Types

| Type Name | UML Primitive | Base Type | Constraints | Default | Description | Normative Reference |
|---|---|---|---|---|---|---|
| `inet:ip-version` | Enumeration | `enumeration` | Values: `unknown` (0), `ipv4` (1), `ipv6` (2) | none | Version of the Internet Protocol. | RFC 6021 |
| `inet:dscp` | Integer | `uint8` | Range: `"0..63"` | none | Differentiated Services Code Point (6-bit field in IP header). | RFC 2474 |
| `inet:ipv6-flow-label` | Integer | `uint32` | Range: `"0..1048575"` (20-bit field) | none | IPv6 Flow Label (20-bit field). | RFC 8200; RFC 3595 |
| `inet:port-number` | Integer | `uint16` | Range: `"0..65535"` | none | Transport-layer port number (TCP/UDP/SCTP/DCCP). | RFC 9293; RFC 0768; RFC 9260; RFC 4340 |
| `inet:protocol-number` | Integer | `uint8` | Range: 0..255 (uint8) | none | Internet Protocol number (identifies next-level protocol in IP header). | RFC 0791; RFC 8200; RFC 2780 |
| `inet:upper-layer-protocol-number` | Integer | `protocol-number` | Range: 0..255 (uint8) | none | Upper-layer protocol number for transport protocols (TCP 6, UDP 17, SCTP 132, etc.). Restricts protocol-number to ULPs. | RFC 2780 |
| `inet:as-number` | Integer | `uint32` | Range: 0..4294967295 (uint32) | none | Autonomous System number. Non-zero values identify an AS; zero is non-routable. | RFC 1930; RFC 6793; RFC 4271 |

### 2.2 IP Address Types

| Type Name | UML Primitive | Base Type | Constraints | Default | Description | Normative Reference |
|---|---|---|---|---|---|---|
| `inet:ip-address` | Union | `union { ipv4-address; ipv6-address; }` | Accepted if it matches either IPv4 or IPv6 address pattern | none | Union type accepting either an IPv4 or IPv6 address. | RFC 6021 |
| `inet:ipv4-address` | String | `string` | Pattern: IPv4 dotted-quad notation (0..255).(0..255).(0..255).(0..255) with optional zone ID (`%<zone>` per RFC 4007) | none | IPv4 address in dotted-quad notation with optional zone index. | RFC 4007; RFC 0791 |
| `inet:ipv6-address` | String | `string` | Pattern: IPv6 address per RFC 4291 sections 2.2, with optional zone index; canonical format per RFC 5952 (lowercase, shortest representation, `::` only once for longest zero run) | none | IPv6 address with optional zone index. Canonical format per RFC 5952. | RFC 4291; RFC 4007; RFC 5952 |
| `inet:ip-address-no-zone` | Union | `union { ipv4-address-no-zone; ipv6-address-no-zone; }` | No zone index permitted | none | Union type for IP address without zone index. | RFC 6991 |
| `inet:ipv4-address-no-zone` | String | `ipv4-address` | No zone index permitted | none | IPv4 address without zone index. | RFC 6991 |
| `inet:ipv6-address-no-zone` | String | `ipv6-address` | No zone index permitted | none | IPv6 address without zone index. | RFC 6991 |
| `inet:ip-address-link-local` | Union | `union { ipv4-address-link-local; ipv6-address-link-local; }` | IPv4 link-local: 169.254/16 prefix; IPv6 link-local: fe80::/10 prefix | none | Union type accepting either an IPv4 or IPv6 link-local address. | RFC 9911 |
| `inet:ipv4-address-link-local` | String | `ipv4-address` | Must be in 169.254/16 prefix (RFC 3927) | none | IPv4 link-local address (RFC 3927). | RFC 3927 |
| `inet:ipv6-address-link-local` | String | `ipv6-address` | Must be in fe80::/10 prefix (RFC 4291) | none | IPv6 link-local address (RFC 4291). | RFC 4291 |

### 2.3 IP Prefix Types

| Type Name | UML Primitive | Base Type | Constraints | Default | Description | Normative Reference |
|---|---|---|---|---|---|---|
| `inet:ip-prefix` | Union | `union { ipv4-prefix; ipv6-prefix; }` | IPv4 prefix: `ip/length` with length 0..32; IPv6 prefix: `ip/length` with length 0..128 | none | Union type for IP prefix (CIDR notation). | RFC 6021 |
| `inet:ipv4-prefix` | String | `string` | Pattern: IPv4 address `/` prefix-length (0..32) | none | IPv4 prefix in CIDR notation (e.g., `192.0.2.0/24`). | RFC 2317 |
| `inet:ipv6-prefix` | String | `string` | Pattern: IPv6 address `/` prefix-length (0..128) | none | IPv6 prefix in CIDR notation (e.g., `2001:db8::/32`). | RFC 4291; RFC 5952 |
| `inet:ip-address-and-prefix` | Union | `union { ipv4-address-and-prefix; ipv6-address-and-prefix; }` | Combines address and prefix-length in one notation | none | Union type for combined IP address-and-prefix notation. | RFC 9911 |
| `inet:ipv4-address-and-prefix` | String | `string` | Pattern: IPv4 address `/` prefix-length (0..32) | none | IPv4 address with embedded prefix-length (e.g., `192.0.2.1/24`). | RFC 9911 |
| `inet:ipv6-address-and-prefix` | String | `string` | Pattern: IPv6 address `/` prefix-length (0..128) | none | IPv6 address with embedded prefix-length (e.g., `2001:db8::1/64`). | RFC 9911 |

### 2.4 Domain, Host, and URI Types

| Type Name | UML Primitive | Base Type | Constraints | Default | Description | Normative Reference |
|---|---|---|---|---|---|---|
| `inet:domain-name` | String | `string` | Length: `"1..253"`; pattern: fully-qualified domain name (FQDN) per RFC 1034/1123/5890 | none | Fully-qualified domain name. Length 1..253 octets. Internationalized domain names per IDNA (RFC 5890). | RFC 1034; RFC 1123; RFC 5890; RFC 2181 |
| `inet:host-name` | String | `domain-name` | Length: `"2..max"`; derived from domain-name, minimum length 2 | none | Host name (FQDN, minimum 2 characters). Distinguished from domain-name for semantic clarity. | RFC 9911 |
| `inet:host` | Union | `union { ip-address; host-name; }` | Accepted if either IP address or host name | none | Union type for host identification: either IP address or host name. | RFC 4001; RFC 6021 |
| `inet:uri` | String | `string` | Pattern: generic URI per RFC 3986 | none | Uniform Resource Identifier (URI). | RFC 3986; RFC 3305 |
| `inet:email-address` | String | `string` | Pattern: email address per RFC 5322 addr-spec; internationalized email per RFC 6532 | none | Email address per RFC 5322/6532 (e.g., `user@example.com`). | RFC 5322; RFC 6532 |

---

## Normative Specification Context (Verbatim)

The following paragraphs from RFC 9911 provide the authoritative specification context for all types in this registry.

> **Section 1 (Introduction):**
> YANG [RFC7950] is a data modeling language used to model configuration and state data manipulated by the Network Configuration Protocol (NETCONF) [RFC6241]. The YANG language supports a small set of built-in data types and provides mechanisms to derive other types from the built-in types.
>
> This document defines a collection of common data types. The definitions are organized into two YANG modules:
> * The "ietf-yang-types" module defines generally useful data types such as types for counters and gauges, types related to date and time, and types for common string values (e.g., UUIDs, dotted-quad notation, and language tags).
> * The "ietf-inet-types" module defines data types relevant for the Internet Protocol suite such as types related to IP addresses, types for domain name, host name, URI, and email, and types for values in common protocol fields (e.g., port numbers).

> **Section 2 (Overview):**
> Some types have an equivalent Structure of Management Information Version 2 (SMIv2) [RFC2578] [RFC2579] data type. A YANG data type is equivalent to an SMIv2 data type if the data types have the same set of values and the semantics of the values are equivalent.

---

## Source References

- **Structural Schema:** `schema/ietf-yang-types@2025-12-22.yang` (RFC 9911, Section 3)
- **Structural Schema:** `schema/ietf-inet-types@2025-12-22.yang` (RFC 9911, Section 4)
- **Normative Specification:** RFC 9911 "Common YANG Data Types" — [https://www.rfc-editor.org/rfc/rfc9911.txt](https://www.rfc-editor.org/rfc/rfc9911.txt)
- **Obsoleted Specification:** RFC 6991 "Common YANG Data Types"
- **Predecessor Specification:** RFC 6021 "Common YANG Data Types"

---

## SMIv2 Equivalents (Cross-Reference)

| YANG Type | Equivalent SMIv2 Type (Module) |
|---|---|
| `yang:counter32` | Counter32 (SNMPv2-SMI) |
| `yang:zero-based-counter32` | ZeroBasedCounter32 (RMON2-MIB) |
| `yang:counter64` | Counter64 (SNMPv2-SMI) |
| `yang:zero-based-counter64` | ZeroBasedCounter64 (HCNUM-TC) |
| `yang:gauge32` | Gauge32 (SNMPv2-SMI) |
| `yang:gauge64` | CounterBasedGauge64 (HCNUM-TC) |
| `yang:object-identifier-128` | OBJECT IDENTIFIER |
| `yang:centiseconds32` | TimeInterval (SNMPv2-TC) |
| `yang:timeticks` | TimeTicks (SNMPv2-SMI) |
| `yang:timestamp` | TimeStamp (SNMPv2-TC) |
| `yang:phys-address` | PhysAddress (SNMPv2-TC) |
| `yang:mac-address` | MacAddress (SNMPv2-TC) |
| `yang:language-tag` | LangTag (LANGTAG-TC-MIB) |
| `inet:ip-version` | InetVersion (INET-ADDRESS-MIB) |
| `inet:dscp` | Dscp (DIFFSERV-DSCP-TC) |
| `inet:ipv6-flow-label` | IPv6FlowLabel (IPV6-FLOW-LABEL-MIB) |
| `inet:port-number` | InetPortNumber (INET-ADDRESS-MIB) |
| `inet:as-number` | InetAutonomousSystemNumber (INET-ADDRESS-MIB) |
| `inet:uri` | Uri (URI-TC-MIB) |
