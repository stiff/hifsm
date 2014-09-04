module Hifsm
  module Adapters
    module ActiveRecordAdapter
      def self.included(base)
        base.class_eval do
          extend ClassMethods
        end
      end

      module ClassMethods
        def hifsm(column, &block)
          include Hifsm.fsm_module(column, &block)
          before_save "hifsm_write_#{column}_attribute"

          send("#{column}_machine_definition").all_states.each do |st|
            state_name = st.to_s
            scope_name = state_name.gsub('.', '_')
            if st.sub_fsm
              scope scope_name, lambda { where(arel_table[column].matches(state_name + '.%')) }
            else
              scope scope_name, lambda { where(column => state_name) }
            end
          end

          define_method "#{column}=" do |value|
            raise 'not (sure will be) implemented'
          end

          define_method "initial_#{column}" do
            read_attribute(column)
          end

          define_method "hifsm_write_#{column}_attribute" do
            write_attribute(column, send(column))
          end
        end
      end
    end
  end
end

ActiveRecord::Base.class_eval do
  include Hifsm::Adapters::ActiveRecordAdapter
end
