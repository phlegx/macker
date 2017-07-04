# encoding: UTF-8

# Macker namespace
module Macker
  # Invalid address, mac address format not valid
  class InvalidAddress < StandardError; end
  # MAC address class
  class Address
    include Comparable

    # Get the value of name, address or iso code
    # @return [String] content of the value
    attr_reader :name, :address, :iso_code

    # Initialize Address object
    # @param mac [Address,Integer,String] a MAC address
    # @param opts [Hash] options for the method
    # @return [Address] the initialized object
    def initialize(mac, opts = {})
      case mac
      when Address
        @val      = mac.to_i
        @name     = mac.name
        @address  = mac.address
        @iso_code = mac.iso_code
      when Integer
        @val = mac
      when String
        @val = cleanup(mac).to_i(16)
      else
        raise(InvalidAddress, "Incompatible type for address initialization: #{mac.class}")
      end
      raise(InvalidAddress, "Invalid MAC address: #{self}") unless valid?
      @name     ||= opts.fetch(:name, nil)
      @address  ||= opts.fetch(:address, nil)
      @iso_code ||= opts.fetch(:iso_code, nil)
    end

    # Format MAC address to integer
    # @return [Integer] integer MAC address
    def to_i
      @val
    end

    # Format MAC address to string
    # @param sep [String] separator, default is ':'
    # @return [String] formatted MAC address
    def to_s(sep = ':')
      @val.to_s(16)
          .rjust(12, '0')
          .insert(10, sep)
          .insert(8, sep)
          .insert(6, sep)
          .insert(4, sep)
          .insert(2, sep)
          .upcase
    end

    # Compare two MAC addresses
    # @param other [Address] MAC address object
    # @return [Boolean] true if the same, else false
    def <=>(other)
      @val <=> other.to_i
    end

    # Check if MAC address is an OUI valid address
    # @return [Boolean] true if valid, else false
    def oui?
      !@name.nil?
    end

    # Check if MAC address is a valid address
    # @return [Boolean] true if valid, else false
    def valid?
      @val.between?(0, 2**48 - 1)
    end

    # Check if MAC address is a broadcast address
    # @return [Boolean] true if broadcast, else false
    def broadcast?
      @val == 2**48 - 1
    end

    # Check if MAC address is an unicast address
    # @return [Boolean] true if unicast, else false
    def unicast?
      !multicast?
    end

    # Check if MAC address is a multicast address
    # @return [Boolean] true if multicast, else false
    def multicast?
      mask = 1 << (5 * 8)
      (mask & @val) != 0
    end

    # Check if MAC address is a global uniq address
    # @return [Boolean] true if uniq, else false
    def global_uniq?
      !local_admin?
    end

    # Check if MAC address is a local address
    # @return [Boolean] true if local, else false
    def local_admin?
      mask = 2 << (5 * 8)
      (mask & @val) != 0
    end

    # Get next MAC address from actual address
    # @return [Adress] next MAC address
    def next
      Address.new((@val + 1) % 2**48)
    end
    alias succ next

    # Get the prefix base16 MAC address
    # @return [Adress] MAC prefix
    def prefix
      to_s('')[0..5]
    end

    # Get the full vendor address
    # @return [String] full vendor address string
    def full_address
      address.join(', ')
    end

    private

    # Clean up a MAC string from special characters
    # @return [String] cleaned MAC address
    def cleanup(mac)
      mac.strip.upcase.gsub(/^0[xX]/, '').gsub(/[^0-9A-F]/, '').ljust(12, '0')
    end
  end
end
