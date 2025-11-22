# FPGA Distortion Pedal
This project is a simple real-time digital distortion effect implemented on the **Altera DE2-115 FPGA**.  
The goal is to take an audio signal, apply digital distortion, and output the processed signal.  
This will later be expanded with multiple distortion presets.

## Current Goals
- Understand the DE2-115 audio signal path (WM8731 CODEC)
- Build clean audio passthrough (input → FPGA → output)
- Implement a basic digital distortion effect
- Add the ability to switch between multiple distortion styles (presets)
- Test using a guitar → preamp (NUX MG300) → FPGA line-in

## Repository Structure
fpga-distortion-pedal/
│
├── README.md
├── src/ # Verilog source files
├── test/ # Testbenches and simulations
└── docs/ # Notes, diagrams, and design planning

## Hardware Used
- Altera DE2-115 FPGA board  
- WM8731 audio codec (onboard)  
- Guitar or audio source  
- Preamp/DI box (ex: NUX MG300) for line-level input  
- 3.5mm line-in / line-out cables

## Project Status
- [X] Repository initialized  
- [X] Documentation started  
- [ ] Audio passthrough (pending)  
- [ ] First distortion effect (pending)  
- [ ] Preset switching (planned)

## Notes
All development is done in **Verilog** using **Quartus** and **ModelSim**.  
Most work (DSP modules, planning, simulation) can be done without the FPGA; hardware testing will occur later on the DE2-115.

