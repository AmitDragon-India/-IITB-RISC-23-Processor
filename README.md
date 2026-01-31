# IITB-RISC-23-Processor

# IITB-RISC-23: 6-Stage Pipelined RISC Processor (SystemVerilog)

This repository contains a **6-stage in-order pipelined RISC processor**
implemented in **SystemVerilog**, based on the IIT Bombay RISC ISA
(IITB-RISC-23).

The design includes **data forwarding, load-use hazard detection,
pipeline stalling, and correct register file behavior**, verified using
**ModelSim / Quartus Prime**.

---

## ✨ Features

- 6-stage pipelined architecture
- 16-bit RISC ISA
- 8 general-purpose registers (R0–R7)
- R0 is **not** special (no PC aliasing)
- Separate instruction and data memory
- Fully working:
  - ALU forwarding
  - Load-use hazard handling
  - Store-data forwarding
  - Branch resolution in EX stage

---

## 🧠 Pipeline Architecture (6 Stages)

| Stage | Name | Description |
|------|------|------------|
| IF | Instruction Fetch | Fetch instruction from instruction memory |
| ID | Instruction Decode | Decode opcode and extract fields |
| RF | Register Fetch | Read register operands and generate immediates |
| EX | Execute | ALU operations, branch resolution, address calc |
| MEM | Memory | Data memory access (LW / SW) |
| WB | Write Back | Write result to register file |

---

## 🔁 Data Hazard Handling

### Forwarding Unit

A dedicated forwarding unit resolves RAW hazards using:

- EX/MEM pipeline register
- MEM/WB pipeline register

**Priority:**


Forwarding supports:
- ALU → ALU
- LLI → ALU
- Store data forwarding
- ALU → Store
- WB → EX

Load results are forwarded **only from MEM/WB** (never EX/MEM).

---

## ⏸️ Load-Use Hazard Handling

Classic load-use case:

```asm
LW  R3, [R2]
ADD R4, R3, R1

Behavior

Load in EX stage

Dependent instruction in RF stage

Pipeline stalls for 1 cycle

RF/EX stage is flushed

Execution resumes with correct forwarded data

🧾 Register File Design

8 × 16-bit registers

Combinational read ports

Synchronous write port

Reset clears all registers

This ensures correct interaction with forwarding and WB stage.

🧪 Verification

Simulated using:

ModelSim (via Quartus Prime)

Tested Scenarios

Independent instructions

ALU forwarding

Load-use hazard (stall + forward)

Store followed by load

WB and EX/MEM forwarding correctness


