#!/usr/bin/env ruby
#
# Downloads data from the Australian Federal Lobbyists Register and output
# as a "comma separated values" (CSV) file to load into a spreadsheet
# Copyright (C) 2009 OpenAustralia Foundation
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# Author: Matthew Landauer
#
# This code brought to you by the following conversation at 10:25am, Sunday morning, 23 August 2009:
# Kat Szuminska: "How about we submit a Perl app to the taskforce as an essay in transparency?"
# Matthew Landauer: "Okay... but I'll write it in Ruby"

require 'rubygems'
require 'hpricot'
require 'open-uri'
require 'csv'

base_url = "http://www.google.com/search?q=cache%3Ahttp%3A%2F%2Flobbyists.pmc.gov.au%2Flobbyistsregister%2Findex.cfm"

def get_page(url)
  sleep_time = 1
  begin
    Hpricot(open(url))
  rescue OpenURI::HTTPError, Timeout::Error
    puts "Had trouble downloading the page #{url} with the error #{$!}. retrying in #{sleep_time}s..."
    sleep(sleep_time)
    puts "Retrying now"
    sleep_time *= 2
    retry
  end
end

page = get_page("#{base_url}%3Fevent%3DwhoIsOnRegister")

lobbyists = []
# Skip first row of table because it contains the headings
page.search("table > tr")[1..-1].each do |row|
  td = row.search("td")
  lobbyists << {:profile_id => td[0].at("input")["value"], :entity => (td[1]/"a").inner_text,
    :trading_name => (td[2]/"a").inner_text, :abn => td[3].inner_text.strip}
end

# For each lobbyist get their clients and output the result
# On the individual lobbyist page the whole layout is done with tables. Not pretty at all. Who wrote this?
CSV.open("lobbying.csv", "w") do |f|
  f <<  ["Business Entity Name", "Trading Name", "ABN", "Clients"]
  lobbyists.each do |l|
    page = get_page("#{base_url}%3Fevent=viewProfile%26profileID%3D#{l[:profile_id]}")
    clients = []
    page.search("table")[5].search("tr")[1..-2].each do |tr|
      clients << tr.search("td")[1].inner_text.strip
    end

    f << [l[:entity], l[:trading_name], l[:abn]] + clients
  end
end
