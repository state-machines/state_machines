// Released under the MIT License.
// Copyright, 2023-2025, by Samuel Williams.

#include <ruby.h>
#include <stdio.h>
#include <assert.h>

struct IO_Event_List_Type {
};

struct IO_Event_List {
	struct IO_Event_List *head, *tail;
	struct IO_Event_List_Type *type;
};

inline static void IO_Event_List_initialize(struct IO_Event_List *list)
{
	list->head = list->tail = list;
	list->type = 0;
}

inline static void IO_Event_List_clear(struct IO_Event_List *list)
{
	list->head = list->tail = NULL;
	list->type = 0;
}

// Append an item to the end of the list.
inline static void IO_Event_List_append(struct IO_Event_List *list, struct IO_Event_List *node)
{
	assert(node->head == NULL);
	assert(node->tail == NULL);
	
	struct IO_Event_List *head = list->head;
	node->tail = list;
	node->head = head;
	list->head = node;
	head->tail = node;
}

// Prepend an item to the beginning of the list.
inline static void IO_Event_List_prepend(struct IO_Event_List *list, struct IO_Event_List *node)
{
	assert(node->head == NULL);
	assert(node->tail == NULL);
	
	struct IO_Event_List *tail = list->tail;
	node->head = list;
	node->tail = tail;
	list->tail = node;
	tail->head = node;
}

// Pop an item from the list.
inline static void IO_Event_List_pop(struct IO_Event_List *node)
{
	assert(node->head != NULL);
	assert(node->tail != NULL);
	
	struct IO_Event_List *head = node->head;
	struct IO_Event_List *tail = node->tail;
	
	head->tail = tail;
	tail->head = head;
	node->head = node->tail = NULL;
}

// Remove an item from the list, if it is in a list.
inline static void IO_Event_List_free(struct IO_Event_List *node)
{
	if (node->head && node->tail) {
		IO_Event_List_pop(node);
	}
}

// Calculate the memory size of the list nodes.
inline static size_t IO_Event_List_memory_size(const struct IO_Event_List *list)
{
	size_t memsize = 0;

	const struct IO_Event_List *node = list->tail;
	while (node != list) {
		memsize += sizeof(struct IO_Event_List);
		node = node->tail;
	}

	return memsize;
}

// Return true if the list is empty.
inline static int IO_Event_List_empty(const struct IO_Event_List *list)
{
	return list->head == list->tail;
}

// Enumerate all items in the list, assuming the list will not be modified during iteration.
inline static void IO_Event_List_immutable_each(struct IO_Event_List *list, void (*callback)(struct IO_Event_List *node))
{
	struct IO_Event_List *node = list->tail;
	
	while (node != list) {
		if (node->type)
			callback(node);
		
		node = node->tail;
	}
}
