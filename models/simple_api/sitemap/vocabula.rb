class SimpleApi::Sitemap::Vocabula < Sequel::Model
  set_dataset :vocabulary

  VOCABULAS = {
    'hotels' => %w(location country admin1 city amenities),
    'movies' => %w(genres countries directors actors producers writers),
    'companies' => %w(top industries)
  }

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

  def self.cleanup(sphere, lang, attribute)
    where(sphere: sphere, lang: lang, kind: attribute).delete
  end

  def self.spec_load_criteria(sphere, lang)
    tm = Time.now
    Sentimeta.env = CONFIG["fapi_stage"] || :production
    multi_insert(((Sentimeta::Client.criteria(:subcriteria => true, sphere: sphere, lang: lang) rescue []) || []).map{|h| h.has_key?('subcriteria') ? h['subcriteria'] : [h] }.flatten.map{|h| {label: h["label"], name: h["name"], sphere: sphere, lang: lang, created_at: tm} })
  end

  def self.spec_load_catalog(sphere, lang)
    ctime = Time.now
    Sentimeta.env = CONFIG['fapi_stage']
    rslt = ['']
    crnt = rslt.dup
    4.times.each do
      crnt = crnt.map do |item|
        cat = Sentimeta::Client.catalog(sphere: 'hotels', path: item, limit: 10000, lang: lang) rescue []
        cat.present? ? cat.map{|i| [ item.blank? ? nil : item, i['name'] ].compact.join(',') } : nil
      end
      .compact
      .flatten
      rslt += crnt
    end
    rslt.delete_if(&:blank?)
    rslt.each_slice(1000) do |items|
      multi_insert(items.map{|i| {name: i[:name], label: i[:label], sphere: sphere, lang: lang, kind: 'catalog', created_at: ctime} })
    end

  end
end
