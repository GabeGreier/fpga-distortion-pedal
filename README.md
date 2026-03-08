# FPGA Distortion Pedal
This project is a simple real-time digital distortion effect implemented on the **Altera DE2-115 FPGA**.  
The goal is to take an audio signal, apply digital distortion, and output the processed signal.  

## Hardware Used
- Altera DE2-115 FPGA board  
- WM8731 audio codec (onboard)  
- Guitar or audio source  
- Preamp/DI box (ex: NUX MG300) for line-level input  
- 3.5mm line-in / line-out cables


## Notes
All development is done in **Verilog** using **Quartus**.  
Some of the codec implementation, aswell as lcd screen was written with AI. I take full responsibility for the code and use of AI in my projects.


## Installing Icarus Verilog (iverilog)
Use one of the following, depending on your OS:

- Ubuntu / Debian:
  ```bash
  sudo apt update
  sudo apt install -y iverilog
  ```
- Fedora:
  ```bash
  sudo dnf install -y iverilog
  ```
- Arch Linux:
  ```bash
  sudo pacman -S iverilog
  ```
- macOS (Homebrew):
  ```bash
  brew install icarus-verilog
  ```

Verify install:
```bash
iverilog -V
```

Quick syntax check for this project:
```bash
iverilog -g2005-sv -t null src/dsp/distortion.v src/audio/wm8731_config.v
```
