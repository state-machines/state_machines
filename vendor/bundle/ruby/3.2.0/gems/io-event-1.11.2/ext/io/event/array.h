// Released under the MIT License.
// Copyright, 2023, by Samuel Williams.

// Provides a simple implementation of unique pointers to elements of the given size.

#include <ruby.h>
#include <stdlib.h>
#include <errno.h>
#include <assert.h>

static const size_t IO_EVENT_ARRAY_MAXIMUM_COUNT = SIZE_MAX / sizeof(void*);
static const size_t IO_EVENT_ARRAY_DEFAULT_COUNT = 128;

struct IO_Event_Array {
	// The array of pointers to elements:
	void **base;
	
	// The allocated size of the array:
	size_t count;
	
	// The biggest item we've seen so far:
	size_t limit;
	
	// The size of each element that is allocated:
	size_t element_size;
	
	void (*element_initialize)(void*);
	void (*element_free)(void*);
};

inline static int IO_Event_Array_initialize(struct IO_Event_Array *array, size_t count, size_t element_size)
{
	array->limit = 0;
	array->element_size = element_size;
	
	if (count) {
		array->base = (void**)calloc(count, sizeof(void*));
		
		if (array->base == NULL) {
			return -1;
		}
		
		array->count = count;
		
		return 1;
	} else {
		array->base = NULL;
		array->count = 0;
		
		return 0;
	}
}

inline static size_t IO_Event_Array_memory_size(const struct IO_Event_Array *array)
{
	// Upper bound.
	return array->count * (sizeof(void*) + array->element_size);
}

inline static void IO_Event_Array_free(struct IO_Event_Array *array)
{
	if (array->base) {
		void **base = array->base;
		size_t limit = array->limit;
		
		array->base = NULL;
		array->count = 0;
		array->limit = 0;
		
		for (size_t i = 0; i < limit; i += 1) {
			void *element = base[i];
			if (element) {
				array->element_free(element);
				
				free(element);
			}
		}
		
		free(base);
	}
}

inline static int IO_Event_Array_resize(struct IO_Event_Array *array, size_t count)
{
	if (count <= array->count) {
		// Already big enough:
		return 0;
	}
	
	if (count > IO_EVENT_ARRAY_MAXIMUM_COUNT) {
		errno = ENOMEM;
		return -1;
	}
	
	size_t new_count = array->count;
	
	// If the array is empty, we need to set the initial size:
	if (new_count == 0) new_count = IO_EVENT_ARRAY_DEFAULT_COUNT;
	else while (new_count < count) {
		// Ensure we don't overflow:
		if (new_count > (IO_EVENT_ARRAY_MAXIMUM_COUNT / 2)) {
			new_count = IO_EVENT_ARRAY_MAXIMUM_COUNT;
			break;
		}
		
		// Compute the next multiple (ideally a power of 2):
		new_count *= 2;
	}
	
	void **new_base = (void**)realloc(array->base, new_count * sizeof(void*));
	
	if (new_base == NULL) {
		return -1;
	}
	
	// Zero out the new memory:
	memset(new_base + array->count, 0, (new_count - array->count) * sizeof(void*));
	
	array->base = (void**)new_base;
	array->count = new_count;
	
	// Resizing sucessful:
	return 1;
}

inline static void* IO_Event_Array_lookup(struct IO_Event_Array *array, size_t index)
{
	size_t count = index + 1;
	
	// Resize the array if necessary:
	if (count > array->count) {
		if (IO_Event_Array_resize(array, count) == -1) {
			return NULL;
		}
	}
	
	// Get the element:
	void **element = array->base + index;
	
	// Allocate the element if it doesn't exist:
	if (*element == NULL) {
		*element = malloc(array->element_size);
		assert(*element);
		
		if (array->element_initialize) {
			array->element_initialize(*element);
		}
		
		// Update the limit:
		if (count > array->limit) array->limit = count;
	}
	
	return *element;
}

inline static void* IO_Event_Array_last(struct IO_Event_Array *array)
{
	if (array->limit == 0) return NULL;
	else return array->base[array->limit - 1];
}

inline static void IO_Event_Array_truncate(struct IO_Event_Array *array, size_t limit)
{
	if (limit < array->limit) {
		for (size_t i = limit; i < array->limit; i += 1) {
			void **element = array->base + i;
			if (*element) {
				array->element_free(*element);
				free(*element);
				*element = NULL;
			}
		}
		
		array->limit = limit;
	}
}

// Push a new element onto the end of the array.
inline static void* IO_Event_Array_push(struct IO_Event_Array *array)
{
	return IO_Event_Array_lookup(array, array->limit);
}

inline static void IO_Event_Array_each(struct IO_Event_Array *array, void (*callback)(void*))
{
	for (size_t i = 0; i < array->limit; i += 1) {
		void *element = array->base[i];
		if (element) {
			callback(element);
		}
	}
}
