class SimpleApi::Sitemap::Vocabula < Sequel::Model
  set_dataset :vocabulary

  def self.fresh?(sphere, lang, attribute)
    !where(lang: lang.to_s, sphere: sphere, kind: attribute).empty? && where(lang: lang.to_s, sphere: sphere, kind: attribute).order(created_at: :desc).first.created_at > 1.week.ago
  end

  def self.take(sphere, lang, attribute)
    return spec_load_criteria(sphere, lang) if attribute == 'criteria'
    return spec_load_catalog(sphere, lang) if attribute == 'catalog' && sphere == 'hotels'
    rslt = []
    offset = 0
    loop do
      data = Sentimeta::Client.fetch :attributes, {id: attribute, limit_values: 10000, offset_values: offset, sphere: sphere, lang: lang}
      p data['values'].size

      break if !data.ok? || data['values'].blank?
      rslt += data['values']
      offset += data['values'].size
    end
    p rslt.size
    # rslt
  end

  def self.spec_load_criteria(sphere, lang)
  end
  def preload_criteria
    Sentimeta.env = CONFIG["fapi_stage"] || :production
    sp_list = ((Sentimeta::Client.spheres rescue []) || []).map{|s| s["name"] }
    DB[:criteria].delete
    (SimpleApi::Rule.all.map(&:sphere).uniq & sp_list).each do |sphere|
      # Sentimeta.lang = :en
      # Sentimeta.sphere = sphere
      DB[:criteria].multi_insert(((Sentimeta::Client.criteria(:subcriteria => true, sphere: sphere, lang: :en) rescue []) || []).map{|h| h.has_key?('subcriteria') ? h['subcriteria'] : [h] }.flatten.map{|h| {label: h["label"], name: h["name"], sphere: sphere} })
    end
  end

  def self.spec_load_catalog(sphere, lang)
  end
end
