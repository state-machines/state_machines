// Released under the MIT License.
// Copyright, 2021-2025, by Samuel Williams.

#pragma once

#include <ruby.h>

#define IO_EVENT_SELECTOR_URING

void Init_IO_Event_Selector_URing(VALUE IO_Event_Selector);
