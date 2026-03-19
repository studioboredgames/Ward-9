# Ward 9 — Game Design Document

## Concept
The player is a hospital night attendant checking patients for anomalies. Over time, it becomes clear the player is the one being evaluated, and is possibly the anomaly themselves.

## Tone
Subtle, realistic, high-tension psychological horror. No jump-scare-heavy action. Focus on observation and paranoia.

## Core Loop
1. **Prepare**: A new shift phase begins. The ward is dimly lit.
2. **Observe**: The player walks to each of the 3 patients.
3. **Focus**: The player stares at a patient (0.6s–0.9s dwell) to open the Decision UI.
4. **Decide**: "All Normal" or "Something Wrong".
5. **Evaluate**: The system logs the choice and the player's behavior (speed, hesitation).
6. **Escalate**: Based on results, the environment begins to distort.

## Rooms
1. **Ward**: All 3 patients are here. Primary gameplay space.
2. **Corridor**: Transition space. No interaction.
3. **Staff Room**: Optional start/end point.

## Patients
- **Patient A**: Bed 1.
- **Patient B**: Bed 2.
- **Patient C**: Bed 3.

## Anomalies
All anomalies have visible/audible cues:
- **Posture**: Unnatural limb positions.
- **Audio**: Whispering, rhythmic tapping.
- **Visual**: Subtle lighting shifts, unnatural shadow direction, physical distortion.

## Evaluation States
- **Stable**: Player is performing correctly and calmly.
- **Suspicious**: Player is missing anomalies OR showing erratic behavior patterns (excessive staring, rapid jumping).
- **Failed**: Ending trigger. The "Observer" is identified as compromised.

## UI Philosophy
- **Minimal HUD**: No crosshair (until looking at a patient). No inventory.
- **Diegetic Elements**: If possible, reports are on physical clipboards. Decision UI is a mental projection/minimal overlay.

## Endings
- **The Good Attendant**: Complete shift correctly. You are "cleansed".
- **The Compromised**: Failed evaluation. You replaced a patient.
- **The Anomaly**: The twist is revealed early due to high suspicion.
