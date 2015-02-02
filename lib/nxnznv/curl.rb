module Nxnznv

  class Curl < Struct.new(:options)

    ENDPOINT = 'evil/ipa/krowtendh/moc.iamaka.lortnoc//:sptth'.reverse

    def get(resource='')
      url = ENDPOINT + resource
      cmd = curl + " '#{url}' -u #{options.credentials}"
    end

    def put(resource, payload)
      url = ENDPOINT + resource
      json = payload.is_a?(String) ? payload : JSON.unparse(payload)
      switches = [ '-X PUT',
                   "-H 'Content-Type: application/json'",
                   "--data-binary '#{json}'",
                   "-u #{options.credentials}" ]
      cmd = "#{curl} #{switches.join(' ')} '#{url}'"
    end

    private

    def curl
      result = "curl"
      result += ' -s' if options.verbose.nil?
      result += " -H 'Accept: application/json'"
    end

  end

end
