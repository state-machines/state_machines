# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2021, by Wander Hillen.
# Copyright, 2021-2024, by Samuel Williams.

class IO
	module Event
		# A priority queue implementation using a standard binary minheap. It uses straight comparison
		# of its contents to determine priority.
		# See <https://en.wikipedia.org/wiki/Binary_heap> for explanations of the main methods.
		class PriorityHeap
			# Initializes the heap.
			def initialize
				# The heap is represented with an array containing a binary tree. See
				# https://en.wikipedia.org/wiki/Binary_heap#Heap_implementation for how this array
				# is built up.
				@contents = []
			end
			
			# @returns [Object | Nil] the smallest element in the heap without removing it, or nil if the heap is empty.
			def peek
				@contents[0]
			end
			
			# @returns [Integer] the number of elements in the heap.
			def size
				@contents.size
			end
			
			# Removes and returns the smallest element in the heap, or nil if the heap is empty.
			#
			# @returns [Object | Nil] The smallest element in the heap, or nil if the heap is empty.
			def pop
				# If the heap is empty:
				if @contents.empty?
					return nil
				end
				
				# If we have only one item, no swapping is required:
				if @contents.size == 1
					return @contents.pop
				end
				
				# Take the root of the tree:
				value = @contents[0]
				
				# Remove the last item in the tree:
				last = @contents.pop
				
				# Overwrite the root of the tree with the item:
				@contents[0] = last
				
				# Bubble it down into place:
				bubble_down(0)
				
				# validate!
				
				return value
			end
			
			# Add a new element to the heap, then rearrange elements until the heap invariant is true again.
			#
			# @parameter element [Object] The element to add to the heap.
			def push(element)
				# Insert the item at the end of the heap:
				@contents.push(element)
				
				# Bubble it up into position:
				bubble_up(@contents.size - 1)
				
				# validate!
				
				return self
			end
			
			# Empties out the heap, discarding all elements
			def clear!
				@contents = []
			end
			
			# Validate the heap invariant. Every element except the root must not be smaller than its parent element. Note that it MAY be equal.
			def valid?
				# Notice we skip index 0 on purpose, because it has no parent
				(1..(@contents.size - 1)).all? { |e| @contents[e] >= @contents[(e - 1) / 2] }
			end
			
			private
			
			# Left here for reference, but unused.
			# def swap(i, j)
			# 	@contents[i], @contents[j] = @contents[j], @contents[i]
			# end
			
			def bubble_up(index)
				parent_index = (index - 1) / 2 # watch out, integer division!
				
				while index > 0 && @contents[index] < @contents[parent_index]
					# If the node has a smaller value than its parent, swap these nodes to uphold the minheap invariant and update the index of the 'current' node. If the node is already at index 0, we can also stop because that is the root of the heap.
					# swap(index, parent_index)
					@contents[index], @contents[parent_index] = @contents[parent_index], @contents[index]
					
					index = parent_index
					parent_index = (index - 1) / 2 # watch out, integer division!
				end
			end
			
			def bubble_down(index)
				swap_value = 0
				swap_index = nil
				
				while true
					left_index = (2 * index) + 1
					left_value = @contents[left_index]
					
					if left_value.nil?
						# This node has no children so it can't bubble down any further. We're done here!
						return
					end
					
					# Determine which of the child nodes has the smallest value:
					right_index = left_index + 1
					right_value = @contents[right_index]
					
					if right_value.nil? or right_value > left_value
						swap_value = left_value
						swap_index = left_index
					else
						swap_value = right_value
						swap_index = right_index
					end
					
					if @contents[index] < swap_value
						# No need to swap, the minheap invariant is already satisfied:
						return
					else
						# At least one of the child node has a smaller value than the current node, swap current node with that child and update current node for if it might need to bubble down even further:
						# swap(index, swap_index)
						@contents[index], @contents[swap_index] = @contents[swap_index], @contents[index]
						
						index = swap_index
					end
				end
			end
		end
	end
end
