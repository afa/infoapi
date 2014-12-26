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
        unless hash_params.values.all?(&:nil?)
          components << 'filters'
          hash_params.keys.sort.each do |param|
            next if hash_params[param].blank?
            components << param
            components << hash_params[param]
          end
        end
      end
    end.join('/')

  end

end
