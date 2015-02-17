require 'ostruct'
module SimpleApi
  module Sitemap
    class Production < Sequel::Model

      set_dataset :productions

      many_to_one :sitemap_session, class: 'SimpleApi::Sitemap::SitemapSession'
      many_to_one :root, class: 'SimpleApi::Sitemap::Root'
      many_to_one :rule, class: 'SimpleApi::Rule'
      # many_to_one :sitemap_session, class: 'SimpleApi::Sitemap::SitemapSession'
      many_to_one :parent, class: 'SimpleApi::Sitempa::Production'
      one_to_many :children, class: 'SimpleApi::Sitemap::Production', key: :parent_id

      state_machine :state, initial: :new_session do
        state :new_session
        state :caches_ready
        state :root_prepared
        state :rule_prepared
        state :indexed
        state :emptied
        state :doubles_marked
        state :merged_forwardables
        state :linked
        state :link_tested
        state :stopped
        state :failed
        state :ready

        event :start do
          transition new_session: :caches_ready, if: lambda { DB[:criteria].count == 0 || DB[:catalogs].count == 0 }
          transition new_session: :root_prepared
        end
        before_transition new_session: :caches_ready, do: :sm_renew_caches
        after_transition new_session: :caches_ready, do: :fire_split_roots

        event :split_roots do
          transition caches_ready: :root_prepared
        end
        before_transition [:caches_ready, :new_session] => :root_prepared, do: :sm_split_roots
        after_transition [:caches_ready, :new_session] => :root_prepared, do: :fire_split_rules

        event :split_rules do
          transition root_prepared: :rule_prepared
        end
        before_transition root_prepared: :rule_prepared, do: :sm_split_rules
        after_transition root_prepared: :rule_prepared, do: :fire_build_indexes

        event :build_indexes do
          transition rule_prepared: :indexed
        end
        before_transition rule_prepared: :indexed, do: :sm_build_indexes
        after_transition rule_prepared: :indexed, do: :fire_mark_empty

        event :mark_empty do
          transition indexed: :emptied
        end
        before_transition indexed: :emptied, do: :sm_mark_empty
        after_transition indexed: :emptied, do: :fire_mark_duplicates

        event :mark_duplicates do
          transition emptied: :doubles_marked
        end
        before_transition emptied: :doubles_marked, do: :sm_mark_duplicates
        after_transition emptied: :doubles_marked, do: :fire_merge_forwardable

        event :merge_forwardable do
          transition doubles_marked: :merged_forwardables
        end
        before_transition doubles_marked: :merged_forwardables, do: :sm_merge_forwardable
        after_transition doubles_marked: :merged_forwardables, do: :fire_prepare_links

        event :prepare_links do
          transition merged_forwardables: :linked
        end
        before_transition merged_forwardables: :linked, do: :sm_prepare_links
        after_transition merged_forwardables: :linked, do: :fire_test_link_avail

        event :test_link_avail do
          transition linked: :link_tested
        end
        before_transition linked: :link_tested, do: :sm_test_link_avail
        after_transition linked: :link_tested, do: :fire_finish

        event :clean do
        end

        event :restart do
        end

        event :finish do
          transition rule_prepared: :ready, if: lambda { rule && children.all?{|child| child.ready? } }
          transition rule_prepared: :rule_prepared
          transition root_prepared: :ready, if: lambda { root && children.all?{|child| child.ready? } }
          transition root_prepared: :root_prepared
          transition link_tested: :ready
        end
        before_transition link_tested: :ready, do: :sm_finish
        after_transition link_tested: :ready, do: :fire_parent_rule_finish
        after_transition rule_prepared: :ready, do: :fire_parent_root_finish
        before_transition root_prepared: :ready, do: :sm_parent_root_finish
        before_transition rule_prepared: :ready, do: :sm_parent_rule_finish

        event :stop do
          transition any - [:failed] => :stopped
        end
      end

      def sm_renew_caches
        DB[:criteria].where(1 => 1).delete
        DB[:catalogs].where(1 => 1).delete
        SimpleApi::Sitemap.preload_criteria
        f = SimpleApi::RuleDefs.from_name('path').load_rule('path', 'any')
        f.class.prepare_list
      end

      def fire_split_roots
        WorkerSplitRoots.perform_async(pk)
      end

      def sm_split_roots
        slist = json_load(step_params, {})['spheres'] || []
        slist.each do |sp|
          rt = SimpleApi::Sitemap::Root.create(sitemap_session_id: sitemap_session.pk, param: param, sphere: sp, name: sp, active: false)
          child = SimpleApi::Sitemap::Production.create(sitemap_session_id: sitemap_session.pk, param: param, root_id: rt.pk, sphere: sp, parent_id: pk, state: 'root_prepared')
        end
      end

      # todo add root_id to all sitemap models

      def fire_split_rules
        children.each{|c| WorkerSplitRules.perform_async(c.pk) }
      end

      def sm_split_rules
        rlist = SimpleApi::Rule.where(sphere: sphere, param: (param || 'group'))
        rlist.each do |rul|
          SimpleApi::Sitemap::Production.create(sitemap_session_id: sitemap_session.pk, param: param, root_id: root.pk, sphere: sphere, rule_id: rul.pk, parent_id: pk, state: 'rule_prepared')
        end
      end

      def fire_build_indexes
        children.each{|c| WorkerBuildIndexes.perform_async(c.pk) }
      end
      def sm_build_indexes
        rule.build_index(root)
      end
      def fire_mark_empty
        WorkerMarkEmpty.perform_async(pk)
      end
      def sm_mark_empty
        Sentimeta.env   = CONFIG["fapi_stage"] || :production # :production is default
        rule.references_dataset.where(is_empty: nil, sitemap_session_id: sitemap_session.pk).order(:id).all.each do |obj|
          puts "rework empty #{rule.pk}:#{obj.pk}" if obj.pk % 100 == 0
          param = json_load(obj.json, {})
          # Sentimeta.lang  = rule.lang.to_sym
          # Sentimeta.sphere = rule.sphere
          path = param.delete('catalog').to_s.split(',') if param.has_key?('catalog')
          path = param.delete("path").to_s.split(',') if param.has_key?('path')
          empty = (Sentimeta::Client.fetch :objects, {sphere: rule.sphere, lang: rule.lang.to_sym, "is_empty" => 4}.merge("criteria" => [param.delete('criteria')].compact, "filters" => param.delete_if{|k, v| k == 'rule' }.merge(path.empty? ? {} : {"catalog" => path + (['']*3).drop(path.size)})) rescue OpenStruct.new(body: {})).body["is_empty"]
          obj.update(:is_empty => empty)
        end
      end
      def fire_mark_duplicates
        WorkerMarkDuplicates.perform_async(pk)
      end
      def sm_mark_duplicates
        doubles = SimpleApi::Sitemap::Reference.select{[min(id).as(:min_id), url]}.group([:url]).having('count(*) > 1')
        #.where(rule_id: rule.pk, root_id: root.pk)
        doubles.each do |dble|
          puts "rework double #{dble[:min_id]}"
          rs = SimpleApi::Sitemap::Reference.order(:id).where(url: dble.url).all.select{|h| h.id != dble[:min_id].to_i }
          # rs = SimpleApi::Sitemap::Reference.order(:id).where(rule_id: rule.pk, root_id: root.pk, url: dble.url).all.select{|h| h.id != dble[:min_id].to_i }
          SimpleApi::Sitemap::Reference.where(:id => rs.map(&:pk)).update(:duplicate_id => dble[:min_id])
        end
      end
      def fire_merge_forwardable
        WorkerMergeForwardable.perform_async(pk)
      end
      def sm_merge_forwardable
        puts "todo: #{SimpleApi::Sitemap::Index.forwardable_indexes(root_id: root_id, rule_id: rule.pk).size}"
        prev = []
        loop do
          break if SimpleApi::Sitemap::Index.forwardable_indexes(root_id: root.pk, rule_id: rule.pk).empty?
          if prev.sort_by{|o| o[:id] } == SimpleApi::Sitemap::Index.forwardable_indexes(root_id: root.pk, rule_id: rule.pk).sort_by{|o| o[:id] }
            puts "cicle #{pk.to_s}"
            break
          end
          prev = SimpleApi::Sitemap::Index.forwardable_indexes(root_id: root.pk, rule_id: rule.pk)
          SimpleApi::Sitemap::Index.forwardable_indexes(root_id: root.pk, rule_id: rule.pk).each do |fwd_idx|
            fwd = SimpleApi::Sitemap::Index[fwd_idx[:id]]
            next unless fwd
            parent = fwd.parent
            next unless parent
            flt = json_load(parent.filter, parent.filter)
            val = json_load(parent.value, parent.value)
            flt = [flt] unless flt.is_a?(::Array)
            val = [val] unless val.is_a?(::Array)
            fwd.update(parent_id: parent.parent_id, filter: JSON.dump(flt + [json_load(fwd.filter, fwd.filter)].flatten), value: JSON.dump(val + [json_load(fwd.value,fwd.value)].flatten))
            parent.delete
          end
        end
        index_ids = SimpleApi::Sitemap::Index.where(root_id: root.pk, rule_id: rule.pk).all.map(&:pk)
        refs = SimpleApi::Sitemap::Reference.where(root_id: root.pk, index_id: index_ids, super_index_id: nil).order(:id).all
        puts "todo: #{refs.size} refs"
        refs.each do |ref|
          ref.update(super_index_id: ref.index.parent_id)
          print '.' if ref.pk % 100 == 0
        end
        puts '', 'done'
      end
      def fire_prepare_links
        WorkerPrepareLinks.perform_async(pk)
      end
      def sm_prepare_links
        Sentimeta.env   = CONFIG["fapi_stage"]
        # Sentimeta.lang  = rule.lang.to_sym
        # Sentimeta.sphere = rule.sphere
        router = SimpleApiRouter.new(rule.lang, rule.sphere)
        leafs = rule.references_dataset.where(is_empty: false, root_id: root.pk).order(:index_id).all.map(&:index).uniq
        parents = []
        leafs.each do |index|
          refs = index.references
          param = json_load(index.json)
          refs_param = json_load(refs.first.json, {}).delete_if{|k, v| k == 'rule' || k == 'rule_id' }
          url = router.route_to('rating', refs_param.dup)
          label = tr_h1_params(json_load(rule.content)['h1'], refs_param)
          path = param.delete('catalog').to_s.split(',') if param.has_key?('catalog')
          path ||= param.delete("path").to_s.split(',') if param.has_key?('path')
          data = (Sentimeta::Client.fetch :objects, {lang: rule.lang.to_sym, sphere: rule.sphere, 'fields' => {'limit_objects' => '100'}}.merge("criteria" => [param.delete('criteria')].compact, "filters" => param.delete_if{|k, v| k == 'rule' }.merge(path.empty? ? {} : {"catalog" => path + (['']*3).drop(path.size)})) rescue OpenStruct.new(body: {})).body
          next if data.blank?
          next if data['objects'].nil?
          puts "rework links #{index.pk}=#{data['objects'].size}.#{refs.size}"
          parents << index.parent if index.parent
          data['objects'].select{|o| o.has_key?('photos') && o['photos'].present? && o['photos'].select{|p| p['type'] != 'trailer'}.present? }.sample(8).each do |obj|
            index.objects_dataset.insert( 
                                         url: url,
                                         photo: obj['photos'].select{|p| p['type'] != 'trailer'}.try(:first).try(:[], 'url'),
                                         label: label,
                                         rule_id: rule.pk,
                                         root_id: root.pk,
                                         index_id: index.pk
                                        )
          end
        end
        until parents.blank?
          current = parents.uniq.dup
          parents.clear
          current.each do |index|
            parents << index.parent if index.parent
            links = index.children.map(&:objects).flatten
            puts "propagate #{index.pk}=#{links.size}"
            links.sample(8).each do |link|
              index.objects_dataset.insert(index_id: index.pk, url: link.url, photo: link.photo, label: link.label, rule_id: rule.pk, root_id: root.pk)
            end
          end
        end
        rule.objects_dataset.where(root_id: root.pk, rule_id: rule.pk).all.uniq.sample(8).each do |link|
          rule.objects_dataset.insert(url: link.url, rule_id: rule.pk, photo: link.photo, label: link.label, index_id: nil, root_id: root.pk)
        end
      end
      def fire_test_link_avail
        WorkerTestLinkAvail.perform_async(pk)
      end
      def sm_test_link_avail
        invalid = []
        SimpleApi::Sitemap::ObjectData.where(root_id: root.pk, rule_id: rule.pk).all.each do |obj|
          unless cod = obj.check_photo.is_a?(TrueClass)
            invalid << "#{cod.to_s} #{obj.photo}"
            # obj.delete
          end
        end
        File.open('./log/invalud_photo.log', 'w+'){|f| invalid.each{|s| f.puts s } }
      end
      def fire_finish
        WorkerFinish.perform_async(pk)
      end
      def sm_finish
      end
      def sm_parent_root_finish
        root.update(active: true)
        (SimpleApi::Sitemap::Root.where(active: true, sphere: sphere).all - [self]).each{|r| r.update(active: false) }
      end
      def sm_parent_rule_finish
      end
      def fire_parent_rule_finish
        WorkerParentRuleFinish.perform_async(parent.pk)
      end
      def fire_parent_root_finish
        WorkerParentRootFinish.perform_async(parent.pk)
      end
    end
  end
end
