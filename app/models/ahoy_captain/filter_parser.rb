module AhoyCaptain
  class FilterParser
    FILTER_MENU_MAX_SIZE = 2
    class Item
      attr_accessor :name, :column, :description, :values, :predicate, :url, :modal, :label

      def title
        column.titleize
      end
    end

    def self.parse(request)
      new(request).tap do |instance|
        instance.parse
      end
    end

    delegate_missing_to :@items

    def initialize(request)
      @request = request
      @params = @request.params
      @filter_params = @request.params[:q] || {}
      @items = {}
    end

    def parse
      @filter_params.each do |key, values|
        item = Item.new

        item.values = Array(values)
        item.predicate = Ransack::Predicate.detect_and_strip_from_string!(key.dup)
        item.column = key.delete_suffix("_#{item.predicate}")
        modal_name = AhoyCaptain.config.filters.detect { |_, filters| filters.include?(item.column) }[1].modal_name
        if modal_name
          item.modal = modal_name
        end

        label = if item.column == "goal"
          AhoyCaptain.config.goals[values].title
        else
          item.values.to_sentence(last_word_connector: " or ")
        end
        item.label = label
        item.description = "#{item.column.titleize} #{::AhoyCaptain::PredicateLabel[item.predicate]} #{label}"
        item.url = build_url(key, values)
        @items[key] = item
      end

      @items
    end

    private

    def build_url(name, values)
      search_params = @request.query_parameters.deep_dup
      if search_params["q"][name].is_a?(Array)
        search_params["q"][name] = search_params["q"][name] - Array(values)
      else
        search_params["q"].delete(name)
      end

      @request.path + "?" + search_params.to_query
    end

  end
end
