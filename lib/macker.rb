# encoding: UTF-8

require 'ostruct'
require 'open-uri'
require 'macker/version'
require 'macker/config'
require 'macker/address'

# Macker namespace
module Macker
  # Invalid cache, file not found or cache empty
  class InvalidCache < StandardError; end
  # Invalid raw data, file not found or cache empty
  class InvalidRawData < StandardError; end
  # Invalid options, invalid options given to method
  class InvalidOptions < StandardError; end
  # Invalid OUI vendor, vendor not found in table
  class NotFoundOuiVendor < StandardError; end

  # Extend instance methods to class methods
  extend self

  # Proc timestamp accessor to set external timestamp
  # @param value [Time] proc timestamp
  # @return [Time] proc timestamp
  attr_accessor :proc_timestamp

  # Get the timestamp of vendor list in memory
  # @return [Time] time object or nil
  attr_reader :mem_timestamp

  # Get or initialize Macker config.
  # @return [OpenStruct] Macker configuration
  def config
    @config ||= Macker::Config.new
  end

  # Set configuration of Macker in a block.
  # @return [OpenStruct] Macker configuration
  def configure
    yield config if block_given?
  end

  # Update all OUI tables
  # @param straight [Boolean] true for straight, default is careful
  # @return [Time] timestamp of the update
  def update(straight = false)
    @prefix_table = {}
    @iso_code_table = {}
    @vendor_table = {}
    vendor_list(straight)
    @mem_timestamp = if config.cache.is_a?(Proc)
                       proc_timestamp
                     else
                       file_timestamp
                     end
  end

  # Lookup for a vendor with given MAC address.
  #
  # @example
  #   lookup('00:04:A9:6D:B8:AC')
  #   lookup(20022409388)
  #
  # @param mac [Address,Integer,String] MAC address
  # @param opts [Hash] options for the method
  # @return [Address] MAC address with vendor data
  def lookup(mac, opts = {})
    expire! if config.auto_expiration
    data = prefix_table[Address.new(mac).prefix]
    if data.nil?
      opts[:raising] ? raise(NotFoundOuiVendor, "OUI not found for MAC: #{mac}") : (return nil)
    end
    Address.new(mac, data)
  end

  # Lookup for a vendor with given MAC address.
  # Raises an error if no vendor found.
  #
  # @example
  #   lookup!('00:04:A9:6D:B8:AC')
  #   lookup!('80:47:FB:B2:9E:D6')
  #
  # @param mac [Address,Integer,String] MAC address
  # @return [Address] MAC address with vendor data
  def lookup!(mac)
    lookup(mac, raising: true)
  end

  # Generate a MAC address.
  # - No options for random MAC.
  # - Vendor option to get a valid OUI MAC.
  # - Vendor Name option to get a random MAC from vendor.
  #
  # @example
  #   generate
  #   generate(vendor: true)
  #   generate(vendor: 'IEEE Registration Authority')
  #
  # @param opts [Hash] options for the method
  # @return [Address] MAC address with data
  def generate(opts = {})
    expire! if config.auto_expiration
    return generate_by_iso_code(opts.delete(:iso_code).upcase, opts) if opts[:iso_code]
    vendor = opts.delete(:vendor)
    case vendor
    when nil, false
      Address.new(rand(2**48))
    when true
      generate_by_vendor(prefix_table[prefix_table.keys.shuffle.sample][:name], opts)
    when String
      generate_by_vendor(vendor, opts)
    else
      raise(InvalidOptions, "Incompatible option vendor for generate: #{vendor.class}")
    end
  end

  # Generate a MAC address.
  # - No options for random MAC address.
  # - Vendor option to get a valid OUI MAC address.
  # - Vendor name option to get a random MAC address from vendor.
  # Raises an error if an error occurs.
  #
  # @example
  #   generate
  #   generate(vendor: true)
  #   generate(vendor: 'No vendor')
  #
  # @param opts [Hash] options for the method
  # @return [Address] MAC address with vendor data
  def generate!(opts = {})
    generate(opts.merge(raising: true))
  end

  # Vendor table with all base16 MAC prefixes as keys
  # @return [Hash] vendor prefixes table
  def prefix_table
    update unless @prefix_table
    @prefix_table
  end

  # Vendor table with all country iso codes as keys
  # @return [Hash] vendor iso codes table
  def iso_code_table
    update unless @iso_code_table
    @iso_code_table
  end

  # Vendor table with all country vendor names as keys
  # @return [Hash] vendor names table
  def vendor_table
    update unless @vendor_table
    @vendor_table
  end

  # Fetch new vendor list if cached list is expired or stale
  # @return [Boolean] true if vendor list is expired and updated from remote
  def expire!
    if expired?
      update(true)
      true
    elsif stale?
      update
      true
    else
      false
    end
  end

  # Check if vendor list is expired
  # @return [Boolean] true if vendor list is expired
  def expired?
    Time.now > vendors_expiration
  end

  # Check if vendor list is stale
  # Stale is true if vendor list is updated straight by another thread.
  # The actual thread has always old vendor list in memory store.
  # @return [Boolean] true if vendor list is stale
  def stale?
    if config.cache.is_a?(Proc)
      proc_timestamp != mem_timestamp
    else
      file_timestamp != mem_timestamp
    end
  end

  # Get vendor list expiration time based on ttl
  # @return [Time] vendor list expiration time
  def vendors_expiration
    if config.cache.is_a?(Proc)
      proc_timestamp + config.ttl_in_seconds
    else
      file_timestamp + config.ttl_in_seconds
    end
  end

  protected

  # Generate a MAC address by vendor.
  #
  # @param vendor [String] name of vendor
  # @param opts [Hash] options for the method
  # @return [Address] MAC address with vendor data
  def generate_by_vendor(vendor, opts = {})
    ouis = vendor_table[vendor]
    if ouis.nil? || ouis.empty?
      opts[:raising] ? raise(NotFoundOuiVendor, "OUI not found for vendor: #{vendor}") : (return nil)
    end
    oui = ouis[rand(ouis.size)]
    m1 = Address.new(oui[:prefix]).to_i
    m2 = rand(2**24)
    mac = m1 + m2
    Address.new(mac,
                name: vendor,
                address: oui[:address],
                iso_code: oui[:iso_code])
  end

  # Generate a MAC address by iso code.
  #
  # @param iso_code [String] iso code
  # @param opts [Hash] options for the method
  # @return [Address] MAC address with vendor data
  def generate_by_iso_code(iso_code, opts = {})
    ouis = iso_code_table[iso_code]
    if ouis.nil? || ouis.empty?
      opts[:raising] ? raise(NotFoundOuiVendor, "OUI not found for iso code #{iso_code}") : (return nil)
    end
    oui = ouis[rand(ouis.size)]
    m1 = Address.new(oui[:prefix]).to_i
    m2 = rand(2**24)
    mac = m1 + m2
    Address.new(mac,
                name: oui[:name],
                address: oui[:address],
                iso_code: iso_code)
  end

  # Get vendor list with different strategies.
  # Parse and read in the content.
  #
  # @example
  #   vendor_list(true)
  #   vendor_list
  #
  # @param straight [Boolean] true for straight, default is careful
  # @return [Hash] vendor list with all base16 MAC prefixes as keys
  def vendor_list(straight = false)
    raw_vendor_list = if straight
                        raw_vendor_list_straight
                      else
                        raw_vendor_list_careful
                      end
    vendor_list = raw_vendor_list.gsub(/\r\n/, "\n").gsub(/\t+/, "\t").split(/\n\n/)
    vendor_list[1..-1].each do |vendor|
      base16_fields = vendor.strip.split("\n")[1].split("\t")
      mac_prefix = Address.new(base16_fields[0].strip[0..5]).prefix
      address = vendor.strip.delete("\t").split("\n")
      iso_code = address[-1].strip
      next unless @prefix_table[mac_prefix].nil?
      @prefix_table[mac_prefix] = add_vendor(base16_fields, address, iso_code)
    end
    @iso_code_table = hash_invert(@prefix_table, :iso_code)
    @vendor_table = hash_invert(@prefix_table, :name)
    @prefix_table
  end

  # Get raw vendor list from cache and then from url
  # @param rescue_straight [Boolean] true for rescue straight, default true
  # @return [String] text content
  def raw_vendor_list_careful(rescue_straight = true)
    res = read_from_cache
    raise if res.to_s.empty?
    res
  rescue
    rescue_straight ? raw_vendor_list_straight : ''
  end

  # Get raw vendor list from url
  # @return [String] text content
  def raw_vendor_list_straight
    res = read_from_url
    raise if res.to_s.empty?
    res
  rescue
    raw_vendor_list_careful(false)
  end

  # Store the provided text data by calling the proc method provided
  # for the cache, or write to the cache file.
  #
  # @example
  #   store_in_cache("E0-43-DB  (hex)      Shenzhen ViewAt Technology Co.,Ltd.
  #                   E043DB    (base 16)  Shenzhen ViewAt Technology Co.,Ltd.
  #                                        9A,Microprofit,6th Gaoxin South...
  #                                        shenzhen  guangdong  518057
  #                                        CN
  #                  ")
  #
  # @param text [String] text content
  # @return [Integer] normally 0
  def store_in_cache(text)
    if config.cache.is_a?(Proc)
      config.cache.call(text)
    elsif config.cache.is_a?(String) || config.cache.is_a?(Pathname)
      write_to_file(text)
    end
  end

  # Writes content to file cache
  # @param text [String] text content
  # @return [Integer] normally 0
  def write_to_file(text)
    open(file_path, 'w') do |f|
      f.write(text)
    end
    file_update
  rescue Errno::ENOENT
    raise InvalidCache
  end

  # Read from cache when exist
  # @return [Proc,String] text content
  def read_from_cache
    if config.cache.is_a?(Proc)
      config.cache.call(nil)
    elsif (config.cache.is_a?(String) || config.cache.is_a?(Pathname)) &&
          File.exist?(file_path)
      open(file_path).read
    end
  end

  # Get remote content and store in cache
  # @return [String] text content
  def read_from_url
    text = open_url.force_encoding(Encoding::UTF_8)
    store_in_cache(text) if text && config.cache
    text
  end

  # Opens an URL and reads the content
  # @return [String] text content
  def open_url
    opts = [config.oui_full_url]
    opts << { 'User-Agent' => config.user_agent } if config.user_agent
    open(*opts).read
  rescue OpenURI::HTTPError
    ''
  end

  # Get file path with timestamp
  # @return [String] file path
  def file_path
    Dir.glob(config.cache).first || File.join(File.dirname(config.cache),
                                              File.basename(config.cache).gsub(/_.+\.txt/, '_0.txt'))
  end

  # Get file name with timestamp
  # @return [String] file name
  def file_name
    File.basename(file_path)
  end

  # Get file timestamp
  # @return [Time] file timestamp
  def file_timestamp
    timestamp = file_name.scan(/\d+/).first
    timestamp ? Time.at(timestamp.to_i) : Time.at(0)
  end

  # Update file name timestamp
  # @return [Integer] normally 0
  def file_update
    File.rename(file_path,
                File.join(File.dirname(file_path),
                          File.basename(file_path).gsub(/_\d+\.txt/, "_#{Time.now.to_i}.txt")))
  end

  private

  # Invert hash with given key to use.
  # @param hash [Hash] source hash
  # @param new_key [Symbol] key for the inverted hash
  # @return [Hash] inverted hash
  def hash_invert(hash, new_key)
    hash.each_with_object({}) { |(key, value), out| (out[value[new_key]] ||= []) << value.merge(prefix: key) }
  end

  # Perform vendor hash
  # @param base16_fields [Array] preifx and name field line
  # @param address [Array] address lines
  # @param iso_code [String] last line, iso code
  # @return [Hash] new vendor
  def add_vendor(base16_fields, address, iso_code)
    { name: base16_fields[-1]
        .strip
        .gsub(/\s+/, ' ')
        .gsub(/[,;](?![\s])/, ', ')
        .gsub(/[,;]+$/, '')
        .sub(/^./, &:upcase),
      address: address[2..-1].map { |a| a
        .strip
        .gsub(/\s+/, ' ')
        .gsub(/[,;](?![\s])/, ', ')
        .gsub(/[,;]+$/, '')
        .sub(/^./, &:upcase)
      },
      iso_code: iso_code.length == 2 ? iso_code.upcase : nil
    }
  end
end
