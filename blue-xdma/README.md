# Blue-XDMA

Blue-XDMA is a project written in Bluespec, which is based on Xilinx's XDMA IP core. It supports FPGA-initiated DMA transfer requests in both the C2H (Card-to-Host) and H2C (Host-to-Card) directions.

## Usage

### Simulation

To run the simulation, including both C2H and H2C directions, simply run:

```shell
make sim
```
Tip: `sim` is set as the default target in the Makefile.

### Synthesis, Place and Route, Write Bitstream

To synthesize, place and route, and generate the bitstream, run the following command:

```shell
make synth
```

## Prerequisites

- Vivado 2022.1
- Bluespec Compiler, version 2023.01 (build 52adafa5)

Please make sure that you have the above prerequisites installed and properly configured before running the commands mentioned above.

## Compatibility

This project has been tested and verified on Vivado 2022.1. We cannot guarantee its compatibility with other versions of Vivado.

## License

This project is licensed under the [MIT License](LICENSE). Feel free to use and modify the code according to your needs.

## Acknowledgements

We would like to express our gratitude to Xilinx for providing the XDMA IP core, which served as the foundation for this project.

If you have any questions or suggestions, please feel free to reach out to us. Happy coding!
