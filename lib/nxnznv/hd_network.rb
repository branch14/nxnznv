require 'logger'

module Nxnznv

  class HdNetwork

    attr_accessor :options, :api

    def initialize(options)
      self.options = options
      self.api = API.new(options)
    end

    # list all domains
    #
    # SYNOPSIS: nxnznv domains
    def domains
      api.domains.map { |domain| [ domain.domain ] }
    end

    # list streams of a domain
    #
    # SYNOPSIS: nxnznv -r <domain> streams
    def streams
      resp = api.get("/#{options.resources}/stream")
      (resp / 'streams/stream').map do |stream|
        [ options.resources,
          (stream / 'stream-id').text,
          (stream / 'stream-name').text ]
      end
    end

    # list events of a stream
    #
    # SYNOPSIS: nxnznv -r <domain/stream_id> events
    def events
      domain, stream_id = options.resources.split('/')
      resp = api.get("/#{domain}/stream/#{stream_id}/event")
      (resp / 'event-list/event').map do |event|
        [ domain,
          stream_id,
          (event / 'event-name').text ]
      end
    end

    # SYNOPSIS: nxnznv -r <domain/stream_id/event_name> event
    def event
      domain, stream_id, event_name = options.resources.split('/')
      api.get("/#{domain}/stream/#{stream_id}/event/#{event_name}")
    end

    # # SYNOPSYS: nxnznv -r <domain/stream_id/event_name> -d until=`date +%s` delete_backup_until
    # def delete_backup_until
    #   domain, stream_id, event_name = options.resources.split('/')
    #   payload = '{ "backupEventDetails": { "deleteTime": :until000 } }'
    #   options.data.each { |key, val| payload.gsub!(":#{key}", val) }
    #   api.put("/#{domain}/stream/#{stream_id}/event/#{event_name}", payload)
    # end
    #
    # # SYNOPSIS: nxnznv -r <domain/stream_id/event_name> delete_backup
    # def delete_backup
    #   domain, stream_id, event_name = options.resources.split('/')
    #   resource = "/#{domain}/stream/#{stream_id}/event/#{event_name}"
    #   event = api.get(resource)
    #   end_time = event['backupEventDetails']['archiveEndTime']
    #   payload = '{ "backupEventDetails": { "deleteTime": %s } }' % end_time
    #   api.put(resource, payload)
    # end
    #
    # # SYNOPSIS: nxnznv -r <domain/stream_id/event_name> delete_primary
    # def delete_primary
    #   domain, stream_id, event_name = options.resources.split('/')
    #   resource = "/#{domain}/stream/#{stream_id}/event/#{event_name}"
    #   event = api.get(resource)
    #   end_time = (Time.now.to_i - 8 * 24 * 60 * 60) * 1000
    #   payload = '{ "primaryEventDetails": { "deleteTime": %s } }' % end_time
    #   #puts "PUT #{resource} #{payload}"
    #   api.put(resource, payload)
    # end
    #
    # # SYNOPSIS: nxnznv find_backups > backups.txt
    # def find_backups
    #   find_events :backup
    # end
    #
    # def find_primaries
    #   find_events :primary
    # end
    #
    # def find_events(method=:backup)
    #   events = Array.new.tap do |result|
    #     api.domains.each do |domain|
    #       domain.streams.each do |stream|
    #         stream.events.each do |event|
    #           if event.send(method)
    #             puts "/#{domain.domain}/stream/#{stream.stream_id}/event/#{event.event_name}"
    #             $stdout.flush
    #           end
    #         end
    #       end
    #     end
    #   end
    # end
    #
    # # SYNOPSIS: nxnznv -r backups.txt delete_backups_by_list
    # def delete_backups_by_list
    #   delete_by_list :method => 'backup'
    # end
    #
    # def delete_primaries_by_list
    #   delete_by_list :method => 'primary', :offset => 8 * 24 * 60 * 60
    # end
    #
    # def delete_by_list(opts={})
    #   raise 'opts missing' if opts.empty?
    #   unless %w(primary backup).include?(opts[:method])
    #     raise 'opts[:method] must be primary or backup'
    #   end
    #
    #   details_key = opts[:method] + 'EventDetails'
    #   offset = opts[:offset] || 0
    #
    #   log = Logger.new(STDOUT)
    #   log.formatter = proc do |severity, datetime, progname, msg|
    #     time = datetime.strftime("%Y-%m-%d %H:%M:%S")
    #     "#{time} #{msg}\n"
    #   end
    #   filename = options.resources
    #   raise "Not a file: #{fielname}" unless File.exist?(filename)
    #   File.read(filename).split("\n").each do |resource|
    #     next unless resource
    #
    #     t0 = Time.now
    #     msg, t_delta = 'no msg', 0
    #
    #     event = api.get(resource)
    #     details = event[details_key]
    #     unless details
    #       msg = 'skip (no details)' # skip
    #     else
    #
    #       start_time_str = details['archiveStartTimeStr']
    #       end_time_str = details['archiveEndTimeStr']
    #       if end_time_str==start_time_str
    #         msg = 'skip (start==end)' # skip
    #       else
    #
    #         end_time = details['archiveEndTime']
    #         unless end_time
    #           end_time = (Time.now.to_i - offset) * 1000
    #           msg = "use now - offset (no end-time)" # try
    #         else
    #           msg = 'use end-time'
    #         end
    #
    #         payload = '{ "%s": { "deleteTime": %s } }' % [ details_key, end_time ]
    #         #puts "PUT #{resource} #{payload}"
    #         response = api.put(resource, payload)
    #         #response = {}
    #       end
    #     end
    #
    #     t1 = Time.now
    #     t_delta = t1 - t0
    #     log.info("[% -25s] % 2.4fs %s %s" % [ msg, t_delta, resource, response.to_json ])
    #   end
    # end
    #
    # # SYNOPSIS: nxnznv -r <pattern> collect
    # def collect
    #   regex = Regexp.new(options.resources) if options.resources
    #   Array.new.tap do |result|
    #     result << Nxnznv::EventDetails.to_a # header
    #     api.domains.each do |domain|
    #       if regex.nil? or domain.domain.match(regex)
    #         domain.streams.each do |stream|
    #           stream.events.each do |event|
    #             result << event.primary if event.primary
    #             result << event.backup if event.backup
    #           end
    #         end
    #       end
    #     end
    #   end
    # end
    #
    # def cpcodes
    #   api.cpcodes
    # end

    def list_all
      sep = "," # "\t"
      puts EventDetails.to_a * sep
      api.domains.each do |domain|
        domain.streams.each do |stream|
          stream.events.each do |event|
            puts event.primary.to_a * sep if event.primary
            puts event.backup.to_a * sep if event.backup
          end
        end
      end
      nil
    end

    # SYNOPSIS: nxnznv delete_backups
    def delete_backups
      api.domains.each do |domain|
        puts "#{domain.domain}"
        domain.streams.each do |stream|
          puts "#{domain.domain}/#{stream.stream_id}"
          stream.events.each do |event|
            puts "#{domain.domain}/#{stream.stream_id}/#{event.event_name}"
            puts delete(event.backup)
            $stdout.flush
          end
        end
      end
      nil
    end

    def rctest
      nil
    end

    private

    def delete(details, offset=0)
      return 'skip, no details' if details.nil?
      end_time = details.archive_end_time
      return "skip, start == end #{ftime(end_time)}" if details.archive_start_time == end_time
      delete_time = (Time.now.utc.to_i * 1000) - offset
      end_time ||= Time.now.utc.to_i * 1000 # assume ongoing stream
      return "skip, delete #{ftime(delete_time)} > end #{ftime(end_time)}" if delete_time > end_time
      details.delete_time!(delete_time)
    end

    def ftime(int)
      Time.at(int/1000).strftime('%Y-%m-%d %H:%M')
    end

  end

end
