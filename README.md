Nxnznv
======

Ruby library and command line client to Akamai HdNetwork REST API.


Installation
------------

    gem install nxnznv-0.1.0.gem


Build
-----

    git clone git@github.com:branch14/nxnznv.git
    cd nxnznv
    gem build nxnznv.gemspec


Usage
-----

### As a CLI util

With credentials as parameters

    nxnznv -u <email> -p <password> domains

Or in the environment

    export NXNZNV_USER=<email>
    export NXNZNV_PASS=<secret>

    nxnznv domains

Drill down to event

    nxnznv -r domain.example.com streams
    nxnznv -r domain.example.com/1234 events
    nxnznv -r domain.example.com/1234/some_event event

Control the output format

    nxnznv -r domain.example.com/1234/some_event -f yaml event

Generate report csv

    nxnznv collect > events_`date -I`.csv

or

    nxnznv collect | nxnznv-report


### As a library

    options = Nxnznv.default_options :verbose => true
    hdn = Nxnznv::API.new(options)

    # these return an Array of Objects
    puts hdn.domains.to_csv
    puts hdn.contacts.to_csv
    puts hdn.archive_locations.to_csv
    puts hdn.config_cpcodes.to_csv
    puts hdn.net_storage_cpcodes.to_csv
    puts hdn.countries.to_csv

    require 'yaml'

    # these return a Hash
    puts hdn.delivery_formats.to_yaml
    puts hdn.edge_maps.to_yaml
    puts hdn.ingest_formats.to_yaml


Contributing
------------

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
