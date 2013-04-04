require 'ruby-dpla'
require 'json'

API_KEY = '45678'
OUTER_FIELD = 'provider.name'
INNER_FIELD = 'sourceResource.format'
outer_fields, inner_fields, map = {}, {}, {}
output = { :name => 'DPLA', :children => [] }
id = 0
record_percent_threshold = 0.001

outer_facet_set = 'terms'
outer_facet_item = 'term'
inner_facet_set = 'terms'
inner_facet_item = 'term'
if INNER_FIELD.index('sourceResource.date') == 0
    inner_facet_set = 'entries'
    inner_facet_item = 'time'
end
if OUTER_FIELD.index('sourceResource.date') == 0
    outer_facet_set = 'entries'
    outer_facet_item = 'time'
end

outer_field_inner_field_counts = DPLA::Query.new({:api_key => API_KEY, :facets => "#{OUTER_FIELD},#{INNER_FIELD}", :page_size => 0 })
total_dpla_records = outer_field_inner_field_counts.response['count'].to_i
outer_fields = outer_field_inner_field_counts.facets[OUTER_FIELD][outer_facet_set]
inner_field_facets = outer_field_inner_field_counts.facets[INNER_FIELD][inner_facet_set].dup
outer_fields.reject!{|of| of['count'] < record_percent_threshold * total_dpla_records}

total_record_count = 0
outer_fields.each do |outer_field|
    dpla_child = {:name => outer_field[outer_facet_item], :children => [], :id => id}
    id += 1
    inner_field_query = DPLA::Query.new({:api_key => API_KEY, OUTER_FIELD => %Q|"#{outer_field[outer_facet_item]}"|, :facets => INNER_FIELD, :page_size => 0})
    inner_fields = inner_field_query.facets[INNER_FIELD][inner_facet_set]
    outer_field_count = outer_field['count'].to_i
    other_contributed_count = outer_field_count
    inner_fields.each do |inner_field|
        if inner_field['count'].to_i >= record_percent_threshold * outer_field_count
            inner_field_facets.delete_if{|iff| iff[inner_facet_item] == inner_field[inner_facet_item]}
            other_contributed_count -= inner_field['count'].to_i
            total_record_count += inner_field['count'].to_i
            dpla_child[:children] << {:name => %Q|"#{inner_field[inner_facet_item]}"|, :size => inner_field['count'], :id => id}
            id += 1
        end
    end
    if other_contributed_count >= record_percent_threshold * outer_field_count
        dpla_child[:children] << {:name => "Other", :size => other_contributed_count, :id => id}
        total_record_count += other_contributed_count
    end
    id += 1
    output[:children] << dpla_child
end

other_record_count = total_dpla_records - total_record_count
other_children = []
inner_field_facets.reject!{|iff| iff['count'].to_i < record_percent_threshold * other_record_count}
inner_field_facets.each do |iff|
    other_children << {:name => %Q|"#{iff[inner_facet_item]}"|, :size => iff['count'], :id => id}
    id += 1
end

output[:children] << {:name => 'Other', :id => id, :size => other_record_count, :children => other_children}

puts JSON.dump(output)
