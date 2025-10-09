// Released under the MIT License.
// Copyright, 2021-2025, by Samuel Williams.

#pragma once

#include <ruby.h>

#ifdef HAVE_SYS_EVENTFD_H
struct IO_Event_Interrupt {
	int descriptor;
};

static inline int IO_Event_Interrupt_descriptor(struct IO_Event_Interrupt *interrupt) {
	return interrupt->descriptor;
}
#else
struct IO_Event_Interrupt {
	int descriptor[2];
};

static inline int IO_Event_Interrupt_descriptor(struct IO_Event_Interrupt *interrupt) {
	return interrupt->descriptor[0];
}
#endif

void IO_Event_Interrupt_open(struct IO_Event_Interrupt *interrupt);
void IO_Event_Interrupt_close(struct IO_Event_Interrupt *interrupt);

void IO_Event_Interrupt_signal(struct IO_Event_Interrupt *interrupt);
void IO_Event_Interrupt_clear(struct IO_Event_Interrupt *interrupt);
