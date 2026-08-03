# ADR 0003: Explicit manual impacts and optional photo alignment

- Status: accepted
- Date: 2026-08-03

## Context

The first prototype reserved module boundaries for automatic impact detection.
Reliable recognition would require a representative private dataset, device and
lighting validation, and a permanent review workflow. That complexity competed
with the core range workflow: start, record, save and review.

## Decision

Version 0.2 contains no automatic detector, model, native vision runtime or scan
record. Every impact is an explicit user action. The pure score engine receives
physical millimetre coordinates, multiplicity and misses and remains the only
authority for ring values and aggregates.

A photo can become a scoring surface after the user identifies its four target
corners in TL, TR, BR, BL order. A deterministic, versioned homography converts
between normalized image coordinates and target millimetres. The immutable
original, alignment and impacts are stored separately. A photo without valid
alignment remains a normal attachment.

## Consequences

- Scores are explainable and never depend on hidden recognition confidence.
- Quick start and offline use do not wait for camera or analysis.
- Exact overlaps require the user to set multiplicity.
- A miss outside the target is registered explicitly as zero.
- Future recognition work, if ever reconsidered, must be a separate proposal and
  cannot silently modify confirmed data.
