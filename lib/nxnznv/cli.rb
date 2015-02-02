require 'optparse'
require 'csv'
require 'yaml'

module Nxnznv

  class CLI

    attr_accessor :options

    def initialize(args)
      self.options = Nxnznv.default_options
      self.options.command = args.pop
      raise 'no command given' if options.command.nil?
      option_parser.parse!(args)
      raise 'no or incomplete credentials given' if options.user.nil? or options.pass.nil?
    end

    def exec
      result = HdNetwork.new(options).send(options.command)
      return if result.nil?
      puts case options.format
           when 'yaml' then result.to_yaml
           when 'json' then JSON.unparse(result)
           else as_csv(result)
           end
    end

    private

    def as_csv(result)
      len = result.first.to_a.size
      CSV.generate do |csv|
        result.each do |row|
          csv << row.to_a
        end
      end
    end

    def option_parser
      OptionParser.new do |opts|
        opts.banner = "Usage: #{File.basename($0)} [options] [command]"
        opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
          options.verbose = v
        end
        opts.on("-c", "--[no-]curl", "Output curl command equivalents") do |v|
          options.curl = v
        end
        opts.on("-n", "--noop", "Dryrun") do |v|
          options.dryrun = v
        end
        opts.on("-u", "--user [USER]", "Set user") do |v|
          options.user = v
        end
        opts.on("-p", "--pass [PASS]", "Set password") do |v|
          options.pass = v
        end
        opts.on("-r", "--resources [RESOURCES]", "Set resources separated by slash") do |v|
          options.resources = v
        end
        opts.on("-f", "--format [FORMAT]", "Set output format: csv (default), json, or yaml") do |v|
          options.format = v
        end
        opts.on("-d", "--data [DATA]", "Set data") do |v|
          key, value = v.split('=')
          options.data.merge! key => value
        end
      end
    end

  end

end
