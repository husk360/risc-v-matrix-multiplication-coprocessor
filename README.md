


# Introduction  


This project designs a matrix multiplication accelerator based on the RISC-V instruction set. This accelerator can be used as a coprocessor for the open-source project PicoRV32 processor and can implement matrix multiplication through custom instructions.  


A total of 4 instructions have been customized in this project, `picorv32_coprocessor_load(_rs2, _rs1)`
used to load data from the CPU into the coprocessor;
`picorv32_coprocessor_weight()` is used to load the cached data in the coprocessor into the weights needed in the calculation; `picorv32_coprocessor_compute()` is used for matrix multiplication of the cached data and weights in the coprocessor;
`picorv32_coprocessor_read(_rd, _rs)` is used to read data from the coprocessor into the CPU.
They are also respectively packaged as C language functions, namely



```
void hard_load(uint32_t a, uint32_t b);
void hard_weight_load();
void hard_compute();
uint32_t hard_read(uint32_t a);
```

In the `define.v`, the size for matrix multiplication and the size of the data can be configured. The main function of the C language running on the CPU is `mulfun.c`, in which a calculation of 12*12 matrix multiplication has already been defined. 


All the following running processes are completed under the Ubuntu 22.04.5 LTS  


# How to run it  

In order to run this project, it is necessary to install the relevant dependencies and toolchains first.


```
sudo apt-get install autoconf automake autotools-dev curl libmpc-dev \
        libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo \
    gperf libtool patchutils bc zlib1g-dev git libexpat1-dev
```



Then use



```
make download-tools  
make -j$(nproc) build-tools  
```

After all the toolchains have been installed, this project can be run. If tool chain installation on the problems, it is suggested that visit PicoRV32 original project at https://github.com/YosysHQ/picorv32

You can directly enter `make` in the terminal to run the program. If you want to view the waveform, you need to complete the simulation and then enter `gtkwave waveform.vcd`,provided that gtkwave is installed on your computer.