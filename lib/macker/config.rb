# encoding: UTF-8

module Macker
  # Configuration class
  class Config
    # Initialization with default configuration.
    # @return [OpenStruct] default configuration
    def initialize
      @config = OpenStruct.new(
        # Full URL of OUI text file
        oui_full_url:    'http://standards-oui.ieee.org/oui.txt',
        # A common user agent
        user_agent:      'Mozilla/5.0 (X11; Linux x86_64; rv:54.0) Gecko/20100101 Firefox/54.0',
        # Will expire the vendors in one day
        ttl_in_seconds:  86_400,
        # Can be a string, pathname or proc
        cache:           File.expand_path(File.dirname(__FILE__) + '/../../data/oui_*.txt'),
        # Expiration can be checked manually
        auto_expiration: true
      )
    end

    # Send missing methods to the OpenStruct configuration.
    #
    # @param method [String] the missing method name
    # @param *args [Array] list of arguments of the missing method
    # @return [Object] a configuration parameter
    def method_missing(method, *args, &block)
      @config.send(method, *args, &block)
    end
  end
end
