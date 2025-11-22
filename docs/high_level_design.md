# High Level Design

## Goal
- Take in an analog audio signal
- Convert it to digital through the WM8731 audio codec
- Apply digital distortion (clipping) on the FPGA
- Output the processed audio back through the codec
- Support multiple distortion presets selectable by switches

---

## System Signal Flow

**Analog Input** → WM8731 **ADC** → **FPGA Processing** → WM8731 **DAC** → **Analog Output**

This defines the entire audio path.  
All DSP work happens inside the FPGA between the ADC and DAC sample streams.

---

## FPGA Digital Signal Path

`ADC Sample` → **Distortion Module** → `DAC Sample`

This is the minimal DSP chain.  
Later versions will branch this into multiple distortion styles/presets.

---

## Part 1 — Audio Interface (WM8731)

Responsibilities:
- Communicate with the WM8731 audio codec  
- Receive 16-bit audio samples from the ADC  
- Send 16-bit audio samples to the DAC  
- Handle audio clocking and I²S protocol  
- Use existing student template / DE2-115 example code as a starting point  

This component enables digital audio flow and must be working before DSP is tested.

---

## Part 2 — Clean Passthrough

Milestone:
- Forward ADC samples directly to the DAC with no processing
- Confirm clean, low-latency, noise-free audio through the system
- Verify correct sample timing and channel alignment

This must be completed before adding distortion.

---

## Part 3 — FPGA DSP (Distortion)

### Stage 1 — Basic Distortion
- Implement `hard_clip(x)`  
- Test using simulation and hardware

### Stage 2 — Multiple Presets
Use a preset selector to choose different clipping functions:

switch(preset) {
case 0: hard_clip(x)
case 1: soft_clip(x)
case 2: asym_clip(x)
case 3: metal_clip(x)
...
}

Each preset implements a different nonlinear shaping curve.

---

## Part 4 — Preset Mapping

- Map FPGA switches (e.g., `SW[2:0]`) to a preset index
- Switch selection updates the active distortion mode in real time
- Allows instant switching between distortion styles during testing

---
