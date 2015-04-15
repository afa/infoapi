require 'ostruct'
module SimpleApi
  module Sitemap
    class Production < Sequel::Model

      set_dataset :productions

      many_to_one :sitemap_session, class: 'SimpleApi::Sitemap::SitemapSession'
      many_to_one :root, class: 'SimpleApi::Sitemap::Root'
      many_to_one :rule, class: 'SimpleApi::Rule'
      # many_to_one :sitemap_session, class: 'SimpleApi::Sitemap::SitemapSession'
      many_to_one :parent, class: 'SimpleApi::Sitemap::Production'
      one_to_many :children, class: 'SimpleApi::Sitemap::Production', key: :parent_id

      state_machine :state, initial: :new_session do
        state :new_session
        state :root_prepared
        state :caches_ready
        state :rule_prepared
        state :indexed
        state :refered
        state :emptied
        state :doubles_marked
        state :merged_forwardables
        state :linked
        state :link_tested

        state :junked
        state :junk_emptied
        state :junk_doubled

        state :stopped
        state :failed
        state :ready

        event :start do
          # transition new_session: :caches_ready, if: lambda { DB[:criteria].count == 0 || DB[:catalogs].count == 0 }
          transition new_session: :root_prepared
        end
        before_transition :new_session => :root_prepared, do: :sm_split_roots
        after_transition :new_session => :root_prepared, do: :fire_renew_caches

        event :renew_caches do
          transition root_prepared: :caches_ready
        end
        before_transition root_prepared: :caches_ready, do: :sm_renew_caches
        after_transition root_prepared: :caches_ready, do: :fire_split_rules

        event :split_rules do
          transition caches_ready: :rule_prepared
        end
        before_transition caches_ready: :rule_prepared, do: :sm_split_rules
        after_transition caches_ready: :rule_prepared, do: :fire_build_indexes

        event :build_junk do
          transition rule_prepared: :junked
        end
        before_transition rule_prepared: :junked, do: :sm_build_junk
        after_transition rule_prepared: :junked, do: :fire_empty_junk

        event :empty_junk do
          transition junked: :junk_emptied
        end
        before_transition junked: :junk_emptied, do: :sm_empty_junk
        after_transition junked: :junk_emptied, do: :fire_finish

        event :build_indexes do
          transition rule_prepared: :indexed
        end
        before_transition rule_prepared: :indexed, do: :sm_build_indexes
        after_transition rule_prepared: :indexed, do: :fire_build_references

        event :build_references do
          transition indexed: :refered
        end
        before_transition indexed: :refered, do: :sm_build_references
        after_transition indexed: :refered, do: :fire_mark_empty

        event :mark_empty do
          transition refered: :emptied
        end
        before_transition refered: :emptied, do: :sm_mark_empty
        after_transition refered: :emptied, do: :fire_mark_duplicates

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
          transition rule_prepared: :ready, if: :rule_ready?
          transition rule_prepared: :rule_prepared
          transition root_prepared: :ready, if: :root_ready?
          transition root_prepared: :root_prepared
          transition link_tested: :ready
          transition junk_emptied: :ready
        end
        before_transition link_tested: :ready, do: :sm_finish
        after_transition link_tested: :ready, do: :fire_parent_rule_finish
        before_transition link_tested: :ready, do: :sm_finish
        after_transition link_tested: :ready, do: :fire_parent_rule_finish
        after_transition rule_prepared: :ready, do: :fire_parent_root_finish
        before_transition root_prepared: :ready, do: :sm_parent_root_finish
        before_transition rule_prepared: :ready, do: :sm_parent_rule_finish
        before_transition junk_emptied: :ready, do: :sm_junk_doubles
        after_transition junk_emptied: :ready, do: :fire_parent_rule_finish

        event :stop do
          transition any - [:failed] => :stopped
        end
      end

      def sm_build_junk
        junk = []
        ars = []
        filtre = rule.filters
        order = filtre.traversal_order || []
        # order = json_load(filtre.traversal_order, filtre.traversal_order)
        order.each do |flt|
          flt = 'catalog' if flt == 'path'
          rdef = filtre[flt]
          rdef = filtre['path'] if flt == 'catalog' && filtre['path']
          values = rdef.fetch_list(rule)
          keyz = [flt] * values.size
          ars << keyz.zip(values).map{|a| Hash[*a] }
        end
        return [] if ars.empty? 
        junk += ars.shift
        while ars.present?
          junk = junk.product(ars.shift).map(&:flatten)
        end
        rslt = junk.map do |ah|
          ah.inject({}){|r, h| r.merge(h.is_a?(Hash) ? h : Hash[*h]) }
        end
        rslt.each{|h| rule.write_ref(OpenStruct.new(root_id: root ? root.pk : nil, sitemap_session_id: sitemap_session ? sitemap_session.pk : nil), h, nil) }

      end

      def fire_empty_junk
        WorkerEmptyJunk.perform_async(pk)
      end

      def sm_empty_junk
          Sentimeta.env   = CONFIG["fapi_stage"] || :production # :production is default
          puts "junking rule #{rule.pk} for #{rule.references_dataset.where(root_id: root.pk, is_empty: nil, sitemap_session_id: sitemap_session.pk).count} refs"
          rule.references_dataset.where(root_id: root.pk, is_empty: nil, sitemap_session_id: sitemap_session.pk).order(:id).all.each do |obj|
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

      def sm_junk_doubles
        doubles = SimpleApi::Sitemap::Reference.from(:refs___rleft).join(:refs___rright, rleft__url: :rright__url).select(:rleft__id).where(rleft__duplicate_id: nil, rleft__rule_id: rule.pk, rleft__root_id: root.pk, rleft__is_empty: false)
        doubles.each do |dble|
          dble.reload
          next unless dble.duplicate_id.nil?
          puts "rejunk double #{dble.pk}"
          ors_1 = SimpleApi::Sitemap::Reference.where(url: dble.url, root_id: root.pk).exclude(duplicate_id: nil).order(:id).first
          if ors_1
          SimpleApi::Sitemap::Reference.where(:id => dble.pk).update(:duplicate_id => ors_1.duplicate_id)
          next
          end
          ors_2 = SimpleApi::Sitemap::Reference.where(url: dble.url, duplicate_id: nil, root_id: root.pk).exclude(rule_id: rule.pk).order(:id).first
          if ors_2
          SimpleApi::Sitemap::Reference.where(:id => dble.pk).update(:duplicate_id => ors_2.pk)
          next
          end
          next if SimpleApi::Sitemap::Reference.where(url: dble.url, root_id: root.pk, duplicate_id: nil).count < 2
          dble.update(duplicate_id: SimpleApi::Sitemap::Reference.where(root_id: root.pk, url: dble.url, duplicate_id: nil).exclude(id: dble.pk).first.pk)
        end
      end


      def rule_ready?
        rule && children.all?{|child| child.ready? } 
      end

      def root_ready?
        root && children.all?{|child| child.ready? } 
      end

      def sm_renew_caches
        SimpleApi::Sitemap::Vocabula::VOCABULAS[root.sphere].each do |attr|
          SimpleApi::Rule.where(sphere: root.sphere, param: %w(group rating rating-annotation)).all.map(&:lang).uniq.each do |lang|
            SimpleApi::Sitemap::Vocabula.take(root.sphere, lang, attr) unless SimpleApi::Sitemap::Vocabula.fresh?(root.sphere, lang, attr)
          end
        end
      end

      def fire_renew_caches
        children.each{|c| WorkerRenewCaches.perform_async(c.pk) }
      end

      def fire_split_roots
        WorkerSplitRoots.perform_async(pk)
      end

      def sm_split_roots
        slist = json_load(step_params, {'spheres' => []})['spheres']
        slist.each do |sp|
          rt = SimpleApi::Sitemap::Root.create(sitemap_session_id: sitemap_session.pk, param: param, sphere: sp, name: sp, active: false)
          # SimpleApi::Sitemap::Index.create(root_id: rt.pk, rule_id: nil, label: sp, filter: '[]', value: '[]', url: "/en/#{sp}/index/#{rt.param}", json: '{}', parent_id: nil)
          child = SimpleApi::Sitemap::Production.create(sitemap_session_id: sitemap_session.pk, param: param, root_id: rt.pk, sphere: sp, parent_id: pk, state: 'root_prepared')
        end
      end

      # todo add root_id to all sitemap models

      def fire_split_rules
        WorkerSplitRules.perform_async(pk)
      end

      def sm_split_rules
        rl = SimpleApi::Rule.where(sphere: sphere, param: %w(rating rating-annotation)).order(:position).all.select{|r| r.filters.traversal_order && r.filters.traversal_order.present? }
        rl.each do |rul|
          SimpleApi::Sitemap::Production.create(sitemap_session_id: sitemap_session.pk, param: rul.param, root_id: root.pk, sphere: sphere, rule_id: rul.pk, parent_id: pk, state: 'rule_prepared')
        end
        rlist = SimpleApi::Rule.where(sphere: sphere, param: (param || 'group'))
        rlist.each do |rul|
          # pidx = SimpleApi::Sitemap::Index.where(root_id: root.pk, rule_id: nil, parent_id: nil).first
          # p pidx
          idx = SimpleApi::Sitemap::Index.create(root_id: root.pk, rule_id: rul.pk, label: json_load(rul.content, {})['index'] || json_load(rul.content, {})['h1'], filter: '[]', value: '[]', url: "/en/#{root.sphere}/index/#{root.param},#{rul.name}", json: '{}', parent_id: nil)
          p idx
          SimpleApi::Sitemap::Production.create(sitemap_session_id: sitemap_session.pk, param: param, root_id: root.pk, sphere: sphere, rule_id: rul.pk, parent_id: pk, state: 'rule_prepared')
        end
      end

      def fire_build_indexes

        children.select{|c| c.param != 'group' }.each{|c| WorkerBuildJunk.perform_async(c.pk) }
        children.select{|c| c.param == 'group' }.each{|c| WorkerBuildIndexes.perform_async(c.pk) }
      end

      def sm_build_indexes
        rule.build_index(root)
      end

      def fire_build_references
        WorkerBuildReferences.perform_async(pk)
      end

      def sm_build_references
        rule.indexes_dataset.where(leaf: true, root_id: root.pk).each do |idx|
          rule.write_ref(root, json_load(idx.json), idx.pk)
          # idx.delete
        end
        # rule.build_index(root)
      end

      def fire_mark_empty
        WorkerMarkEmpty.perform_async(pk)
      end

      def sm_mark_empty
        Sentimeta.env   = CONFIG["fapi_stage"] || :production # :production is default
        rule.references_dataset.where(root_id: root.pk, is_empty: nil, sitemap_session_id: sitemap_session.pk).order(:id).all.each do |obj|
          puts "rework empty #{rule.pk}:#{obj.pk}" if obj.pk % 100 == 0
          param = json_load(obj.json, {})
          # Sentimeta.lang  = rule.lang.to_sym
          # Sentimeta.sphere = rule.sphere
          path = param.delete('catalog').to_s.split(',') if param.has_key?('catalog')
          path = param.delete("path").to_s.split(',') if param.has_key?('path')
          empty = (Sentimeta::Client.fetch :objects, {sphere: rule.sphere, lang: rule.lang.to_sym, "is_empty" => 4}.merge("criteria" => [param.delete('criteria')].compact, "filters" => param.delete_if{|k, v| k == 'rule' }.merge(path.empty? ? {} : {"catalog" => path + (['']*3).drop(path.size)})) rescue OpenStruct.new(body: {})).body["is_empty"]
          obj.update(:is_empty => empty)
        end
        puts 'mark indexes'
        rule.references_dataset.where(sitemap_session_id: sitemap_session.pk, root_id: root.pk).order(:id).all.each do |obj|
          obj.index.try(:update, {empty: obj.is_empty})
        end
      end

      def fire_mark_duplicates
        WorkerMarkDuplicates.perform_async(pk)
      end

      def sm_mark_duplicates
        doubles = SimpleApi::Sitemap::Reference.from(:refs___rleft).join(:refs___rright, rleft__url: :rright__url).select(:rleft__id).where(rleft__duplicate_id: nil, rleft__rule_id: rule.pk, rleft__root_id: root.pk, rleft__is_empty: false)
        doubles.each do |dble|
          dble.reload
          next unless dble.duplicate_id.nil?
          puts "rework double #{dble.pk}"
          ors_1 = SimpleApi::Sitemap::Reference.where(url: dble.url, root_id: root.pk).exclude(duplicate_id: nil).order(:id).first
          if ors_1
          SimpleApi::Sitemap::Reference.where(:id => dble.pk).update(:duplicate_id => ors_1.duplicate_id)
          next
          end
          ors_2 = SimpleApi::Sitemap::Reference.where(url: dble.url, duplicate_id: nil, root_id: root.pk).exclude(rule_id: rule.pk).order(:id).first
          if ors_2
          SimpleApi::Sitemap::Reference.where(:id => dble.pk).update(:duplicate_id => ors_2.pk)
          next
          end
          next if SimpleApi::Sitemap::Reference.where(url: dble.url, root_id: root.pk, duplicate_id: nil).count < 2
          dble.update(duplicate_id: SimpleApi::Sitemap::Reference.where(root_id: root.pk, url: dble.url, duplicate_id: nil).exclude(id: dble.pk).first.pk)

        end
      end

      def fire_merge_forwardable
        WorkerMergeForwardable.perform_async(pk)
      end

      def sm_merge_forwardable
        puts "mf stage 1 "
        rule.indexes_dataset.use_cursor.distinct(:parent_id).where(leaf: true, root_id: root.pk).select(:parent_id).group(:parent_id).order(:parent_id).map(&:parent).each do |idx|
          print '.' if idx.try(:pk) % 100 == 0
        # rule.indexes_dataset.where(leaf: true, root_id: root.pk).all.map(&:parent).compact.uniq.each do |idx|
          if idx.children_dataset.where{ Sequel.|({empty: false}, {empty: nil})}.empty?
            idx.update(empty: true)
          end
        end
        curr = []
        prev = []
        par = rule.indexes_dataset.use_cursor.where(empty: true, root_id: root.pk).exclude(leaf: true).all
        puts "propagate empty #{par.size}"
        loop do
          curr = par.compact.uniq
          par = []
          break if curr.empty?
          break if curr.map(&:pk).sort == prev
          prev = curr.map(&:pk).sort
          curr.map(&:parent).compact.uniq.each do |ix|
            print '.' if ix.try(:pk) % 100 == 0
            par << ix.update(empty: true) if (ix && !ix.empty) && ix.children_dataset.where{ Sequel.|({empty: false}, {empty: nil})}.empty?
          end
        end
        puts "todo: #{SimpleApi::Sitemap::Index.forwardable_indexes_dataset(root_id: root_id, rule_id: rule_id).count}"
        prev = []
        loop do
          ds = SimpleApi::Sitemap::Index.forwardable_indexes_dataset(root_id: root_id, rule_id: rule_id)
          break if ds.empty?
          if prev.sort_by{|o| o[:id] } == ds.order(:id).all
            puts "cycle #{pk.to_s}"
            break
          end
          prev = SimpleApi::Sitemap::Index.forwardable_indexes(root_id: root.pk, rule_id: rule.pk)
          SimpleApi::Sitemap::Index.forwardable_indexes(root_id: root.pk, rule_id: rule.pk).each_with_index do |fwd_idx, i|
            print '.' if i % 100 == 0
            fwd = SimpleApi::Sitemap::Index[fwd_idx[:id]]
            next unless fwd
            parent = fwd.parent
            # p 'fwd-par', fwd, parent
            next unless parent
            fwd.update({parent_id: parent.parent_id, root_id: parent.root_id, rule_id: parent.rule_id}.merge(make_merged_values(parent, fwd)))
            parent.delete
          end
        end
        # idxs = SimpleApi::Sitemap::Index.select(:rule_id).group(:rule_id).having{count(:id) < 2}.all.map{|i| SimpleApi::Sitemap::Index.where(parent_id: nil, rule_id: i.rule_id).first }
        # puts "todo #{idxs.size} heads"
        # idxs.each do |idx|
        #   idx.children.each do |child|
        #     child.update({parent_id: nil}.merge(make_merged_values(idx, child)))
        #   end
        #   idx.delete
        # end
        # # idxs = SimpleApi::Sitemap::Index.where(rule_id: rule.pk, parent_id: nil, root_id: root.pk).all.select{|i| i.children.size <= 1 }
        # puts 
        # index_ids = SimpleApi::Sitemap::Index.where(root_id: root.pk, rule_id: rule.pk).all.map(&:pk)
        # refs = SimpleApi::Sitemap::Reference.where(root_id: root.pk, index_id: index_ids, super_index_id: nil).order(:id).all
        # puts "todo: #{refs.size} refs"
        # refs.each do |ref|
        #   ref.update(super_index_id: ref.index.parent_id)
        #   print '.' if ref.pk % 100 == 0
        # end
        puts '', 'done'
      end

      def make_merged_values(left, right)
        flt = json_load(left.filter, left.filter)
        val = json_load(left.value, left.value)
        flt = [flt] unless flt.is_a?(::Array)
        val = [val] unless val.is_a?(::Array)
        {filter: JSON.dump(flt + [json_load(right.filter, right.filter)].flatten), value: JSON.dump(val + [json_load(right.value,right.value)].flatten), label: [left.label, right.label].join(',')} #.tap{|x| p 'prep', left, right, x }
      end

      def fire_prepare_links
        WorkerPrepareLinks.perform_async(pk)
      end

      def sm_prepare_links
        puts "pl rule #{rule.pk} prod #{pk} start"
        Sentimeta.env = CONFIG["fapi_stage"]
        # Sentimeta.lang  = rule.lang.to_sym
        # Sentimeta.sphere = rule.sphere
        router = SimpleApiRouter.new(rule.lang, rule.sphere)
        puts "pl stage 1 count leafs"
        leafs = SimpleApi::Sitemap::Index.select(:indexes__id).join(:refs, index_id: :id).where(indexes__rule_id: rule.pk, refs__is_empty: false, indexes__root_id: root.pk).order(:id).distinct(:id).map(&:reload)
        puts "pl stage 2 #{leafs.size} leafs"
        # leafs = rule.references_dataset.where(is_empty: false, root_id: root.pk).order(:index_id).all.map(&:index).uniq.compact
        parents = []
        puts "links todo leafs #{leafs.size}"
        leafs.each do |index|
          refs = index.references
          parm = json_load(index.json)
          refs_param = json_load(refs.first.json, {}).delete_if{|k, v| k == 'rule' || k == 'rule_id' }
          url = router.route_to('rating', refs_param.dup)
          label = tr_h1_params(json_load(rule.content)['h1'], refs_param.dup, sphere, rule.lang)
          path = parm.delete('catalog').to_s.split(',') if parm.has_key?('catalog')
          path ||= parm.delete("path").to_s.split(',') if parm.has_key?('path')
          data = Sentimeta::Client.objects({lang: rule.lang.to_sym, sphere: rule.sphere, 'fields' => {'limit_objects' => '100'}}.merge("criteria" => [parm.delete('criteria')].compact, "filters" => parm.delete_if{|k, v| k == 'rule' }.merge(path.empty? ? {} : {"catalog" => path + (['']*3).drop(path.size)}))) rescue []
          next if data.blank?
          # next if data['objects'].nil?
          puts "rework links #{index.pk}=#{data.size}.#{refs.size}"
          parents << index.parent if index.parent
          data.select{|o| o.has_key?('photos') && o['photos'].present? && o['photos'].select{|p| p['type'] != 'trailer'}.present? }.sample(8).each do |obj|
            obj_ph = obj['photos'].select{|p| p['type'] != 'trailer'}.try(:first)
            index.objects_dataset.insert( 
                                         url: url,
                                         photo: obj_ph.try(:[], 'url'),
                                         crypto_hash: obj_ph.try(:[], 'hash'),
                                         label: label,
                                         rule_id: rule.pk,
                                         root_id: root.pk,
                                         index_id: index.pk
                                        )
          end
        end
        until parents.blank?
          puts "pl stage 3 #{parents.size} parents cycled"
          current = parents.uniq.dup
          parents.clear
          current.each do |index|
            parents << index.parent if index.parent
            links = index.children.map(&:objects).flatten
            puts "propagate #{index.pk}=#{links.size}"
            links.sample(8).each do |link|
              index.objects_dataset.insert(index_id: index.pk, crypto_hash: link.crypto_hash, url: link.url, photo: link.photo, label: link.label, rule_id: rule.pk, root_id: root.pk)
            end
          end
        end
        puts "pl stage 4 upd root objs from #{rule.objects_dataset.where(root_id: root.pk).count} photos"
        rule.objects_dataset.where(root_id: root.pk).all.uniq.sample(8).each do |link|
          rule.objects_dataset.insert(url: link.url, rule_id: rule.pk, photo: link.photo, label: link.label, index_id: nil, root_id: root.pk)
        end
        puts "pl stage 5 for #{rule.indexes_dataset.count}"
        rule.indexes_dataset.use_cursor.where(leaf: true, root_id: root.pk).each do |idx|
          unless idx.references_dataset.empty?
            idx.references_dataset.each do |r|
              ph = idx.objects_dataset.exclude(photo: nil).all.sample
              r.update(photo: ph.photo, crypto_hash: ph.crypto_hash, index_id: idx.parent_id, label: ph.label) if ph
            end
          end
          idx.delete
        end
        puts "pl rule #{rule.pk} prod #{pk} done"
      end

      def fire_test_link_avail
        WorkerTestLinkAvail.perform_async(pk)
      end

      def sm_test_link_avail
        invalid = []
        SimpleApi::Sitemap::ObjectData.where(root_id: root.pk, rule_id: rule.pk).all.each_with_index do |obj, i|
          print '.' if i % 100 == 0
          unless cod = obj.check_photo.is_a?(TrueClass)
            invalid << "#{cod.to_s} #{obj.photo}"
            # obj.delete
          end
        end
        puts "", "test links done for #{invalid.size} bads"
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
