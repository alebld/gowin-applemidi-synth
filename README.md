# RTP-MIDI Synthesizer for Gowin GW2A-18 FPGA

## Overview

This repository contains the SystemVerilog source code for an RTP-MIDI AppleMIDI synthesizer designed to run on the Gowin GW2A-18 FPGA. AppleMIDI is a protocol commonly used for real-time musical instrument communication over Ethernet, making it suitable for various music production and performance applications involving far away devices. 
This project is just a proof of concept to learn how to implement various communication protocols over Ethernet, nonetheless it may be useful to those seeking to achieve similar results.

## Features

- RTP-MIDI protocol support for seamless integration with other MIDI devices and software.
- Real-time synthesis capabilities for generating musical tones and effects.
- Low-latency Ethernet communication for real-time musical applications.
- User-friendly interface for configuring and controlling the synthesizer.

## Development

The project is still a work in progress. At the moment, .
What remains to do:
- Better implementation of the AppleMIDI protocol (e.g. at the moment the synchronization between the devices is not really implemented).
- Full support of the MIDI messages (now only note on and note off without velocity are used)
- Refactoring of most parts of the code which at the moment are not very readable.
- Better sound synthesis.

## Acknowledgments

This projects is based on the [URP and ARP implementation on the same board](https://github.com/sipeed/TangPrimer-20K-example/tree/main/Ethernet/verilog_UDP).
