# PS/2-IR
IR Remote Control to PS/2 Keyboard Adapter

## Introduction

PS/2-IR is a receiver for infrared remote controls masquerading as a standard
PS/2 computer keyboard. With this small and cheap device, one can use a common
TV/DVD/SAT or universal remote control to control a desktop computer or HTPC.

Although any wireless input device may be used to control a media center PC,
few if any can be used to actually power on the computer. This is where PS/2-IR
comes in. Although the PS/2 port is a legacy interface, with many mainboards it
is the only option that allows the computer to be powered on via the keyboard.
Another advantage is that it can reliably be used to navigate the BIOS setup
or a bootloader menu.

The PS/2-IR adapter supports any infrared remote control using the common NEC
or Extended NEC protocol with a carrier frequency of 38 kHz. Any IR function
code sent by the remote can be mapped to an arbitrary PC keyboard scancode.
Mainboards that support power-on by PS/2 keyboard will boot up the system in
response to the ACPI Power On scancode.

## Hardware

The PS/2-IR adapter is based on the tiny Microchip PIC12F1571 microcontroller.
Although relatively recent, it is one of the cheapest 8-bit microcontrollers
on the market and very easily available.

The infrared sensor is a standard TSOP4838 with integrated pre-amplifier and
demodulator. Its power input is connected through a simple RC filter.

The complete circuit is powered directly from the 5V line the PS/2 interface,
with just two bypass capacitors added. Although nominally 5V, it should also
work just fine with non-standard 3.3V PS/2 interfaces.

The layout fits comfortably on a tiny and cheap 32x30mm 2-layer PCB. Mounted
in a translucent case, the device does not even need an opening for the IR
sensor.

## Firmware

The firmware is written exclusively in assembler. Components are implemented
in separate source files, and assembled into relocatable objects combined by
the linker. The GNU PIC assembler was used for development, but MPASM should
work as well.

The IR decoder is completely interrupt driven, making use of a hardware timer
to measure pulse duration. The internal low-power RC oscillator is used to
clock the timer, which allows the device to go to sleep during measurements.
In order to cope with the low accuracy of the uncalibrated RC oscillator, the
bit detection allows for fairly large tolerances in timing. This also helps
to ensure compatibility with various models of remote controls.

The PS/2 synchronous serial I/O is implemented in software, by bit-banging
tri-state GPIO pins. Transmission is done at a clock rate of 25 kHz, using
busy delay loops to control the signal timing, with compensation for cycles
spent by sourrounding instructions. The CPU clock rate of 4 MHz has been
selected to minimize the number of delay cycles needed. During bus idle time,
a pin change interrupt is set up to detect host requests, allowing the CPU to
be powered off.

The PC keyboard control state, command protocol and scancode generation are
implemented in a separate component, layered on top of the serial communication
interface. Although this firmware implements only a subset of the PC keyboard
functionality, all standard control commands are recognized and will elicit
a response in the expected format. Most commands which control unavailable
functionality are silently ignored. One exception is the command to select the
scancode set, which will be responded to with an error code if an attempt is
made to set a scancode set other than set 2.

A look-up table with 256 positions is used to map IR function codes to
PC keyboard scancodes. This table is defined in its own separate source
file so it can easily be exchanged for another, enabling different types
of remote controls to be supported with minimal changes. In addition to
the function code mapping, this remote control definition file also sets
the device address used by the remote.

In addition to the base scancode, each entry in the look-up table also allows
for various bits to configure the scancode type type, whether to send break
codes on key release, and which modifier key scancodes to send along with the
base scancode.
