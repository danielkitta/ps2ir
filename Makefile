# PS/2 IR adapter

PICASM = gpasm
PICLINK = gplink

PICASMFLAGS = -p12f1571

OBJECTS = main.o

all: ps2ir.hex

clean:
	-rm -f *.cod *.hex *.lst *.map *.o

.PHONY: all clean
.SUFFIXES: .asm .o

ps2ir.hex: $(OBJECTS)
	$(PICLINK) -o $@ $(OBJECTS)

$(OBJECTS): common.inc

.asm.o:
	$(PICASM) $(PICASMFLAGS) -c -o $@ $<
