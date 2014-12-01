require 'open-uri'
class SimpleApiRouter
  attr_accessor :lang, :sphere
  def initialize(lang, sphere)
    self.lang = lang
    self.sphere = sphere
  end

  def route_to(action, hash_params={})
    criteria = hash_params.delete('criteria')
    if criteria.is_a?(::Array)
      criteria.sort!
    end
    # params = hash_params.inject([]){|rslt, (k, v)| rslt << {k => v} }.sort_by{|item| item.keys.first }
    # p params
    [''].tap do |components|
      components << lang
      components << sphere
      components << action
      unless criteria.blank?
        components << 'criteria'
        components << (criteria.is_a?(::Array) ? criteria.join(',') : criteria)
      end
      unless hash_params.empty?
        path = hash_params.delete("path")
          hash_params["catalog"] = path if path
        hash_params.keys.sort.each do |param|
          components << param
          components << hash_params[param]
        end
      end
    end.join('/')

  end

  # def route_rating
end
