# Macker (The Mac Maker)

[![Gem Version](https://badge.fury.io/rb/macker.svg)](https://rubygems.org/gems/macker)
[![Gem](https://img.shields.io/gem/dt/macker.svg)](https://rubygems.org/gems/macker)
[![Build Status](https://secure.travis-ci.org/phlegx/macker.svg?branch=master)](https://travis-ci.org/phlegx/macker)
[![Code Climate](http://img.shields.io/codeclimate/github/phlegx/macker.svg)](https://codeclimate.com/github/phlegx/macker)
[![Inline Docs](http://inch-ci.org/github/phlegx/macker.svg?branch=master)](http://inch-ci.org/github/phlegx/macker)
[![Dependency Status](https://gemnasium.com/phlegx/macker.svg)](https://gemnasium.com/phlegx/macker)
[![License](https://img.shields.io/github/license/phlegx/macker.svg)](http://opensource.org/licenses/MIT)

Real MAC address generator and vendor lookup.

## Features

* Generate random mac addresses
* Generate random mac addresses by vendor
* Lookup vendor by mac address
* Fetch OUI list and use cache system
* High configurable
* See the [documentation](http://www.rubydoc.info/gems/macker)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'macker'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install macker

## Usage

### Configuration

The following configuration is the default configuration of Macker. Store the configration code and load it at the beginning of Macker use.
Rails users can create a file `macker.rb` in `config/initializers` to load the own Macker configuration.

```ruby
Macker.configure do |config|
  config.oui_full_url    = 'http://linuxnet.ca/ieee/oui.txt'                                       # Full URL of OUI text file
  config.user_agent      = 'Mozilla/5.0 (X11; Linux x86_64; rv:54.0) Gecko/20100101 Firefox/54.0'  # A common user agent
  config.ttl_in_seconds  = 86_400                                                                  # Will expire the vendors in one day
  config.cache           = File.expand_path(File.dirname(__FILE__) + '/../../data/oui_*.txt')      # Can be a string, pathname or proc
  config.auto_expiration = true                                                                    # Expiration can be checked manually
end
```

### Generat MAC address

```ruby
mac = Macker.generate
# => #<Macker::Address:0x000000047e5cd0 @val=257034854932948, @name=nil, @address=nil, @iso_code=nil>
mac.to_s
# => "E9:C5:97:39:21:D4"

mac = Macker.generate(vendor: true)
# => #<Macker::Address:0x0000000477ed50 @val=272999927425737, @name="Huawei Technologies Co.,ltd", @address=["D1, Huawei Industrial..."], @iso_code="CN">
mac.to_s('-')
# => "F8-4A-BF-B2-AA-C9"
mac.to_i
# => 272999927425737
mac.prefix
# => "F84ABF"
mac.name
# => "Huawei Technologies Co.,ltd"
mac.address
# => ["D1, Huawei Industrial Base, Bantian, Longgang, Shenzhen", "Shenzhen Guangdong 518129", "Cn"]
mac.full_address
# => "D1, Huawei Industrial Base, Bantian, Longgang, Shenzhen, Shenzhen Guangdong 518129, Cn"
mac.iso_code
# => "CN"

mac = Macker.generate(vendor: 'Apple, Inc.')
# => #<Macker::Address:0x000000046e6910 @val=61638330009701, @name="Apple, Inc.", @address=["1 Infinite Loop", "Cupertino Ca 95014", "Us"], @iso_code="US">
mac.to_s
# => "64:E6:82:E5:CC:58"

mac = Macker.generate(iso_code: 'US')
# => #<Macker::Address:0x000000046b86f0 @val=161304050786, @name="The Weather Channel", @address=["Mail Stop 500", "Atlanta Ga 30339", "Us"], @iso_code="US">

# Raise an exception
Macker.generate!(iso_code: 'HELLO')
```

### Lookup MAC address

```ruby
Macker.lookup('64:E6:82:E5:CC:58')
# => #<Macker::Address:0x00000004699520 @val=110941201353816, @name="Apple, Inc.", @address=["1 Infinite Loop", "Cupertino Ca 95014", "Us"], @iso_code="US">

Macker.lookup(mac)
# => #<Macker::Address:0x000000046886d0 @val=161304050786, @name="The Weather Channel", @address=["Mail Stop 500", "Atlanta Ga 30339", "Us"], @iso_code="US">

# More examples
Macker.lookup('64-E6-82-E5-CC-58')
Macker.lookup('64E682E5CC58')
Macker.lookup(110941201353816)
Macker.lookup!(110941201353816)
```

### MAC address
```ruby
mymac = Macker.lookup('64-E6-82-E5-CC-58')
mymac.class
# => Macker::Address

# Some methods of the address class
mymac.name
mymac.address
mymac.iso_code

mymac.to_i
mymac.to_s

mymac.oui?
mymac.valid?
mymac.broadcast?
mymac.unicast?
mymac.multicast?
mymac.global_uniq?
mymac.local_admin?

mymac.next
mymac.succ
mymac.prefix
mymac.full_address
```

### Cache control

```ruby
# Update OUI from cache (careful)
Macker.update
# => 2017-07-03 13:03:00 +0200

# Update OUI from remote (straight)
Macker.update(true)
# => 2017-07-03 13:04:00 +0200

# Vendor table with all base16 MAC prefixes as keys
Macker.prefix_table
# => "F8DA0C"=>{:name=>"Hon Hai..."},  ...

# Vendor table with all country iso codes as keys
Macker.iso_code_table
# => "CN"=>[{:name=>"Hon Hai..."} ... ]

# Vendor table with all country vendor names as keys
Macker.vendor_table
# => "Apple, Inc."=>[{:prefix=>...} ... ]

Macker.expire!
# => false

Macker.expired?
# => false

Macker.stale?
# => false

Macker.vendors_expiration
# => 2017-07-04 13:04:00 +0200

# Get configuration of Macker
Macker.config
# => #<Macker::Config:0x0000000124ff30 @config=#...>>
```

## Contributors

* Inspired by MacVendor [github.com/uceem/mac_vendor](https://github.com/uceem/mac_vendor).
* Inspired by MacAddressEui48 [github.com/cunchem/mac_address_eui48](https://github.com/cunchem/mac_address_eui48).

## Contributing

1. Fork it ( https://github.com/[your-username]/macker/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## License

The MIT License

Copyright (c) 2017 Phlegx Systems OG

