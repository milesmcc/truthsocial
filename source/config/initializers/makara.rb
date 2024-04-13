Makara::Cookie::DEFAULT_OPTIONS[:same_site] = :lax
Makara::Cookie::DEFAULT_OPTIONS[:secure]    = Rails.env.production? || ENV['LOCAL_HTTPS'] == 'true'

module ReadFromReplica
  def read_from_replica
    if Rails.env.production? &&  ENV['DB_REPLICA_ENABLED'] == 'true'
      ActiveRecord::Base.connection.without_sticking do
        yield
      end
    else
      yield
    end
  end
end

Object.send :include, ReadFromReplica
