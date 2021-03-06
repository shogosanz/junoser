require 'junoser/display/set'
require 'junoser/display/structure'

module Junoser
  module Display
    class << self
      def display_set?(str)
        str =~ /\Aset|deactivate/
      end

      def structured?(str)
        !display_set?(str)
      end
    end
  end
end
