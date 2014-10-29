require 'tester'
require 'sequel'
module SimpleApi
  module Rule
    def init(config)
      Sequel.postgres(config['db'].inject({}){|r, k| r.merge(k[0].to_sym => k[1]) }) do |db|
        data = {}
        db[:rules].order(:id).all.map{|i| OpenStruct.new(i.inject({}){|r, (k, v)| r.merge(k.to_sym => v) }) }.each do |rule|
          unless data.has_key?(rule.sphere)
            data[rule.sphere] = {}
          end
          unless data[rule.sphere].has_key?('infotext')
            data[rule.sphere]['infotext'] = {}
          end
          unless data[rule.sphere]['infotext'].has_key?(rule.param)
            data[rule.sphere]['infotext'][rule.param] = {}
          end
          unless data[rule.sphere]['infotext'][rule.param].has_key?(rule.lang)
            if %w(main about).include?(rule.param)
              data[rule.sphere]['infotext'][rule.param][rule.lang] = {}
            else
              data[rule.sphere]['infotext'][rule.param][rule.lang] = []
            end
          end
          if %w(main about).include?(rule.param)
            data[rule.sphere]['infotext'][rule.param][rule.lang][rule.design] = rule.content
          else
            data[rule.sphere]['infotext'][rule.param][rule.lang] << rule
          end
        end
        data
      end
    end

    def prepare_params(params)
      OpenStruct.new(JSON.load(params))
    end

    def process(rules, params, sphere, logger)
      located = rules.fetch(sphere, {}).fetch('infotext', {}).fetch(params.param, {}).fetch(params.lang, {})
      found = %w(main about).include?(params.param) ? located[params.design] : located.detect do |rule|
        # r = OpenStruct.new JSON.load(rule)
        pairs = [[params.path || params.data['path'], rule.path]]
        pairs += [[params.criteria || params.data['criteria'], rule.criteria], [params.stars || params.data['stars'], rule.stars]] if params.param == 'rating-annotation'
        pairs.inject(true){|rslt, a| rslt && Tester::test(*a) }
      end
      logger.info "found #{found.inspect}"
      content = %w(main about).include?(params.param) ? found : found.try(:content)
    end

    module_function :init, :process, :prepare_params
  end
end
