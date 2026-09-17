# Wishbone-compatible-Laplacian-Filter-IP
A laplacian filter IP written in verilog to be used with Wishbone B4 bus protocol.

This IP is not wishbone certified. There is no documentation as of yet, I will add a wishbone datasheet in future.

I did not write the testbench because i am a lazy bum. 

Also ran a different test with an image, used a 256x256 cameraman.png. the output is attached in the files.

## FPGA Implementation & Synthesis Reports

Target Device:Nexys4DDR FPGA (Vivado Implementation)

### Resource Utilization

| Resource | Utilization | Available | Utilization % |
| :--- | :---: | :---: | :---: |
| LUT  | 89 | 63,400 | 0.14% |
| FF   | 36 | 126,800 | 0.03% |
| IO   | 84 | 210 | 40.00% |
| BUFG | 1  | 32 | 3.13% |


---

### Power & Thermal Analysis

| Parameter | Value |
| :--- | :--- |
| Total On-Chip Power | 8.936 W |
| Junction Temperature | 65.8 °C |
| Thermal Margin | 19.2 °C (4.2 W) |


