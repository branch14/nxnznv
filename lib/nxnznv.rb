require 'ostruct'
require 'nokogiri'

module Nxnznv

  def self.default_options(options={})
    OpenStruct.new({ :user => ENV['NXNZNV_USER'],
                     :pass => ENV['NXNZNV_PASS'],
                     :data => {} }.merge(options))
  end

end

%w( array
    numeric
    nxnznv/api
    nxnznv/hd_network
    nxnznv/cli
    nxnznv/curl ).each do |file|

  require File.expand_path(File.join('..', file), __FILE__)
end
