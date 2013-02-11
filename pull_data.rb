require 'ruby-dpla'
require 'json'

providers, contributors, map = {}, {}, {}
output = { :name => 'dpla', :children => [] }

contributor_query = DPLA::Query.new({:facets => 'aggregatedCHO.contributor', :page_size => 0, :provider => "*" })
provider_query = DPLA::Query.new({:facets => 'provider.name', :page_size => 0})

contributor_query.facets['aggregatedCHO.contributor']['terms'].each do |term|
    contributors[term['term']] = term['count']
end

provider_query.facets['provider.name']['terms'].each do |term|
    providers[term['term']] = term['count']
    map[term['term']] = []
end

contributors.keys.each do |contributor|
    query = DPLA::Query.new({'aggregatedCHO.contributor' => %Q["#{contributor}"], :page_size => 1 })
    puts 'fetching'
    map[query.results.first['provider']['name']] << contributor
end

map.each do |provider, prov_contributors|
    prov_contributors.uniq!
    children = []
    prov_contributors.each do |contributor|
        children << { :name => contributor, :size => contributors[contributor] }
    end
    output[:children] << { :name => provider, :children => children }
end

puts JSON.dump(output)
