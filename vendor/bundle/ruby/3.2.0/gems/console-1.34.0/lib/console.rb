# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2025, by Samuel Williams.
# Copyright, 2019, by Bryan Powell.
# Copyright, 2020, by Michael Adams.
# Copyright, 2021, by Cédric Boutillier.

require_relative "console/version"
require_relative "console/interface"

# @namespace
module Console
	Console.extend(Interface)
end
