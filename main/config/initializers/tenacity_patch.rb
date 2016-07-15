# Tenacity override for primary key which is redefined1
#
module Tenacity

  module OrmExt
    module ActiveRecord
      module ClassMethods

        def _t_find(id)
          where(self.primary_key => _t_serialize(id))
        end

        def _t_find_bulk(ids)
          return [] if ids.nil? || ids.empty?
          where(:all, :conditions => ["#{self.primary_key} in (?)", _t_serialize_ids(ids)])
        end

        def _t_delete(ids, run_callbacks=true)
          if run_callbacks
            destroy_all(["#{self.primary_key} in (?)", _t_serialize_ids(ids)])
          else
            delete_all(["#{self.parimary_key} in (?)", _t_serialize_ids(ids)])
          end
        end

      end
    end
  end
end
