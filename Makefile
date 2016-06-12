# PS/2 IR adapter project

PICASM = gpasm
PICLINK = gplink

PROCESSOR = 12f1571
PICASMFLAGS = -p $(PROCESSOR)
PICLINKFLAGS = -O2 -m -s $(PROCESSOR).lkr

OBJECTS = irdecode.o keyboard.o keycodes.o main.o ps2io.o util.o

all: ps2ir.hex

clean:
	-rm -f *.cod *.hex *.lst *.map *.o

.PHONY: all clean
.SUFFIXES: .asm .o

ps2ir.hex: $(OBJECTS)
	$(PICLINK) $(PICLINKFLAGS) -o $@ $(OBJECTS)

$(OBJECTS): common.inc
keyboard.o keycodes.o: keycodes.inc
ps2io.o: util.inc

.asm.o:
	$(PICASM) $(PICASMFLAGS) -c -o $@ $<
