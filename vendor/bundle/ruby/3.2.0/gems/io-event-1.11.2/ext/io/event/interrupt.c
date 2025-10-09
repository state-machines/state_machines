// Released under the MIT License.
// Copyright, 2021-2025, by Samuel Williams.

#include "interrupt.h"
#include <unistd.h>

#include "selector/selector.h"

#ifdef HAVE_RUBY_WIN32_H
#include <ruby/win32.h>
#if !defined(HAVE_PIPE) && !defined(pipe)
#define pipe(p)	rb_w32_pipe(p)
#endif
#endif

#ifdef HAVE_SYS_EVENTFD_H
#include <sys/eventfd.h>

void IO_Event_Interrupt_open(struct IO_Event_Interrupt *interrupt)
{
	interrupt->descriptor = eventfd(0, EFD_CLOEXEC | EFD_NONBLOCK);
	rb_update_max_fd(interrupt->descriptor);
}

void IO_Event_Interrupt_close(struct IO_Event_Interrupt *interrupt)
{
	close(interrupt->descriptor);
}

void IO_Event_Interrupt_signal(struct IO_Event_Interrupt *interrupt)
{
	uint64_t value = 1;
	ssize_t result = write(interrupt->descriptor, &value, sizeof(value));
	
	if (result == -1) {
		if (errno == EAGAIN || errno == EWOULDBLOCK) return;
		
		rb_sys_fail("IO_Event_Interrupt_signal:write");
	}
}

void IO_Event_Interrupt_clear(struct IO_Event_Interrupt *interrupt)
{
	uint64_t value = 0;
	ssize_t result = read(interrupt->descriptor, &value, sizeof(value));
	
	if (result == -1) {
		if (errno == EAGAIN || errno == EWOULDBLOCK) return;
		
		rb_sys_fail("IO_Event_Interrupt_clear:read");
	}
}
#else
void IO_Event_Interrupt_open(struct IO_Event_Interrupt *interrupt)
{
#ifdef __linux__
	pipe2(interrupt->descriptor, O_CLOEXEC | O_NONBLOCK);
#else
	pipe(interrupt->descriptor);
	IO_Event_Selector_nonblock_set(interrupt->descriptor[0]);
	IO_Event_Selector_nonblock_set(interrupt->descriptor[1]);
#endif
	
	rb_update_max_fd(interrupt->descriptor[0]);
	rb_update_max_fd(interrupt->descriptor[1]);
}

void IO_Event_Interrupt_close(struct IO_Event_Interrupt *interrupt)
{
	close(interrupt->descriptor[0]);
	close(interrupt->descriptor[1]);
}

void IO_Event_Interrupt_signal(struct IO_Event_Interrupt *interrupt)
{
	ssize_t result = write(interrupt->descriptor[1], ".", 1);
	
	if (result == -1) {
		if (errno == EAGAIN || errno == EWOULDBLOCK) {
			// If we can't write to the pipe, it means the other end is full. In that case, we can be sure that the other end has already been woken up or is about to be woken up.
		} else {
			rb_sys_fail("IO_Event_Interrupt_signal:write");
		}
	}
}

void IO_Event_Interrupt_clear(struct IO_Event_Interrupt *interrupt)
{
	char buffer[128];
	ssize_t result = read(interrupt->descriptor[0], buffer, sizeof(buffer));
	
	if (result == -1) {
		if (errno == EAGAIN || errno == EWOULDBLOCK) {
			// If we can't read from the pipe, it means the other end is empty. In that case, we can be sure that the other end is already clear.
		} else {
			rb_sys_fail("IO_Event_Interrupt_clear:read");
		}
	}
}
#endif
