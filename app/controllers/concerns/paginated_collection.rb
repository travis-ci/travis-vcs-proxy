module PaginatedCollection
  extend ActiveSupport::Concern

  def paginated_collection(resource_name, serializer, collection)
    data = {}
    limit = collection.limit_value
    pagination = {
      count: collection.total_count,
      is_first: collection.first_page?,
      is_last: collection.last_page?,
      offset: (collection.current_page - 1) * limit,
      limit: limit,
      first: {
        limit: limit,
        offset: 0
      },
      last: {
        limit: limit,
        offset: (collection.total_pages - 1) * limit
      },
      prev: nil,
      next: nil
    }
    pagination[:prev] = { limit: limit, offset: (collection.prev_page - 1) * limit } if collection.prev_page
    pagination[:next] = { limit: limit, offset: collection.current_page * limit } if collection.next_page

    data[:meta] = { pagination: pagination }
    data[resource_name] = collection.map do |item|
      presented_entity(serializer, item)
    end

    data
  end
end