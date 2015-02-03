require 'open-uri'
class SimpleApiRouter
  attr_accessor :lang, :sphere
  def initialize(lang, sphere)
    self.lang = lang
    self.sphere = sphere
  end

  def route_to(action, hash_params={})
    hsh = hash_params.dup
    criteria = hsh.delete('criteria')
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
      unless hsh.empty?
        path = hsh.delete("path")
        hsh["catalog"] = path if path
        unless hsh.values.all?(&:nil?)
          components << 'filters'
          hsh.keys.sort.each do |param|
            next if hsh[param].blank?
            components << param
            components << hsh[param]
          end
        end
      end
    end.join('/')

  end

end
