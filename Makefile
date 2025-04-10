

RISCV_GNU_TOOLCHAIN_INSTALL_PREFIX = /opt/riscv32

# Give the user some easy overrides for local configuration quirks.
# If you change one of these and it breaks, then you get to keep both pieces.

PYTHON = python3
VERILATOR = verilator


#TEST_OBJS = $(addsuffix .o,$(basename $(wildcard tests/*.S)))
FIRMWARE_OBJS = firmware/start.o firmware/irq.o firmware/print.o firmware/hello.o firmware/sieve.o firmware/multest.o firmware/stats.o firmware/mulfun.o

TOOLCHAIN_PREFIX = $(RISCV_GNU_TOOLCHAIN_INSTALL_PREFIX)i/bin/riscv32-unknown-elf-
COMPRESSED_ISA = C

# Add things like "export http_proxy=... https_proxy=..." here

test_verilator: testbench_verilator firmware/firmware.hex
	./testbench_verilator


testbench_verilator: testbench.v picorv32.v testbench.cc
	$(VERILATOR) --cc --exe -Wno-lint -trace -CFLAGS "-DVL_STACK=10485760" --top-module picorv32_wrapper testbench.v picorv32.v testbench.cc \
			$(subst C,-DCOMPRESSED_ISA,$(COMPRESSED_ISA)) --Mdir testbench_verilator_dir
	$(MAKE) -C testbench_verilator_dir -f Vpicorv32_wrapper.mk
	cp testbench_verilator_dir/Vpicorv32_wrapper testbench_verilator

firmware/firmware.hex: firmware/firmware.bin firmware/makehex.py
	$(PYTHON) firmware/makehex.py $< 32768 > $@

firmware/firmware.bin: firmware/firmware.elf
	$(TOOLCHAIN_PREFIX)objcopy -O binary $< $@
	chmod -x $@

firmware/firmware.elf: $(FIRMWARE_OBJS)  firmware/sections.lds
	$(TOOLCHAIN_PREFIX)gcc -Os -mabi=ilp32 -march=rv32im$(subst C,c,$(COMPRESSED_ISA)) -ffreestanding -nostdlib -o $@ \
		-Wl,--build-id=none,-Bstatic,-T,firmware/sections.lds,-Map,firmware/firmware.map,--strip-debug \
		$(FIRMWARE_OBJS)  -lgcc
	chmod -x $@

firmware/start.o: firmware/start.S     #把start.s编译成start.o
	$(TOOLCHAIN_PREFIX)gcc -c -mabi=ilp32 -march=rv32im$(subst C,c,$(COMPRESSED_ISA)) -o $@ $<

firmware/%.o: firmware/%.c				#把固件中的.c文件编译成.o文件
	$(TOOLCHAIN_PREFIX)gcc -c -mabi=ilp32 -march=rv32i$(subst C,c,$(COMPRESSED_ISA)) -Os --std=c99 $(GCC_WARNS) -ffreestanding -nostdlib -o $@ $<

