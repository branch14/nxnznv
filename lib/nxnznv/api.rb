require 'net/https'
require 'uri'
require 'logger'
require 'time'
require 'nokogiri'

# code conventions deviating from ruby standards:
#
# * methods which names end in ? return estimated values,
#   which only can be assumed from values provided by the api
module Nxnznv

  class Base

    attr_accessor :root, :parent, :payload

    def initialize(root, parent, payload)
      self.root = root
      self.parent = parent
      self.payload = payload
    end

  end

  class Domain < Base

    def domain
      ( payload / 'configuration-details/hostname' ).text
    end

    def streams
      resource = "/#{domain}/stream"
      result = root.get(resource) / 'streams/stream'
      return [] if result.empty?
      result.map { |payload| Stream.new(root, self, payload) }
    end

    def to_a
      [ domain ]
    end

  end

  class Stream < Base

    def stream_id
      (payload / 'stream-id').text
    end

    def stream_name
      (payload / 'stream-name').text
    end

    def events
      domain = parent.domain
      resource = "/#{domain}/stream/#{stream_id}/event"
      result = root.get(resource) / 'event-list/event'
      return [] if result.empty?
      result.map { |payload| Event.new(root, self, payload) }
    end

  end

  class Event < Base

    def event_name
      (payload / 'event-name').text
    end

    def primary
      primary_event = payload / 'primary-event'
      return nil if primary_event.empty?
      primary_event.first['kind'] = 'primary'
      EventDetails.new(root, self, primary_event)
    end

    def backup
      backup_event = payload / 'backup-event'
      return nil if backup_event.empty?
      backup_event.first['kind'] = 'backup'
      EventDetails.new(root, self, backup_event)
    end

  end

  class EventDetails < Base

    SEVEN_DAYS     =  7 * 24 * 60 * 60 * 1000
    THIRTYONE_DAYS = 31 * 24 * 60 * 60 * 1000
    ADJUSTMENT_DAY = Time.local(2013, 'jan', 15).to_i * 1000

    class << self
      def to_a
        %w( domain
            stream_id
            stream_name
            event_name
            p_or_b
            archive_start_time
            archive_end_time
            on_air_start_time
            best_guess_window_start_time
            delete_time
            duration_in_seconds
            duration_human_readable
            best_guess_bitrate_in_mbps
            estimated_size_in_gigabyte )
      end
    end

    def to_a
      [ domain,
        stream_id,
        stream_name,
        event_name,
        payload.first['kind'],
        archive_start_time ? Time.at(archive_start_time/1000) : nil,
        archive_end_time   ? Time.at(archive_end_time/1000)   : nil,
        on_air_start_time  ? Time.at(on_air_start_time/1000)  : nil,
        window_start_time? ? Time.at(window_start_time?/1000) : nil,
        delete_time        ? Time.at(delete_time/1000)        : nil,
        duration_in_seconds?,
        duration_in_seconds?.human_duration,
        guessed_bitrate_in_mbps?,
        size_in_gigabyte? ]
    end

    def suggested_delete_time
      (Time.now.utc.to_i * 1000) - SEVEN_DAYS
    end

    def delete_time!(time=nil)
      time ||= suggested_delete_time
      payload = <<-EOF
        <?xml version="1.0" encoding="UTF-8"?>
        <event>
          <backup-event>
            <delete-time>#{format_time(time)}</delete-time>
          </backup-event>
        </event>
      EOF
      payload = payload.gsub(/(^|\n)\s*/, '')
      resp = root.put("/#{domain}/stream/#{stream_id}/event/#{event_name}", payload)
      (resp / 'response-message/message').text
    end

    def domain
      parent.parent.parent.domain
    end

    def stream_id
      parent.parent.stream_id
    end

    def stream_name
      parent.parent.stream_name
    end

    def event_name
      parent.event_name
    end

    def archive_end_time
      parse_time (payload / 'archive-end-time').text
    end

    def archive_start_time
      parse_time (payload / 'archive-start-time').text
    end

    def on_air_start_time
      parse_time (payload / 'on-air-time').text
    end

    def on_air_end_time
      parse_time (payload / 'off-air-time').text
    end

    def delete_time
      parse_time (payload / 'delete-time').text
    end

    # falls back to now (assuming live stream)
    def archive_end_time_or_now?
      archive_end_time || Time.now.to_i*1000
    end

    # based on window_start_time
    def duration_in_seconds?
      ((archive_end_time_or_now? - window_start_time?) / 1000)
    end

    def size_in_gigabyte?
      duration_in_seconds? * guessed_bitrate_in_mbps? / 8 / 1024
    end

    # educated guess
    def window_start_time?
      return archive_start_time if (archive_end_time_or_now? - archive_start_time) <= SEVEN_DAYS
      return archive_end_time_or_now? - THIRTYONE_DAYS if archive_end_time_or_now? < ADJUSTMENT_DAY
      archive_end_time_or_now? - SEVEN_DAYS
    end

    def guessed_bitrate_in_mbps?
      case stream_name
      when /^HD/ then 2.5
      when /^SD/ then 1.3
      else 0.8
      end
    end

    private

    # input ex. "12/18/2019 12:34:56 AM" or ''
    def parse_time(str)
      return nil if str == ''
      dt = DateTime.strptime("#{str} +0000", '%m/%d/%Y %I:%M:%S %p %z')
      dt.strftime('%s').to_i * 1000
    end

    def format_time(int)
      Time.at(int/1000).utc.strftime('%m/%d/%Y %I:%M:%S %p')
    end

  end

  class CPCode < Base

    def code
      payload['cpcode']
    end

    def description
      payload['description']
    end

    def to_a
      [ code,
        description ]
    end

  end

  class Location < Base

    def to_a
      [ payload['id'],
        payload['name'] ]
    end

  end

  class Contact < Base

    def to_a
      [ payload['name'],
        payload['pin'] ]
    end

  end

  class Country < Base

    def to_a
      [ payload['countryCode'],
        payload['countryName'] ]
    end

  end

  class API

    ENDPOINT = 'evil/ipa/krowtendh/moc.iamaka.lortnoc//:sptth'.reverse

    attr_accessor :options

    def initialize(options)
      self.options = options

      @log = Logger.new('nxnznv.log')
      @log.formatter = proc do |severity, datetime, progname, msg|
        time = datetime.strftime("%Y-%m-%d %H:%M:%S")
        "#{time} #{msg}\n"
      end
    end

    def domains
      (get('/') / 'domains/domain').map do |payload|
        Domain.new(self, self, payload)
      end
    end

    # returns [ config_cpcodes, net_storage_cpcodes ]
    def cpcodes
      @cpcodes ||= Array.new.tap do |result|
        response = get('/utils/cpcode')
        result << response['configCPCodes']['cpcodeList'].map do |payload|
          CPCode.new(self, self, payload)
        end
        result << response['netStorageCPCodes']['cpcodeList'].map do |payload|
          CPCode.new(self, self, payload)
        end
      end
    end

    def config_cpcodes
      cpcodes.first
    end

    def net_storage_cpcodes
      cpcodes.last
    end

    def archive_locations
      get('/utils/archivelocation')['repSetList'].map do |payload|
        Location.new(self, self, payload)
      end
    end

    def contacts
      get('/utils/contacts')['contactList'].map do |payload|
        Contact.new(self, self, payload)
      end
    end

    def countries
      get('/utils/countries')['geoCountryList'].map do |payload|
        Country.new(self, self, payload)
      end
    end

    # returns a Hash
    def delivery_formats
      get('/utils/delivery/format')
    end

    # returns a Hash
    def edge_maps
      get('/utils/edge-maps')
    end

    # returns a Hash
    def ingest_formats
      get('/utils/ingest/format')
    end

    # internals here

    def get(resource='/')
      url = ENDPOINT + resource

      uri = URI.parse(url)
      req = Net::HTTP::Get.new(uri.path) # GET
      req.basic_auth(options.user, options.pass)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      t0 = Time.now
      res = http.request(req)
      t1 = Time.now

      puts Curl.new(options).get(resource) if options.curl
      @log.info "% 3s in %2.4fs for % -4s %s" % [ res.code, t1-t0, 'GET', resource ]

      result = res.body
      Nokogiri::XML(result)
    rescue Exception => e
      @log.fatal "#{e} (GET #{resource})"
      Nokogiri::XML::Builder.new { send(:'response-message') { message("#{e} (GET #{resource})") } }
    end

    def put(resource, payload)
      url = ENDPOINT + resource
      json = payload.is_a?(String) ? payload : JSON.unparse(payload)

      uri = URI.parse(url)
      req = Net::HTTP::Put.new(uri.path) # PUT
      req['Content-Type'] = 'application/xml'
      req.basic_auth(options.user, options.pass)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      t0 = Time.now
      res = http.request(req, json) # json
      t1 = Time.now

      puts Curl.new(options).put(resource, payload) if options.curl
      @log.info "% 3s in %2.4fs for % -4s %s" % [ res.code, t1-t0, 'PUT', resource ]

      result = res.body
      Nokogiri::XML(result)
    rescue Exception => e
      @log.fatal "#{e} (PUT #{resource})"
      Nokogiri::XML::Builder.new { send(:'response-message') { message("#{e} (PUT #{resource})") } }
    end

  end

end
