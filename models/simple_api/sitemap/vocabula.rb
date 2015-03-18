class SimpleApi::Sitemap::Vocabula < Sequel::Model
  set_dataset :vocabulary

  def self.take(sphere, lang, attribute)
    loop do
      data = Sentimeta::Client.fetch :attributes, {limit_values: 10000, offset_values: 0, sphere: sphere, lang: lang}

      break if data.blank? || data['values'].blank
    end
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

      def load_catalog
      end
end
