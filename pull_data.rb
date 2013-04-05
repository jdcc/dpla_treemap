require 'ruby-dpla'
require 'json'
require 'uri'

fields = [
    'sourceResource.contributor',
    'sourceResource.language.name',
    'sourceResource.format',
    'sourceResource.date.begin',
    'provider.name',
    'sourceResource.spatial.name',
    'sourceResource.spatial.state',
    'hasView.format'
]
permutations = fields.permutation(2).to_a
permutations += fields.map{|f| [f, f]}
#permutations.reject!{|p| p[0] == 'sourceResource.format' }
class JsonBuilder
    API_KEY = '8c048d67cab2cf4646bb86c1c23e8e53'
    def build(outer_field, inner_field)
        of = outer_field
        innf = inner_field
        outer_fields, inner_fields, map = {}, {}, {}
        output = { :name => 'DPLA', :children => [], :outerField => of, :innerField => innf }
        record_percent_threshold = 0.001

        outer_facet_set = 'terms'
        outer_facet_item = 'term'
        inner_facet_set = 'terms'
        inner_facet_item = 'term'
        if innf.index('sourceResource.date') == 0
            inner_facet_set = 'entries'
            inner_facet_item = 'time'
        end
        if of.index('sourceResource.date') == 0
            outer_facet_set = 'entries'
            outer_facet_item = 'time'
        end

        outer_field_inner_field_counts = DPLA::Query.new({:api_key => API_KEY, :facets => "#{of},#{innf}", :page_size => 0 })
        total_dpla_records = outer_field_inner_field_counts.response['count'].to_i
        outer_fields = outer_field_inner_field_counts.facets[of][outer_facet_set]
        inner_field_facets = outer_field_inner_field_counts.facets[innf][inner_facet_set].dup
        outer_fields.reject!{|of| of['count'] < record_percent_threshold * total_dpla_records}

        total_record_count = 0
        outer_fields.each do |outer_field|
            dpla_child = {:name => outer_field[outer_facet_item], :children => [], :id => outer_field[outer_facet_item]}
            inner_field_query = DPLA::Query.new({:api_key => API_KEY, of => JSON.dump([outer_field[outer_facet_item]])[1..-2], :facets => innf, :page_size => 0})
            inner_fields = inner_field_query.facets[innf][inner_facet_set]
            outer_field_count = outer_field['count'].to_i
            other_contributed_count = outer_field_count
            inner_fields.each do |inner_field|
                if inner_field['count'].to_i >= record_percent_threshold * outer_field_count
                    inner_field_facets.delete_if{|iff| iff[inner_facet_item] == inner_field[inner_facet_item]}
                    other_contributed_count -= inner_field['count'].to_i
                    total_record_count += inner_field['count'].to_i
                    dpla_child[:children] << {:name => %Q|"#{inner_field[inner_facet_item]}"|, :size => inner_field['count'], :id => "#{outer_field[outer_facet_item]}-#{inner_field[inner_facet_item]}"}
                end
            end
            if other_contributed_count >= record_percent_threshold * outer_field_count
                dpla_child[:children] << {:name => "Other", :size => other_contributed_count, :id => "#{outer_field[outer_facet_item]}-Other"}
                total_record_count += other_contributed_count
            end
            output[:children] << dpla_child
        end

        other_record_count = total_dpla_records - total_record_count
        other_children = []
        inner_field_facets.reject!{|iff| iff['count'].to_i < record_percent_threshold * other_record_count}
        inner_field_facets.each do |iff|
            other_record_count -= iff['count'].to_i
            other_children << {:name => %Q|"#{iff[inner_facet_item]}"|, :size => iff['count'], :id => "Other-#{iff[inner_facet_item]}"}
        end

        other_children << {:name => 'Other', :id => 'Other-Other', :size => other_record_count}
        output[:children] << {:name => 'Other', :id => 'Other', :children => other_children}
        output
    end
end

jb = JsonBuilder.new
output = permutations.map{|p| jb.build(*p) }
puts JSON.dump(output)
