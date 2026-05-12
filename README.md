# I2C Master Controller

RTL Design and Verification of I2C Master Protocol using Verilog HDL.

---

## Features

- Start Condition Generation
- Stop Condition Generation
- Address Transmission
- ACK/NACK Handling
- Read Operation
- Write Operation
- FSM-Based Architecture
- Clock Generation

---

## Protocol Details

The I2C protocol uses:
- SDA → Serial Data Line
- SCL → Serial Clock Line

This project implements an I2C Master Controller capable of initiating read and write operations with slave devices.

---

## Project Structure

```text
rtl/        -> RTL source files
tb/         -> Testbench files
waveforms/  -> Simulation waveform images
docs/       -> FSM and architecture diagrams
```

---

## Simulation Tool

- Vivado XSIM
- ModelSim

---

## Verification

- Functional Verification
- ACK Verification
- Read/Write Transaction Testing
- FSM Verification

---

## Future Improvements

- Repeated Start
- Multi-byte Transfer
- Clock Stretching
- UVM Verification

---

## Author

Elina Sahoo
