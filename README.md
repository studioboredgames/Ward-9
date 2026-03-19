# Ward 9 — Centralized Psychological Engine

A high-fidelity psychological horror experience built in Godot 4. This project implements a behavior-aware "Central Director" that dynamically manipulates player perception, memory, and trust.

## Core Architecture (The Director Model)

The game is no longer a collection of features; it is a unified **Centralized Psychological Authority**.

### 1. Psychological Director (`psychological_director.gd`)
- **N+2 Delayed Causality**: Analyzes behavior from Cycle N to strike in Cycle N+2.
- **Consequence Queuing**: Schedules long-term "System Betrayal" events.
- **Rules Enforcement**: Strictly enforces single-distortion, silence ratios (40%), and plausibility constraints.

### 2. Adaptive Anomaly System (`anomaly_manager.gd`)
- **Paranoia-Driven Targeting**: Actively identifies and attacks player "blind spots" (least-viewed areas).
- **Hardened Selection**: Punishes passivity (bias) and speed-running (scans) with delayed injections and intensity shifts.

### 3. Perceptual Distortion Suite
- **Memory Desync**: Patients revert to historical states when unobserved.
- **Truth Instability**: 15% chance to invert system feedback to seed doubt.
- **Reality Bleed**: Subtle time-scale glitches and atmospheric noise events.
- **Control Loss**: Simulated perceptual input lag (50–150ms).

## Implementation Timeline (Phases 1–10)

- **Phases 1–4**: Core Loop, Atmosphere, and Basic Anomaly selection.
- **Phases 5–6**: Initial Hallucinations and Paranoia Tracking.
- **Phases 7–10**: System Betrayal, Reality Bleed, identity Tracking, and centralized Architectural Control.

## Developer Hand-off

### Scene Setup
- **`main.tscn`**: Contains all 10+ psychological modules. The root node is the `GameManager` (Signal Router).
- **Nodes to Monitor**: Search for `[Director]` or `[AnomalyManager]` in the console output for real-time behavior logs.

### Verification
The system is working if:
1. Anomalies target ignored patients.
2. Feedback is occasionally misleading.
3. The "vibe" shifts from diagnostic to paranoid over time.

---

**Git Master Repository**: `https://github.com/studioboredgames/Ward-9.git`
**Final Commit**: `b6fb62f` (Final Master Proof Hardening).
Targeted for itch.io.
