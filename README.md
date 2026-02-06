# BlinkNotch


https://github.com/user-attachments/assets/bd9eb8b8-c80d-4f9e-8253-2c2f0912902d


**A calm macOS utility that quietly restores healthy blinking during focused work.**

BlinkNotch is a lightweight background app that helps reduce dry eye during prolonged screen use. Instead of alerts, sounds, or notifications, it uses a subtle, peripheral animation near the Mac notch: two eyes appear, blink once slowly, and disappear.

No interruption. No instructions. Just a gentle cue for a natural reflex.



## Context (facts)

- **Normal blink rate:** 15–20 blinks per minute  
- **During focused screen work:** 3–7 blinks per minute  
  → a **60–70% reduction**
- **Blink quality drops:** many screen-time blinks are incomplete, failing to fully spread tears or release protective oil
- **Oil glands at risk:** each eyelid contains **20–40 meibomian glands** that rely on complete blinking to function
- **Scale:** dry eye affects an estimated **500 million to 1 billion adults worldwide**
- **Risk groups:** office and screen workers report dry-eye symptoms **2–3× more often**
- **Healthcare impact:** dry eye is among the **top reasons for eye-care visits globally**



## Why this matters (not “just dry eyes”)

The tear film is the eye’s **primary optical surface**.

When blinking is reduced or incomplete, tear breakup leads to:
- Blurred or fluctuating vision
- Reduced contrast sensitivity (harder to read and see details)
- Increased glare and light sensitivity
- Faster visual fatigue

Chronic reduced blinking accelerates **meibomian gland dropout**:
- Gland loss is **irreversible**
- Less oil → tears evaporate faster permanently

Severe dry eye can progress to:
- Corneal inflammation
- Surface erosions or ulcers
- Scarring that permanently degrades vision quality



## What severe dry eye feels like

Patients commonly report:
- Persistent burning or stinging
- A gritty, scraping sensation with every blink
- Pain when opening eyes, especially in the morning
- Vision that blurs within seconds after blinking
- Light sensitivity severe enough to limit screen time

In advanced cases, blinking itself can feel painful, causing people to blink even less.



## The problem

Focused screen work suppresses blinking by up to **70%**, disrupting tear and oil distribution and accelerating irreversible oil-gland loss.

Existing reminder-based tools rely on alerts, sounds, or notifications. These interrupt attention, are easily ignored, and do not address **blink quality**, leaving hundreds of millions of screen users exposed to progressive visual degradation during prolonged digital work.



## The idea behind BlinkNotch

BlinkNotch does not tell users to blink.

It **mirrors the missing reflex**.

- The Mac notch briefly comes alive with eyes
- The eyes perform **one slow, relaxed blink**
- Users instinctively blink along
- The UI disappears immediately

The system feels *aware*, not corrective.



## Design principles

- **Calm technology**  
  Invisible most of the time

- **Motion over instruction**  
  The animation itself is the guidance

- **Peripheral awareness**  
  Lives near the notch, not at the center of attention

- **Extreme restraint**  
  One blink, then gone



## What BlinkNotch does

- Runs silently in the background
- Appears every **10–15 minutes** (slightly randomized)
- Shows a brief eye animation (~4 seconds total)
- Performs **one slow, complete blink**
- Fades out and returns to idle



## What BlinkNotch does NOT do

- No sound
- No notifications
- No text during use
- No stats, streaks, or gamification
- No camera
- No tracking or analytics

Everything runs locally on your Mac.



## Animation behavior

**Blink timing**
- Eyes appear: ~0.5–1.0 s  
- Close: ~0.9–1.1 s  
- Closed rest: ~0.4–0.6 s  
- Open: ~1.1–1.3 s  
- Fade out: ~0.2–0.3 s  

Total visible time: ~3.5–4.0 seconds.

No squeezing. No looping. No exaggeration.



## User controls

BlinkNotch has **no settings page** by design.

Menu bar options:
- Pause (15 minutes / 1 hour / Today)
- Reminder frequency (10 / 15 / 20 minutes)
- Intensity (Subtle / Standard)
- Run at login
- Quit
- Support this project



## Privacy

BlinkNotch:
- Does not use the camera
- Does not collect data
- Does not track behavior
- Does not require internet access



## One-line summary

**BlinkNotch quietly restores a natural blink during focused work, helping protect tear stability and oil-gland health, then disappears.**
